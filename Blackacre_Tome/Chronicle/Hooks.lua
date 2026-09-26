Blackacre = Blackacre or {}
Blackacre.Chronicle = Blackacre.Chronicle or {}
Blackacre.Chronicle.Hooks = {}

local function GetSeasoning(level)
    level = level or 1
    for _, band in ipairs(Blackacre.HookSeasoning or {}) do
        if level <= band.maxLevel then
            return band.text
        end
    end
    return "on the path"
end

function Blackacre.Chronicle.Hooks.GetContext()
    local raceLoc = UnitRace("player") or "unknown"
    local classLoc = UnitClass("player") or "adventurer"
    local level = UnitLevel("player") or 1
    local spec = ""
    if GetSpecialization then
        local idx = GetSpecialization()
        if idx then
            local _, name = GetSpecializationInfo(idx)
            spec = name or ""
        end
    end
    local zone = Blackacre.GetZoneContext()
    return {
        name = Blackacre.GetCharName(),
        race = raceLoc,
        class = classLoc,
        level = level,
        spec = spec,
        zone = zone.zoneName ~= "" and zone.zoneName or "unknown lands",
        zoneId = zone.zoneId,
        subzone = zone.subzone,
        yearKC = Blackacre.YearCalendar.GetPresentADP and Blackacre.YearCalendar.GetPresentADP() or Blackacre.YearCalendar.GetYearKC(),
        seasoning = GetSeasoning(level),
    }
end

local function Fill(template, slots)
    return (template:gsub("{(%w+)}", function(key)
        local v = slots[key]
        if v == nil or v == "" then
            return ""
        end
        return tostring(v)
    end)):gsub("%s+", " "):gsub("%s+([%.,;:])", "%1"):gsub("^%s+", ""):gsub("%s+$", "")
end

function Blackacre.Chronicle.Hooks.Resolve(kind, facts, context)
    context = context or Blackacre.Chronicle.Hooks.GetContext()
    facts = facts or {}
    -- Manual pages are user-authored. Do not run them through the automatic
    -- Chronicle prose templates, because an empty page otherwise becomes a
    -- generated sentence such as "Untitled." before the editor opens.
    if kind == "MANUAL" then
        return facts.manualTitle or facts.title or "Journal note",
            facts.manualBody or facts.body or ""
    end
    if facts.promptBody and facts.promptBody ~= "" then
        return facts.title or facts.promptTitle or "A page", facts.promptBody
    end
    if kind == "AFTERLIFE" then
        local line
        if facts.stage == "begin" then
            line = "And so your Rites of Return start. . ."
        elseif facts.stage == "return" then
            line = "You completed their Rites"
        elseif facts.stage == "abandon" then
            line = "You abandoned your Rites"
        end
        if line then
            return facts.title or "Rites of Return", line
        end
    end
    local banks = Blackacre.HookTemplates or {}
    local list = banks[kind]
    if kind == "PROFESSION" and type(list) == "table" and facts.echelon and type(list[facts.echelon]) == "string" then
        list = { list[facts.echelon] }
    elseif kind == "PVP" and type(list) == "table" and facts.outcome and type(list[facts.outcome]) == "string" then
        list = { list[facts.outcome] }
    end
    if type(list) ~= "table" or type(list[1]) ~= "string" then
        list = banks.DEFAULT or { "It is {yearKC} {month} and {day}, and I mark this moment today. . ." }
    end
    local template = list[math.random(1, #list)]

    local slots = {
        name = context.name,
        race = context.race,
        class = context.class,
        level = tostring(context.level),
        zone = facts.zoneName or context.zone,
        yearKC = (function()
            if Blackacre.YearCalendar and Blackacre.YearCalendar.JournalStamp then
                return (Blackacre.YearCalendar.JournalStamp())
            end
            return Blackacre.YearCalendar.FormatYear(facts.yearKC or context.yearKC)
        end)(),
        month = (function()
            if Blackacre.YearCalendar and Blackacre.YearCalendar.JournalStamp then
                local _, m = Blackacre.YearCalendar.JournalStamp()
                return m
            end
            return ""
        end)(),
        day = (function()
            if Blackacre.YearCalendar and Blackacre.YearCalendar.JournalStamp then
                local _, _, d = Blackacre.YearCalendar.JournalStamp()
                return d
            end
            return ""
        end)(),
        seasoning = context.seasoning,
        age = (Blackacre.Birthpath and Blackacre.Birthpath.FormatAge and Blackacre.Birthpath.FormatAge()) or "",
        birthYear = (Blackacre.YearCalendar.GetBirthADP and Blackacre.YearCalendar.GetBirthADP()
            and Blackacre.YearCalendar.FormatYearADP(Blackacre.YearCalendar.GetBirthADP())) or "",
        eraName = (function()
            local e = Blackacre.GetEraAtYear and Blackacre.GetEraAtYear(Blackacre.YearCalendar.GetPresentADP())
            return e and e.name or ""
        end)(),
        kind = kind or "NOTE",
        questName = facts.questName or facts.name or "an unnamed trial",
        questOffer = facts.questOffer or "",
        questReward = facts.questReward or "",
        giverName = facts.giverName or facts.questGiver or "",
        dayDescription = facts.dayDescription or "",
        weatherText = facts.weatherText or "",
        achievementDetail = facts.achievementDetail or "",
        pvpBody = facts.pvpBody or facts.promptBody or "",
        lineName = facts.lineName or facts.questName or "an unnamed road",
        standingName = facts.standingName or "a new standing",
        factionName = facts.factionName or facts.name or "an unnamed people",
        renownLevel = facts.renownLevel and tostring(facts.renownLevel) or "the highest rung",
        onePager = facts.onePager or facts.body or "",
        achievementName = facts.achievementName or facts.name or "an unnamed feat",
        titleName = facts.titleName or facts.name or "an untitled honor",
        skillName = facts.skillName or "their craft",
        skillRank = facts.skillRank and tostring(facts.skillRank) or "a new rank",
        manualTitle = facts.manualTitle or facts.title or "a private note",
        manualBody = facts.manualBody or facts.body or "",
        bagDetail = facts.bagDetail or "an oversized pack",
        meterName = facts.meter == "hunger" and "hunger"
            or facts.meter == "thirst" and "thirst"
            or facts.meter == "exposure" and "exposure"
            or facts.meterName or "vital strength",
        meterValue = facts.value and tostring(math.floor(facts.value)) or "low",
        pathName = facts.pathName or "an unnamed afterlife",
        afterlifeDetail = facts.stage == "begin" and ("The road opened after a fall in " .. (facts.deathZone or context.zone or "unknown lands") .. ".")
            or facts.stage == "task" and (facts.taskBody or "A rite was fulfilled.")
            or facts.stage == "return" and ("They returned to the living from " .. (facts.pathName or "death's realm") .. ".")
            or facts.stage == "abandon" and "The path was left unfinished."
            or (facts.taskBody or "A soul-rite was marked."),
        roadmapName = facts.roadmapName or "an unnamed road",
        roadmapDetail = facts.stage == "begin" and ("First ink on the chart points toward " .. (facts.zoneName or "unknown lands") .. ".")
            or facts.stage == "arrive" and ("The road opens into " .. (facts.zoneName or "a new land") .. ". " .. (facts.lore or ""))
            or facts.stage == "chapter" and ("They close the chapter of " .. (facts.zoneName or "that land") .. ". " .. (facts.lore or ""))
            or facts.stage == "lock" and ("They choose to linger near level " .. tostring(facts.lockLevel or "?") .. " in " .. (facts.zoneName or "place") .. ", so the story may breathe.")
            or facts.stage == "complete" and "The expedition chart is finished — for now."
            or facts.stage == "abandon" and "The chart is folded away unfinished."
            or (facts.lore or "The road continues."),
        mapName = facts.mapName or "the field",
        outcomeLine = facts.outcomeLine or "The skirmish ended.",
        damageText = facts.damageText or "unknown",
        healingText = facts.healingText or "unknown",
        deaths = facts.deaths and tostring(facts.deaths) or "0",
        killingBlows = facts.killingBlows and tostring(facts.killingBlows) or "0",
        spec = context.spec or "",
        specClause = (context.spec and context.spec ~= "") and (" (" .. context.spec .. ")") or "",
    }

    local body = Fill(template, slots)
    if Blackacre.Voice and Blackacre.Voice.MaybeApplyChronicle then
        body = Blackacre.Voice.MaybeApplyChronicle(body)
    end
    local title
    if kind == "QUEST" or kind == "META_QUEST" then
        title = facts.questName or facts.title or "Quest completed"
    elseif kind == "QUESTLINE" then
        title = facts.title or facts.lineName or facts.questName or "A road completed"
    elseif kind == "ACHIEVEMENT" or kind == "META_ACHIEVEMENT" or kind == "FOS" then
        title = facts.achievementName or facts.title or "Achievement"
    elseif kind == "REPUTATION" then
        title = facts.title or ((facts.factionName or "A people") .. ": " .. (facts.standingName or "new standing"))
    elseif kind == "RENOWN" then
        title = facts.title or ("Renown: " .. (facts.factionName or "a cause"))
    elseif kind == "TITLE" then
        title = facts.titleName or "Title gained"
    elseif kind == "PROFESSION" then
        title = (facts.skillName or "Profession") .. " advanced"
    elseif kind == "MANUAL" then
        title = facts.manualTitle or facts.title or "Journal note"
    elseif kind == "DEATH" then
        title = facts.title or ("Fell in " .. (facts.zoneName or slots.zone or "the field"))
    elseif kind == "HC_ENCUMBRANCE" then
        title = facts.title or "Encumbrance broken"
    elseif kind == "HC_MOUNT" then
        title = facts.title or "Mounted without ground rite"
    elseif kind == "HC_FLY" then
        title = facts.title or "Flew without sky rite"
    elseif kind == "SURVIVAL" then
        title = facts.title or "Survival critical"
    elseif kind == "AFTERLIFE" then
        title = facts.title or ("Afterlife: " .. (facts.pathName or "unknown"))
    elseif kind == "ROADMAP" then
        title = facts.title or ("Road: " .. (facts.roadmapName or "expedition"))
    elseif kind == "PVP" then
        title = facts.title or ("Field report: " .. (facts.mapName or "battle"))
    else
        title = facts.title or kind or "Entry"
    end

    return title, body
end

function Blackacre.Chronicle.Hooks.Regenerate(entry)
    if not entry then return end
    local context = entry.context or Blackacre.Chronicle.Hooks.GetContext()
    local title, body = Blackacre.Chronicle.Hooks.Resolve(entry.kind, entry.facts, context)
    entry.title = title
    entry.body = body
    entry.editedAt = time()
    if Blackacre.Chronicle.Store and Blackacre.Chronicle.Store.Touch then
        Blackacre.Chronicle.Store.Touch()
    end
    return entry
end
