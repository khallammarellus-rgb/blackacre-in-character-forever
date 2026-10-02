-- In Character Forever: Journal - Page Capture

Blackacre = Blackacre or {}
Blackacre.Chronicle = Blackacre.Chronicle or {}
Blackacre.Chronicle.Capture = {}

local time, pcall, tostring = time, pcall, tostring
local C_Timer = C_Timer

local lastTitleIndex = nil
local titleReady = false
local suppressToasts = false
local repScanPending = false

local STANDING_NAME = {
    [4] = "Friendly",
    [5] = "Honored",
    [6] = "Revered",
    [7] = "Exalted",
}

local function Toast(msg, kit)
    if suppressToasts then return end
    local quiet = Blackacre.CharDB.settings and Blackacre.CharDB.settings.quietNotifications
    if quiet then return end
    Blackacre.UI.Theme.Toast(msg, kit)
end

local function StoryDB()
    Blackacre.CharDB.chronicleStory = Blackacre.CharDB.chronicleStory or {
        chains = {},
        repStanding = {},
    }
    return Blackacre.CharDB.chronicleStory
end

--- Store a finished entry, announce it, and open the book to it.
local function Publish(entry)
    Blackacre.Chronicle.Store.Add(entry)
    Toast("Journal updated: " .. (entry.title or entry.kind), "journal")
    if Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.OnNewEntry then
        Blackacre.Chronicle.UI.OnNewEntry(entry)
    end
    return entry
end

local function MakeEntry(kind, facts, source)
    facts = facts or {}
    local context = Blackacre.Chronicle.Hooks.GetContext()
    facts.zoneName = facts.zoneName or context.zone
    local title, body = Blackacre.Chronicle.Hooks.Resolve(kind, facts, context)
    local zone = Blackacre.GetZoneContext()
    local now = time()
    return Publish({
        kind = kind,
        source = source or "auto",
        facts = facts,
        context = context,
        title = title,
        body = body,
        zoneId = zone.zoneId,
        zoneName = zone.zoneName,
        yearKC = context.yearKC,
        createdAt = now,
        editedAt = now,
        pinned = false,
        tags = {},
        editable = true,
    })
end

function Blackacre.Chronicle.Capture.AddEntry(kind, facts, source)
    return MakeEntry(kind, facts, source or "auto")
end

--- Add an entry another module built in full (e.g. a logged quest page
--- with its own storyAt), with the same toast and book jump as any page.
function Blackacre.Chronicle.Capture.AddPreparedEntry(entry)
    return Publish(entry)
end

-- A fresh page gets a starting title and opening line from the in-game hour
-- and where the player stands, instead of "Untitled". Weather is not used:
-- no Forever weather API has been confirmed in the real client yet.
local TOD_PHRASE = {
    Night = "tonight", Dawn = "at dawn", Morning = "this morning",
    Midday = "at midday", Afternoon = "this afternoon", Evening = "this evening",
}

local function TimeOfDayWord()
    local h = GetGameTime and GetGameTime()
    if not h then return nil end
    if h < 5 then return "Night" end
    if h < 8 then return "Dawn" end
    if h < 12 then return "Morning" end
    if h < 14 then return "Midday" end
    if h < 18 then return "Afternoon" end
    if h < 21 then return "Evening" end
    return "Night"
end

local MONTH_NAMES = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
}
Blackacre.Chronicle.Capture.MONTH_NAMES = MONTH_NAMES

local function Ordinal(n)
    local tens = n % 100
    if tens >= 11 and tens <= 13 then return n .. "th" end
    local last = n % 10
    if last == 1 then return n .. "st" end
    if last == 2 then return n .. "nd" end
    if last == 3 then return n .. "rd" end
    return n .. "th"
end
Blackacre.Chronicle.Capture.Ordinal = Ordinal

-- Server calendar date (same day the in-game calendar shows); local clock
-- as fallback. Returns day number and month name, or nil.
local function CurrentDayMonth()
    local d = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime
        and C_DateAndTime.GetCurrentCalendarTime()
    local day, month = d and d.monthDay, d and d.month
    if not (day and month) then
        local t = date("*t")
        day, month = t.day, t.month
    end
    local name = month and MONTH_NAMES[month]
    if not (day and name) then return nil end
    return day, name
end

local function DefaultManualPage()
    local zone = Blackacre.GetZoneContext()
    local zoneName = zone.zoneName ~= "" and zone.zoneName or nil
    local sub = zone.subzone ~= "" and zone.subzone ~= zoneName and zone.subzone or nil
    local tod = TimeOfDayWord()
    local day, month = CurrentDayMonth()

    -- Title: "Evening of 26 September in Elwynn Forest"
    local title = tod or "A page"
    if day then title = title .. " of " .. day .. " " .. month end
    if zoneName then title = title .. " in " .. zoneName end
    if not tod and not day and not zoneName then title = "A new page" end

    -- Opening line, first person (journal pages are always in character):
    -- "I set these words down this evening, the 26th of September, in
    --  Goldshire, Elwynn Forest, in the year 32 K.C."
    local place = (sub and zoneName) and (sub .. ", " .. zoneName) or zoneName or sub
    local year = Blackacre.UI.Theme.FormatFactionYear(Blackacre.YearCalendar.GetPresentADP())
    local line = "I set these words down"
    if tod then line = line .. " " .. TOD_PHRASE[tod] end
    if day then line = line .. ", the " .. Ordinal(day) .. " of " .. month end
    if place then line = line .. (day and ", in " or " in ") .. place end
    if year and year ~= "?" then line = line .. ", in the year " .. year end
    return title, line .. ".\n\n"
end

--- A blank page written now. `storyAt` (optional) places it earlier in the
--- book's chronology, e.g. right after the page the player is reading.
function Blackacre.Chronicle.Capture.AddManual(title, body, kind, storyAt, yearKC)
    kind = kind or "MANUAL"
    if title == nil and body == nil and kind == "MANUAL" then
        title, body = DefaultManualPage()
    end
    local facts = { manualTitle = title, manualBody = body, title = title, body = body }
    if not storyAt then
        return MakeEntry(kind, facts, "manual")
    end
    local context = Blackacre.Chronicle.Hooks.GetContext()
    local zone = Blackacre.GetZoneContext()
    local now = time()
    return Publish({
        kind = kind,
        source = "manual",
        facts = facts,
        context = context,
        title = title,
        body = body,
        zoneId = zone.zoneId,
        zoneName = zone.zoneName,
        yearKC = yearKC or context.yearKC,
        createdAt = now,
        storyAt = storyAt,
        editedAt = now,
        pinned = false,
        tags = {},
        editable = true,
    })
end

---------------------------------------------------------------------------
-- Quest finales (called by the Quest Index when a quest is turned in)
---------------------------------------------------------------------------

local function IsMetaQuest(questID)
    if C_QuestLog and C_QuestLog.IsMetaQuest then
        local ok, v = pcall(C_QuestLog.IsMetaQuest, questID)
        if ok and v then return true end
    end
    local E = Enum and Enum.QuestClassification
    if E and C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification then
        local ok, c = pcall(C_QuestInfoSystem.GetQuestClassification, questID)
        if ok and c == E.Meta then return true end
    end
    return false
end

local function SceneBits(snapshot)
    if not snapshot then return nil end
    local title, body = Blackacre.Chronicle.Prompt.Build(snapshot)
    local opening = body and body:match("^(.-)\n") or nil
    local npc = snapshot.giverName and ("I spoke with " .. snapshot.giverName .. ".") or nil
    return { opening = opening, npc = npc, title = title, body = body }
end

--- Meta quests and chain finales earn their own page automatically (they are
--- meta-tier). Returns true when a page was written, so the caller does not
--- also write an ordinary quest page.
function Blackacre.Chronicle.Capture.OnQuestTurnedIn(questID, questName, snapshot)
    local zoneName = snapshot and (snapshot.subzone ~= "" and snapshot.subzone or snapshot.zone) or nil

    if IsMetaQuest(questID) then
        local title, body = Blackacre.Chronicle.Prompt.Build(snapshot)
        MakeEntry("META_QUEST", {
            questId = questID,
            questName = questName,
            zoneName = zoneName,
            title = title,
            promptTitle = title,
            promptBody = body,
        })
        return true
    end

    Blackacre.QuestLines.RememberBeat(questID, questName, zoneName, SceneBits(snapshot))
    local isFinale, _, lineId = Blackacre.QuestLines.IsFinale(questID)
    if not isFinale and lineId and C_QuestLine and C_QuestLine.IsComplete then
        local ok, done = pcall(C_QuestLine.IsComplete, lineId)
        isFinale = ok and done
    end
    if not isFinale then return false end

    local title, body, meta = Blackacre.QuestLines.BuildOnePager(lineId, questName, zoneName, snapshot)
    MakeEntry("QUESTLINE", {
        questId = questID,
        zoneName = zoneName,
        title = title,
        promptTitle = title,
        promptBody = body,
        lineId = meta and meta.lineId or lineId,
        lineName = meta and meta.lineName,
    })
    return true
end

---------------------------------------------------------------------------
-- Achievements, titles, standings, professions
---------------------------------------------------------------------------

local function IsMetaAchievement(achievementID)
    local n = GetAchievementNumCriteria(achievementID) or 0
    if n < 2 then return false end
    local hits = 0
    for i = 1, n do
        local ok, _, criteriaType = pcall(GetAchievementCriteriaInfo, achievementID, i)
        if ok and (criteriaType == 8 or criteriaType == 36) then
            hits = hits + 1
        end
    end
    return hits >= 2
end

local function IsFeatOfStrength(achievementID)
    if AchievementUtil and AchievementUtil.IsFeatOfStrength then
        local ok, v = pcall(AchievementUtil.IsFeatOfStrength, achievementID)
        if ok and v then return true end
    end
    return false
end

local function OnAchievement(achievementID)
    if not achievementID then return end
    local _, name, _, _, _, _, _, description = GetAchievementInfo(achievementID)
    name = name or ("Achievement #" .. tostring(achievementID))
    local kind = "ACHIEVEMENT"
    if IsFeatOfStrength(achievementID) then
        kind = "FOS"
    elseif IsMetaAchievement(achievementID) then
        kind = "META_ACHIEVEMENT"
    end
    MakeEntry(kind, {
        achievementId = achievementID,
        achievementName = name,
        achievementDetail = description or "",
        name = name,
    })
end

local function CheckTitleChange()
    if not titleReady then return end
    local idx = GetCurrentTitle()
    if idx and idx > 0 and idx ~= lastTitleIndex then
        local titleName = GetTitleName(idx)
        if titleName and titleName ~= "" then
            titleName = titleName:gsub("%s+$", "")
            MakeEntry("TITLE", { titleIndex = idx, titleName = titleName, name = titleName })
        end
    end
    if idx then lastTitleIndex = idx end
end

local function ScanReputationBrackets()
    local db = StoryDB()
    db.repStanding = db.repStanding or {}
    local num = C_Reputation.GetNumFactions()
    if not num or num < 1 then return end
    for i = 1, num do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if type(data) == "table" and not data.isHeader then
            local factionId = data.factionID
            local standingId = data.reaction
            if factionId and standingId then
                local prev = db.repStanding[factionId]
                db.repStanding[factionId] = standingId
                local label = STANDING_NAME[standingId]
                if label and prev and standingId > prev then
                    MakeEntry("REPUTATION", {
                        factionId = factionId,
                        factionName = data.name or ("Faction #" .. tostring(factionId)),
                        standingId = standingId,
                        standingName = label,
                        name = data.name,
                    })
                end
            end
        end
    end
end

-- Profession milestones: finishing each training tier by skill-ups.
-- Only the highest tier reached is remembered per profession, so a jump
-- past a threshold (74 -> 76) still counts, and nothing repeats.
local PROFESSION_TIERS = {
    { at = 75, echelon = "apprentice" },
    { at = 150, echelon = "journeyman" },
    { at = 225, echelon = "expert" },
    { at = 300, echelon = "artisan" },
}
local professionSlots = {}

local function NoteProfessions(writeEntry)
    local db = StoryDB()
    db.professionTier = db.professionTier or {}
    -- GetProfessions returns up to seven indices with nil gaps (an empty
    -- primary slot), so walk all seven instead of stopping at the first gap.
    local s = professionSlots
    s[1], s[2], s[3], s[4], s[5], s[6], s[7] = GetProfessions()
    for slot = 1, 7 do
        local idx = s[slot]
        if idx then
            local name, _, rank = GetProfessionInfo(idx)
            local reached
            for _, tier in ipairs(PROFESSION_TIERS) do
                if rank and rank >= tier.at then reached = tier end
            end
            if name and reached and (db.professionTier[name] or 0) < reached.at then
                db.professionTier[name] = reached.at
                if writeEntry then
                    MakeEntry("PROFESSION", { skillName = name, skillRank = rank, echelon = reached.echelon })
                end
            end
        end
    end
end

-- Weapon skills (and Unarmed) at their absolute cap: 5 x the level cap.
-- Skill line ids are the vanilla-era ones Forever's Skills window lists.
local WEAPON_SKILLS = {
    44, 172, 43, 55, 54, 160, 229, 136, 173, 473, -- axes, 2h axes, swords, 2h swords, maces, 2h maces, polearms, staves, daggers, fist
    45, 46, 226, 176, 228,                        -- bows, guns, crossbows, thrown, wands
    162,                                          -- unarmed
}

local function NoteWeaponSkills(writeEntry)
    local db = StoryDB()
    db.weaponMaxed = db.weaponMaxed or {}
    local cap = 5 * (GetMaxPlayerLevel() or 60)
    for _, id in ipairs(WEAPON_SKILLS) do
        local info = not db.weaponMaxed[id] and C_SkillInfo.GetSkillLineInfoByID(id)
        if info and info.maxRank and info.maxRank >= cap and info.rank >= info.maxRank then
            db.weaponMaxed[id] = true
            if writeEntry then
                MakeEntry("WEAPON_SKILL", { skillName = info.name, skillRank = info.rank })
            end
        end
    end
end

-- Skill-ups fire SKILL_LINES_CHANGED in bursts; check once per burst.
local skillCheckPending = false
local function ScheduleSkillCheck()
    if skillCheckPending then return end
    skillCheckPending = true
    C_Timer.After(1, function()
        skillCheckPending = false
        NoteProfessions(true)
        NoteWeaponSkills(true)
    end)
end

local function RunRepScan()
    repScanPending = false
    ScanReputationBrackets()
end

function Blackacre.Chronicle.Capture.Init()
    local frame = CreateFrame("Frame")
    local professionReady = false

    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("SKILL_LINES_CHANGED")
    frame:RegisterEvent("ACHIEVEMENT_EARNED")
    frame:RegisterEvent("KNOWN_TITLES_UPDATE")
    frame:RegisterEvent("UPDATE_FACTION")
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", "player")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGIN" then
            lastTitleIndex = GetCurrentTitle()
            titleReady = true
            C_Timer.After(3, ScanReputationBrackets)
            C_Timer.After(4, function()
                -- Remember where skills already stand, silently.
                NoteProfessions(false)
                NoteWeaponSkills(false)
                professionReady = true
            end)
        elseif event == "SKILL_LINES_CHANGED" then
            if professionReady then ScheduleSkillCheck() end
        elseif event == "ACHIEVEMENT_EARNED" then
            OnAchievement(...)
        elseif event == "KNOWN_TITLES_UPDATE" or event == "UNIT_NAME_UPDATE" then
            CheckTitleChange()
        elseif event == "UPDATE_FACTION" then
            -- Fires on every reputation gain (each kill while grinding). Scan
            -- once, 2 s after a burst starts; dropping the event instead could
            -- miss a tier crossing that was the last gain of a burst.
            if repScanPending then return end
            repScanPending = true
            C_Timer.After(2, RunRepScan)
        end
    end)
end
