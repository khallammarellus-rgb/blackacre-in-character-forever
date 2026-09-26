Blackacre = Blackacre or {}
Blackacre.Lifecycle = {}

-- Hot-path upvalues (DBM-Core style): direct register reads, not global lookups.
local pairs, time, tonumber = pairs, time, tonumber
local C_Timer, CreateFrame = C_Timer, CreateFrame

local function BeaconTTL()
    return (Blackacre.BeaconConfig and Blackacre.BeaconConfig.TTL) or (24 * 60 * 60)
end

local function ReemitCooldown()
    return (Blackacre.BeaconConfig and Blackacre.BeaconConfig.REEMIT_COOLDOWN) or (15 * 60)
end

local MAX_BULLETIN_DAYS = 7

function Blackacre.Lifecycle.GetBeaconTTL()
    return BeaconTTL()
end

function Blackacre.Lifecycle.GetBulletinTTLSeconds()
    local days = Blackacre.CharDB.settings.bulletinTTLDays
        or Blackacre.CharDB.settings.noticeTTLDays
        or 3
    days = math.min(math.max(days, 1), MAX_BULLETIN_DAYS)
    return days * 24 * 60 * 60
end

Blackacre.Lifecycle.GetNoticeTTLSeconds = Blackacre.Lifecycle.GetBulletinTTLSeconds

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
    if BlackacreDB.notices and not BlackacreDB.bulletins then
        BlackacreDB.bulletins = BlackacreDB.notices
    end
    BlackacreDB.bulletins = BlackacreDB.bulletins or {}
    BlackacreDB.notices = BlackacreDB.bulletins
    BlackacreDB.beacons = BlackacreDB.beacons or {}
    return Blackacre.CharDB.presence
end

function Blackacre.Lifecycle.Init()
    Blackacre.Lifecycle.EnsurePresenceDB()
    -- Emit never survives a logout. Draft and named saves do.
    Blackacre.CharDB.presence.emitEnabled = false
    C_Timer.NewTicker(60, Blackacre.Lifecycle.Sweep)
    C_Timer.NewTicker(20, function()
        local p = Blackacre.CharDB and Blackacre.CharDB.presence
        if not p or not p.emitEnabled then return end
        local b = Blackacre.Lifecycle.GetActiveOwnedBeacon()
        if not b then return end
        if b.locKind == "roving" then
            local ctx = Blackacre.GetZoneContext()
            b.zoneId = ctx.zoneId
            b.zoneName = ctx.zoneName
            b.subzone = ctx.subzone
            b.coords = ctx.coords
        end
        if Blackacre.Comms and Blackacre.Comms.BroadcastBeacon then
            Blackacre.Comms.BroadcastBeacon(b)
        end
    end)
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGOUT")
    f:RegisterEvent("PLAYER_LEAVING_WORLD")
    f:SetScript("OnEvent", function()
        local p = Blackacre.Lifecycle.EnsurePresenceDB()
        if p.emitEnabled and p.activeBeaconId then
            local id = p.activeBeaconId
            p.emitEnabled = false
            if Blackacre.Comms and Blackacre.Comms.BroadcastRetract then
                Blackacre.Comms.BroadcastRetract(id, "beacon")
            end
        else
            p.emitEnabled = false
        end
    end)
end

local function StoreFor(kind)
    if kind == "beacon" then
        return BlackacreDB.beacons
    end
    return BlackacreDB.bulletins or BlackacreDB.notices
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
                if BlackacreDB.cache and BlackacreDB.cache.beacon then
                    BlackacreDB.cache.beacon[id] = nil
                end
            end
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
    -- Standing still with nothing expired used to rebuild flyout, pins, and re-deliver
    -- every beacon once a minute. Distance delivery is owned by the move watcher.
    if not beaconsChanged and not bulletinsChanged and not cacheChanged then
        return
    end
    if Blackacre.Flyout and Blackacre.Flyout.Refresh then Blackacre.Flyout.Refresh() end
    if bulletinsChanged and Blackacre.BoardView and Blackacre.BoardView.Refresh then
        Blackacre.BoardView.Refresh()
    end
    if beaconsChanged and Blackacre.BeaconPins and Blackacre.BeaconPins.Refresh then
        Blackacre.BeaconPins.Refresh()
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
        if p.activeBeaconId == id then p.activeBeaconId = nil end
    end
    Blackacre.History.SaveDraft(kind, entry)
end

function Blackacre.Lifecycle.DeleteOwned(kind, id)
    kind = NormalizeKind(kind)
    local store = StoreFor(kind)
    local entry = store[id]
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
    if Blackacre.Flyout and Blackacre.Flyout.Refresh then Blackacre.Flyout.Refresh() end
    if Blackacre.BoardView and Blackacre.BoardView.Refresh then Blackacre.BoardView.Refresh() end
    if Blackacre.BeaconHead and Blackacre.BeaconHead.OnCacheChanged then
        Blackacre.BeaconHead.OnCacheChanged()
    end
    if Blackacre.BeaconPins and Blackacre.BeaconPins.Refresh then
        Blackacre.BeaconPins.Refresh()
    end
end

function Blackacre.Lifecycle.HandleRemoteRetract(kind, id)
    kind = NormalizeKind(kind)
    if BlackacreDB.cache then
        if BlackacreDB.cache[kind] then BlackacreDB.cache[kind][id] = nil end
        if kind == "bulletin" and BlackacreDB.cache.notice then
            BlackacreDB.cache.notice[id] = nil
        end
    end
    if BlackacreDB.beacons then BlackacreDB.beacons[id] = nil end
    if kind == "beacon" then
        if Blackacre.Flyout and Blackacre.Flyout.Refresh then Blackacre.Flyout.Refresh() end
        if Blackacre.BeaconHead and Blackacre.BeaconHead.OnCacheChanged then
            Blackacre.BeaconHead.OnCacheChanged()
        end
        if Blackacre.BeaconPins and Blackacre.BeaconPins.Refresh then
            Blackacre.BeaconPins.Refresh()
        end
    else
        if Blackacre.BoardView and Blackacre.BoardView.Refresh then
            Blackacre.BoardView.Refresh()
        end
    end
end

function Blackacre.Lifecycle.CanEmitBeacon()
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    if p.emitEnabled == false then
        return false, "Emit is off. Set a beacon, then turn Emit on."
    end
    if not p.draftBeacon then
        return false, "Set a beacon first (Tool Box → Beacon)."
    end
    return true
end

function Blackacre.Lifecycle.CreateBeacon(templateId, slotValues, opts)
    opts = opts or {}
    if not (Blackacre.SentenceTemplates and Blackacre.SentenceTemplates.Resolve) then
        Blackacre.Print("Beacons require the Blackacre Presence package.")
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
        stationary = extra.stationary,
        waxSeal = extra.waxSeal,
        font = extra.font,
        createdAt = now,
        expiresAt = now + Blackacre.Lifecycle.GetBulletinTTLSeconds(),
        editCount = 0,
        status = Blackacre.STATUS.ACTIVE,
    }
end

Blackacre.Lifecycle.CreateNotice = Blackacre.Lifecycle.CreateBulletin

function Blackacre.Lifecycle.SaveDraftBeacon(beacon)
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    p.draftBeacon = beacon
    return beacon
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
    Blackacre.Comms.BroadcastBeacon(beacon)
    if Blackacre.Flyout and Blackacre.Flyout.Refresh then Blackacre.Flyout.Refresh() end
    if Blackacre.BeaconPins and Blackacre.BeaconPins.Refresh then Blackacre.BeaconPins.Refresh() end
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
    BlackacreDB.notices = BlackacreDB.bulletins
    Blackacre.Comms.AnnounceBulletin(bulletin)
    if Blackacre.BoardView and Blackacre.BoardView.Refresh then
        Blackacre.BoardView.Refresh()
    end
end

Blackacre.Lifecycle.PostNotice = Blackacre.Lifecycle.PostBulletin

function Blackacre.Lifecycle.GetActiveOwnedBeacon()
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    if not p.activeBeaconId then return nil end
    return BlackacreDB.beacons[p.activeBeaconId]
end
