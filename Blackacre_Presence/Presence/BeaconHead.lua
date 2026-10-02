-- In Character Forever: Beacons & Bulletins - Beacon Crumbs

Blackacre = Blackacre or {}
Blackacre.BeaconHead = {}

local FOUND_YARDS = 25          -- roughly /say hearing distance
local LEAD_OPEN_YARDS = 200     -- Lead fallback where there's no subzone name
local SWITCH_COOLDOWN = 10 * 60 -- same emitter, new beacon: wait before restarting
local HEARD_KEEP = 7 * 24 * 60 * 60

local localFrame

-- Yards between us and the beacon, or nil if we can't tell (other map, no position).
local function DistanceYards(ctx, beacon)
    if not ctx.zoneId or ctx.zoneId == 0 or ctx.zoneId ~= beacon.zoneId then return nil end
    return Blackacre.MapDistanceYards(ctx.zoneId, ctx.coords, beacon.coords)
end

local function HeardDB()
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    p.heardBeacons = p.heardBeacons or {}
    return p.heardBeacons
end

-- Which beacon each emitter's crumbs we've had, so nothing repeats. Keyed by
-- sender (beacons carry no name on screen; this never leaves our SavedVariables).
local function HeardKey(beacon)
    return beacon.senderName or beacon.ownerGUID
end

local function EnsureLocalFrame()
    if localFrame then return localFrame end
    local f = CreateFrame("Frame", "BlackacreLocalCrumb", UIParent, "BackdropTemplate")
    f:SetSize(420, 90)
    f:SetPoint("TOP", 0, -80)
    f:SetFrameStrata("DIALOG")
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.ApplyParchmentBackdrop then
        Blackacre.UI.Theme.ApplyParchmentBackdrop(f, 0.95)
    end
    f.who = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.who:SetPoint("TOPLEFT", 14, -10)
    f.who:SetText("A local says")
    if Blackacre.UI and Blackacre.UI.Theme then Blackacre.UI.Theme.GoldTitle(f.who) end
    f.body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.body:SetPoint("TOPLEFT", 14, -32)
    f.body:SetPoint("BOTTOMRIGHT", -96, 12)
    f.body:SetJustifyH("LEFT")
    f.body:SetJustifyV("TOP")
    f:EnableMouse(true)
    f.report = Blackacre.Report.MakeButton(f, function()
        Blackacre.Report.Beacon(f.beacon)
        f:Hide()
    end)
    f.report:SetPoint("BOTTOMRIGHT", -10, 10)
    f:Hide()
    localFrame = f
    return f
end

local LEAD_HOLD = 12 -- seconds; long enough to read and reach the Report button
local leadShownAt = 0

local function ShowLocal(text, beacon)
    if not text or text == "" then return end
    local f = EnsureLocalFrame()
    f.body:SetText(text)
    f.beacon = beacon
    f:Show()
    local shownAt = GetTime()
    leadShownAt = shownAt
    f:SetScript("OnLeave", function(self)
        if GetTime() - leadShownAt >= LEAD_HOLD then self:Hide() end
    end)
    C_Timer.After(LEAD_HOLD, function()
        -- Only hide the popup this timer belongs to, and not while the mouse is on it.
        if leadShownAt == shownAt and f:IsShown() and not f:IsMouseOver() then f:Hide() end
    end)
end

local function ShowFound(text)
    if not text or text == "" then return end
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast(text)
    else
        Blackacre.Print(text)
    end
    if Minimap and Minimap.PingLocation then
        pcall(function() Minimap:PingLocation(0, 0) end)
    end
end

local function InRegion(ctx, beacon)
    if ctx.zoneId and ctx.zoneId ~= 0 and ctx.zoneId == beacon.zoneId then return true end
    local a, b = ctx.zoneName or "", beacon.zoneName or ""
    return a ~= "" and a:lower() == b:lower()
end

local function LeadHere(ctx, beacon, d)
    local a = (ctx.subzone or ""):lower()
    local b = (beacon.subzone or ""):lower()
    if a ~= "" and b ~= "" then return a == b end
    -- No subzone name to compare (open country): fall back to distance.
    return d ~= nil and d <= LEAD_OPEN_YARDS
end

local function HasText(t)
    return t ~= nil and t ~= ""
end

-- Hunting = we've had the Lead and are closing in. A roving emitter then
-- keeps our copy of their position fresh until we find them (or stop).
local function StartHunting(beacon, rec)
    if rec.hunting or rec.stopped then return end
    rec.hunting = true
    if beacon.locKind == "roving" and beacon.senderName and Blackacre.Comms.SendBeaconWatch then
        Blackacre.Comms.SendBeaconWatch(beacon.senderName, beacon.id, true)
    end
end

local function StopHunting(beacon, rec)
    if not rec.hunting then return end
    rec.hunting = false
    if beacon.locKind == "roving" and beacon.senderName and Blackacre.Comms.SendBeaconWatch then
        Blackacre.Comms.SendBeaconWatch(beacon.senderName, beacon.id, false)
    end
end

local function DeliverInner(beacon)
    if not beacon then return end
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    if p.seekingEnabled == false then return end
    if Blackacre.InInstance() then return end
    if beacon.ownerGUID and beacon.ownerGUID == UnitGUID("player") then return end
    if Blackacre.IsMuted(beacon.senderName) or Blackacre.IsMuted(beacon.ownerGUID) then return end
    local key = HeardKey(beacon)
    if not key then return end

    local heard = HeardDB()
    local rec = heard[key]
    local now = time()
    if rec and rec.id ~= beacon.id and rec.at and (now - rec.at) < SWITCH_COOLDOWN then
        return
    end
    if not rec or rec.id ~= beacon.id then
        rec = { id = beacon.id, rumor = false, lead = false, found = false, at = now }
        heard[key] = rec
    end
    if rec.found then return rec end

    local ctx = Blackacre.GetZoneSnapshot()
    if not InRegion(ctx, beacon) then return rec end
    local d = DistanceYards(ctx, beacon)

    -- Not following this trail: we only ever get its Rumor (in Trails).
    local followed = Blackacre.Trails and Blackacre.Trails.IsFollowing(beacon)
    if not followed then
        if not rec.rumor then
            rec.rumor, rec.at = true, now
            if (HasText(beacon.shortText) or HasText(beacon.rumor)) and Blackacre.Trails then
                Blackacre.Trails.OnRumorHeard(beacon)
            end
        end
        return rec
    end
    -- Just followed: wait for the Lead/Found text before climbing, or the
    -- Lead would be marked heard with nothing shown.
    if beacon.lead == nil and beacon.found == nil then return rec end

    -- Highest rung first; reaching one marks the ones below it as heard.
    if d and d <= FOUND_YARDS then
        rec.found, rec.lead, rec.rumor, rec.at = true, true, true, now
        StopHunting(beacon, rec)
        if HasText(beacon.found) then
            ShowFound(beacon.found)
        end
        if beacon.senderName then Blackacre.Comms.SendBeaconStage(beacon.senderName, beacon.id, "found") end
        return rec
    end
    if LeadHere(ctx, beacon, d) then
        StartHunting(beacon, rec)
        if not rec.lead then
            rec.lead, rec.rumor, rec.at = true, true, now
            if HasText(beacon.lead) then
                ShowLocal(beacon.lead, beacon)
            end
            if beacon.senderName then Blackacre.Comms.SendBeaconStage(beacon.senderName, beacon.id, "lead") end
        end
        return rec
    end
    if not rec.rumor then
        rec.rumor, rec.at = true, now
        -- The Status line (third person, e.g. "A curious traveler seeks
        -- conversation nearby.") and the Rumor land in the Trails pane.
        if (HasText(beacon.shortText) or HasText(beacon.rumor)) and Blackacre.Trails then
            Blackacre.Trails.OnRumorHeard(beacon)
        end
    end
    return rec
end

function Blackacre.BeaconHead.Deliver(beacon)
    local rec = DeliverInner(beacon)
    if rec and Blackacre.BeaconHint then Blackacre.BeaconHint.Update(beacon, rec) end
end

-- Our ladder record for a beacon (nil if none yet). Used by the Trails pane.
function Blackacre.BeaconHead.Record(beacon)
    local key = beacon and HeardKey(beacon)
    local rec = key and HeardDB()[key]
    if rec and rec.id == beacon.id then return rec end
    return nil
end

-- We let go of a trail: stop position updates and drop the minimap hint.
-- Following again later picks up where we left off.
function Blackacre.BeaconHead.StopFollowing(beacon)
    local rec = Blackacre.BeaconHead.Record(beacon)
    if rec then StopHunting(beacon, rec) end
    if Blackacre.BeaconHint then Blackacre.BeaconHint.Update(beacon, nil) end
end

-- Whispering or targeting the emitter means we've found them in play:
-- stop asking for their position (no Found toast; that's for walking up).
-- Pass the whispered name or the target's GUID. Runs on every target change,
-- so no closure per call and nothing to walk when no beacon is heard.
local function StopHuntingPlayer(name, guid)
    local beacons = Blackacre.Lifecycle.HeardBeacons()
    if not next(beacons) then return end
    local heard = HeardDB()
    local SameName = Blackacre.Comms.SameName
    for _, b in pairs(beacons) do
        local rec = heard[HeardKey(b) or ""]
        if rec and rec.id == b.id and rec.hunting
            and ((name and SameName(b.senderName, name)) or (guid and b.ownerGUID == guid)) then
            StopHunting(b, rec)
            rec.stopped = true -- don't start again for this beacon
            if Blackacre.BeaconHint then Blackacre.BeaconHint.Update(b, rec) end
        end
    end
end

local function PruneHeard()
    local heard = HeardDB()
    local cutoff = time() - HEARD_KEEP
    for k, rec in pairs(heard) do
        if not rec.at or rec.at < cutoff then
            heard[k] = nil
        else
            rec.hunting = nil -- emitters forget watchers at logout; ask again if needed
        end
    end
end

function Blackacre.BeaconHead.OnCacheChanged(beacon)
    if beacon then
        Blackacre.BeaconHead.Deliver(beacon)
        return
    end
    -- Only beacons heard from others; our own is never delivered to us.
    local now = time()
    for _, b in pairs(Blackacre.Lifecycle.HeardBeacons()) do
        if not b.expiresAt or b.expiresAt >= now then
            Blackacre.BeaconHead.Deliver(b)
        end
    end
end

-- Arriving in a region: ask once "who's emitting here?" so we learn of
-- beacons that went up before we arrived. At most once per region per 5 min.
local ZONE_ASK_COOLDOWN = 5 * 60
local askedZoneAt = {}

function Blackacre.BeaconHead.QueryHere()
    local p = Blackacre.CharDB and Blackacre.CharDB.presence
    if p and (p.seekingEnabled == false or p.receiveBeacons == false) then return end
    if Blackacre.InInstance() then return end
    local zoneId = Blackacre.GetZoneSnapshot().zoneId
    if not zoneId or zoneId == 0 then return end
    local now = GetTime()
    if askedZoneAt[zoneId] and (now - askedZoneAt[zoneId]) < ZONE_ASK_COOLDOWN then return end
    if Blackacre.Comms.SendBeaconZoneQuery(zoneId) then
        askedZoneAt[zoneId] = now -- only count it if the channel was ready
    end
end

function Blackacre.BeaconHead.Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED")
    f:RegisterEvent("ZONE_CHANGED_INDOORS")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:SetScript("OnEvent", function(_, event)
        C_Timer.After(0.3, Blackacre.BeaconHead.OnCacheChanged)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(8, Blackacre.BeaconHead.QueryHere) -- hidden channel joins late at login
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            C_Timer.After(2, Blackacre.BeaconHead.QueryHere)
        end
    end)
    if Blackacre.OnPlayerMove then
        Blackacre.OnPlayerMove(Blackacre.BeaconHead.OnCacheChanged)
    end
    PruneHeard()
    local found = CreateFrame("Frame")
    found:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    found:RegisterEvent("PLAYER_TARGET_CHANGED")
    found:SetScript("OnEvent", function(_, event, _, target)
        if event == "CHAT_MSG_WHISPER_INFORM" then
            if target then StopHuntingPlayer(target, nil) end
        else
            local guid = UnitGUID("target")
            if guid then StopHuntingPlayer(nil, guid) end
        end
    end)
end
