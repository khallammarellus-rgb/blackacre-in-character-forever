-- In Character Forever: Beacons & Bulletins - Beacon Emitter

Blackacre = Blackacre or {}
Blackacre.BeaconEmitter = {}

local GetTime = GetTime
local MOVE_YARDS = 50
local WHISPER_GAP = 30       -- seconds between Blackacre whispers, however busy
local askedMoved = {}        -- beacon id -> true once the popup has been shown
local stageSeen = {}         -- sender .. stage .. id -> true
local lastWhisperAt = -1000

---------------------------------------------------------------------------
-- 1. Moving off your spot
---------------------------------------------------------------------------
local function LiveFixedBeacon()
    local p = Blackacre.CharDB and Blackacre.CharDB.presence
    if not p or not p.emitEnabled or Blackacre.InInstance() then return nil end
    local b = Blackacre.Lifecycle.GetActiveOwnedBeacon()
    if not b or b.locKind == "roving" or b.leftSpot then return nil end
    return b
end

local function CheckMoved()
    local b = LiveFixedBeacon()
    if not b or askedMoved[b.id] then return end
    local ctx = Blackacre.GetZoneSnapshot()
    local far
    if ctx.zoneId ~= b.zoneId then
        far = true
    else
        local d = Blackacre.MapDistanceYards(ctx.zoneId, ctx.coords, b.coords)
        far = d ~= nil and d > MOVE_YARDS
    end
    if far then
        askedMoved[b.id] = true
        StaticPopup_Show("BLACKACRE_BEACON_MOVED", nil, nil, b.id)
    end
end

local function SameActive(id)
    local b = Blackacre.Lifecycle.GetActiveOwnedBeacon()
    return b and b.id == id and b or nil
end

StaticPopupDialogs["BLACKACRE_BEACON_MOVED"] = {
    text = "You're moving away from where your beacon says you are. What would you like to do?",
    button1 = "Withdraw beacon",
    button2 = "Switch to roving",
    button3 = "Leave & update crumbs",
    selectCallbackByIndex = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
    OnButton1 = function(_, id)
        if not SameActive(id) then return end
        Blackacre.Lifecycle.StopBeacon()
        Blackacre.Lifecycle.EnsurePresenceDB().emitEnabled = false
    end,
    OnButton2 = function(_, id)
        local b = SameActive(id)
        if not b then return end
        b.locKind = "roving"
        Blackacre.Lifecycle.SendHeartbeat(true)
        Blackacre.Print("Your beacon now roves with you.")
    end,
    OnButton3 = function(_, id)
        local b = SameActive(id)
        if not b then return end
        b.leftSpot = true -- don't ask again for this beacon
        if Blackacre.PostEditor and Blackacre.PostEditor.ShowBeaconEditor then
            Blackacre.PostEditor.ShowBeaconEditor()
        end
        if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
            Blackacre.UI.Theme.Toast("Rewrite your crumbs so seekers learn you've moved on, then click Update.")
        end
    end,
    OnShow = function(self)
        -- Tooltip on the third button explaining what "update crumbs" means.
        local b3 = (self.GetButton and self:GetButton(3)) or self.button3
        if not b3 or b3.blackacreTip then return end
        b3.blackacreTip = true
        b3:HookScript("OnEnter", function(btn)
            if not (btn:GetParent() and btn:GetParent().which == "BLACKACRE_BEACON_MOVED") then return end
            GameTooltip:SetOwner(btn, "ANCHOR_TOP")
            GameTooltip:SetText("Leave & update crumbs")
            GameTooltip:AddLine("Your beacon stays where you set it. Seekers will now get a crumb telling them you were once there but are no longer. "
                .. "Updating your crumbs is important so you can still be sought.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b3:HookScript("OnLeave", GameTooltip_Hide)
    end,
}

---------------------------------------------------------------------------
-- 2. Someone is on your trail
---------------------------------------------------------------------------
-- Keyed by Status (template id). Lead = they've heard of you nearby;
-- found = they're close enough to hear you speak.
local STAGE_LINES = {
    seeking = {
        lead = "Word of you has reached someone looking for the same kind of company.",
        found = "Someone has come looking for company. They're close.",
    },
    watching = {
        lead = "Someone nearby has heard that you keep watch here.",
        found = "Someone approaches your post.",
    },
    calling = {
        lead = "Your call has been heard.",
        found = "Someone has answered your call and is near.",
    },
    dark_work = {
        lead = "Whispers of your craft have reached a curious ear.",
        found = "Someone unafraid draws near.",
    },
    trade = {
        lead = "Your reputation as a tradesman precedes you.",
        found = "Another trade opportunity approaches.",
    },
    aid = {
        lead = "Someone has heard that you're in need.",
        found = "Help is close at hand.",
    },
    story = {
        lead = "Someone has heard you have a tale to tell.",
        found = "A listener has found you.",
    },
}
local DEFAULT_LINES = {
    lead = "Someone has heard of you nearby.",
    found = "Someone is close.",
}

local function BlackacreWhisper(text)
    local info = ChatTypeInfo and ChatTypeInfo["WHISPER"]
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffc9a227Blackacre|r whispers: " .. text,
            info and info.r or 1, info and info.g or 0.5, info and info.b or 1)
    end
end

-- A seeker's add-on told us they reached a stage ("lead" or "found").
function Blackacre.BeaconEmitter.OnStage(sender, id, stage)
    if stage ~= "lead" and stage ~= "found" then return end
    local p = Blackacre.CharDB and Blackacre.CharDB.presence
    if not p or not p.emitEnabled or Blackacre.InInstance() then return end
    local b = Blackacre.Lifecycle.GetActiveOwnedBeacon()
    if not b or b.id ~= id then return end
    local key = sender .. "|" .. stage .. "|" .. id
    if stageSeen[key] then return end
    stageSeen[key] = true
    local now = GetTime()
    if now - lastWhisperAt < WHISPER_GAP then return end
    lastWhisperAt = now
    local lines = STAGE_LINES[b.templateId] or DEFAULT_LINES
    BlackacreWhisper(lines[stage] or DEFAULT_LINES[stage])
end

function Blackacre.BeaconEmitter.Init()
    if Blackacre.OnPlayerMove then
        Blackacre.OnPlayerMove(CheckMoved)
    end
end
