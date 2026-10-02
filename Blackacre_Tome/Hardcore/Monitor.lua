-- In Character Forever: Journal - Honor Monitor

Blackacre = Blackacre or {}
Blackacre.Hardcore = Blackacre.Hardcore or {}
Blackacre.Hardcore.Monitor = {}

local format, concat, time = string.format, table.concat, time
local CreateFrame, C_Timer, IsMounted = CreateFrame, C_Timer, IsMounted

local ALLOWED_BAG_SLOTS = 6

local lastBagSignature = ""
local mountStainActive = false
local deathLock = false
local bagWait = false
local mountWait = false
local offenders = {}

local function EnsureHardcoreDB()
    Blackacre.CharDB.hardcore = Blackacre.CharDB.hardcore or {
        deathCount = 0,
        lastDeathAt = nil,
        encumbranceActive = false,
        mountViolations = 0,
        encumbranceViolations = 0,
    }
    Blackacre.CharDB.gate = Blackacre.CharDB.gate or { ground = false }
    return Blackacre.CharDB.hardcore
end

local function NotifySettings()
    if Blackacre.Options and Blackacre.Options.Notify then Blackacre.Options.Notify() end
end

function Blackacre.Hardcore.GetStatus()
    local hc = EnsureHardcoreDB()
    local gate = Blackacre.CharDB.gate
    return {
        deathCount = hc.deathCount or 0,
        encumbranceActive = hc.encumbranceActive and true or false,
        mountViolations = hc.mountViolations or 0,
        encumbranceViolations = hc.encumbranceViolations or 0,
        groundGate = gate.ground and true or false,
        clean = (hc.deathCount or 0) == 0
            and not hc.encumbranceActive
            and (hc.mountViolations or 0) == 0,
    }
end

local function GetBagNumSlots(bagId)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bagId) or 0
    end
    return 0
end

-- Worn bags 1-4 only (0 is the backpack).
local function ScanBags()
    for i = #offenders, 1, -1 do offenders[i] = nil end
    for bagId = 1, 4 do
        local slots = GetBagNumSlots(bagId)
        if slots > 0 and slots ~= ALLOWED_BAG_SLOTS then
            offenders[#offenders + 1] = format("bag %d (%d slots)", bagId, slots)
        end
    end
    return offenders
end

local function CheckBags()
    local hc = EnsureHardcoreDB()
    local list = ScanBags()
    local signature = concat(list, "|")
    if signature == lastBagSignature then return end
    lastBagSignature = signature

    if #list == 0 then
        hc.encumbranceActive = false
        return
    end
    -- Log only when the set of oversized bags changes.
    hc.encumbranceActive = true
    hc.encumbranceViolations = (hc.encumbranceViolations or 0) + 1
    NotifySettings()
end

local function CheckMount()
    if not IsMounted() then
        mountStainActive = false
        return
    end
    if Blackacre.CharDB.gate.ground or mountStainActive then return end
    mountStainActive = true
    local hc = EnsureHardcoreDB()
    hc.mountViolations = (hc.mountViolations or 0) + 1
    NotifySettings()
end

local function OnDeath()
    if deathLock then return end
    deathLock = true
    local hc = EnsureHardcoreDB()
    hc.deathCount = (hc.deathCount or 0) + 1
    hc.lastDeathAt = time()
    local zone = Blackacre.GetZoneContext()
    Blackacre.Chronicle.Capture.AddEntry("DEATH", {
        zoneName = zone.zoneName,
        deathIndex = hc.deathCount,
        title = "Death #" .. tostring(hc.deathCount) .. " - " .. (zone.zoneName or "unknown"),
    }, "auto")
    Blackacre.UI.Theme.Toast("Death #" .. tostring(hc.deathCount) .. " in " .. (zone.zoneName or "unknown"), "maw")
    NotifySettings()
    -- Afterlife rites live in Backstory; absent, deaths are simply counted.
    if Blackacre.Afterlife and Blackacre.Afterlife.PathTracker then
        Blackacre.Afterlife.PathTracker.OnDeath()
    end
    C_Timer.After(5, function() deathLock = false end)
end

local function ScheduleBags()
    if bagWait then return end
    bagWait = true
    C_Timer.After(0.35, function()
        bagWait = false
        CheckBags()
    end)
end

local function ScheduleMount()
    if mountWait then return end
    mountWait = true
    C_Timer.After(0.2, function()
        mountWait = false
        CheckMount()
    end)
end

function Blackacre.Hardcore.Monitor.Init()
    EnsureHardcoreDB()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("PLAYER_DEAD")
    -- Fires on both mounting and dismounting.
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_DEAD" then
            OnDeath()
            return
        end
        if event ~= "PLAYER_MOUNT_DISPLAY_CHANGED" then
            ScheduleBags()
        end
        if event == "PLAYER_MOUNT_DISPLAY_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            ScheduleMount()
        end
    end)
end

function Blackacre.Hardcore.SetGroundGate(complete)
    Blackacre.CharDB.gate.ground = complete and true or false
    mountStainActive = false
    NotifySettings()
end
