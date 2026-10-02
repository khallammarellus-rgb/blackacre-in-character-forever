-- In Character Forever: Journal - Page Prompts

Blackacre = Blackacre or {}
Blackacre.Chronicle = Blackacre.Chronicle or {}
Blackacre.Chronicle.Prompt = {}

local lastGiver = {
    name = nil,
    sex = 2,
}

local function UnitForGiver()
    if UnitExists and UnitExists("npc") then
        return "npc"
    end
    if UnitExists and UnitExists("questnpc") then
        return "questnpc"
    end
    if UnitExists and UnitExists("target") and UnitCanCooperate and not UnitCanAttack("player", "target") then
        return "target"
    end
    return nil
end

function Blackacre.Chronicle.Prompt.CaptureGiver()
    local unit = UnitForGiver()
    if not unit then
        return lastGiver
    end
    local name = UnitName(unit)
    if name and name ~= "" then
        lastGiver.name = name
        lastGiver.sex = (UnitSex and UnitSex(unit)) or 2
    end
    return lastGiver
end

local function WeatherKind()
    local info
    if C_Weather and C_Weather.GetCurrentWeather then
        local ok, result = pcall(C_Weather.GetCurrentWeather)
        if ok then
            info = result
        end
    end
    if type(info) ~= "table" then
        return "clear", 0
    end
    local t = info.type
    local intensity = tonumber(info.intensity) or 0
    local E = Enum and Enum.WeatherType
    if E then
        if t == E.Rain then
            return "rain", intensity
        end
        if t == E.Snow then
            return "snow", intensity
        end
        if t == E.Sandstorm then
            return "sand", intensity
        end
        return "clear", intensity
    end
    if t == 1 then
        return "rain", intensity
    end
    if t == 2 then
        return "snow", intensity
    end
    if t == 3 then
        return "sand", intensity
    end
    return "clear", intensity
end

local function TimePhrase(hour)
    hour = tonumber(hour) or 12
    if hour >= 0 and hour < 5 then
        return "late in the night", "before the sun rose"
    end
    if hour >= 5 and hour < 7 then
        return "early in the morning", "before the sun rose"
    end
    if hour >= 7 and hour < 11 then
        return "in the morning", nil
    end
    if hour >= 11 and hour < 14 then
        return "at midday", nil
    end
    if hour >= 14 and hour < 17 then
        return "in the afternoon", nil
    end
    if hour >= 17 and hour < 20 then
        return "in the evening", nil
    end
    return "after nightfall", nil
end

local function WeatherClause(kind, intensity)
    intensity = intensity or 0
    if kind == "snow" then
        if intensity >= 0.7 then
            return "a blizzard tore through"
        end
        if intensity >= 0.35 then
            return "a sleet of snow swept through"
        end
        return "snow drifted on the wind"
    end
    if kind == "rain" then
        if intensity >= 0.7 then
            return "a hard rain fell"
        end
        return "rain fell"
    end
    if kind == "sand" then
        return "sand tore across the ground"
    end
    return nil
end

local function PlaceName(snapshot)
    local sub = snapshot.subzone or ""
    local zone = snapshot.zone or ""
    if sub ~= "" and zone ~= "" and sub ~= zone then
        return sub, zone
    end
    if sub ~= "" then
        return sub, nil
    end
    if zone ~= "" then
        return zone, nil
    end
    return "these lands", nil
end

local function Pronouns(sex)
    if sex == 3 then
        return "she", "her", "her"
    end
    if sex == 2 then
        return "he", "him", "his"
    end
    return "they", "them", "their"
end

function Blackacre.Chronicle.Prompt.Snapshot()
    Blackacre.Chronicle.Prompt.CaptureGiver()
    local hour, minute = 12, 0
    if GetGameTime then
        hour, minute = GetGameTime()
    end
    local zone = (GetZoneText and GetZoneText()) or ""
    local subzone = (GetSubZoneText and GetSubZoneText()) or (GetMinimapZoneText and GetMinimapZoneText()) or ""
    local wKind, wInt = WeatherKind()
    return {
        hour = hour or 12,
        minute = minute or 0,
        zone = zone,
        subzone = subzone,
        weather = wKind,
        intensity = wInt,
        giverName = lastGiver.name,
        giverSex = lastGiver.sex,
    }
end

local function OpeningLine(snapshot)
    local place, parent = PlaceName(snapshot)
    local when, beforeSun = TimePhrase(snapshot.hour)
    local weather = WeatherClause(snapshot.weather, snapshot.intensity)
    local where = place
    if parent then
        where = place .. ", " .. parent
    end
    if beforeSun then
        local line = "It was " .. when .. " " .. beforeSun .. " in " .. where
        if weather then
            line = line .. " and " .. weather
        end
        return line .. "."
    end
    local line = "It was " .. when .. " in " .. where
    if weather then
        line = line .. " and " .. weather
    end
    return line .. "."
end

local function NpcLines(snapshot)
    local name = snapshot.giverName
    if not name or name == "" then
        return "I spoke with someone who needed a willing hand."
    end
    local he = Pronouns(snapshot.giverSex)
    return "I spoke with " .. name .. ". " .. he:gsub("^%l", string.upper) .. " had work for willing hands."
end

local QUESTIONS = {
    "Did I take any risks?",
    "Was I accompanied by a companion, enemy, or maybe a stalker?",
    "What do I want to remember from this venture?",
}

local function Voiced(text)
    if Blackacre.Voice and Blackacre.Voice.MaybeApplyChronicle then
        return Blackacre.Voice.MaybeApplyChronicle(text)
    end
    return text
end

--- A quest the player chose to journal: one first-person line setting the
--- scene, trailing off so the player can carry on in their own words.
--- The quest's original text stays in the Quest Index, not on the page.
---   rec: a Quest Index record { title, giver, scene, dayText } where dayText
---        is like "the 27th of September".
function Blackacre.Chronicle.Prompt.BuildQuestPage(rec)
    local scene = rec.scene or Blackacre.Chronicle.Prompt.Snapshot()
    local place, parent = PlaceName(scene)
    local where = parent and (place .. ", " .. parent) or place
    local when = TimePhrase(scene.hour)
    local weather = WeatherClause(scene.weather, scene.intensity)

    local opening = "It was " .. (rec.dayText and (rec.dayText .. ", ") or "") .. when .. ", in " .. where
    if weather then opening = opening .. ", and " .. weather end
    opening = opening .. "."
    local giver = rec.giver and rec.giver ~= "" and rec.giver or nil
    local done = giver and ("I had finished what " .. giver .. " asked of me")
        or "I had seen a task through to its end"
    return rec.title or "A task seen through", Voiced(opening .. " " .. done .. "...")
end

--- First-person scene + labeled Prompt. Never uses the quest title.
function Blackacre.Chronicle.Prompt.Build(snapshot, extras)
    extras = extras or {}
    snapshot = snapshot or Blackacre.Chronicle.Prompt.Snapshot()
    local parts = {}
    if extras.questName and extras.questName ~= "" and Blackacre.YearCalendar and Blackacre.YearCalendar.JournalStamp then
        local y, m, d = Blackacre.YearCalendar.JournalStamp()
        parts[#parts + 1] = string.format(
            "It was %s %s, and %s and I just marked another milestone in my personal histories. . .(%s).",
            y, m, d, extras.questName
        )
        parts[#parts + 1] = ""
    end
    if extras.chain and #extras.chain > 0 then
        for i = 1, #extras.chain do
            parts[#parts + 1] = extras.chain[i]
        end
        parts[#parts + 1] = ""
    end
    parts[#parts + 1] = OpeningLine(snapshot)
    parts[#parts + 1] = ""
    parts[#parts + 1] = extras.npcOverride or NpcLines(snapshot)
    if extras.note and extras.note ~= "" then
        parts[#parts + 1] = extras.note
    end
    if extras.questOffer and extras.questOffer ~= "" then
        parts[#parts + 1] = ""
        parts[#parts + 1] = "\"" .. extras.questOffer .. "\""
    end
    if extras.questReward and extras.questReward ~= "" and extras.questReward ~= extras.questOffer then
        parts[#parts + 1] = ""
        parts[#parts + 1] = "\"" .. extras.questReward .. "\""
    end
    parts[#parts + 1] = ""
    parts[#parts + 1] = "Prompt"
    for i = 1, #QUESTIONS do
        parts[#parts + 1] = QUESTIONS[i]
    end
    local place = select(1, PlaceName(snapshot))
    local title
    if snapshot.giverName and snapshot.giverName ~= "" then
        title = snapshot.giverName .. ", " .. place
    else
        title = place
    end
    return title, table.concat(parts, "\n")
end
