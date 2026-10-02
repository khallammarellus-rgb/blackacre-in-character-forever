-- In Character Forever: Journal - Voice

Blackacre = Blackacre or {}
Blackacre.Voice = {}

local OLD_PROFILE = {
    dwarf = { language = "dwarven", accent = "scottish" },
    orc = { language = "orcish", accent = "blunt" },
    undead = { language = "gutterspeak", accent = "london_old" },
    goblin = { language = "goblin", accent = "blunt" },
    blood_elf = { language = "thalassian", accent = "colonial" },
    night_elf = { language = "darnassian", accent = "proper_english" },
    tauren = { language = "taurahe", accent = "native_american" },
    draenei = { language = "draenei", accent = "measured" },
    pandaren = { language = "pandaren", accent = "measured" },
    vulpera = { language = "vulpera", accent = "american" },
    human = { language = "common", accent = "californian" },
    afrikaans = { language = "none", accent = "cape" },
}

local RACE_MAP = {
    Dwarf = { language = "dwarven", accent = "scottish" },
    DarkIronDwarf = { language = "dwarven", accent = "scottish" },
    Orc = { language = "orcish", accent = "blunt" },
    MagharOrc = { language = "orcish", accent = "blunt" },
    NightElf = { language = "darnassian", accent = "proper_english" },
    Nightborne = { language = "darnassian", accent = "proper_english" },
    Skyborne = { language = "darnassian", accent = "proper_english" },
    BloodElf = { language = "thalassian", accent = "colonial" },
    VoidElf = { language = "thalassian", accent = "colonial" },
    Tauren = { language = "taurahe", accent = "native_american" },
    HighmountainTauren = { language = "taurahe", accent = "native_american" },
    Troll = { language = "zandali", accent = "caribbean" },
    ZandalariTroll = { language = "zandali", accent = "african" },
    Gnome = { language = "common", accent = "american" },
    Mechagnome = { language = "common", accent = "american" },
    Human = { language = "common", accent = "californian" },
    KulTiran = { language = "common", accent = "proper_english" },
    Scourge = { language = "gutterspeak", accent = "london_old" },
    Draenei = { language = "draenei", accent = "measured" },
    LightforgedDraenei = { language = "draenei", accent = "measured" },
    Goblin = { language = "goblin", accent = "blunt" },
    Pandaren = { language = "pandaren", accent = "measured" },
    Vulpera = { language = "vulpera", accent = "american" },
    Worgen = { language = "common", accent = "london_old" },
}

local GREET_OPEN = { hello = true, hi = true, greetings = true, hail = true }
local FAREWELL_CLOSE = { goodbye = true, farewell = true, bye = true }
local AGREEMENT = { yes = true, ok = true, okay = true, aye = true, yep = true }

local function EnsureVoiceDB()
    Blackacre.CharDB = Blackacre.CharDB or {}
    local profile = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    local v = profile and profile.voice
    if not v then
        -- Migrate the character's existing voice choices into the active,
        -- reusable AceDB profile the first time that profile is used.
        v = Blackacre.CharDB.voice or {
            language = "auto",
            accent = "auto",
            applyToChronicle = true,
            applyToBulletins = false,
        }
        if profile then profile.voice = v else Blackacre.CharDB.voice = v end
    end
    if v.language == nil then
        local old = v.accent or "auto"
        local mapped = OLD_PROFILE[old]
        if old == "none" then
            v.language = "none"
            v.accent = "none"
        elseif mapped then
            v.language = mapped.language
            v.accent = mapped.accent
        else
            v.language = "auto"
            if old ~= "auto" then
                v.accent = "auto"
            end
        end
    end
    return v
end

function Blackacre.Voice.GetSettings()
    return EnsureVoiceDB()
end

local function RaceDefaults()
    local _, raceFile = UnitRace("player")
    return (raceFile and RACE_MAP[raceFile]) or { language = "none", accent = "none" }
end

function Blackacre.Voice.AccentLabel(id)
    if id == "auto" then return "Auto (from race)" end
    if id == "none" then return "None" end
    local a = Blackacre.VoiceAccents and Blackacre.VoiceAccents[id]
    return (a and a.label) or id
end

function Blackacre.Voice.LanguageLabel(id)
    if id == "auto" then return "Auto (from race)" end
    if id == "none" then return "None" end
    local a = Blackacre.VoiceLanguages and Blackacre.VoiceLanguages[id]
    return (a and a.label) or id
end

function Blackacre.Voice.Resolve()
    local v = EnsureVoiceDB()
    local def = RaceDefaults()
    local language = v.language or "auto"
    local accent = v.accent or "auto"
    if language == "auto" then language = def.language end
    if accent == "auto" then accent = def.accent end
    if not language or language == "" then language = "none" end
    if not accent or accent == "" then accent = "none" end
    return language, accent
end

local function StripDashes(text)
    if not text or text == "" then return text end
    text = text:gsub("\226\128\148", "'")
    text = text:gsub("\226\128\147", "'")
    text = text:gsub("\226\128\146", "'")
    text = text:gsub("%-%-", "'")
    return text
end

local function WordCount(text)
    local n = 0
    for _ in text:gmatch("%a[%w']*") do
        n = n + 1
    end
    return n
end

local function IntensityCap(text)
    local words = WordCount(text)
    return math.max(2, math.min(4, math.ceil(words / 3)))
end

local function IsProtectedWord(word)
    if word:find("://", 1, true) then return true end
    if word:find("[%']") and #word > 2 then return true end
    if word:match("^%u%u%u+$") then return true end
    return false
end

local function CapCopy(fromWord, to)
    if not to or to == "" then return to end
    local first = fromWord:sub(1, 1)
    if first:match("%u") then
        return to:sub(1, 1):upper() .. to:sub(2)
    end
    return to
end

local function ReplacePhrase(text, from, to)
    if not from or from == "" or not to then return text, 0 end
    local n = 0
    local lowerFrom = from:lower()
    local len = #from
    local i = 1
    local out = {}
    local tlen = #text
    local lower = text:lower()
    while i <= tlen do
        local j = lower:find(lowerFrom, i, true)
        if not j then
            out[#out + 1] = text:sub(i)
            break
        end
        local beforeOk = (j == 1) or not text:sub(j - 1, j - 1):match("[%w']")
        local afterIdx = j + len
        local afterOk = (afterIdx > tlen) or not text:sub(afterIdx, afterIdx):match("[%w']")
        if beforeOk and afterOk then
            out[#out + 1] = text:sub(i, j - 1)
            local orig = text:sub(j, j + len - 1)
            out[#out + 1] = CapCopy(orig, to)
            n = n + 1
            i = j + len
        else
            out[#out + 1] = text:sub(i, j)
            i = j + 1
        end
    end
    return table.concat(out), n
end

local function FirstWord(text)
    return (text:match("^%s*('?%a[%w']*)"))
end

local function LastWord(text)
    return (text:match("('?%a[%w']*)%s*%p*%s*$"))
end

local function BareCore(text)
    local s = text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("[%p]+$", "")
    return s
end

local function ApplyAccent(text, accentId)
    if not accentId or accentId == "none" then return text end
    local acc = Blackacre.VoiceAccents and Blackacre.VoiceAccents[accentId]
    if not acc then return text end
    local cap = IntensityCap(text)
    local changes = 0

    for _, p in ipairs(acc.phrases or {}) do
        if p[1] ~= p[2] then
            local n
            text, n = ReplacePhrase(text, p[1], p[2])
            changes = changes + (n or 0)
        end
    end

    for _, w in ipairs(acc.words or {}) do
        if changes >= cap then break end
        if w[1] ~= w[2] then
            local n
            text, n = ReplacePhrase(text, w[1], w[2])
            changes = changes + (n or 0)
        end
    end

    for _, sfx in ipairs(acc.suffixes or {}) do
        if changes >= cap then break end
        local from, to = sfx[1], sfx[2]
        text = text:gsub("(%a[%w']*)", function(word)
            if changes >= cap then return word end
            if IsProtectedWord(word) then return word end
            local lower = word:lower()
            if #lower > #from and lower:sub(-#from) == from then
                local stem = word:sub(1, #word - #from)
                changes = changes + 1
                return stem .. to
            end
            return word
        end)
    end

    return text
end

local function ApplyLanguage(original, accented, languageId)
    if not languageId or languageId == "none" then return accented end
    local lang = Blackacre.VoiceLanguages and Blackacre.VoiceLanguages[languageId]
    if not lang then return accented end

    local core = BareCore(original)
    if lang.agreement and AGREEMENT[core] then
        return lang.agreement
    end

    local out = accented
    local used = false

    local first = FirstWord(original)
    if first and GREET_OPEN[first:lower()] and lang.hello then
        if core == first:lower() then
            local punct = original:match("(%p+)%s*$") or ""
            return lang.hello .. punct
        end
        local aFirst = FirstWord(out)
        if aFirst then
            local replaced
            out, replaced = ReplacePhrase(out, aFirst, lang.hello)
            if replaced > 0 then used = true end
        end
    end

    if not used then
        local last = LastWord(original)
        if last and FAREWELL_CLOSE[last:lower()] and lang.goodbye then
            local aLast = LastWord(out)
            if aLast then
                out = ReplacePhrase(out, aLast, lang.goodbye)
                used = true
            end
        end
    end

    if not used then
        for _, p in ipairs(lang.phrases or {}) do
            local n
            out, n = ReplacePhrase(out, p[1], p[2])
            if n > 0 then
                used = true
                break
            end
        end
    end

    return out
end

function Blackacre.Voice.Apply(text, languageId, accentId)
    if not text or text == "" then return text end
    text = StripDashes(text)
    if languageId == nil and accentId == nil then
        languageId, accentId = Blackacre.Voice.Resolve()
    elseif accentId == nil and languageId and languageId:find("+", 1, true) then
        -- old single-profile call
        languageId, accentId = Blackacre.Voice.Resolve()
    end
    if accentId == nil and languageId and OLD_PROFILE[languageId] then
        local mapped = OLD_PROFILE[languageId]
        languageId, accentId = mapped.language, mapped.accent
    end
    languageId = languageId or "none"
    accentId = accentId or "none"
    local original = text
    local voiced = ApplyAccent(text, accentId)
    voiced = ApplyLanguage(original, voiced, languageId)
    return StripDashes(voiced)
end

function Blackacre.Voice.MaybeApplyChronicle(text)
    local v = EnsureVoiceDB()
    if v.applyToChronicle == false then return text end
    return Blackacre.Voice.Apply(text)
end

function Blackacre.Voice.MaybeApplyBulletin(text)
    local v = EnsureVoiceDB()
    if not v.applyToBulletins then return text end
    return Blackacre.Voice.Apply(text)
end
