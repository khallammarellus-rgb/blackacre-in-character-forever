-- In Character Forever: Beacons & Bulletins - Beacon Minimap Hint

Blackacre = Blackacre or {}
Blackacre.BeaconHint = {}

local pairs, random, sin, cos, pi = pairs, math.random, math.sin, math.cos, math.pi
local HBDPins = LibStub("HereBeDragons-Pins-2.0", true)

local HINT_MIN, HINT_MAX = 25, 60   -- yards off the true spot
local HINT_SIZE = 22                -- pixels on the minimap
local HINT_REF = "Blackacre-BeaconHint"

local pool, shown = {}, {}  -- shown: beacon id -> icon frame
local offsets = {}          -- beacon id -> { dx, dy } in yards, rolled once

local function NewIcon()
    local f = CreateFrame("Frame", nil, Minimap)
    f:SetSize(HINT_SIZE, HINT_SIZE)
    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetColorTexture(1, 0.82, 0.25, 0.55)
    local mask = Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Textures
        and Blackacre.UI.Theme.Textures.beaconHintMask
    if mask and f.CreateMaskTexture then
        local m = f:CreateMaskTexture()
        m:SetTexture(mask, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        m:SetAllPoints(tex)
        tex:AddMaskTexture(m)
    end
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Someone is about, somewhere near here.", 1, 0.82, 0.25, true)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", GameTooltip_Hide)
    return f
end

local function Release(id)
    local icon = shown[id]
    if not icon then return end
    shown[id] = nil
    if HBDPins then HBDPins:RemoveMinimapIcon(HINT_REF, icon) end
    icon:Hide()
    pool[#pool + 1] = icon
end

local function Offset(id)
    local o = offsets[id]
    if not o then
        local angle = random() * 2 * pi
        local dist = HINT_MIN + random() * (HINT_MAX - HINT_MIN)
        o = { cos(angle) * dist, sin(angle) * dist }
        offsets[id] = o
    end
    return o[1], o[2]
end

-- Show or move the hint for one beacon.
local function Place(beacon)
    if not HBDPins or not beacon.zoneId or beacon.zoneId == 0 or not beacon.coords then return end
    if not (C_Map and C_Map.GetMapWorldSize) then return end
    local w, h = C_Map.GetMapWorldSize(beacon.zoneId)
    if not w or w <= 0 or not h or h <= 0 then return end
    local dx, dy = Offset(beacon.id)
    local x = beacon.coords.x + dx / w
    local y = beacon.coords.y + dy / h
    local icon = shown[beacon.id]
    if not icon then
        icon = pool[#pool]
        if icon then pool[#pool] = nil else icon = NewIcon() end
        shown[beacon.id] = icon
    end
    icon:Show()
    -- floatOnEdge = true: stays on the minimap rim, pointing the way, when far.
    HBDPins:AddMinimapIconMap(HINT_REF, icon, beacon.zoneId, x, y, false, true)
end

-- rec: our ladder record for this beacon (from BeaconHead).
function Blackacre.BeaconHint.Update(beacon, rec)
    if not beacon then return end
    local followed = Blackacre.Trails and Blackacre.Trails.IsFollowing(beacon)
    if followed and rec and rec.lead and not rec.found and not rec.stopped then
        Place(beacon)
    else
        Release(beacon.id)
    end
end

-- Drop hints whose beacon is gone (expired, withdrawn, muted, receive off).
function Blackacre.BeaconHint.Refresh()
    local p = Blackacre.CharDB and Blackacre.CharDB.presence
    local off = p and (p.receiveBeacons == false or p.seekingEnabled == false)
    local heard = Blackacre.Lifecycle.HeardBeacons()
    for id in pairs(shown) do
        if off or not heard[id] then Release(id) end
    end
    for id in pairs(offsets) do
        if not heard[id] then offsets[id] = nil end
    end
end

function Blackacre.BeaconHint.Init()
    if not HBDPins then
        Blackacre.Print("HereBeDragons didn't load; beacon minimap hints are off.")
    end
end
