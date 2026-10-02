-- In Character Forever - Beacon and Notice Lifecycle

Blackacre = Blackacre or {}
Blackacre.Lifecycle = {}

local pairs, time, tonumber = pairs, time, tonumber
local C_Timer, CreateFrame = C_Timer, CreateFrame

local function BeaconTTL()
    return (Blackacre.BeaconConfig and Blackacre.BeaconConfig.TTL) or (24 * 60 * 60)
end

local MAX_BULLETIN_DAYS = 7
-- Owner rule: a notice stays up 12 hours to 7 days, poster's choice.
local MIN_BULLETIN_SECONDS = 12 * 60 * 60
local MAX_BULLETIN_SECONDS = MAX_BULLETIN_DAYS * 24 * 60 * 60

function Blackacre.Lifecycle.ClampBulletinSeconds(seconds)
    seconds = tonumber(seconds) or (3 * 24 * 60 * 60)
    if seconds < MIN_BULLETIN_SECONDS then return MIN_BULLETIN_SECONDS end
    if seconds > MAX_BULLETIN_SECONDS then return MAX_BULLETIN_SECONDS end
    return seconds
end

function Blackacre.Lifecycle.GetBulletinTTLSeconds()
    local days = Blackacre.CharDB.settings.bulletinTTLDays
        or Blackacre.CharDB.settings.noticeTTLDays
        or 3
    days = math.min(math.max(days, 1), MAX_BULLETIN_DAYS)
    return days * 24 * 60 * 60
end

-- Account-wide store fix-ups. Once per session: EnsurePresenceDB runs on
-- every beacon message and move tick, and these only matter after a load.
local accountMigrated = false

local function MigrateAccountStores()
    accountMigrated = true
    -- "notices" was the old name for bulletins. Older builds kept both names
    -- pointing at one table, but SavedVariables writes shared tables twice,
    -- so every notice was stored on disk twice. Fold the old name in once.
    if type(BlackacreDB.notices) == "table" then
        if not BlackacreDB.bulletins then
            BlackacreDB.bulletins = BlackacreDB.notices
        elseif BlackacreDB.notices ~= BlackacreDB.bulletins then
            for id, b in pairs(BlackacreDB.notices) do
                if BlackacreDB.bulletins[id] == nil then BlackacreDB.bulletins[id] = b end
            end
        end
    end
    BlackacreDB.notices = nil
    BlackacreDB.bulletins = BlackacreDB.bulletins or {}
    local cache = BlackacreDB.cache
    if cache and type(cache.notice) == "table" then
        cache.bulletin = cache.bulletin or {}
        for id, wrapped in pairs(cache.notice) do
            if cache.bulletin[id] == nil then cache.bulletin[id] = wrapped end
        end
        cache.notice = nil
    end
    -- Older builds also cached every notice we posted, so it sat on disk in
    -- both stores. The posted copy in BlackacreDB.bulletins is the real one.
    local bucket = cache and cache.bulletin
    if bucket then
        for id in pairs(bucket) do
            if BlackacreDB.bulletins[id] ~= nil then bucket[id] = nil end
        end
    end
    BlackacreDB.beacons = BlackacreDB.beacons or {}
end

function Blackacre.Lifecycle.EnsurePresenceDB()
    Blackacre.CharDB.presence = Blackacre.CharDB.presence or {
        receiveBeacons = true,
        seekingEnabled = true,
        emitEnabled = false,
        lastEmitAt = nil,
        activeBeaconId = nil,
        showNameZone = true,
        showNameProximity = true,
        savedBeacons = {},
        draftBeacon = nil,
        heardBeacons = {},
        innToastDay = {},
        lastPingByName = {},
    }
    local p = Blackacre.CharDB.presence
    if p.receiveBeacons == nil then p.receiveBeacons = true end
    if p.seekingEnabled == nil then p.seekingEnabled = true end
    if p.emitEnabled == nil then p.emitEnabled = false end
    p.savedBeacons = p.savedBeacons or {}
    p.heardBeacons = p.heardBeacons or {}
    p.innToastDay = p.innToastDay or {}
    p.lastPingByName = p.lastPingByName or {}
    if not accountMigrated then MigrateAccountStores() end
    -- Cheap, and keeps callers safe if the SavedVariables global is ever swapped.
    if not BlackacreDB.bulletins then BlackacreDB.bulletins = {} end
    if not BlackacreDB.beacons then BlackacreDB.beacons = {} end
    return p
end

---------------------------------------------------------------------------
-- Beacons: our own live in SavedVariables (BlackacreDB.beacons); beacons we
-- hear from other players live in memory only and vanish at logout.
---------------------------------------------------------------------------
local heard = {}

function Blackacre.Lifecycle.HeardBeacons()
    return heard
end

-- Keep one beacon per player: a new id from the same sender replaces the old.
function Blackacre.Lifecycle.StoreHeardBeacon(beacon)
    for id, b in pairs(heard) do
        if id ~= beacon.id and b.senderName == beacon.senderName then heard[id] = nil end
    end
    heard[beacon.id] = beacon
end

-- One-time clean-up: older builds saved other players' beacons to disk.
local function DropSavedForeignBeacons()
    local me = UnitGUID("player")
    for id, b in pairs(BlackacreDB.beacons or {}) do
        if b.ownerGUID ~= me then BlackacreDB.beacons[id] = nil end
    end
    if BlackacreDB.cache then BlackacreDB.cache.beacon = nil end
end

local HEARTBEAT_EVERY = 5 * 60   -- the "I'm here" note, for anyone who missed it
local ROVING_MIN_GAP = 10        -- roving: at most one area-change note per 10 s
local lastHeartbeatAt = 0

-- Send the "I'm here" note for our active beacon (roving beacons move with us).
function Blackacre.Lifecycle.SendHeartbeat(force)
    local p = Blackacre.CharDB and Blackacre.CharDB.presence
    if not p or not p.emitEnabled then return end
    if Blackacre.InInstance() then return end -- beacons rest inside dungeons, raids, battlegrounds
    local b = Blackacre.Lifecycle.GetActiveOwnedBeacon()
    if not b then return end
    local now = GetTime()
    if not force and (now - lastHeartbeatAt) < ROVING_MIN_GAP then return end
    lastHeartbeatAt = now
    if b.locKind == "roving" then
        local ctx = Blackacre.GetZoneContext()
        b.zoneId = ctx.zoneId
        b.zoneName = ctx.zoneName
        b.subzone = ctx.subzone
        b.coords = ctx.coords
    end
    if Blackacre.Comms and Blackacre.Comms.SendBeaconHeartbeat then
        Blackacre.Comms.SendBeaconHeartbeat(b)
    end
end

function Blackacre.Lifecycle.Init()
    Blackacre.Lifecycle.EnsurePresenceDB()
    DropSavedForeignBeacons()
    -- Emit never survives a logout. Draft and named saves do.
    Blackacre.CharDB.presence.emitEnabled = false
    C_Timer.NewTicker(60, Blackacre.Lifecycle.Sweep)
    C_Timer.NewTicker(HEARTBEAT_EVERY, function()
        Blackacre.Lifecycle.SendHeartbeat(true)
    end)
    -- A roving beacon follows us into new areas; tell seekers when it moves.
    local moved = CreateFrame("Frame")
    moved:RegisterEvent("ZONE_CHANGED")
    moved:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    moved:SetScript("OnEvent", function()
        local b = Blackacre.Lifecycle.GetActiveOwnedBeacon()
        if b and b.locKind == "roving" then
            C_Timer.After(1, function() Blackacre.Lifecycle.SendHeartbeat(false) end)
        end
    end)
    -- Loading screens (portals, boats, dungeons, logout): seekers drop our
    -- beacon while we're away. Emit itself stays on; on arrival we announce
    -- again, unless we're inside an instance (beacons rest there).
    -- (This used to turn Emit off on every loading screen.)
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LEAVING_WORLD")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event)
        local p = Blackacre.Lifecycle.EnsurePresenceDB()
        if not p.emitEnabled or not p.activeBeaconId then return end
        if event == "PLAYER_LEAVING_WORLD" then
            if Blackacre.Comms and Blackacre.Comms.BroadcastRetract then
                Blackacre.Comms.BroadcastRetract(p.activeBeaconId, "beacon")
            end
        else
            C_Timer.After(5, function() Blackacre.Lifecycle.SendHeartbeat(true) end)
        end
    end)
end

local function StoreFor(kind)
    if kind == "beacon" then
        return BlackacreDB.beacons
    end
    return BlackacreDB.bulletins
end

local function NormalizeKind(kind)
    if kind == "notice" then return "bulletin" end
    return kind
end

function Blackacre.Lifecycle.Sweep()
    local now = time()
    local guid = UnitGUID("player")
    local beaconsChanged, bulletinsChanged, cacheChanged = false, false, false
    for id, beacon in pairs(BlackacreDB.beacons or {}) do
        if beacon.expiresAt and beacon.expiresAt < now then
            beaconsChanged = true
            if beacon.ownerGUID == guid then
                Blackacre.Lifecycle.ExpireOwned("beacon", id)
            else
                BlackacreDB.beacons[id] = nil
            end
        end
    end
    for id, beacon in pairs(heard) do
        if beacon.expiresAt and beacon.expiresAt < now then
            beaconsChanged = true
            heard[id] = nil
        end
    end
    for id, bulletin in pairs(BlackacreDB.bulletins or {}) do
        if bulletin.expiresAt and bulletin.expiresAt < now and bulletin.status == Blackacre.STATUS.ACTIVE then
            bulletinsChanged = true
            if bulletin.ownerGUID == guid then
                Blackacre.Lifecycle.ExpireOwned("bulletin", id)
            else
                BlackacreDB.bulletins[id] = nil
            end
        end
    end
    if BlackacreDB.cache then
        for _, bucket in pairs(BlackacreDB.cache) do
            for id, wrapped in pairs(bucket) do
                local entry = wrapped.data
                if entry and entry.expiresAt and entry.expiresAt < now then
                    bucket[id] = nil
                    cacheChanged = true
                end
            end
        end
    end
    if BlackacreDB.withdrawn then
        for id, row in pairs(BlackacreDB.withdrawn) do
            if not row.untilTime or row.untilTime < now then
                BlackacreDB.withdrawn[id] = nil
            end
        end
    end
    -- Standing still with nothing expired used to rebuild flyout, pins, and re-deliver
    -- every beacon once a minute. Distance delivery is owned by the move watcher.
    if not beaconsChanged and not bulletinsChanged and not cacheChanged then
        return
    end
    if beaconsChanged and Blackacre.BeaconHint and Blackacre.BeaconHint.Refresh then
        Blackacre.BeaconHint.Refresh()
    end
end

function Blackacre.Lifecycle.ExpireOwned(kind, id)
    kind = NormalizeKind(kind)
    local store = StoreFor(kind)
    local entry = store[id]
    if not entry then return end
    entry.status = Blackacre.STATUS.EXPIRED
    store[id] = nil
    if kind == "beacon" then
        local p = Blackacre.Lifecycle.EnsurePresenceDB()
        if p.activeBeaconId == id then
            p.activeBeaconId = nil
            p.emitEnabled = false -- it has burned out; Emit shows off again
            if Blackacre.Comms and Blackacre.Comms.BroadcastRetract then
                Blackacre.Comms.BroadcastRetract(id, "beacon")
            end
            if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
                Blackacre.UI.Theme.Toast("Your beacon has faded.")
            end
        end
    end
    Blackacre.History.SaveDraft(kind, entry)
end

function Blackacre.Lifecycle.DeleteOwned(kind, id)
    kind = NormalizeKind(kind)
    local store = StoreFor(kind)
    local entry = store[id]
    if kind == "bulletin" then
        Blackacre.Lifecycle.MarkWithdrawn(id, entry and entry.postedZones, entry and entry.expiresAt, true)
    end
    if entry then
        entry.status = Blackacre.STATUS.DRAFT
        store[id] = nil
        Blackacre.History.SaveDraft(kind, entry)
    end
    if kind == "beacon" then
        local p = Blackacre.Lifecycle.EnsurePresenceDB()
        if p.activeBeaconId == id then p.activeBeaconId = nil end
    end
    Blackacre.Comms.BroadcastRetract(id, kind)
    if BlackacreDB.cache then
        if BlackacreDB.cache[kind] then BlackacreDB.cache[kind][id] = nil end
        if kind == "bulletin" and BlackacreDB.cache.notice then
            BlackacreDB.cache.notice[id] = nil
        end
    end
    if Blackacre.BeaconHead and Blackacre.BeaconHead.OnCacheChanged then
        Blackacre.BeaconHead.OnCacheChanged()
    end
    if Blackacre.BeaconHint and Blackacre.BeaconHint.Refresh then
        Blackacre.BeaconHint.Refresh()
    end
end

-- A withdrawal heard on the channel. Only honoured when it comes from the
-- notice's or beacon's own author (sender = who sent the withdrawal).
function Blackacre.Lifecycle.HandleRemoteRetract(kind, id, sender)
    kind = NormalizeKind(kind)
    local SameName = Blackacre.Comms.SameName
    if kind == "beacon" then
        local b = heard[id]
        if not b or not SameName(b.senderName, sender) then return end
        heard[id] = nil
        if Blackacre.BeaconHead and Blackacre.BeaconHead.OnCacheChanged then
            Blackacre.BeaconHead.OnCacheChanged()
        end
        if Blackacre.BeaconHint and Blackacre.BeaconHint.Refresh then
            Blackacre.BeaconHint.Refresh()
        end
        return
    end
    local bucket = BlackacreDB.cache and BlackacreDB.cache.bulletin
    local held = bucket and bucket[id] and bucket[id].data
    if held and not SameName(held.authorName or held.senderName, sender) then
        return -- someone else trying to take this notice down
    end
    -- Remember it (even if we don't hold a copy yet) so a later copy from the
    -- same author is refused. It can't affect anyone else's notices.
    Blackacre.Lifecycle.MarkWithdrawn(id, held and held.postedZones, held and held.expiresAt, false, sender)
    if bucket then bucket[id] = nil end
    if BlackacreDB.cache and BlackacreDB.cache.notice then BlackacreDB.cache.notice[id] = nil end
    if Blackacre.InnBoard and Blackacre.InnBoard.RefreshIfOpen then Blackacre.InnBoard.RefreshIfOpen() end
end

function Blackacre.Lifecycle.CreateBeacon(templateId, slotValues, opts)
    opts = opts or {}
    if not (Blackacre.SentenceTemplates and Blackacre.SentenceTemplates.Resolve) then
        Blackacre.Print("Beacons require In Character Forever: Beacons & Bulletins.")
        return nil
    end
    local resolved = Blackacre.SentenceTemplates.Resolve(templateId, slotValues, Blackacre.CharDB.residence)
    if not resolved then return nil end
    local ctx = Blackacre.GetZoneContext()
    local now = time()
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    local rumor = opts.rumor or ""
    local lead = opts.lead or ""
    local found = opts.found or ""
    if #rumor > 250 then rumor = rumor:sub(1, 250) end
    if #lead > 250 then lead = lead:sub(1, 250) end
    if #found > 250 then found = found:sub(1, 250) end
    local coords = opts.coords or ctx.coords
    return {
        id = Blackacre.NewID(),
        ownerGUID = UnitGUID("player"),
        charName = Blackacre.GetCharName(),
        templateId = templateId,
        slots = resolved.slots,
        fullText = resolved.fullText,
        shortText = resolved.shortText,
        breadcrumb = resolved.shortText,
        zoneId = opts.zoneId or ctx.zoneId,
        zoneName = opts.zoneName or ctx.zoneName,
        subzone = opts.subzone or ctx.subzone,
        coords = coords,
        locKind = opts.locKind or "present",
        rumor = rumor,
        lead = lead,
        found = found,
        createdAt = now,
        expiresAt = now + BeaconTTL(),
        status = Blackacre.STATUS.ACTIVE,
        showNameZone = opts.showNameZone,
        showNameProximity = opts.showNameProximity,
    }
end

function Blackacre.Lifecycle.CreateBulletin(title, bodyText, boardId, scopeTier, extra)
    extra = extra or {}
    local now = time()
    bodyText = bodyText or ""
    if #bodyText > 500 then bodyText = bodyText:sub(1, 500) end
    return {
        id = Blackacre.NewID(),
        ownerGUID = UnitGUID("player"),
        charName = Blackacre.GetCharName(),
        title = title,
        bodyText = bodyText,
        scopeTier = scopeTier or Blackacre.SCOPE.INDIVIDUAL,
        boardId = boardId,
        postedZones = extra.postedZones or {},
        innNpcID = extra.innNpcID,       -- set only for "Only this inn"
        innName = extra.innName,
        zoneName = extra.zoneName,
        factionNet = extra.factionNet,     -- "Spread the word": faction name
        factionNetID = extra.factionNetID,
        lang = extra.lang,               -- author's language ("Common", "Orcish")
        -- Server clock, so a report's send time lines up with Blizzard's log.
        postedAt = GetServerTime and GetServerTime() or now,
        stationary = extra.stationary,
        waxSeal = extra.waxSeal,
        font = extra.font,
        createdAt = now,
        expiresAt = now + Blackacre.Lifecycle.ClampBulletinSeconds(extra.ttlSeconds or Blackacre.Lifecycle.GetBulletinTTLSeconds()),
        editCount = 0,
        status = Blackacre.STATUS.ACTIVE,
    }
end

function Blackacre.Lifecycle.SaveNamedBeacon(slot, name, beacon)
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    slot = math.max(1, math.min(5, tonumber(slot) or 1))
    p.savedBeacons[slot] = {
        name = name and name ~= "" and name or ("Beacon " .. slot),
        beacon = beacon,
    }
    p.draftBeacon = beacon
end

function Blackacre.Lifecycle.LoadNamedBeacon(slot)
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    slot = math.max(1, math.min(5, tonumber(slot) or 1))
    local row = p.savedBeacons[slot]
    if not row or not row.beacon then return nil end
    p.draftBeacon = row.beacon
    return row.beacon, row.name
end

function Blackacre.Lifecycle.PostBeacon(beacon)
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    if p.emitEnabled == false then
        Blackacre.Print("Turn Emit on after the beacon is set.")
        return false
    end
    if not beacon then
        Blackacre.Print("Set a beacon first.")
        return false
    end
    local guid = UnitGUID("player")
    BlackacreDB.beacons = BlackacreDB.beacons or {}
    for id, b in pairs(BlackacreDB.beacons) do
        if b.ownerGUID == guid then
            BlackacreDB.beacons[id] = nil
        end
    end
    if beacon.showNameZone == nil then beacon.showNameZone = p.showNameZone ~= false end
    if beacon.showNameProximity == nil then beacon.showNameProximity = p.showNameProximity ~= false end
    beacon.expiresAt = time() + BeaconTTL()
    BlackacreDB.beacons[beacon.id] = beacon
    p.activeBeaconId = beacon.id
    p.draftBeacon = beacon
    p.lastEmitAt = time()
    Blackacre.Lifecycle.SendHeartbeat(true)
    Blackacre.Lifecycle.ArmExpiryWarning(beacon)
    if Blackacre.BeaconHint and Blackacre.BeaconHint.Refresh then Blackacre.BeaconHint.Refresh() end
    return true
end

---------------------------------------------------------------------------
-- Beacon lifetime: 24 hours of real time. Five minutes before it fades the
-- emitter gets a toast and a Renew popup. Renewing is only possible in
-- those last five minutes, so nobody can keep resetting the clock, and
-- Update (new crumbs) keeps the same expiry.
---------------------------------------------------------------------------
local RENEW_WINDOW = 5 * 60
local expiryTimer

function Blackacre.Lifecycle.ArmExpiryWarning(beacon)
    if expiryTimer then
        expiryTimer:Cancel()
        expiryTimer = nil
    end
    if not beacon or not beacon.expiresAt then return end
    local delay = math.max(0, beacon.expiresAt - RENEW_WINDOW - time())
    local id = beacon.id
    expiryTimer = C_Timer.NewTimer(delay, function()
        expiryTimer = nil
        local p = Blackacre.Lifecycle.EnsurePresenceDB()
        local live = Blackacre.Lifecycle.GetActiveOwnedBeacon()
        if not p.emitEnabled or not live or live.id ~= id then return end
        if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
            Blackacre.UI.Theme.Toast("Your beacon fades in 5 minutes.")
        end
        StaticPopup_Show("BLACKACRE_BEACON_RENEW")
    end)
end

function Blackacre.Lifecycle.CanRenewBeacon()
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    local live = Blackacre.Lifecycle.GetActiveOwnedBeacon()
    return p.emitEnabled and live ~= nil and live.expiresAt ~= nil
        and (live.expiresAt - time()) <= RENEW_WINDOW
end

function Blackacre.Lifecycle.RenewBeacon()
    if not Blackacre.Lifecycle.CanRenewBeacon() then
        Blackacre.Print("A beacon can only be renewed in its last five minutes.")
        return false
    end
    local live = Blackacre.Lifecycle.GetActiveOwnedBeacon()
    live.expiresAt = time() + BeaconTTL()
    Blackacre.Lifecycle.SendHeartbeat(true) -- carries the new expiry to seekers
    Blackacre.Lifecycle.ArmExpiryWarning(live)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast("Your beacon will burn for another day.")
    end
    return true
end

StaticPopupDialogs["BLACKACRE_BEACON_RENEW"] = {
    text = "Your beacon fades in 5 minutes. Renew it for another day?",
    button1 = "Renew",
    button2 = "Let it fade",
    OnAccept = function() Blackacre.Lifecycle.RenewBeacon() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Swap new crumbs into the beacon that's already emitting (Update button).
-- Keeps the old expiry; seekers drop the old version and hear the new one.
function Blackacre.Lifecycle.UpdateActiveBeacon(newBeacon)
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    local old = Blackacre.Lifecycle.GetActiveOwnedBeacon()
    if not p.emitEnabled or not old or not newBeacon then
        Blackacre.Print("You have no beacon emitting to update.")
        return false
    end
    newBeacon.expiresAt = old.expiresAt
    if newBeacon.locKind ~= "roving" then newBeacon.leftSpot = old.leftSpot end
    if Blackacre.Comms and Blackacre.Comms.BroadcastRetract then
        Blackacre.Comms.BroadcastRetract(old.id, "beacon")
    end
    BlackacreDB.beacons[old.id] = nil
    BlackacreDB.beacons[newBeacon.id] = newBeacon
    p.activeBeaconId = newBeacon.id
    p.draftBeacon = newBeacon
    Blackacre.Lifecycle.SendHeartbeat(true)
    Blackacre.Lifecycle.ArmExpiryWarning(newBeacon)
    return true
end

function Blackacre.Lifecycle.SetEmitEnabled(on)
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    if on then
        if not p.draftBeacon then
            Blackacre.Print("Set a beacon first (Tool Box → Beacon).")
            return false
        end
        p.emitEnabled = true
        return Blackacre.Lifecycle.PostBeacon(p.draftBeacon)
    end
    p.emitEnabled = false
    local id = p.activeBeaconId
    if id then
        if Blackacre.Comms and Blackacre.Comms.BroadcastRetract then
            Blackacre.Comms.BroadcastRetract(id, "beacon")
        end
        p.activeBeaconId = nil
    end
    return true
end

function Blackacre.Lifecycle.SetSeekingEnabled(on)
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    p.seekingEnabled = on and true or false
    p.receiveBeacons = p.seekingEnabled
end

function Blackacre.Lifecycle.StopBeacon()
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    local id = p.activeBeaconId
    if not id or not BlackacreDB.beacons[id] then
        Blackacre.Print("You have no active beacon.")
        return
    end
    Blackacre.Lifecycle.DeleteOwned("beacon", id)
    Blackacre.Print("Beacon withdrawn.")
end

function Blackacre.Lifecycle.PostBulletin(bulletin)
    BlackacreDB.bulletins = BlackacreDB.bulletins or {}
    BlackacreDB.bulletins[bulletin.id] = bulletin
    Blackacre.Comms.AnnounceBulletin(bulletin)
end

-- Withdrawn notices, remembered until they would have expired so a stale copy
-- held by an offline player can't bring them back. Passed along with inn replies.
local WITHDRAWN_HOLD = MAX_BULLETIN_SECONDS

local function WithdrawnStore()
    BlackacreDB.withdrawn = BlackacreDB.withdrawn or {}
    return BlackacreDB.withdrawn
end

-- mine = we withdrew it ourselves (the author keeps telling the inns).
-- by   = the player who withdrew it; it only counts against their own notices.
function Blackacre.Lifecycle.MarkWithdrawn(id, zones, untilTime, mine, by)
    if not id then return end
    local store = WithdrawnStore()
    local row = store[id] or {}
    row.untilTime = untilTime or row.untilTime or (time() + WITHDRAWN_HOLD)
    if type(zones) == "table" and #zones > 0 then row.zones = zones end
    if mine then row.mine = true end
    if by then row.by = by end
    store[id] = row
end

-- author: who wrote the notice we're checking. A withdrawal only counts if we
-- made it ourselves, or it came from that same author (nobody else can take
-- someone's notice down).
function Blackacre.Lifecycle.IsWithdrawn(id, author)
    local store = BlackacreDB.withdrawn
    local row = store and id and store[id]
    if not row then return false end
    if row.mine then return true end
    if not author or not row.by then return false end
    return Blackacre.Comms.SameName(row.by, author)
end

function Blackacre.Lifecycle.GetWithdrawn()
    return WithdrawnStore()
end

-- Named drafts the player saved (My drafts), newest first. Any of them can
-- be posted from an innkeeper's Post Notice list.
local MAX_SAVED_DRAFTS = 20

function Blackacre.Lifecycle.GetSavedBulletins()
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    p.savedBulletins = p.savedBulletins or {}
    -- Older builds had one "active" draft instead of picking at the inn. Fold
    -- it into the list once (unless it was already a copy of a saved draft).
    local d = p.draftBulletin
    if d then
        p.draftBulletin = nil -- first: SaveNamedBulletin calls back in here
        if not d.draftSourceId and (d.bodyText or "") ~= "" then
            Blackacre.Lifecycle.SaveNamedBulletin({
                draftName = d.draftName or "Notice",
                title = d.title,
                bodyText = d.bodyText,
                stationary = d.stationary,
                waxSeal = d.waxSeal,
                font = d.font,
            })
        end
    end
    return p.savedBulletins
end

-- Saving under a name that's already there updates that draft (same id).
function Blackacre.Lifecycle.SaveNamedBulletin(draft)
    local list = Blackacre.Lifecycle.GetSavedBulletins()
    for i = #list, 1, -1 do
        if list[i].draftName == draft.draftName then
            draft.id = draft.id or list[i].id
            table.remove(list, i)
        end
    end
    draft.id = draft.id or Blackacre.NewID()
    draft.savedAt = time()
    table.insert(list, 1, draft)
    while #list > MAX_SAVED_DRAFTS do table.remove(list) end
    return draft
end

function Blackacre.Lifecycle.DeleteSavedBulletin(id)
    local list = Blackacre.Lifecycle.GetSavedBulletins()
    for i = #list, 1, -1 do
        if list[i].id == id then table.remove(list, i) end
    end
end

function Blackacre.Lifecycle.GetActiveOwnedBeacon()
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    if not p.activeBeaconId then return nil end
    return BlackacreDB.beacons[p.activeBeaconId]
end
