Blackacre = Blackacre or {}
Blackacre.Survival = Blackacre.Survival or {}
Blackacre.Survival.Engine = {}
Blackacre.Survival.Engine.BUILD = "2026-09-20-stacks"

-- Hot-path upvalues (DBM-Core style): direct register reads, not global lookups.
local time, tostring, tonumber = time, tostring, tonumber
local UnitRace, CreateFrame = UnitRace, CreateFrame
local C_Container, C_Timer = C_Container, C_Timer

local TICK_SEC = 15
local DEBUFF_AT = 10
local MAX_CATCHUP_SEC = 300

local lastClimateLabel = nil
local skipClimateToast = true
local undeadKnown, undeadValue
local hasFood, hasWater = false, false
local provisionsKnown = false

local DEBUFF_TOAST = {
    hunger = "You feel faint and hungry",
    thirst = "Your water skins are getting light",
    exposure = "The elements are getting harsh on you",
}
local ZERO_TOAST = {
    hunger = "You need to eat soon",
    thirst = "Your throat feels dry",
    exposure = "The environment turns against you",
}

local FOOD_HINTS = {
    "food", "feast", "meal", "banquet", "well fed", "stew", "soup", "roast",
    "bread", "pie", "cake", "sausage", "fish", "seafood", "haunch", "ribs",
}
local DRINK_HINTS = {
    "drink", "refreshment", "tea", "coffee", "juice", "water", "wine", "ale",
    "mead", "milk", "waterskin",
}
local CANNIBALIZE_IDS = {
    [20577] = true,
    [20578] = true,
}

local function EnsureDB()
    Blackacre.CharDB.survival = Blackacre.CharDB.survival or {
        enabled = true,
        hunger = 100,
        thirst = 100,
        exposure = 100,
        lastTick = time(),
        hideMeters = false,
    }
    local s = Blackacre.CharDB.survival
    if s.hunger == nil then s.hunger = 100 end
    if s.thirst == nil then s.thirst = 100 end
    if s.exposure == nil then s.exposure = 100 end
    if s.enabled == nil then s.enabled = true end
    return s
end

local function Clamp(v)
    if v < 0 then return 0 end
    if v > 100 then return 100 end
    return v
end

local function IsUndead()
    if undeadKnown then return undeadValue end
    local raceFile = Blackacre.Compat and Blackacre.Compat.GetPlayerRaceFile and Blackacre.Compat.GetPlayerRaceFile()
    if raceFile == "Scourge" then
        undeadKnown, undeadValue = true, true
        return true
    end
    local race = UnitRace and UnitRace("player") or ""
    race = race:lower()
    undeadValue = (race:find("undead", 1, true) or race:find("forsaken", 1, true)) and true or false
    undeadKnown = true
    return undeadValue
end

local function Toast(msg)
    if not msg or msg == "" then return end
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast(msg)
    else
        Blackacre.Print(msg)
    end
end

local function CurrentClimate()
    local zone = Blackacre.GetZoneContext()
    return Blackacre.ZoneClimate.GetProfile(zone.zoneId, zone.zoneName, zone.subzone)
end

local function NameHasHint(name, hints)
    if not name or name == "" then return false end
    local lower = name:lower()
    for i = 1, #hints do
        if lower:find(hints[i], 1, true) then
            return true
        end
    end
    return false
end

-- GetItemInfoInstant only. GetItemInfo queries the server when the item is cold and hitches the client.
local function ItemClass(itemID)
    if not itemID then return nil, nil, nil end
    if C_Item and C_Item.GetItemInfoInstant then
        local _, itemType, itemSubType, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
        return classID, subclassID, itemSubType or itemType
    end
    if GetItemInfoInstant then
        local _, itemType, itemSubType, _, _, classID, subclassID = GetItemInfoInstant(itemID)
        return classID, subclassID, itemSubType or itemType
    end
    return nil, nil, nil
end

local function BagItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
    return nil
end

local function BagItemID(bag, slot)
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    end
    if GetContainerItemID then
        return GetContainerItemID(bag, slot)
    end
    local link = BagItemLink(bag, slot)
    if link then
        return tonumber(link:match("item:(%d+)"))
    end
    return nil
end

local function BagSlotCount(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    if GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function BagMax()
    if NUM_TOTAL_EQUIPPED_BAG_SLOTS then return NUM_TOTAL_EQUIPPED_BAG_SLOTS end
    if NUM_BAG_SLOTS then return NUM_BAG_SLOTS end
    return 4
end

-- Food & Drink subclass is 5 on Retail/Forever; name-split water vs food.
local function ClassifyProvision(itemID, itemName)
    local classID, subclassID, itemSubType = ItemClass(itemID)
    local name = itemName or ""
    local sub = tostring(itemSubType or ""):lower()
    local isFoodDrink = (classID == 0 and subclassID == 5)
        or sub:find("food", 1, true)
        or sub:find("drink", 1, true)
    if NameHasHint(name, DRINK_HINTS) then return "water" end
    if isFoodDrink or NameHasHint(name, FOOD_HINTS) then return "food" end
    return nil
end

local function RescanProvisions()
    hasFood, hasWater = false, false
    for bag = 0, BagMax() do
        local slots = BagSlotCount(bag)
        for slot = 1, slots do
            local itemID = BagItemID(bag, slot)
            if itemID then
                local link = BagItemLink(bag, slot)
                local itemName = link and link:match("%[(.-)%]") or ""
                local kind = ClassifyProvision(itemID, itemName)
                if kind == "food" then hasFood = true end
                if kind == "water" then hasWater = true end
                if hasFood and hasWater then
                    provisionsKnown = true
                    return
                end
            end
        end
    end
    provisionsKnown = true
end

function Blackacre.Survival.Engine.ScanProvisions()
    if not provisionsKnown then
        RescanProvisions()
    end
    return hasFood, hasWater
end

function Blackacre.Survival.Engine.MarkProvisionsDirty()
    provisionsKnown = false
end

function Blackacre.Survival.GetState()
    local s = EnsureDB()
    local zone = Blackacre.GetZoneContext()
    local climate = Blackacre.ZoneClimate.GetProfile(zone.zoneId, zone.zoneName, zone.subzone)
    local hasFood, hasWater = Blackacre.Survival.Engine.ScanProvisions()
    return {
        enabled = s.enabled,
        hunger = s.hunger,
        thirst = s.thirst,
        exposure = s.exposure,
        climate = climate,
        zoneName = zone.zoneName,
        hasFood = hasFood,
        hasWater = hasWater,
        hideMeters = s.hideMeters,
        undead = IsUndead(),
    }
end

local function FireCrossing(meter, prev, now)
    if prev > DEBUFF_AT and now <= DEBUFF_AT then
        Toast(DEBUFF_TOAST[meter])
    end
    if prev > 0 and now <= 0 then
        Toast(ZERO_TOAST[meter])
    end
end

function Blackacre.Survival.Engine.Tick()
    local s = EnsureDB()
    if not s.enabled then
        s.lastTick = time()
        return
    end

    local now = time()
    local elapsed = now - (s.lastTick or now)
    if elapsed < 0 then elapsed = 0 end
    if elapsed > MAX_CATCHUP_SEC then elapsed = MAX_CATCHUP_SEC end
    s.lastTick = now
    if elapsed < 1 then return end

    local minutes = elapsed / 60
    local climate = CurrentClimate()
    local hasFood, hasWater = Blackacre.Survival.Engine.ScanProvisions()

    local prevH, prevT, prevE = s.hunger, s.thirst, s.exposure
    local hungerLoss = (climate.hunger or 1) * minutes
    local thirstLoss = (climate.thirst or 1) * minutes
    local exposureLoss = (climate.exposure or 1) * minutes
    if hasFood then hungerLoss = 0 end
    if hasWater then thirstLoss = 0 end

    s.hunger = Clamp(s.hunger - hungerLoss)
    s.thirst = Clamp(s.thirst - thirstLoss)
    s.exposure = Clamp(s.exposure - exposureLoss)

    FireCrossing("hunger", prevH, s.hunger)
    FireCrossing("thirst", prevT, s.thirst)
    FireCrossing("exposure", prevE, s.exposure)

    if Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
        Blackacre.Survival.UI.Refresh()
    end
end

function Blackacre.Survival.Engine.Recover(kind, amount)
    local s = EnsureDB()
    amount = amount or 20
    if kind == "hunger" or kind == "eat" then
        if IsUndead() then
            if Blackacre.Print then
                Blackacre.Print("The dead do not eat as the living do. Cannibalize.")
            end
            return
        end
        s.hunger = 100
    elseif kind == "thirst" or kind == "drink" then
        s.thirst = 100
    elseif kind == "exposure" or kind == "rest" then
        s.exposure = Clamp(s.exposure + amount)
    elseif kind == "full" then
        if not IsUndead() then
            s.hunger = 100
        end
        s.thirst = 100
        s.exposure = Clamp(s.exposure + amount)
    end
    if Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
        Blackacre.Survival.UI.Refresh()
    end
end

function Blackacre.Survival.Engine.SetEnabled(on)
    EnsureDB().enabled = on and true or false
    EnsureDB().lastTick = time()
    if Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
        Blackacre.Survival.UI.Refresh()
    end
end

local function GetSpellNameSafe(spellID)
    if not spellID then return "" end
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID) or ""
    end
    if GetSpellInfo then
        return GetSpellInfo(spellID) or ""
    end
    return ""
end

local function IsCannibalize(name, spellID)
    if spellID and CANNIBALIZE_IDS[spellID] then return true end
    if name and name:lower():find("cannibalize", 1, true) then return true end
    return false
end

local function MaybeClimateToast()
    if skipClimateToast then return end
    local climate = CurrentClimate()
    local label = climate and climate.label or "temperate"
    if label == lastClimateLabel then return end
    lastClimateLabel = label
    local msg = Blackacre.ZoneClimate.EnterMessage(climate)
    if msg then
        Toast(msg)
    end
end

function Blackacre.Survival.Engine.Init()
    EnsureDB()
    EnsureDB().lastTick = time()
    skipClimateToast = true
    lastClimateLabel = CurrentClimate().label
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    -- One event after the bag settles, not BAG_UPDATE per slot.
    if not pcall(frame.RegisterEvent, frame, "BAG_UPDATE_DELAYED") then
        frame:RegisterEvent("BAG_UPDATE")
    end
    if frame.RegisterUnitEvent then
        frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    else
        frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "BAG_UPDATE_DELAYED" or event == "BAG_UPDATE" then
            provisionsKnown = false
            return
        end
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unitTarget, _, spellID = ...
            if unitTarget ~= "player" then return end
            local s = EnsureDB()
            if not s.enabled then return end
            local name = GetSpellNameSafe(spellID)
            if IsCannibalize(name, spellID) then
                s.hunger = 100
            elseif NameHasHint(name, FOOD_HINTS) then
                if not IsUndead() then
                    s.hunger = 100
                end
            elseif NameHasHint(name, DRINK_HINTS) then
                s.thirst = 100
            else
                return
            end
            if Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
                Blackacre.Survival.UI.Refresh()
            end
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            EnsureDB().lastTick = time()
            lastClimateLabel = CurrentClimate().label
            skipClimateToast = false
        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
            MaybeClimateToast()
        end
        if Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
            Blackacre.Survival.UI.Refresh()
        end
    end)

    C_Timer.NewTicker(TICK_SEC, function()
        Blackacre.Survival.Engine.Tick()
    end)
end
