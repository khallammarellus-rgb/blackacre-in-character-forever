-- In Character Forever: Journal - Age Bands

Blackacre = Blackacre or {}

Blackacre.LongevityProfiles = {
    mortal = {
        label = "Mortal span",
        bands = {
            { id = "child", maxAge = 12, text = "still a child of the hearth" },
            { id = "youth", maxAge = 17, text = "youth on the edge of the road" },
            { id = "young_adult", maxAge = 25, text = "young adult, newly blooded by the world" },
            { id = "adult", maxAge = 40, text = "in the prime of mortal years" },
            { id = "veteran", maxAge = 60, text = "veteran of hard seasons" },
            { id = "elder", maxAge = 99999, text = "elder among short-lived peoples" },
        },
    },
    long_lived = {
        label = "Long-lived",
        bands = {
            { id = "child", maxAge = 40, text = "still young by their people's reckoning" },
            { id = "youth", maxAge = 80, text = "coming into long adulthood" },
            { id = "young_adult", maxAge = 200, text = "a younger adult of centuries" },
            { id = "adult", maxAge = 500, text = "settled into long adulthood" },
            { id = "veteran", maxAge = 1000, text = "aged in the long count" },
            { id = "elder", maxAge = 999999, text = "ancient among the long-lived" },
        },
    },
    elf = {
        label = "Elven span",
        bands = {
            { id = "child", maxAge = 100, text = "a child by elven count" },
            { id = "youth", maxAge = 300, text = "youth among the stars' children" },
            { id = "young_adult", maxAge = 1000, text = "young by millennia, adult by deed" },
            { id = "adult", maxAge = 5000, text = "in the long adulthood of the elves" },
            { id = "veteran", maxAge = 10000, text = "veteran of ages; witness of ruin and vigil" },
            { id = "elder", maxAge = 999999, text = "elder of the Long Vigil and older nights" },
        },
    },
    undead = {
        label = "Undead span",
        bands = {
            { id = "child", maxAge = 12, text = "a brief living childhood, if any" },
            { id = "youth", maxAge = 17, text = "cut short or twisted young" },
            { id = "young_adult", maxAge = 30, text = "death found them early in life" },
            { id = "adult", maxAge = 60, text = "a full mortal life before the grave" },
            { id = "veteran", maxAge = 200, text = "long in undeath" },
            { id = "elder", maxAge = 99999, text = "ancient among the restless" },
        },
    },
}

-- WoW Forever's playable races (UnitRace file tokens).
Blackacre.RaceLongevityMap = {
    Human = "mortal",
    Dwarf = "mortal",
    Gnome = "mortal",
    NightElf = "elf",
    Orc = "mortal",
    Troll = "mortal",
    Tauren = "mortal",
    Scourge = "undead",
    Skyborne = "mortal",
}

function Blackacre.DetectLongevityProfile()
    local _, raceFile = UnitRace("player")
    return raceFile and Blackacre.RaceLongevityMap[raceFile] or "mortal"
end

function Blackacre.GetLongevityProfileId()
    local id = Blackacre.YearCalendar.EnsureIdentity()
    if id.longevityProfile and id.longevityProfile ~= "auto" and Blackacre.LongevityProfiles[id.longevityProfile] then
        return id.longevityProfile
    end
    return Blackacre.DetectLongevityProfile()
end

function Blackacre.GetLongevityProfile()
    local pid = Blackacre.GetLongevityProfileId()
    return Blackacre.LongevityProfiles[pid] or Blackacre.LongevityProfiles.mortal, pid
end

function Blackacre.GetAgeBand(ageYears)
    ageYears = tonumber(ageYears) or 0
    if ageYears < 0 then ageYears = 0 end
    local profile = Blackacre.GetLongevityProfile()
    for _, band in ipairs(profile.bands) do
        if ageYears <= band.maxAge then
            return band, profile
        end
    end
    return profile.bands[#profile.bands], profile
end
