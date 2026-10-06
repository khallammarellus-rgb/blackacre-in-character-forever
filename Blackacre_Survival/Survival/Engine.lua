-- In Character Forever: Survival - Meter Engine

Blackacre = Blackacre or {}
Blackacre.Survival = Blackacre.Survival or {}
Blackacre.Survival.Engine = {}
Blackacre.Survival.Engine.BUILD = "2026-09-20-stacks"

local time, tostring, tonumber, format = time, tostring, tonumber, string.format
local UnitRace, CreateFrame = UnitRace, CreateFrame
local C_Timer = C_Timer
-- Forever has the C_ namespaced versions (APIDocumentationGenerated), so the
-- bag scan binds them once instead of re-checking per slot.
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemID = C_Container.GetContainerItemID
local GetContainerItemLink = C_Container.GetContainerItemLink
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local GetItemSpell = C_Item.GetItemSpell
local IsItemDataCachedByID = C_Item.IsItemDataCachedByID
local RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID
local GetSpellName = C_Spell.GetSpellName

local TICK_SEC = 15
local DEBUFF_AT = 10
local MAX_CATCHUP_SEC = 300

-- Exposure depends on where you are (owner rules):
--   rested area (an inn, a city): exposure recovers
--   by a campfire: recovers, a little slower
--   indoors: exposure holds steady
--   in water: exposure drains twice as fast
local REST_RECOVER_PER_MIN = 5
local CAMPFIRE_RECOVER_PER_MIN = 3
local WATER_EXPOSURE_MULT = 2
-- Forever has no campfire API. The vanilla Basic Campfire puts a "Cozy Fire"
-- aura on everyone standing near it. That name isn't in Forever's UI files,
-- so it's matched by name here and still needs confirming in-game.
local CAMPFIRE_AURAS = { "Cozy Fire" }
local exposureMode = "open" -- how exposure behaves until the next tick

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

-- Whole words only, compiled once. Plain substrings matched "tea" inside
-- Steak and "ale" inside Scale, so gear and steaks counted as water.
local function Words(hints)
    for i = 1, #hints do
        hints[i] = "%f[%a]" .. hints[i] .. "%f[%A]"
    end
    return hints
end
-- Used only to tell water from food for a Food & Drink item whose Use spell
-- isn't recognised (see ProvisionKindAt).
local DRINK_HINTS = Words({
    "drink", "refreshment", "tea", "coffee", "juice", "water", "wine", "ale",
    "mead", "milk", "waterskin",
})
-- What eating and drinking are called, as whole spell names. Exact names, not
-- words inside names: Conjure Water, Water Walking, Stealth and Fishing must not
-- refill anything. The value is which meter(s) the spell restores.
local EAT_SPELLS = {
    ["food"] = "food",
    ["drink"] = "drink",
    ["refreshment"] = "both",
    ["food & drink"] = "both",
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
    local _, raceFile = UnitRace("player")
    undeadValue = raceFile == "Scourge"
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
    local zone = Blackacre.GetZoneSnapshot()
    return Blackacre.ZoneClimate.GetProfile(zone.zoneId, zone.zoneName, zone.subzone)
end

local function NameHasHint(name, hints)
    if not name or name == "" then return false end
    local lower = name:lower()
    for i = 1, #hints do
        if lower:find(hints[i]) then
            return true
        end
    end
    return false
end

-- GetItemInfoInstant only. GetItemInfo queries the server when the item is cold and hitches the client.
local function ItemClass(itemID)
    if not itemID then return nil, nil, nil end
    local _, itemType, itemSubType, _, _, classID, subclassID = GetItemInfoInstant(itemID)
    return classID, subclassID, itemSubType or itemType
end

local function BagMax()
    if NUM_TOTAL_EQUIPPED_BAG_SLOTS then return NUM_TOTAL_EQUIPPED_BAG_SLOTS end
    if NUM_BAG_SLOTS then return NUM_BAG_SLOTS end
    return 4
end

local function GetSpellNameSafe(spellID)
    if not spellID then return "" end
    return GetSpellName(spellID) or ""
end

local function IsCannibalize(name, spellID)
    if spellID and CANNIBALIZE_IDS[spellID] then return true end
    if name and name:lower():find("cannibalize", 1, true) then return true end
    return false
end

-- What a spell does to the meters never changes, so classify each spell id
-- once: "food", "drink", "both", "cannibalize" or "none". Every cast in combat
-- lands here; most are "none".
local spellKind = {}
local function SpellKind(spellID)
    local kind = spellID and spellKind[spellID]
    if kind then return kind end
    local name = GetSpellNameSafe(spellID)
    if IsCannibalize(name, spellID) then
        kind = "cannibalize"
    else
        kind = EAT_SPELLS[name:lower()] or "none"
    end
    if spellID then spellKind[spellID] = kind end
    return kind
end

-- Food & Drink is the game's own item type (subclass 5 on Retail/Forever).
local function IsFoodDrink(itemID)
    local classID, subclassID, itemSubType = ItemClass(itemID)
    if classID == 0 and subclassID == 5 then return true end
    local sub = itemSubType and tostring(itemSubType):lower()
    return sub ~= nil and (sub:find("food", 1, true) or sub:find("drink", 1, true)) ~= nil
end

-- Supplies are decided by what using the item does. If its Use spell is an
-- eating or drinking spell it counts: "food", "water" or "both". That is the
-- same test the cast handler applies, so an item is supplies exactly when using
-- it would restore a meter, whatever it is called. An item the game files under
-- Food & Drink still counts when its Use spell isn't recognised (water if the
-- name says so, else food). Names alone never count: gear with "ale" in its name
-- was water. Each item id is classified once, so the rescan allocates nothing.
local provisionKind = {}   -- item id -> "food", "water", "both" or false
local provisionWhy = {}    -- item id -> reason text, for /ba survival scan
local loadState = {}       -- item id -> 1 asked the game for its data, 2 answered
local engineFrame

local USE_KIND = { food = "food", drink = "water", both = "both" }

local function ProvisionKindAt(itemID, bag, slot)
    local kind = provisionKind[itemID]
    if kind ~= nil then return kind end

    local useName, useID = GetItemSpell(itemID)
    local why
    kind = useID and USE_KIND[SpellKind(useID)]
    if kind then
        why = "Use: " .. useName
    elseif IsFoodDrink(itemID) then
        local link = GetContainerItemLink(bag, slot)
        if not link then return "food" end -- link not ready; don't remember a guess
        local name = link:match("%[(.-)%]") or ""
        kind = NameHasHint(name, DRINK_HINTS) and "water" or "food"
        why = "item type; Use: " .. (useName or "none")
    end
    kind = kind or false

    -- An item the game hasn't loaded yet may not report its Use spell. Use what
    -- we have for now, ask the game for it, and look again when it answers.
    if IsItemDataCachedByID(itemID) or loadState[itemID] == 2 then
        provisionKind[itemID], provisionWhy[itemID] = kind, why
    elseif not loadState[itemID] then
        loadState[itemID] = 1
        if engineFrame then engineFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT") end
        RequestLoadItemDataByID(itemID)
    end
    return kind
end

local function RescanProvisions()
    hasFood, hasWater = false, false
    for bag = 0, BagMax() do
        local slots = GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemID = GetContainerItemID(bag, slot)
            if itemID then
                local kind = ProvisionKindAt(itemID, bag, slot)
                if kind then
                    if kind ~= "water" then hasFood = true end
                    if kind ~= "food" then hasWater = true end
                end
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

function Blackacre.Survival.GetState()
    local s = EnsureDB()
    local zone = Blackacre.GetZoneSnapshot()
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

local function NearCampfire()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then return false end
    -- Aura data can be withheld from add-ons in combat; nobody rests by a fire mid-fight.
    if UnitAffectingCombat("player") then return false end
    for i = 1, #CAMPFIRE_AURAS do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", CAMPFIRE_AURAS[i], "HELPFUL")
        if ok and aura then return true end
    end
    return false
end

local function ReadExposureMode()
    if IsResting() then return "rested" end
    if NearCampfire() then return "campfire" end
    if IsIndoors() then return "sheltered" end
    if IsSwimming() then return "wet" end
    return "open"
end

--- "rested", "campfire", "sheltered", "wet" or "open" (for the meter tooltip).
function Blackacre.Survival.Engine.ExposureMode()
    return exposureMode
end

local function FireCrossing(meter, prev, now)
    if prev > DEBUFF_AT and now <= DEBUFF_AT then
        Toast(DEBUFF_TOAST[meter])
    end
    if prev > 0 and now <= 0 then
        Toast(ZERO_TOAST[meter])
    end
end

-- Also called the moment you enter or leave a rested area or a building, so
-- the time before the change is charged at the old rate, not the new one.
function Blackacre.Survival.Engine.Tick()
    local s = EnsureDB()
    -- The interval that just ended ran under the mode read at its start.
    local mode = exposureMode
    exposureMode = ReadExposureMode()
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
    local boons = Blackacre.Boons
    if boons then
        hungerLoss = hungerLoss * boons.Mult("survival.hunger.drain")
        thirstLoss = thirstLoss * boons.Mult("survival.thirst.drain")
        exposureLoss = exposureLoss * boons.Mult("survival.exposure.drain")
    end
    if hasFood then hungerLoss = 0 end
    if hasWater then thirstLoss = 0 end
    if mode == "rested" then
        exposureLoss = -REST_RECOVER_PER_MIN * minutes
    elseif mode == "campfire" then
        exposureLoss = -CAMPFIRE_RECOVER_PER_MIN * minutes
    elseif mode == "sheltered" then
        exposureLoss = 0
    elseif mode == "wet" then
        exposureLoss = exposureLoss * WATER_EXPOSURE_MULT
    end

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

--- /ba survival scan: what the add-on sees in the bags and why, so what counts
--- as food or drink can be checked by eye. Shows each item's real Use spell.
function Blackacre.Survival.Engine.PrintProvisions()
    local seen, count = {}, 0
    for bag = 0, BagMax() do
        for slot = 1, (GetContainerNumSlots(bag) or 0) do
            local itemID = GetContainerItemID(bag, slot)
            if itemID and not seen[itemID] then
                seen[itemID] = true
                local kind = ProvisionKindAt(itemID, bag, slot)
                if kind then
                    count = count + 1
                    Blackacre.Print(format("%s: %s (%s)",
                        GetContainerItemLink(bag, slot) or itemID, kind, provisionWhy[itemID] or "loading"))
                end
            end
        end
    end
    if count == 0 then Blackacre.Print("No food or drink found in your bags.") end
    provisionsKnown = false
    local food, water = Blackacre.Survival.Engine.ScanProvisions()
    Blackacre.Print(format("Food on hand: %s. Drink on hand: %s.", food and "yes" or "no", water and "yes" or "no"))
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
    engineFrame = frame
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    frame:RegisterEvent("PLAYER_UPDATE_RESTING")
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
        if event == "ITEM_DATA_LOAD_RESULT" then
            -- Other add-ons ask for items too; only react to the ones we asked for.
            local itemID = ...
            if loadState[itemID] == 1 then
                loadState[itemID] = 2
                provisionsKnown = false
            end
            return
        end
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unitTarget, _, spellID = ...
            if unitTarget ~= "player" then return end
            local kind = SpellKind(spellID)
            if kind == "none" then return end
            local s = EnsureDB()
            if not s.enabled then return end
            if kind == "cannibalize" then
                s.hunger = 100
            else
                -- "food", "drink" or "both"
                if kind ~= "drink" and not IsUndead() then s.hunger = 100 end
                if kind ~= "food" then s.thirst = 100 end
            end
            if Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
                Blackacre.Survival.UI.Refresh()
            end
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            EnsureDB().lastTick = time()
            exposureMode = ReadExposureMode()
            lastClimateLabel = CurrentClimate().label
            skipClimateToast = false
        elseif event == "PLAYER_UPDATE_RESTING" or event == "ZONE_CHANGED_INDOORS" then
            -- Rested or indoors just changed: settle the time so far, then
            -- the new rate starts now. Tick refreshes the meters itself.
            Blackacre.Survival.Engine.Tick()
            return
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
