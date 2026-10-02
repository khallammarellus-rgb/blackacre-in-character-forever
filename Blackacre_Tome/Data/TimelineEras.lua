-- In Character Forever: Journal - Timeline Eras

Blackacre = Blackacre or {}

Blackacre.TimelineEras = {
    { id = "ordering", startADP = -200000, endADP = -100000, name = "Ordering of Azeroth", blurb = "Titans, keepers, and the shaping of the world.", tags = { "primordial", "titan" }, ancientRelevant = true },
    { id = "dragon_age", startADP = -100000, endADP = -25000, name = "Age of Dragons", blurb = "Aspects rise; proto-dragons and early flights.", tags = { "primordial", "dragon" }, ancientRelevant = true },
    { id = "scaleborn", startADP = -25000, endADP = -20000, name = "War of the Scaleborn", blurb = "Primalists vs Aspects; dracthyr forged, then stasis.", tags = { "dragon", "dracthyr" }, ancientRelevant = true, foreverHide = true },
    { id = "troll_empires", startADP = -16000, endADP = -15000, name = "Troll empires", blurb = "Empire ages before the kaldorei ascendancy.", tags = { "ancient" }, ancientRelevant = true },
    { id = "well_of_eternity", startADP = -15000, endADP = -10050, name = "Well of Eternity", blurb = "Kaldorei rise on the Well's shores.", tags = { "elf", "ancient" }, ancientRelevant = true },
    { id = "war_of_ancients", startADP = -10020, endADP = -9990, name = "War of the Ancients", blurb = "Legion invades; Azshara falls to ruin.", tags = { "elf", "legion", "ancient_war" }, ancientRelevant = true },
    { id = "sundering", startADP = -10000, endADP = -9900, name = "The Sundering", blurb = "The world is broken; seas swallow Kalimdor.", tags = { "elf", "cataclysm" }, ancientRelevant = true },
    { id = "long_vigil", startADP = -9900, endADP = -3000, name = "Long Vigil", blurb = "Night elves keep the world tree and the quiet centuries.", tags = { "elf", "vigil" }, ancientRelevant = true },
    { id = "highborne_exile", startADP = -7300, endADP = -6800, name = "Highborne exile", blurb = "Quel'dorei path toward the east.", tags = { "elf" }, ancientRelevant = true },
    { id = "arathor", startADP = -2800, endADP = -2700, name = "Arathor & Troll Wars", blurb = "Human kingdoms take root in the east.", tags = { "human", "ancient" }, ancientRelevant = true },
    { id = "pre_portal", startADP = -100, endADP = -1, name = "Eve of the Portal", blurb = "Stormwind stands; Draenor darkens.", tags = { "prelude" }, ancientRelevant = false },
    { id = "first_war", startADP = 0, endADP = 3, name = "First War", blurb = "Dark Portal opens; Stormwind falls.", tags = { "war", "classic_war" }, ancientRelevant = false },
    { id = "second_war", startADP = 4, endADP = 6, name = "Second War", blurb = "Alliance of Lordaeron; Blackrock siege.", tags = { "war", "classic_war" }, ancientRelevant = false },
    { id = "internment", startADP = 7, endADP = 14, name = "Internment years", blurb = "Beyond the Dark Portal; orc camps; quiet wounds.", tags = { "aftermath" }, ancientRelevant = false },
    { id = "rising_darkness", startADP = 15, endADP = 19, name = "Tide of Darkness", blurb = "New Horde; Cult of the Damned; Alliance splinters.", tags = { "prelude_third" }, ancientRelevant = false },
    { id = "third_war", startADP = 20, endADP = 24, name = "Third War", blurb = "Scourge, Kalimdor, and the Frozen Throne's shadow.", tags = { "war", "scourge" }, ancientRelevant = false },
    { id = "vanilla", startADP = 25, endADP = 26, name = "Age of Adventure", blurb = "Classic adventuring across the old world.", tags = { "modern", "classic" }, ancientRelevant = false, foreverHide = true },
    { id = "bc", startADP = 26, endADP = 27, name = "Burning Crusade", blurb = "Outland and the reopened Portal.", tags = { "modern", "outland" }, ancientRelevant = false, foreverHide = true },
    { id = "wrath", startADP = 27, endADP = 28, name = "Wrath of the Lich King", blurb = "Northrend and the fall of the Lich King.", tags = { "modern", "scourge" }, ancientRelevant = false, foreverHide = true },
    { id = "cata", startADP = 28, endADP = 29, name = "Cataclysm", blurb = "The Shattering remakes the surface world.", tags = { "modern", "cataclysm" }, ancientRelevant = false, foreverHide = true },
    { id = "mop", startADP = 30, endADP = 31, name = "Mists of Pandaria", blurb = "Mists part; pandaren shores.", tags = { "modern" }, ancientRelevant = false, foreverHide = true },
    { id = "wod", startADP = 31, endADP = 32, name = "Warlords of Draenor", blurb = "Alternate Draenor and Iron Horde.", tags = { "modern" }, ancientRelevant = false, foreverHide = true },
    { id = "legion", startADP = 32, endADP = 34, name = "Legion", blurb = "Third invasion; Broken Isles; Argus.", tags = { "modern", "legion" }, ancientRelevant = false, foreverHide = true },
    { id = "bfa", startADP = 34, endADP = 36, name = "Battle for Azeroth", blurb = "Faction war and the wounds of Azeroth.", tags = { "modern" }, ancientRelevant = false, foreverHide = true },
    { id = "sl", startADP = 36, endADP = 37, name = "Shadowlands", blurb = "Death's realms open.", tags = { "modern", "death" }, ancientRelevant = false, foreverHide = true },
    { id = "df", startADP = 40, endADP = 41, name = "Dragonflight", blurb = "Isles awaken; dracthyr rise from stasis.", tags = { "modern", "dragon", "dracthyr" }, ancientRelevant = true, foreverHide = true },
    { id = "tww", startADP = 42, endADP = 50, name = "The War Within & after", blurb = "Deep places and the present campaign.", tags = { "modern", "earthen" }, ancientRelevant = true, foreverHide = true },
}

function Blackacre.MinAdultBirthADP()
    return Blackacre.YearCalendar.GetPresentADP() - 18
end

-- Birth eras a Forever character can come from. Built once: the Age of
-- Adventure is the present (too young to be born in), the Third War is too
-- recent for an adult at year 25, and later expansions haven't happened.
local birthEras
function Blackacre.ListEras()
    if birthEras then return birthEras end
    birthEras = {}
    for _, e in ipairs(Blackacre.TimelineEras) do
        if not e.foreverHide and e.id ~= "third_war" then
            birthEras[#birthEras + 1] = e
        end
    end
    return birthEras
end

function Blackacre.GetEraById(eraId)
    for _, e in ipairs(Blackacre.TimelineEras) do
        if e.id == eraId then return e end
    end
    return nil
end

--- The era a year falls in, across the whole timeline (the present year 25
--- is the Age of Adventure even though no one is born in it).
function Blackacre.GetEraAtYear(yearADP)
    yearADP = tonumber(yearADP)
    if yearADP == nil then return nil end
    local eras = Blackacre.TimelineEras
    for _, e in ipairs(eras) do
        if yearADP >= e.startADP and yearADP <= e.endADP then
            return e
        end
    end
    local best, bestDist
    for _, e in ipairs(eras) do
        local d = math.abs(yearADP - (e.startADP + e.endADP) / 2)
        if not bestDist or d < bestDist then
            best, bestDist = e, d
        end
    end
    return best
end
