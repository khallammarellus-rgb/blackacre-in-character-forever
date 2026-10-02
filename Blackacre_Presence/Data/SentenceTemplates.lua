-- In Character Forever: Beacons & Bulletins - Beacon Sentences

Blackacre = Blackacre or {}
Blackacre.SentenceTemplates = {}

local templates = {
    {
        id = "seeking",
        label = "Seeking company",
        slots = { "disposition", "role", "intent" },
        full = "I am a {disposition} {role}, seeking {intent} in these parts.",
        short = "A {disposition} {role} seeks {intent} nearby.",
    },
    {
        id = "watching",
        label = "Keeping watch",
        slots = { "disposition", "role", "location" },
        full = "I keep watch near {location}, a {disposition} {role} open to quiet company.",
        short = "A {disposition} {role} keeps watch near {location}.",
    },
    {
        id = "calling",
        label = "Calling out",
        slots = { "role", "intent", "location" },
        full = "I call softly for {intent} around {location} — a {role} on the road.",
        short = "A {role} seeks {intent} about {location}.",
    },
    {
        id = "dark_work",
        label = "Dark craft",
        slots = { "role", "location" },
        full = "I practice a shadowed craft near {location}. Those unafraid may approach.",
        short = "A {role} works dark arts near {location}.",
    },
    {
        id = "trade",
        label = "Trade talk",
        slots = { "disposition", "role" },
        full = "I am a {disposition} {role} open to trade and fair words.",
        short = "A {disposition} {role} offers trade nearby.",
    },
    {
        id = "aid",
        label = "In need of aid",
        slots = { "disposition", "role", "intent" },
        full = "I am a {disposition} {role} in need of {intent}.",
        short = "A {disposition} {role} is in need of {intent} nearby.",
    },
    {
        id = "story",
        label = "Tales",
        slots = { "disposition", "role" },
        full = "I am a {disposition} {role} with a tale, if you have ears for it.",
        short = "A {disposition} {role} offers a tale nearby.",
    },
}

local slotOptions = {
    disposition = {
        "curious", "friendly", "wary", "seasoned", "quiet", "bold", "weary", "cheerful",
    },
    role = {
        "traveler", "scholar", "merchant", "soldier", "healer", "storyteller",
        "adventurer", "artisan", "scout", "pilgrim", "mage", "rogue", "hunter",
    },
    intent = {
        "conversation", "companionship", "a shared tale", "aid on the road",
        "trade talk", "quiet company", "training partners", "fellow explorers",
        "a helping hand", "a healer's touch", "safe escort", "shelter for the night",
    },
    location = {
        "the crossroads", "the market square", "the tavern door", "the city gates",
        "the harbor", "the temple steps", "the old quarter", "these streets",
    },
}

function Blackacre.SentenceTemplates.GetTemplates()
    return templates
end

function Blackacre.SentenceTemplates.GetSlotOptions(slotName)
    return slotOptions[slotName] or {}
end

local function fillPattern(pattern, slots)
    return (pattern:gsub("{(%w+)}", function(key)
        return slots[key] or key
    end))
end

function Blackacre.SentenceTemplates.Resolve(templateId, slotValues, locationOverride)
    for _, template in ipairs(templates) do
        if template.id == templateId then
            local slots = {}
            for k, v in pairs(slotValues or {}) do
                slots[k] = v
            end
            if locationOverride and locationOverride ~= "" then
                slots.location = locationOverride
            elseif not slots.location then
                local zone = Blackacre.GetZoneContext()
                slots.location = zone.subzone ~= "" and zone.subzone or zone.zoneName
            end
            return {
                templateId = templateId,
                slots = slots,
                fullText = fillPattern(template.full, slots),
                shortText = fillPattern(template.short, slots),
            }
        end
    end
    return nil
end
