-- In Character Forever: Survival - Meter Engine

Blackacre = Blackacre or {}
Blackacre.Survival = Blackacre.Survival or {}
Blackacre.Survival.Engine = {}
Blackacre.Survival.Engine.BUILD = "2026-09-20-stacks"

local time, tostring, tonumber, format = time, tostring, tonumber, string.format
local UnitRace, CreateFrame = UnitRace, CreateFrame
local UnitIsDeadOrGhost, UnitIsFeignDeath = UnitIsDeadOrGhost, UnitIsFeignDeath
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
local GetItemInfo = C_Item.GetItemInfo
local GetSpellDescription = C_Spell.GetSpellDescription
local RequestLoadSpellData = C_Spell.RequestLoadSpellData
local GetTime, UnitLevel = GetTime, UnitLevel

local TICK_SEC = 15
local DEBUFF_AT = 10
local MAX_CATCHUP_SEC = 300

-- Exposure depends on where you are (owner rules), first match wins:
--   at a camp ("Campfire Nearby"): recovers 1 a second
--   by a fire ("Cozy Fire"): recovers 1 every 5 seconds
--   rested area (an inn, a city): recovers
--   indoors: holds steady
--   in water: drains twice as fast
local CAMP_RECOVER_PER_MIN = 60
local COZY_RECOVER_PER_MIN = 12
local REST_RECOVER_PER_MIN = 5
local WATER_EXPOSURE_MULT = 2
-- Forever's Camps have no add-on API (PLAYER_CAMPING is the logout timer), so
-- a fire is found by the buff it puts on you, matched by name. Neither name is
-- in Forever's UI files; the owner read both in-game.
local CAMP_AURA = "Campfire Nearby"
local COZY_AURA = "Cozy Fire"
-- By a fire the meter climbs every second or five, so it's checked that
-- often while you stay; everywhere else every TICK_SEC is plenty.
local TICK_FOR_MODE = { camp = 1, cozy = 5 }
local exposureMode = "open" -- how exposure behaves until the next tick

-- Provisions slow the drain by the best tier in your bags that you're old
-- enough to eat: food slows hunger, water slows thirst. Forever's food heals
-- on a fixed ladder (59/234/531/841/1338/2065, then 2452 for the rare top
-- tier) and water restores 145/420/803/1293/1915/2821, then 4038. Owner's
-- rates: 10% for tier 1, +5% a tier, and the rare tier 7 jumps to 70%.
local TIER_SLOW = { 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.70 }
-- Least amount for tiers 2..7: halfway between ladder steps.
local HEALTH_STEPS = { 150, 400, 700, 1100, 1700, 2300 }
local MANA_STEPS = { 280, 600, 1050, 1600, 2400, 3400 }
local HEALTH_PAT, MANA_PAT = "([%d,]+) health", "([%d,]+) mana"
-- Vendor and mage food share one Use spell per tier: the fallback when the
-- spell's text isn't loaded yet or the client isn't in English.
local FOOD_SPELL_TIER = { [433] = 1, [434] = 2, [435] = 3, [1127] = 4, [1129] = 5, [1131] = 6, [25660] = 7 }
local DRINK_SPELL_TIER = { [430] = 1, [431] = 2, [432] = 3, [1133] = 4, [1135] = 5, [1137] = 6, [22734] = 7 }
-- Hunger holds still for as long as this buff lasts.
local WELL_FED_AURA = "Well Fed"
local wellFed = false
-- Thirst climbs 1 a second while you drink; drinking to the end fills it.
local DRINK_RECOVER_PER_MIN = 60
local drinking          -- the drink's aura name while you sit and drink, else nil
local drinkSeen, drinkEnds, drinkStarted = false, 0, 0

local lastClimateLabel = nil
local skipClimateToast = true
local undeadKnown, undeadValue
local hasFood, hasWater = false, false
local foodTier, waterTier = 0, 0 -- best usable tier on hand, 0 = none
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
local RETURN_TOAST = "You return to your body hungry and parched"

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
-- Forever's cooked (Well Fed) foods all use "Nutritious Food", not "Food",
-- and the Enriched Manna Biscuit uses its own name (Wowhead's Forever data, 2026-10-11).
local EAT_SPELLS = {
    ["food"] = "food",
    ["nutritious food"] = "food",
    ["drink"] = "drink",
    ["refreshment"] = "both",
    ["food & drink"] = "both",
    ["enriched manna biscuit"] = "both",
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

local function StepTier(amount, steps)
    local tier = 1
    for i = 1, #steps do
        if amount >= steps[i] then tier = i + 1 end
    end
    return tier
end

local function Amount(text, pattern)
    local n = text:match(pattern)
    return n and tonumber((n:gsub(",", "")))
end

-- An item's tier (1-7) as food and as water, read from the number its Use
-- spell restores ("Restores 841 health over 27 sec."), plus the level needed
-- to eat it. Learned once per item id, as soon as the item and the spell's
-- text are both loaded; until then a best guess is used.
local foodTierOf, waterTierOf, minLevelOf = {}, {}, {}
local tiersKnown = {}
local spellWait = {} -- spell id -> true while we wait for its text

local function LearnTiers(itemID, kind)
    if tiersKnown[itemID] then return end
    local _, useID = GetItemSpell(itemID)
    local text = useID and GetSpellDescription(useID) or ""
    if useID and text == "" and not spellWait[useID] then
        spellWait[useID] = true
        if engineFrame then engineFrame:RegisterEvent("SPELL_TEXT_UPDATE") end
        RequestLoadSpellData(useID)
    end
    if kind ~= "water" then
        local health = Amount(text, HEALTH_PAT)
        foodTierOf[itemID] = health and StepTier(health, HEALTH_STEPS) or FOOD_SPELL_TIER[useID] or 1
    end
    if kind ~= "food" then
        local mana = Amount(text, MANA_PAT)
        waterTierOf[itemID] = mana and StepTier(mana, MANA_STEPS) or DRINK_SPELL_TIER[useID] or 1
    end
    if IsItemDataCachedByID(itemID) then
        local _, _, _, _, minLevel = GetItemInfo(itemID)
        minLevelOf[itemID] = minLevel or 0
        if text ~= "" or not useID then tiersKnown[itemID] = true end
    end
end

-- Every slot is read (not stopping at the first food and water) to find the
-- best tier. Runs only after the bags change, never on the tick.
local function RescanProvisions()
    hasFood, hasWater = false, false
    foodTier, waterTier = 0, 0
    local level = UnitLevel("player") or 1
    for bag = 0, BagMax() do
        local slots = GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemID = GetContainerItemID(bag, slot)
            if itemID then
                local kind = ProvisionKindAt(itemID, bag, slot)
                if kind then
                    LearnTiers(itemID, kind)
                    -- Food you aren't old enough to eat doesn't help.
                    if (minLevelOf[itemID] or 0) <= level then
                        if kind ~= "water" then
                            hasFood = true
                            local t = foodTierOf[itemID] or 1
                            if t > foodTier then foodTier = t end
                        end
                        if kind ~= "food" then
                            hasWater = true
                            local t = waterTierOf[itemID] or 1
                            if t > waterTier then waterTier = t end
                        end
                    end
                end
            end
        end
    end
    provisionsKnown = true
end

--- hasFood, hasWater, foodTier, waterTier (tiers 1-7, 0 = none on hand).
function Blackacre.Survival.Engine.ScanProvisions()
    if not provisionsKnown then
        RescanProvisions()
    end
    return hasFood, hasWater, foodTier, waterTier
end

--- How much slower a tier makes the drain, as a whole percent (0 for none).
function Blackacre.Survival.Engine.TierSlowPct(tier)
    local slow = TIER_SLOW[tier]
    return slow and math.floor(slow * 100 + 0.5) or 0
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
        spiritForm = s.spiritForm == true,
        foodTier = foodTier,
        waterTier = waterTier,
        wellFed = wellFed,
        drinking = drinking ~= nil,
    }
end

local function HasBuff(name)
    local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", name, "HELPFUL")
    return ok and aura ~= nil
end

-- "camp", "cozy" or nil.
local function FireNearby()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then return nil end
    -- Aura data can be withheld from add-ons in combat; nobody rests by a fire mid-fight.
    if UnitAffectingCombat("player") then return nil end
    if HasBuff(CAMP_AURA) then return "camp" end
    if HasBuff(COZY_AURA) then return "cozy" end
    return nil
end

local function ReadExposureMode()
    local fire = FireNearby()
    if fire then return fire end
    if IsResting() then return "rested" end
    if IsIndoors() then return "sheltered" end
    if IsSwimming() then return "wet" end
    return "open"
end

-- Buff data can be withheld from add-ons in combat: keep what we last knew.
local function ReadWellFed()
    if UnitAffectingCombat("player") or not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then
        return wellFed
    end
    return HasBuff(WELL_FED_AURA)
end

-- Seconds between ticks: every second while drinking or at a camp, every
-- five by a cozy fire, otherwise TICK_SEC.
local function Pace()
    if drinking then return 1 end
    return TICK_FOR_MODE[exposureMode] or TICK_SEC
end

local ticker, tickEvery
local CheckDrink -- defined below Tick
local function OnTicker()
    CheckDrink()
    Blackacre.Survival.Engine.Tick()
end

-- The ticker is only rebuilt when the pace changes (a fire, or a drink).
local function SetTickRate(sec)
    if sec == tickEvery then return end
    if ticker then ticker:Cancel() end
    tickEvery = sec
    ticker = C_Timer.NewTicker(sec, OnTicker)
end

--- "camp", "cozy", "rested", "sheltered", "wet" or "open" (for the meter tooltip).
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

-- Also called the moment you enter or leave a rested area, a building or a
-- fire, so the time before the change is charged at the old rate, not the new one.
function Blackacre.Survival.Engine.Tick()
    local s = EnsureDB()
    -- The interval that just ended ran under the mode read at its start.
    local mode, fed, sipping = exposureMode, wellFed, drinking
    exposureMode = ReadExposureMode()
    wellFed = ReadWellFed()
    SetTickRate(Pace())
    if not s.enabled or s.spiritForm then
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
    Blackacre.Survival.Engine.ScanProvisions() -- brings foodTier / waterTier up to date

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
    if foodTier > 0 then hungerLoss = hungerLoss * (1 - TIER_SLOW[foodTier]) end
    if waterTier > 0 then thirstLoss = thirstLoss * (1 - TIER_SLOW[waterTier]) end
    if fed then hungerLoss = 0 end
    if sipping then thirstLoss = -DRINK_RECOVER_PER_MIN * minutes end
    if mode == "camp" then
        exposureLoss = -CAMP_RECOVER_PER_MIN * minutes
    elseif mode == "cozy" then
        exposureLoss = -COZY_RECOVER_PER_MIN * minutes
    elseif mode == "rested" then
        exposureLoss = -REST_RECOVER_PER_MIN * minutes
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

-- Standing up early keeps the sips taken; drinking until the drink's own
-- timer runs out fills thirst.
local function StopDrinking()
    Blackacre.Survival.Engine.Tick() -- settle the sips so far
    local finished = drinkSeen and drinkEnds > 0 and GetTime() >= drinkEnds - 0.5
    drinking = nil
    local s = EnsureDB()
    if finished and s.enabled and not s.spiritForm then s.thirst = 100 end
    SetTickRate(Pace())
    if Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
        Blackacre.Survival.UI.Refresh()
    end
end

-- While drinking: note when the drink will end, and stop once its buff is
-- gone. A drink whose buff never shows within 3 seconds stops too.
CheckDrink = function()
    if not drinking then return end
    local getAura = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
    local ok, aura = false, nil
    if getAura then ok, aura = pcall(getAura, "player", drinking, "HELPFUL") end
    if ok and aura then
        drinkSeen = true
        drinkEnds = aura.expirationTime or 0
    elseif drinkSeen or GetTime() - drinkStarted > 3 then
        StopDrinking()
    end
end

-- The drink's buff carries the Use spell's name ("Drink", "Refreshment").
local function StartDrinking(spellID)
    Blackacre.Survival.Engine.Tick() -- settle thirst so far at the old rate
    drinking = GetSpellNameSafe(spellID)
    drinkSeen, drinkEnds, drinkStarted = false, 0, GetTime()
    SetTickRate(Pace())
end

--- True while the Well Fed buff holds hunger still.
function Blackacre.Survival.Engine.IsWellFed()
    return wellFed
end

--- True while you sit and drink.
function Blackacre.Survival.Engine.IsDrinking()
    return drinking ~= nil
end

local function IsSpirit()
    if not UnitIsDeadOrGhost("player") then return false end
    -- A hunter playing dead is still alive.
    return not (UnitIsFeignDeath and UnitIsFeignDeath("player"))
end

-- Dead or a ghost: a spirit doesn't hunger, thirst or feel the weather, so
-- every meter stops. Back in your body you wake starved and parched, and
-- exposure carries on from where it stopped. The flag is saved, so a
-- resurrection during a loading screen or a /reload is still caught.
local function UpdateSpiritForm()
    local s = EnsureDB()
    local spirit = IsSpirit()
    if spirit == (s.spiritForm == true) then return end
    if spirit then
        -- Charge the time before death at the living rate, then stop.
        Blackacre.Survival.Engine.Tick()
        s.spiritForm = true
    else
        s.spiritForm = nil
        s.lastTick = time() -- the time spent dead costs nothing
        if s.enabled then
            s.hunger, s.thirst = 0, 0
            Toast(RETURN_TOAST)
        end
    end
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
                    LearnTiers(itemID, kind)
                    Blackacre.Print(format("%s: %s (%s), tier %s, needs level %s",
                        GetContainerItemLink(bag, slot) or itemID, kind, provisionWhy[itemID] or "loading",
                        tostring(kind == "water" and waterTierOf[itemID] or foodTierOf[itemID] or "?"),
                        tostring(minLevelOf[itemID] or "?")))
                end
            end
        end
    end
    if count == 0 then Blackacre.Print("No food or drink found in your bags.") end
    provisionsKnown = false
    local food, water, fTier, wTier = Blackacre.Survival.Engine.ScanProvisions()
    local pct = Blackacre.Survival.Engine.TierSlowPct
    Blackacre.Print(format("Food on hand: %s (hunger %d%% slower). Drink on hand: %s (thirst %d%% slower).",
        food and "yes" or "no", pct(fTier), water and "yes" or "no", pct(wTier)))
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
    -- Dying, releasing (ALIVE also fires on a res taken at the corpse) and the
    -- ghost's return. Each one re-reads the player, so order doesn't matter.
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_ALIVE")
    frame:RegisterEvent("PLAYER_UNGHOST")
    -- A new level can make food in the bags old enough to eat.
    frame:RegisterEvent("PLAYER_LEVEL_UP")
    -- One event after the bag settles, not BAG_UPDATE per slot.
    if not pcall(frame.RegisterEvent, frame, "BAG_UPDATE_DELAYED") then
        frame:RegisterEvent("BAG_UPDATE")
    end
    if frame.RegisterUnitEvent then
        frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        frame:RegisterUnitEvent("UNIT_AURA", "player")
    else
        frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        frame:RegisterEvent("UNIT_AURA")
    end
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "UNIT_AURA" then
            -- Only fires, Well Fed and a drink matter here. In combat the
            -- fire and Well Fed reads are a single check each, so a fight's
            -- stream of aura changes costs next to nothing.
            if ... ~= "player" then return end
            CheckDrink()
            local fire = FireNearby()
            local was = TICK_FOR_MODE[exposureMode] and exposureMode or nil
            if fire ~= was or ReadWellFed() ~= wellFed then
                -- Something changed: settle the time so far, then the new rate starts now.
                Blackacre.Survival.Engine.Tick()
            end
            return
        end
        if event == "BAG_UPDATE_DELAYED" or event == "BAG_UPDATE" or event == "PLAYER_LEVEL_UP" then
            provisionsKnown = false
            return
        end
        if event == "SPELL_TEXT_UPDATE" then
            -- Only the food spells we asked about; their tier can now be read.
            local spellID = ...
            if spellWait[spellID] then
                spellWait[spellID] = nil
                provisionsKnown = false
            end
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
                -- "food", "drink" or "both". Eating fills hunger at once;
                -- drinking fills thirst a sip at a time (see StartDrinking).
                if kind ~= "food" then StartDrinking(spellID) end
                if kind ~= "drink" and not IsUndead() then s.hunger = 100 end
            end
            if Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
                Blackacre.Survival.UI.Refresh()
            end
            return
        end
        if event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
            UpdateSpiritForm()
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            EnsureDB().lastTick = time()
            exposureMode = ReadExposureMode()
            wellFed = ReadWellFed()
            SetTickRate(Pace())
            lastClimateLabel = CurrentClimate().label
            skipClimateToast = false
            UpdateSpiritForm()
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

    SetTickRate(TICK_SEC)
end
