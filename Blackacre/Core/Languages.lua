-- In Character Forever - Languages

Blackacre = Blackacre or {}
Blackacre.Languages = {}

local concat, max = table.concat, math.max

-- Languages a player can tick as learned on the Character Sheet.
Blackacre.Languages.LEARNABLE = { "Common", "Orcish" }

local SYLLABLES = {
    Common = {
        "an", "ash", "bor", "dan", "ras", "ne", "vil", "kor", "mod", "ver", "lo", "hir",
        "ti", "se", "ko", "eth", "ol", "gra", "nud", "ma", "den", "thor", "va", "re",
    },
    Orcish = {
        "lok", "tar", "og", "ar", "zug", "kaz", "mog", "gul", "nar", "thrum", "ka", "ruk",
        "mok", "gra", "dar", "osh", "kek", "ul", "ag", "gor", "zog", "ma", "ruh", "nak",
    },
}

-- The language this character writes in (for notices they post).
function Blackacre.Languages.MyLanguage()
    if GetDefaultLanguage then
        local name = GetDefaultLanguage("player")
        if name and name ~= "" then return name end
    end
    return nil
end

local function LearnedStore()
    local c = Blackacre.CharDB
    if not c then return nil end
    c.knownLanguages = c.knownLanguages or {}
    return c.knownLanguages
end

-- Does the game say this character speaks it natively?
function Blackacre.Languages.IsNative(langName)
    if not (GetNumLanguages and GetLanguageByIndex) then return false end
    for i = 1, GetNumLanguages() do
        if GetLanguageByIndex(i) == langName then return true end
    end
    return false
end

function Blackacre.Languages.IsLearned(langName)
    local store = LearnedStore()
    return store ~= nil and store[langName] == true
end

function Blackacre.Languages.SetLearned(langName, on)
    local store = LearnedStore()
    if store then store[langName] = on and true or nil end
end

-- No language on the notice (older posts) counts as readable.
function Blackacre.Languages.Knows(langName)
    if not langName or langName == "" then return true end
    return Blackacre.Languages.IsNative(langName) or Blackacre.Languages.IsLearned(langName)
end

local function Hash(s)
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + s:byte(i)) % 2147483647
    end
    return h
end

local function ScrambleWord(word, list)
    local h = Hash(word:lower())
    local target = max(2, #word)
    local parts, len = {}, 0
    while len < target do
        local syl = list[(h % #list) + 1]
        parts[#parts + 1] = syl
        len = len + #syl
        h = (h * 69069 + 1) % 2147483648 -- small multiplier keeps this exact in Lua numbers
    end
    local out = concat(parts)
    if #out > target + 1 then out = out:sub(1, target + 1) end
    if word:sub(1, 1):match("%u") then
        out = out:sub(1, 1):upper() .. out:sub(2)
    end
    return out
end

-- Gibberish in the given language; spacing and punctuation kept.
function Blackacre.Languages.Scramble(text, langName)
    if not text or text == "" then return text end
    local list = SYLLABLES[langName] or SYLLABLES.Common
    return (text:gsub("[%a']+", function(word) return ScrambleWord(word, list) end))
end

-- What a reader sees: the real text if they know the language, else gibberish.
function Blackacre.Languages.ForReader(text, langName)
    if Blackacre.Languages.Knows(langName) then return text end
    return Blackacre.Languages.Scramble(text, langName)
end
