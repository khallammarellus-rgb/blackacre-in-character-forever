-- In Character Forever: Beacons & Bulletins - Inn Relay

Blackacre = Blackacre or {}
Blackacre.InnRelay = {}

local pairs, type, time, random, min = pairs, type, time, math.random, math.min
local GetTime, UnitGUID = GetTime, UnitGUID
local C_Timer = C_Timer

local QUERY_COOLDOWN = 5 * 60    -- one question per region per 5 minutes
local ASKING_WINDOW = 6          -- seconds the list may say "Asking around…"
local AUTHOR_DELAY_MAX = 0.5
local RELAY_DELAY_MIN, RELAY_DELAY_MAX = 0.8, 3.5
local MAX_PER_REPLY = 20

local lastQueryAt = {}  -- zoneKey -> GetTime() of our last question
local pending = {}      -- zoneKey -> { covered = { [id] = true } } while a reply waits

local function SEP()
    return Blackacre.SEP
end

local function SeekingOn()
    local p = Blackacre.CharDB and Blackacre.CharDB.presence
    return not (p and p.seekingEnabled == false)
end

local function PostedIn(b, zoneKey, factions)
    return Blackacre.Boards.BulletinMatchesZone(b, zoneKey, nil, nil, factions)
end

-- Every live, not-withdrawn notice this client holds for a region.
-- Returns list and whether any of them are our own.
local function HeldForZone(zoneKey, factions)
    local out, seen, mine = {}, {}, false
    local now = time()
    local me = UnitGUID("player")
    local function consider(b)
        if not b or not b.id or seen[b.id] then return end
        if b.expiresAt and b.expiresAt < now then return end
        if b.status and b.status ~= Blackacre.STATUS.ACTIVE then return end
        if Blackacre.Lifecycle.IsWithdrawn(b.id, b.authorName) then return end
        if not PostedIn(b, zoneKey, factions) then return end
        seen[b.id] = true
        out[#out + 1] = b
        if b.ownerGUID == me then mine = true end
    end
    for _, b in pairs(BlackacreDB.bulletins or {}) do consider(b) end
    local cache = BlackacreDB.cache and BlackacreDB.cache.bulletin
    if cache then
        for _, wrapped in pairs(cache) do consider(wrapped.data) end
    end
    return out, mine
end

-- Withdrawn ids for a region. Returns list and whether any were withdrawn by us.
local function WithdrawnForZone(zoneKey)
    local out, mine = {}, false
    for id, row in pairs(Blackacre.Lifecycle.GetWithdrawn()) do
        local zones = row.zones
        if type(zones) == "table" then
            for i = 1, #zones do
                if zones[i] == zoneKey and row.mine then
                    out[#out + 1] = { id = id, untilTime = row.untilTime }
                    mine = true
                    break
                end
            end
        end
    end
    return out, mine
end

-- Wire copy of a notice: only what a reader needs, no local bookkeeping.
-- Our own notices go without their text: an author's words only travel on
-- the logged path (Comms.SendBulletinText), so reports match Blizzard's log.
local function WireCopy(b, own)
    return {
        id = b.id, ownerGUID = b.ownerGUID, charName = b.charName,
        authorName = b.authorName, textLogged = b.textLogged,
        postedAt = b.postedAt, zoneName = b.zoneName,
        factionNet = b.factionNet, factionNetID = b.factionNetID, lang = b.lang,
        title = (not own) and b.title or nil,
        bodyText = (not own) and b.bodyText or nil,
        postedZones = b.postedZones, innNpcID = b.innNpcID, innName = b.innName,
        boardId = b.boardId, scopeTier = b.scopeTier, expiresAt = b.expiresAt,
        stationary = b.stationary, waxSeal = b.waxSeal, font = b.font,
    }
end

local function SendList(zoneKey, covered, factions)
    local held = HeldForZone(zoneKey, factions)
    local me = UnitGUID("player")
    local send, ownSent = {}, {}
    for i = 1, #held do
        local b = held[i]
        local own = b.ownerGUID == me
        -- Someone else already answered with this one; only the author repeats.
        if not (covered and covered[b.id]) or own then
            send[#send + 1] = WireCopy(b, own)
            if own then ownSent[#ownSent + 1] = b end
            if #send >= MAX_PER_REPLY then break end
        end
    end
    -- Withdrawn ids ride along with every reply (they only ever remove things).
    local withdrawn = WithdrawnForZone(zoneKey)
    if #send == 0 and #withdrawn == 0 then return end
    local encoded = Blackacre.Comms.Encode({ opcode = "IL", b = send, w = withdrawn })
    Blackacre.Comms.SendChannelRaw("IL" .. SEP() .. zoneKey .. SEP() .. encoded, "BULK")
    for i = 1, #ownSent do
        Blackacre.Comms.SendBulletinText(ownSent[i])
    end
end

-- Ask the channel for a region's notices. Returns true if a question went out.
function Blackacre.InnRelay.Query(zoneKey)
    if not zoneKey or zoneKey == "unknown" or not SeekingOn() then return false end
    local now = GetTime()
    if lastQueryAt[zoneKey] and (now - lastQueryAt[zoneKey]) < QUERY_COOLDOWN then
        return false
    end
    -- Name the factions whose innkeepers we know here, so notices spread
    -- through those networks come back too.
    local names = {}
    for name in pairs(Blackacre.YellowPages.FactionsInZone(Blackacre.GetZoneSnapshot().zoneName)) do
        names[#names + 1] = name
    end
    if not Blackacre.Comms.SendChannelRaw("IQ" .. SEP() .. zoneKey .. SEP() .. table.concat(names, ",")) then
        return false -- channel not joined yet; try again next time
    end
    lastQueryAt[zoneKey] = now
    return true
end

function Blackacre.InnRelay.QueryHere()
    return Blackacre.InnRelay.Query((Blackacre.Boards.CurrentZoneKey()))
end

-- True for a few seconds after we asked about a region (drives "Asking around…").
function Blackacre.InnRelay.IsAsking(zoneKey)
    local t = zoneKey and lastQueryAt[zoneKey]
    return t ~= nil and (GetTime() - t) < ASKING_WINDOW
end

local function ParseFactions(list)
    local set = {}
    if type(list) == "string" then
        for name in list:gmatch("[^,]+") do set[name] = true end
    end
    return set
end

function Blackacre.InnRelay.OnQuery(_, zoneKey, factionList)
    if pending[zoneKey] then return end -- a reply for this region is already queued
    local factions = ParseFactions(factionList)
    -- Answer if we hold notices for this region, or we withdrew one there ourselves
    -- (so the author still tells the inns it's gone). Nothing to say: stay quiet.
    local held, heldMine = HeldForZone(zoneKey, factions)
    local _, withdrewMine = WithdrawnForZone(zoneKey)
    local mine = heldMine or withdrewMine
    if #held == 0 and not withdrewMine then return end
    local delay
    if mine then
        delay = random() * AUTHOR_DELAY_MAX
    else
        delay = RELAY_DELAY_MIN + random() * (RELAY_DELAY_MAX - RELAY_DELAY_MIN)
    end
    local slot = { covered = {} }
    pending[zoneKey] = slot
    C_Timer.After(delay, function()
        if pending[zoneKey] == slot then pending[zoneKey] = nil end
        SendList(zoneKey, slot.covered, factions)
    end)
end

function Blackacre.InnRelay.OnList(sender, zoneKey, encoded)
    local slot = pending[zoneKey]
    local here = Blackacre.Boards.CurrentZoneKey()
    -- Not our region and we're not waiting to answer it: don't even unpack.
    if not slot and zoneKey ~= here then return end
    local data = Blackacre.Comms.Decode(encoded)
    if type(data) ~= "table" then return end
    if type(data.w) == "table" then
        for i = 1, min(#data.w, 100) do
            local w = data.w[i]
            if type(w) == "table" and w.id then
                -- Checked inside: only counts against the sender's own notices.
                Blackacre.Lifecycle.HandleRemoteRetract("bulletin", w.id, sender)
            end
        end
    end
    local list = data.b
    if type(list) ~= "table" then return end
    for i = 1, min(#list, MAX_PER_REPLY) do
        local b = list[i]
        if type(b) == "table" and b.id then
            if slot then slot.covered[b.id] = true end
            Blackacre.Comms.IngestBulletin(b, sender)
        end
    end
    if Blackacre.InnBoard and Blackacre.InnBoard.RefreshIfOpen then
        Blackacre.InnBoard.RefreshIfOpen()
    end
end
