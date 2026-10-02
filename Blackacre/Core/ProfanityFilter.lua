-- In Character Forever - Content Filter

Blackacre = Blackacre or {}
Blackacre.ProfanityFilter = {}

local LEET = {
    ["0"] = "o", ["1"] = "i", ["3"] = "e", ["4"] = "a", ["5"] = "s",
    ["7"] = "t", ["@"] = "a", ["$"] = "s",
}

-- Whole words only (%f frontier patterns): a plain substring search flagged
-- "girl", "swirl" and "whirl" as "irl".
local OOC_PATTERNS = {
    { "ooc:", "%f[%w]ooc:" },
    { "lfg", "%f[%w]lfg%f[%W]" },
    { "irl", "%f[%w]irl%f[%W]" },
    { "brb", "%f[%w]brb%f[%W]" },
    { "afk", "%f[%w]afk%f[%W]" },
    { "gtg", "%f[%w]gtg%f[%W]" },
}

local function normalize(text)
    text = string.lower(text or "")
    text = text:gsub("[%p%s]", "")
    local out = {}
    for i = 1, #text do
        local ch = text:sub(i, i)
        out[#out + 1] = LEET[ch] or ch
    end
    return table.concat(out)
end

function Blackacre.ProfanityFilter.IsBlocked(text)
    local norm = normalize(text)
    for _, term in ipairs(Blackacre.Blocklist) do
        local termNorm = normalize(term)
        if termNorm ~= "" and norm:find(termNorm, 1, true) then
            return true, "Content blocked by Blackacre safety filter."
        end
    end
    return false
end

function Blackacre.ProfanityFilter.GetOOCWarnings(text)
    local lower = string.lower(text or "")
    local warnings = {}
    for _, p in ipairs(OOC_PATTERNS) do
        if lower:find(p[2]) then
            warnings[#warnings + 1] = p[1]
        end
    end
    if text and text:find("%(") then
        warnings[#warnings + 1] = "parenthetical aside"
    end
    return warnings
end

function Blackacre.ProfanityFilter.ValidateBulletin(title, body, onProceed)
    local blocked, reason = Blackacre.ProfanityFilter.IsBlocked(title)
    if blocked then
        Blackacre.Print(reason)
        return false
    end
    blocked, reason = Blackacre.ProfanityFilter.IsBlocked(body)
    if blocked then
        Blackacre.Print(reason)
        return false
    end

    local warnings = Blackacre.ProfanityFilter.GetOOCWarnings(body)
    if #warnings > 0 and onProceed then
        StaticPopup_Show("Blackacre_OOC_WARNING", nil, nil, { onProceed = onProceed })
        return false
    end
    return true
end

-- Beacon crumbs: narration for the seeker, in third person ("Folk at the bar
-- mention a hooded dwarf..."). Hard block on profanity; a soft, skippable
-- warning for out-of-character markers. Voice is never forced.
function Blackacre.ProfanityFilter.ValidateCrumbs(texts, onProceed)
    local warned = false
    for i = 1, #texts do
        local blocked, reason = Blackacre.ProfanityFilter.IsBlocked(texts[i])
        if blocked then
            Blackacre.Print(reason)
            return false
        end
        if #Blackacre.ProfanityFilter.GetOOCWarnings(texts[i]) > 0 then warned = true end
    end
    if warned and onProceed then
        StaticPopup_Show("Blackacre_OOC_CRUMB", nil, nil, { onProceed = onProceed })
        return false
    end
    return true
end

StaticPopupDialogs["Blackacre_OOC_CRUMB"] = {
    text = "A crumb might read as out-of-character. Keep it anyway?",
    button1 = "Keep it",
    button2 = "Edit",
    OnAccept = function(self)
        local data = self.data
        if data and data.onProceed then data.onProceed() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["Blackacre_OOC_WARNING"] = {
    text = "This bulletin might read as out-of-character. Post anyway?",
    button1 = "Post anyway",
    button2 = "Edit",
    OnAccept = function(self)
        local data = self.data
        if data and data.onProceed then
            data.onProceed()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
