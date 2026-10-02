-- In Character Forever - Comms

Blackacre = Blackacre or {}
Blackacre.Comms = {}

local AceSerializer = LibStub("AceSerializer-3.0")
-- LibDeflate registers with LibStub and returns the library from the file.
-- The addon loader discards that return, so the global stays nil.
local LibDeflate = LibStub("LibDeflate")

local CHANNEL_NAME = Blackacre.CHANNEL_NAME or "Blackacre"
local PREFIX = Blackacre.PREFIX
local SEP = Blackacre.SEP
local OLD_CHANNEL = "BA_Channel"

local function EncodePayload(tbl)
    local serialized = AceSerializer:Serialize(tbl)
    local compressed = LibDeflate:CompressDeflate(serialized)
    return "Z:" .. LibDeflate:EncodeForPrint(compressed)
end

local BYTE_Z, BYTE_COLON = 90, 58 -- "Z:"

local function DecodePayload(msg)
    -- Byte compare: every channel message lands here, so don't cut a substring.
    if not msg or msg:byte(1) ~= BYTE_Z or msg:byte(2) ~= BYTE_COLON then
        return nil
    end
    local compressed = LibDeflate:DecodeForPrint(msg:sub(3))
    if not compressed then return nil end
    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then return nil end
    local ok, data = AceSerializer:Deserialize(serialized)
    if ok then return data end
    return nil
end

local CHANNEL_NAME_LOWER = CHANNEL_NAME:lower()

local function ChannelNameMatch(name)
    return name and name:lower() == CHANNEL_NAME_LOWER
end

local cachedChannelID
local leftLegacyChannel = false
local channelHidden = false

local function HideChannelFromChat()
    if channelHidden then return end
    local touched = false
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local f = _G["ChatFrame" .. i]
        if f and ChatFrame_RemoveChannel then
            pcall(ChatFrame_RemoveChannel, f, CHANNEL_NAME)
            touched = true
        end
    end
    if touched then
        channelHidden = true
    end
end

local function KnownChannelID()
    if cachedChannelID and cachedChannelID > 0 then
        local _, name = GetChannelName(cachedChannelID)
        if ChannelNameMatch(name) then
            return cachedChannelID
        end
        cachedChannelID = nil
        channelHidden = false
    end
    local id = GetChannelName(CHANNEL_NAME)
    if id and id > 0 then
        cachedChannelID = id
        return id
    end
    return nil
end

local function FilterBlackacreChat(_, _, msg, sender, language, _, _, _, _, _, channelName)
    if ChannelNameMatch(channelName) then
        return true
    end
end

local chatFilterInstalled
local function InstallChatFilter()
    if chatFilterInstalled then return end
    chatFilterInstalled = true
    if ChatFrame_AddMessageEventFilter then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FilterBlackacreChat)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", FilterBlackacreChat)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_JOIN", FilterBlackacreChat)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LEAVE", FilterBlackacreChat)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE_USER", FilterBlackacreChat)
    end
end

-- Joining the hidden channel.
-- * We wait for General so Blackacre doesn't grab channel /1 and bump General
--   to /2 at login, but only up to GENERAL_WAIT seconds: players who left
--   General still get connected.
-- * WoW caps chat channels (about 10). If the join fails we quietly try
--   again the moment the player leaves a channel.
local GENERAL_WAIT = 20
local JOIN_BACKOFF = 60
local firstJoinAttemptAt
local joinFailedAt

local function GeneralJoined()
    local channels = { GetChannelList() }
    for i = 2, #channels, 3 do
        if channels[i] == "General" then return true end
    end
    return false
end

local function EnsureChannel(retries)
    retries = retries or 3
    -- Leave the old channel name once. Doing it on every send is a server request.
    if not leftLegacyChannel then
        leftLegacyChannel = true
        pcall(LeaveChannelByName, OLD_CHANNEL)
    end
    local existing = KnownChannelID()
    if existing then
        HideChannelFromChat()
        joinFailedAt = nil
        return existing
    end
    local now = GetTime()
    if joinFailedAt and (now - joinFailedAt) < JOIN_BACKOFF then
        return nil -- failed recently; wait for a channel to free up or the backoff
    end

    firstJoinAttemptAt = firstJoinAttemptAt or now
    if not GeneralJoined() and (now - firstJoinAttemptAt) < GENERAL_WAIT then
        C_Timer.After(2, function() EnsureChannel(retries) end)
        return nil
    end

    JoinTemporaryChannel(CHANNEL_NAME)
    local channelID = GetChannelName(CHANNEL_NAME)
    if channelID and channelID > 0 then
        cachedChannelID = channelID
        joinFailedAt = nil
        HideChannelFromChat()
        return channelID
    end
    if retries > 0 then
        C_Timer.After(1, function() EnsureChannel(retries - 1) end)
    else
        joinFailedAt = now
    end
    return nil
end

local function SendOnChannel(message, prio)
    local channelID = EnsureChannel()
    if not channelID then return false end
    if not Blackacre.addon then return false end
    Blackacre.addon:SendCommMessage(PREFIX, message, "CHANNEL", channelID, prio or "NORMAL")
    return true
end

local function SendWhisper(target, message, _logged, prio)
    -- AceComm splits long payloads and sends them through ChatThrottleLib.
    -- There is no SendAddonMessageLogged on CTL; calling it errored every full bulletin.
    if not Blackacre.addon then return end
    Blackacre.addon:SendCommMessage(PREFIX, message, "WHISPER", target, prio or "NORMAL")
end

local function CacheEntry(kind, entry)
    BlackacreDB.cache = BlackacreDB.cache or {}
    BlackacreDB.cache[kind] = BlackacreDB.cache[kind] or {}
    BlackacreDB.cache[kind][entry.id] = {
        data = entry,
        lastConfirmedAt = time(),
    }
end

function Blackacre.Comms.Init(addonRef)
    local ace = addonRef or Blackacre.addon
    if not ace then return end
    ace:RegisterComm(PREFIX, Blackacre.Comms.OnCommReceived)
    InstallChatFilter()
end

---------------------------------------------------------------------------
-- Version check. Each player says "HI <build>" once after joining the
-- channel. Anyone who hears a newer build than their own gets one system
-- line. Hearing an older one, we answer after a short random wait, unless
-- someone already did (everyone hears the channel), so the out-of-date
-- player learns about it without a flood of replies.
---------------------------------------------------------------------------
local NEWER_TEXT = "A new version of Blackacre is available, full function might be limited until you update the add on."
local newerWarned = false
local helloSent = false
local lastHelloHeardAt = -1000
local helloReplyPending = false

local function SystemLine(text)
    local info = ChatTypeInfo and ChatTypeInfo["SYSTEM"]
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(text, info and info.r or 1, info and info.g or 1, info and info.b or 0)
    end
end

local function SendHello()
    SendOnChannel("HI" .. SEP .. (Blackacre.BUILD or 0))
end

-- Once per session, as soon as the channel is joined (can take ~20 s at login).
local function TrySendHello(tries)
    if helloSent then return end
    if KnownChannelID() then
        helloSent = true
        SendHello()
    elseif tries > 0 then
        C_Timer.After(10, function() TrySendHello(tries - 1) end)
    end
end

local function OnHello(build)
    build = tonumber(build)
    local mine = Blackacre.BUILD or 0
    if not build then return end
    if build > mine and not newerWarned then
        newerWarned = true
        SystemLine(NEWER_TEXT)
    end
    if build >= mine then
        lastHelloHeardAt = GetTime() -- someone as new as us just spoke up
        return
    end
    -- They're behind us. One of us should answer; wait a moment and see.
    if helloReplyPending or (GetTime() - lastHelloHeardAt) < 60 then return end
    helloReplyPending = true
    C_Timer.After(1 + math.random() * 4, function()
        helloReplyPending = false
        if (GetTime() - lastHelloHeardAt) < 5 then return end -- someone beat us to it
        lastHelloHeardAt = GetTime()
        SendHello()
    end)
end

function Blackacre.Comms.Enable()
    InstallChatFilter()
    local frame = CreateFrame("Frame")
    local announcedJoin = false
    frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, event, msg, channelName)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(2, function()
                local id = EnsureChannel()
                HideChannelFromChat()
                -- Once per session, not on every loading screen.
                if id and not announcedJoin and Blackacre.Print then
                    announcedJoin = true
                    Blackacre.Print("Blackacre comms joined")
                end
                TrySendHello(8)
            end)
            return
        end
        if msg == "YOU_JOINED" and (channelName == "General" or channelName == "Trade" or ChannelNameMatch(channelName)) then
            C_Timer.After(1, function()
                EnsureChannel()
                HideChannelFromChat()
            end)
        elseif (msg == "YOU_LEFT" or msg == "YOU_CHANGED") and not KnownChannelID() then
            -- A channel slot may have freed up: try again right away.
            joinFailedAt = nil
            C_Timer.After(1, function() EnsureChannel() end)
        end
    end)
    C_Timer.NewTicker(3600, function()
        -- Chat settings can put the hidden channel back. Re-hide hourly, not per message.
        channelHidden = false
        EnsureChannel()
    end)
    C_Timer.After(3, EnsureChannel)
end

function Blackacre.Comms.SendPing()
    local id = EnsureChannel()
    HideChannelFromChat()
    SendOnChannel("PING")
    if id then
        Blackacre.Print("Comms pinged")
    else
        Blackacre.Print("Attempting to join")
    end
end

function Blackacre.Comms.BroadcastRetract(id, kind)
    if kind == "notice" then kind = "bulletin" end
    SendOnChannel("RT" .. SEP .. kind .. SEP .. id)
end

---------------------------------------------------------------------------
-- Logged author text (reporting).
--
-- A player's own words (notice title/body, later beacon crumbs) are sent with
-- C_ChatInfo.SendAddonMessageLogged as plain readable text. Blizzard keeps
-- that copy against the author's account, so a report can be checked against
-- what was really sent. Readers only accept an author's words from these
-- logged messages; copies passed on by other players stay unlogged so a
-- bystander never has someone else's text logged against them.
--
-- Wire: TX <sep> kind <sep> id <sep> fieldCount <sep> field <sep> part <sep> parts <sep> text
---------------------------------------------------------------------------
local LOGGED_CHUNK = 200        -- bytes of text per message (255 max incl. header)
local LOGGED_GAP = 0.4          -- seconds between logged sends
local LOGGED_MAX_PARTS = 8
local INCOMING_TTL = 120        -- seconds to wait for all parts / the metadata
local THROTTLED = Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.AddonMessageThrottle

local loggedQueue = {}
local loggedBusy = false

local function SameName(a, b)
    if not a or not b then return false end
    return Ambiguate(a, "none") == Ambiguate(b, "none")
end
Blackacre.Comms.SameName = SameName

local function PumpLogged()
    local item = table.remove(loggedQueue, 1)
    if not item then
        loggedBusy = false
        return
    end
    loggedBusy = true
    local ok, result = pcall(C_ChatInfo.SendAddonMessageLogged, PREFIX, item.msg, item.chatType, item.target)
    if ok and THROTTLED and result == THROTTLED then
        table.insert(loggedQueue, 1, item) -- try again after the throttle refills
        C_Timer.After(1.5, PumpLogged)
        return
    end
    C_Timer.After(LOGGED_GAP, PumpLogged)
end

-- Plain text, but newlines/backslashes escaped so one field is one line.
local function EscapeText(t)
    return (t:gsub("\\", "\\\\"):gsub("\n", "\\n"))
end

local function UnescapeText(t)
    return (t:gsub("\\(.)", function(c)
        if c == "n" then return "\n" end
        return c
    end))
end

-- Split on byte count without cutting a multi-byte (accented) character.
local function SplitUtf8(text, size)
    local parts, i, n = {}, 1, #text
    if n == 0 then return { "" } end
    while i <= n do
        local j = math.min(i + size - 1, n)
        while j < n and j > i do
            local nextByte = text:byte(j + 1)
            if nextByte < 0x80 or nextByte >= 0xC0 then break end
            j = j - 1
        end
        parts[#parts + 1] = text:sub(i, j)
        i = j + 1
    end
    return parts
end

-- fields = ordered list of { key, text }. Sent on the hidden channel, or as a
-- whisper to one player when whisperTo is given.
function Blackacre.Comms.SendLoggedText(kind, id, fields, whisperTo)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessageLogged) then return false end
    local chatType, target = "WHISPER", whisperTo
    if not whisperTo then
        chatType, target = "CHANNEL", EnsureChannel()
        if not target then return false end
    end
    local count = #fields
    for f = 1, count do
        local key, text = fields[f][1], EscapeText(fields[f][2] or "")
        local parts = SplitUtf8(text, LOGGED_CHUNK)
        for p = 1, math.min(#parts, LOGGED_MAX_PARTS) do
            loggedQueue[#loggedQueue + 1] = {
                msg = "TX" .. SEP .. kind .. SEP .. id .. SEP .. count .. SEP .. key .. SEP .. p .. SEP .. #parts .. SEP .. parts[p],
                chatType = chatType,
                target = target,
            }
        end
    end
    if not loggedBusy then PumpLogged() end
    return true
end

function Blackacre.Comms.SendBulletinText(bulletin)
    return Blackacre.Comms.SendLoggedText("b", bulletin.id, {
        { "t", bulletin.title or "" },
        { "b", bulletin.bodyText or "" },
    })
end

-- Incoming logged parts, keyed by sender + id, until every field is whole.
local incoming = {}
-- Author metadata waiting for its logged text, and finished text waiting for metadata.
local awaitingMeta = {}
local finishedText = {}
local beaconText = {} -- beacon id -> { sender, fields, at } (logged crumbs)
local awaitingBeacon = {} -- beacon id -> { beacon, sender, at } ("I'm here" note waiting for crumbs)

-- Runs on incoming traffic, so sweep at most every few seconds rather than
-- walking all five tables for every message on a busy channel.
local PRUNE_EVERY = 10
local incomingPrunedAt = -1000

local function PruneIncoming()
    local now = GetTime()
    if now - incomingPrunedAt < PRUNE_EVERY then return end
    incomingPrunedAt = now
    for k, row in pairs(incoming) do
        if now - row.at > INCOMING_TTL then incoming[k] = nil end
    end
    for k, row in pairs(awaitingMeta) do
        if now - row.at > INCOMING_TTL then awaitingMeta[k] = nil end
    end
    for k, row in pairs(finishedText) do
        if now - row.at > INCOMING_TTL then finishedText[k] = nil end
    end
    for k, row in pairs(beaconText) do
        if now - row.at > INCOMING_TTL then beaconText[k] = nil end
    end
    for k, row in pairs(awaitingBeacon) do
        if now - row.at > INCOMING_TTL then awaitingBeacon[k] = nil end
    end
end

local StoreBulletin -- defined below
local TryMergeBeacon -- defined in the beacon section below

-- Metadata and logged text from the same author both arrived: store the notice.
local function TryMergeBulletin(id)
    local meta, text = awaitingMeta[id], finishedText[id]
    if not meta or not text or not SameName(meta.sender, text.sender) then return end
    awaitingMeta[id], finishedText[id] = nil, nil
    local data = meta.data
    data.title = text.fields.t
    data.bodyText = text.fields.b
    data.authorName = text.sender   -- server-verified sender of the logged text
    data.textLogged = true
    StoreBulletin(data, text.sender)
end

local function OnLoggedMessage(prefix, message, _, sender)
    if prefix ~= PREFIX or type(message) ~= "string" or not sender then return end
    if SameName(sender, UnitName("player")) then return end
    local op, kind, id, fieldCount, key, part, parts, text = strsplit(SEP, message, 8)
    if op ~= "TX" or not id or not key or not text then return end
    fieldCount, part, parts = tonumber(fieldCount), tonumber(part), tonumber(parts)
    if not fieldCount or not part or not parts or parts > LOGGED_MAX_PARTS or part < 1 or part > parts then return end
    PruneIncoming()
    local slotKey = sender .. SEP .. id
    local row = incoming[slotKey]
    if not row then
        row = { kind = kind, id = id, sender = sender, fieldCount = fieldCount, fields = {}, at = GetTime() }
        incoming[slotKey] = row
    end
    local field = row.fields[key]
    if not field then
        field = { parts = {}, total = parts, have = 0 }
        row.fields[key] = field
    end
    if not field.parts[part] then
        field.parts[part] = text
        field.have = field.have + 1
    end
    -- Whole yet?
    local done = 0
    for _, f in pairs(row.fields) do
        if f.have == f.total then done = done + 1 end
    end
    if done < row.fieldCount then return end
    incoming[slotKey] = nil
    local out = {}
    for k, f in pairs(row.fields) do
        out[k] = UnescapeText(table.concat(f.parts, "", 1, f.total))
    end
    if kind == "b" then
        finishedText[id] = { sender = sender, fields = out, at = GetTime() }
        TryMergeBulletin(id)
    elseif kind == "c" then
        beaconText[id] = { sender = sender, fields = out, at = GetTime() }
        TryMergeBeacon(id)
    end
end

local loggedFrame = CreateFrame("Frame")
loggedFrame:RegisterEvent("CHAT_MSG_ADDON_LOGGED")
loggedFrame:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
    OnLoggedMessage(prefix, message, channel, sender)
end)

-- Our own full name, for authorName on notices we post.
local function MyFullName()
    local name, realm = UnitFullName("player")
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end
Blackacre.Comms.MyFullName = MyFullName

function Blackacre.Comms.AnnounceBulletin(bulletin)
    bulletin.authorName = bulletin.authorName or MyFullName()
    -- Title and body go only through the logged path below.
    local payload = EncodePayload({
        opcode = "NSZ",
        id = bulletin.id,
        postedAt = bulletin.postedAt,
        zoneName = bulletin.zoneName,
        factionNet = bulletin.factionNet,
        factionNetID = bulletin.factionNetID,
        lang = bulletin.lang,
        postedZones = bulletin.postedZones,
        innNpcID = bulletin.innNpcID,
        innName = bulletin.innName,
        boardId = bulletin.boardId,
        scopeTier = bulletin.scopeTier,
        expiresAt = bulletin.expiresAt,
        charName = bulletin.charName,
        ownerGUID = bulletin.ownerGUID,
        stationary = bulletin.stationary,
        waxSeal = bulletin.waxSeal,
        font = bulletin.font,
    })
    SendOnChannel(payload)
    Blackacre.Comms.SendBulletinText(bulletin)
    -- Our own notice lives in BlackacreDB.bulletins only. Also caching it put
    -- the same table under two SavedVariables keys, so it was written to disk
    -- twice and came back as two copies. Every reader checks both stores.
    BlackacreDB.bulletins = BlackacreDB.bulletins or {}
    BlackacreDB.bulletins[bulletin.id] = bulletin
end

local function SeekingOn()
    local p = Blackacre.CharDB and Blackacre.CharDB.presence
    if p and p.seekingEnabled == false then return false end
    if p and p.receiveBeacons == false then return false end
    return true
end

local function ZoneNameMatch(a, b)
    if not a or not b or a == "" or b == "" then return false end
    return a:lower() == b:lower()
end

---------------------------------------------------------------------------
-- Beacons ("message diet", Presence step 2).
--   BH  "I'm here" note: id, region map id, region name, subzone, x, y,
--       expiry, location kind, owner GUID. Plain text, ~100 bytes. Sent on
--       Emit, when a roving emitter changes area, and every 5 minutes.
--   BZ  "Who's emitting in region N?" Sent by a seeker entering a region.
--   BF  "Send me the crumbs for beacon <id>." Whisper from a seeker there.
-- Crumbs come back as logged text (kind "c": s = status line, r/l/f =
-- rumor/lead/found), whispered to that one seeker, so a report is backed by
-- Blizzard's log. No character name is ever sent; beacons are anonymous.
---------------------------------------------------------------------------
local BEACON_ASK_COOLDOWN = 60        -- seeker: re-ask for crumbs no sooner
local CRUMB_ANSWER_COOLDOWN = 5 * 60  -- emitter: per seeker, per beacon
local ZONE_ANSWER_COOLDOWN = 60       -- emitter: per seeker
local ZONE_ANSWER_JITTER = 2          -- spread many emitters' answers out

local askedCrumbsAt = {}   -- beacon id -> GetTime()
local answeredCrumbs = {}  -- seeker .. id -> GetTime()
local answeredZone = {}    -- seeker -> GetTime()
local askedTrailAt = {}    -- beacon id -> GetTime()

-- These only matter for their cooldown; drop old rows (at most once a minute)
-- so a long session on a busy channel doesn't keep every name it ever heard.
local cooldownsPrunedAt = 0
local function PruneCooldowns(now)
    if now - cooldownsPrunedAt < 60 then return end
    cooldownsPrunedAt = now
    for k, at in pairs(askedCrumbsAt) do
        if now - at > BEACON_ASK_COOLDOWN then askedCrumbsAt[k] = nil end
    end
    for k, at in pairs(askedTrailAt) do
        if now - at > BEACON_ASK_COOLDOWN then askedTrailAt[k] = nil end
    end
    for k, at in pairs(answeredCrumbs) do
        if now - at > CRUMB_ANSWER_COOLDOWN then answeredCrumbs[k] = nil end
    end
    for k, at in pairs(answeredZone) do
        if now - at > ZONE_ANSWER_COOLDOWN then answeredZone[k] = nil end
    end
end

function Blackacre.Comms.SendBeaconHeartbeat(beacon, whisperTo)
    local c = beacon.coords or {}
    local msg = "BH" .. SEP .. beacon.id
        .. SEP .. (beacon.zoneId or 0)
        .. SEP .. (beacon.zoneName or "")
        .. SEP .. (beacon.subzone or "")
        .. SEP .. string.format("%.4f", c.x or 0)
        .. SEP .. string.format("%.4f", c.y or 0)
        .. SEP .. (beacon.expiresAt or 0)
        .. SEP .. (beacon.locKind or "present")
        .. SEP .. (beacon.ownerGUID or "")
    if whisperTo then
        SendWhisper(whisperTo, msg, false, "NORMAL")
    else
        SendOnChannel(msg)
    end
end

function Blackacre.Comms.SendBeaconZoneQuery(zoneId)
    if not zoneId or zoneId == 0 then return false end
    return SendOnChannel("BZ" .. SEP .. zoneId)
end

local function InMyRegion(zoneId, zoneName)
    local ctx = Blackacre.GetZoneSnapshot()
    if zoneId and zoneId ~= 0 and zoneId == ctx.zoneId then return true end
    return ZoneNameMatch(zoneName, ctx.zoneName)
end

-- isNew: first time we hear this beacon (minimap alert); otherwise just refresh.
local function NotifyBeacon(beacon)
    if Blackacre.BeaconHead and Blackacre.BeaconHead.OnCacheChanged then
        Blackacre.BeaconHead.OnCacheChanged(beacon)
    end
    if Blackacre.BeaconHint and Blackacre.BeaconHint.Refresh then
        Blackacre.BeaconHint.Refresh()
    end
    if Blackacre.Trails and Blackacre.Trails.Refresh then Blackacre.Trails.Refresh() end
end

-- Logged crumbs arrive in two parts:
--   rumor part (s = Status line, r = Rumor): merged with the "I'm here" note
--     to make the heard beacon.
--   trail part (l = Lead, f = Found): added to a beacon we already hold,
--     only ever requested once we Follow it.
TryMergeBeacon = function(id)
    local text = beaconText[id]
    if not text then return end
    if text.fields.l ~= nil or text.fields.f ~= nil then
        local known = Blackacre.Lifecycle.HeardBeacons()[id]
        if not known or not SameName(known.senderName, text.sender) then return end
        beaconText[id] = nil
        known.lead, known.found = text.fields.l, text.fields.f
        NotifyBeacon(known)
        return
    end
    local hb = awaitingBeacon[id]
    if not hb or not SameName(hb.sender, text.sender) then return end
    awaitingBeacon[id], beaconText[id] = nil, nil
    local beacon = hb.beacon
    beacon.shortText = text.fields.s
    beacon.rumor = text.fields.r
    beacon.textLogged = true
    Blackacre.Lifecycle.StoreHeardBeacon(beacon)
    NotifyBeacon(beacon)
end

local function OnBeaconHeartbeat(sender, fields)
    if not SeekingOn() then return end
    local id, zoneId, zoneName = fields[2], tonumber(fields[3]), fields[4]
    if not id or not InMyRegion(zoneId, zoneName) then return end -- other regions: stop here
    local ownerGUID = (fields[10] and fields[10] ~= "") and fields[10] or nil
    if Blackacre.IsMuted(sender) or Blackacre.IsMuted(ownerGUID) then return end
    local expiresAt = tonumber(fields[8])
    if expiresAt and expiresAt < time() then return end
    local coords = { x = tonumber(fields[6]) or 0, y = tonumber(fields[7]) or 0 }

    local known = Blackacre.Lifecycle.HeardBeacons()[id]
    if known and SameName(known.senderName, sender) then
        -- Already have the crumbs: just follow the emitter's new spot.
        known.zoneId, known.zoneName, known.subzone = zoneId, zoneName, fields[5]
        known.coords, known.expiresAt, known.locKind = coords, expiresAt, fields[9]
        NotifyBeacon(known)
        return
    end

    PruneIncoming()
    awaitingBeacon[id] = {
        sender = sender,
        at = GetTime(),
        beacon = {
            id = id,
            senderName = sender,   -- kept for Report/Mute only; never shown
            ownerGUID = ownerGUID,
            zoneId = zoneId,
            zoneName = zoneName,
            subzone = fields[5],
            coords = coords,
            expiresAt = expiresAt,
            locKind = fields[9],
            status = Blackacre.STATUS.ACTIVE,
            receivedAt = time(),
        },
    }
    local now = GetTime()
    PruneCooldowns(now)
    if not askedCrumbsAt[id] or (now - askedCrumbsAt[id]) > BEACON_ASK_COOLDOWN then
        askedCrumbsAt[id] = now
        SendWhisper(sender, "BF" .. SEP .. id .. SEP .. "rumor", false, "NORMAL")
    end
    TryMergeBeacon(id)
end

-- Emitter side: our active beacon, only while Emit is on.
local function MyLiveBeacon()
    local p = Blackacre.CharDB and Blackacre.CharDB.presence
    if not p or not p.emitEnabled then return nil end
    if Blackacre.InInstance() then return nil end -- resting inside an instance
    return Blackacre.Lifecycle.GetActiveOwnedBeacon()
end

local function OnBeaconZoneQuery(sender, zoneId)
    local b = MyLiveBeacon()
    if not b or tonumber(zoneId) ~= b.zoneId then return end
    local now = GetTime()
    PruneCooldowns(now)
    if answeredZone[sender] and (now - answeredZone[sender]) < ZONE_ANSWER_COOLDOWN then return end
    answeredZone[sender] = now
    C_Timer.After(math.random() * ZONE_ANSWER_JITTER, function()
        local live = MyLiveBeacon()
        if live then Blackacre.Comms.SendBeaconHeartbeat(live, sender) end
    end)
end

local function OnCrumbRequest(sender, id, part)
    local b = MyLiveBeacon()
    if not b or b.id ~= id then return end
    part = (part == "trail") and "trail" or "rumor"
    local key = sender .. SEP .. id .. SEP .. part
    local now = GetTime()
    if answeredCrumbs[key] and (now - answeredCrumbs[key]) < CRUMB_ANSWER_COOLDOWN then return end
    answeredCrumbs[key] = now
    if part == "trail" then
        Blackacre.Comms.SendLoggedText("c", b.id, {
            { "l", b.lead or "" },
            { "f", b.found or "" },
        }, sender)
    else
        Blackacre.Comms.SendLoggedText("c", b.id, {
            { "s", b.shortText or "" },
            { "r", b.rumor or "" },
        }, sender)
    end
end

---------------------------------------------------------------------------
-- Fresh position for seekers who are closing in (Presence step 3).
--   BW  seeker -> emitter: "I've had your Lead; keep me posted."   (whisper)
--   BU  seeker -> emitter: "Found you / stop."                      (whisper)
--   BP  emitter -> each watching seeker: region, x, y, subzone     (whisper)
-- Only roving beacons need this. The emitter sends BP when it stops moving
-- or changes area, only to seekers who asked, and forgets them after
-- WATCH_TTL. Standing still with no watchers costs nothing.
---------------------------------------------------------------------------
local WATCH_TTL = 20 * 60
local MAX_WATCHERS = 12
local POSITION_MIN_GAP = 3

local watchers = {}         -- seeker -> expiry (GetTime)
local lastPositionAt = 0
local positionPending = false
local SendPositionToWatchers -- recursive via the timer below

-- Seeker: we just chose to Follow this trail; ask for its Lead and Found.
function Blackacre.Comms.RequestTrail(beacon)
    if not beacon or not beacon.senderName then return end
    if beacon.lead ~= nil or beacon.found ~= nil then return end -- already have them
    local now = GetTime()
    if askedTrailAt[beacon.id] and (now - askedTrailAt[beacon.id]) < BEACON_ASK_COOLDOWN then return end
    askedTrailAt[beacon.id] = now
    SendWhisper(beacon.senderName, "BF" .. SEP .. beacon.id .. SEP .. "trail", false, "NORMAL")
end

-- Seeker -> emitter: "I've had your Lead" / "I've found you" (anonymous on
-- screen). The emitter's add-on turns it into a Blackacre whisper.
function Blackacre.Comms.SendBeaconStage(emitter, id, stage)
    SendWhisper(emitter, "BE" .. SEP .. id .. SEP .. stage, false, "NORMAL")
end

function Blackacre.Comms.SendBeaconWatch(emitter, id, on)
    SendWhisper(emitter, (on and "BW" or "BU") .. SEP .. id, false, "NORMAL")
end

local function PositionMessage(b)
    local ctx = Blackacre.GetZoneContext()
    b.zoneId, b.zoneName, b.subzone, b.coords = ctx.zoneId, ctx.zoneName, ctx.subzone, ctx.coords
    return "BP" .. SEP .. b.id
        .. SEP .. (b.zoneId or 0)
        .. SEP .. string.format("%.4f", b.coords.x or 0)
        .. SEP .. string.format("%.4f", b.coords.y or 0)
        .. SEP .. (b.subzone or "")
        .. SEP .. (b.zoneName or "")
end

SendPositionToWatchers = function(force)
    if not next(watchers) then return end
    local b = MyLiveBeacon()
    if not b or b.locKind ~= "roving" then
        wipe(watchers)
        return
    end
    local now = GetTime()
    local waited = now - lastPositionAt
    if not force and waited < POSITION_MIN_GAP then
        -- Too soon: send once more when the gap is up, so the last stop still counts.
        if not positionPending then
            positionPending = true
            C_Timer.After(POSITION_MIN_GAP - waited, function()
                positionPending = false
                SendPositionToWatchers(true)
            end)
        end
        return
    end
    lastPositionAt = now
    local msg = PositionMessage(b)
    for seeker, untilAt in pairs(watchers) do
        if untilAt < now then
            watchers[seeker] = nil
        else
            SendWhisper(seeker, msg, false, "NORMAL")
        end
    end
end

local function OnBeaconWatch(sender, id, on)
    local b = MyLiveBeacon()
    if not b or b.id ~= id or b.locKind ~= "roving" then return end
    if not on then
        watchers[sender] = nil
        return
    end
    if not watchers[sender] then
        local count = 0
        for _ in pairs(watchers) do count = count + 1 end
        if count >= MAX_WATCHERS then return end
    end
    watchers[sender] = GetTime() + WATCH_TTL
    SendWhisper(sender, PositionMessage(b), false, "NORMAL")
end

local function OnBeaconPosition(sender, fields)
    local id = fields[2]
    local known = id and Blackacre.Lifecycle.HeardBeacons()[id]
    if not known or not SameName(known.senderName, sender) then return end
    known.zoneId = tonumber(fields[3]) or known.zoneId
    known.coords = { x = tonumber(fields[4]) or 0, y = tonumber(fields[5]) or 0 }
    known.subzone = fields[6] or known.subzone
    known.zoneName = fields[7] or known.zoneName
    if Blackacre.BeaconHead and Blackacre.BeaconHead.OnCacheChanged then
        Blackacre.BeaconHead.OnCacheChanged(known)
    end
end

-- Emitter: tell watchers when we stop moving or change area.
local positionFrame = CreateFrame("Frame")
pcall(positionFrame.RegisterEvent, positionFrame, "PLAYER_STOPPED_MOVING")
positionFrame:RegisterEvent("ZONE_CHANGED")
positionFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
positionFrame:SetScript("OnEvent", function(_, event)
    if not next(watchers) then return end
    if event == "PLAYER_STOPPED_MOVING" then
        SendPositionToWatchers(false)
    else
        C_Timer.After(1, function() SendPositionToWatchers(true) end)
    end
end)

-- Store a notice whose text has already passed the rules in AcceptBulletin.
StoreBulletin = function(data, sender)
    if not SeekingOn() then return end
    if not data or not data.id then return end
    if Blackacre.Lifecycle.IsWithdrawn(data.id, data.authorName or sender) then return end
    if data.expiresAt and data.expiresAt < time() then return end
    if Blackacre.IsMuted(sender) or Blackacre.IsMuted(data.authorName) or Blackacre.IsMuted(data.ownerGUID) then return end
    local bulletin = {
        id = data.id,
        ownerGUID = data.ownerGUID or sender,
        charName = data.charName or sender,
        authorName = data.authorName,
        textLogged = data.textLogged,
        postedAt = data.postedAt,
        zoneName = data.zoneName,
        factionNet = data.factionNet,
        factionNetID = data.factionNetID,
        lang = data.lang,
        title = data.title or "Bulletin",
        bodyText = data.bodyText,
        postedZones = data.postedZones,
        innNpcID = data.innNpcID,
        innName = data.innName,
        boardId = data.boardId,
        scopeTier = data.scopeTier or Blackacre.SCOPE.INDIVIDUAL,
        expiresAt = data.expiresAt,
        stationary = data.stationary,
        waxSeal = data.waxSeal,
        font = data.font,
        status = Blackacre.STATUS.ACTIVE,
        receivedAt = time(),
        senderName = sender,
    }
    CacheEntry("bulletin", bulletin)
    if Blackacre.InnBoard and Blackacre.InnBoard.OnBulletinDiscovered then
        Blackacre.InnBoard.OnBulletinDiscovered(bulletin)
    end
end

-- The rule for every incoming notice:
--   * no text in it -> it comes from its author; wait for their logged text.
--   * text in it and the sender claims to be the author -> ignore the text
--     (an author's words only count when logged) and wait for the logged copy.
--   * text in it from someone else -> a passed-on copy; accept as is.
local function AcceptBulletin(data, sender)
    if type(data) ~= "table" or not data.id then return end
    if Blackacre.Lifecycle.IsWithdrawn(data.id, data.authorName or sender) then return end
    local hasText = data.title ~= nil or data.bodyText ~= nil
    if not hasText or not data.authorName or SameName(sender, data.authorName) then
        data.title, data.bodyText = nil, nil
        PruneIncoming()
        awaitingMeta[data.id] = { data = data, sender = sender, at = GetTime() }
        TryMergeBulletin(data.id)
        return
    end
    StoreBulletin(data, sender)
end

-- Our own channel messages echo back to us, and the sender may or may not
-- carry "-Realm". Match both forms exactly (not Ambiguate, which would also
-- match a same-named player from another realm).
local myName, myFullName
local function IsMe(sender)
    if not myFullName then
        -- Realm can be missing very early in the session; cache once it's known.
        myName = UnitName("player")
        local full = MyFullName()
        if full and full:find("-", 1, true) then myFullName = full end
    end
    return sender == myName or sender == myFullName
end

-- Plain (non-encoded) messages are split into this one reused table: this is
-- the busiest path in the add-on, so it allocates nothing per message.
-- Handlers read fields during the call and never keep the table itself.
local fields = {}
local function FillFields(...)
    local n = select("#", ...)
    for i = 1, n do fields[i] = (select(i, ...)) end
    for i = n + 1, #fields do fields[i] = nil end
end

function Blackacre.Comms.OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= PREFIX or not message or not sender then return end
    if IsMe(sender) then return end
    if C_FriendList and C_FriendList.IsIgnored and C_FriendList.IsIgnored(sender) then return end

    if message == "PING" then
        SendWhisper(sender, "PONG", false)
        return
    end
    if message == "PONG" then
        Blackacre.Print("Comms ping from " .. sender)
        return
    end

    local decoded = DecodePayload(message)
    if decoded then
        if decoded.opcode == "NSZ" then
            AcceptBulletin(decoded, sender)
        elseif decoded.opcode == "IC_SUM" then
            if Blackacre.Share and Blackacre.Share.OnPeerSummary then
                Blackacre.Share.OnPeerSummary(sender, decoded)
            end
        end
        return
    end

    FillFields(strsplit(SEP, message))
    local opcode = fields[1]
    if opcode == "RT" then
        local kind, id = fields[2], fields[3]
        if kind == "notice" then kind = "bulletin" end
        if kind and id then
            -- Only the author can take their own notice or beacon down.
            Blackacre.Lifecycle.HandleRemoteRetract(kind, id, sender)
        end
    elseif opcode == "HI" then
        OnHello(fields[2])
    elseif opcode == "SQ" then
        Blackacre.Comms.SendSummaryTo(sender)
    elseif opcode == "BH" then
        OnBeaconHeartbeat(sender, fields)
    elseif opcode == "BZ" then
        OnBeaconZoneQuery(sender, fields[2])
    elseif opcode == "BW" or opcode == "BU" then
        if fields[2] then OnBeaconWatch(sender, fields[2], opcode == "BW") end
    elseif opcode == "BE" then
        if Blackacre.BeaconEmitter and fields[2] and fields[3] then
            Blackacre.BeaconEmitter.OnStage(sender, fields[2], fields[3])
        end
    elseif opcode == "BP" then
        OnBeaconPosition(sender, fields)
    elseif opcode == "BF" then
        if fields[2] then OnCrumbRequest(sender, fields[2], fields[3]) end
    elseif opcode == "IQ" then
        -- Inn query: "any notices for this region?" (Presence InnRelay answers)
        if Blackacre.InnRelay and fields[2] then
            Blackacre.InnRelay.OnQuery(sender, fields[2], fields[3])
        end
    elseif opcode == "IL" then
        -- Inn list: region key in plain text so other regions skip unpacking.
        if Blackacre.InnRelay and fields[2] and fields[3] then
            Blackacre.InnRelay.OnList(sender, fields[2], fields[3])
        end
    end
end

-- Small helpers for Presence (InnRelay). Kept here so all wire format stays in Comms.
Blackacre.Comms.Encode = EncodePayload
Blackacre.Comms.Decode = DecodePayload
Blackacre.Comms.IngestBulletin = AcceptBulletin

function Blackacre.Comms.SendChannelRaw(message, prio)
    return SendOnChannel(message, prio)
end

function Blackacre.Comms.SendSummaryTo(target)
    if not target or target == "" then return end
    if not Blackacre.Share or not Blackacre.Share.Export then return end
    local payload = Blackacre.Share.Export.BuildPeerPayload()
    local encoded = EncodePayload(payload)
    SendWhisper(target, encoded, false, "NORMAL")
end

function Blackacre.Comms.RequestSummary(target)
    if not target or target == "" then
        Blackacre.Print("Usage: /ic share PlayerName")
        return
    end
    SendWhisper(target, "SQ", false, "NORMAL")
    Blackacre.Print("Requested Blackacre summary from " .. target .. ".")
end
