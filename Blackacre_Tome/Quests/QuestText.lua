-- In Character Forever: Journal - Shared Quest Text

Blackacre = Blackacre or {}
Blackacre.QuestText = {}

local pairs, ipairs, type, tostring = pairs, ipairs, type, tostring
local C_Timer, InCombatLockdown, GetLocale = C_Timer, InCombatLockdown, GetLocale
local UnitName, UnitRace, UnitClass = UnitName, UnitRace, UnitClass
local CreateFrame = CreateFrame

local FILL_BATCH = 50   -- records handled per step
local FILL_STEP = 0.1   -- seconds between steps
local COMBAT_WAIT = 5   -- seconds before checking again while in combat

-- Record field -> stored field.
local FIELDS = { startText = "s", objective = "o", progressText = "p", endText = "e" }

local function Store()
    local db = Blackacre.DB
    if not db then return nil end
    db.questText = db.questText or {}
    local loc = GetLocale()
    db.questText[loc] = db.questText[loc] or {}
    return db.questText[loc]
end

---------------------------------------------------------------------------
-- Name, race and class tokens
---------------------------------------------------------------------------

local function Escape(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

local function SwapOut(text, word, token)
    if not word or word == "" then return text end
    return (text:gsub("%f[%w]" .. Escape(word) .. "%f[%W]", token))
end

local function SwapIn(text, token, word)
    return (text:gsub(token, (word:gsub("%%", "%%%%"))))
end

--- Who the text was written to: { name, race, class } (race/class may be nil).
local function Me()
    return UnitName("player"), UnitRace("player"), UnitClass("player")
end

local function Tokenize(text, name, race, class)
    text = SwapOut(text, name, "{N}")
    if race then
        text = SwapOut(text, race, "{R}")
        text = SwapOut(text, race:lower(), "{r}")
    end
    if class then
        text = SwapOut(text, class, "{C}")
        text = SwapOut(text, class:lower(), "{c}")
    end
    return text
end

local function Detokenize(text)
    local name, race, class = Me()
    text = SwapIn(text, "{N}", name or "")
    text = SwapIn(text, "{R}", race or "")
    text = SwapIn(text, "{r}", (race or ""):lower())
    text = SwapIn(text, "{C}", class or "")
    text = SwapIn(text, "{c}", (class or ""):lower())
    return text
end

---------------------------------------------------------------------------
-- Saving
---------------------------------------------------------------------------

local function Put(store, rec, name, race, class)
    if rec.textShared or type(rec.id) ~= "number" then return end
    local saved = store[rec.id]
    for field, key in pairs(FIELDS) do
        local text = rec[field]
        if text and text ~= "" and not (saved and saved[key]) then
            saved = saved or {}
            saved[key] = Tokenize(text, name, race, class)
        end
    end
    if saved then
        saved.t = saved.t or rec.title
        saved.by = saved.by or name    -- the character who saw it, for "Text retrieved from"
        store[rec.id] = saved
    end
end

--- Share a quest's words as this character captures them.
function Blackacre.QuestText.Save(rec)
    local store = Store()
    if store and rec then Put(store, rec, Me()) end
end

--- A quest's shared words in this character's name, shaped like a quest record
--- ({ startText, objective, progressText, endText, textFrom, textFromRealm }),
--- or nil. For the Warband list, whose records keep no words of their own.
function Blackacre.QuestText.Lookup(questID)
    local store = Store()
    local saved = store and store[questID]
    if not saved then return nil end
    local out = { id = questID, textFrom = saved.by, textFromRealm = saved.realm }
    for field, key in pairs(FIELDS) do
        if saved[key] then out[field] = Detokenize(saved[key]) end
    end
    return out
end

--- True when test(text, arg) holds for any of this quest's shared words (the
--- Quest Index search). The stored text is tested as is: no copy per quest.
function Blackacre.QuestText.Contains(questID, test, arg)
    local store = Store()
    local saved = store and store[questID]
    if not saved then return false end
    for _, key in pairs(FIELDS) do
        local text = saved[key]
        if text and test(text, arg) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Filling, spread over time
---------------------------------------------------------------------------

local queue, running = {}, false

local function NeedsText(rec)
    for field in pairs(FIELDS) do
        if rec[field] and rec[field] ~= "" then return false end
    end
    return true
end

local function Fill(store, rec)
    local saved = store[rec.id]
    if not saved or not NeedsText(rec) then return false end
    for field, key in pairs(FIELDS) do
        if saved[key] then rec[field] = Detokenize(saved[key]) end
    end
    -- Borrowed words are never shared back out under this character.
    rec.textShared = true
    -- Shown in the Quest Index tooltip. Text another player sent carries
    -- their realm (saved.realm); text from this account's characters doesn't.
    rec.textFrom = saved.by or "another character"
    rec.textFromRealm = saved.realm
    return true
end

local function Step()
    if InCombatLockdown() then
        C_Timer.After(COMBAT_WAIT, Step)
        return
    end
    local store = Store()
    local handled, filled = 0, false
    while queue[1] and handled < FILL_BATCH do
        local job = table.remove(queue)
        handled = handled + 1
        if store then
            if job.seedFrom then
                Put(store, job.rec, job.seedFrom, nil, nil)
            elseif Fill(store, job.rec) then
                filled = true
            end
        end
    end
    if filled and Blackacre.QuestIndex and Blackacre.QuestIndex.Refresh then
        Blackacre.QuestIndex.Refresh()
    end
    if queue[1] then
        C_Timer.After(FILL_STEP, Step)
    else
        running = false
    end
end

local function Run()
    if running or not queue[1] then return end
    running = true
    C_Timer.After(FILL_STEP, Step)
end

--- Once per account: share what every character already captured. Other
--- characters' race and class aren't known, so only their name (from the
--- "Name - Realm" profile key) is turned into a token; profiles with a
--- custom name are skipped so no stranger's name leaks across.
local function QueueSeed()
    local db = Blackacre.DB
    local ace = Blackacre.db
    if not (db and ace and ace.profiles) or db.questTextSeeded then return end
    db.questTextSeeded = true
    local current = Blackacre.ActiveProfileID
    for key, profile in pairs(ace.profiles) do
        local name = type(key) == "string" and key:match("^(.-) %- ")
        local log = type(profile) == "table" and profile.characterData
            and profile.characterData.questLog
        if name and key ~= current and log and log.quests then
            for _, rec in pairs(log.quests) do
                if not NeedsText(rec) then
                    queue[#queue + 1] = { rec = rec, seedFrom = name }
                end
            end
        end
    end
end

--- Queue this character's own words to share, then its missing ones to fill.
--- Fill jobs go in first so they run last, after everything is shared.
function Blackacre.QuestText.Init()
    local log = Blackacre.CharDB and Blackacre.CharDB.questLog
    if not log or not log.quests then return end
    for _, rec in pairs(log.quests) do
        if NeedsText(rec) then queue[#queue + 1] = { rec = rec } end
    end
    QueueSeed()
    local store = Store()
    if store then
        local name, race, class = Me()
        for _, rec in pairs(log.quests) do
            if not NeedsText(rec) then Put(store, rec, name, race, class) end
        end
    end
    Run()
end

---------------------------------------------------------------------------
-- Between players
---------------------------------------------------------------------------
-- Like TRP3's profile directory: meeting another player who uses the add-on
-- (mouseover or target) quietly asks them for up to ASK_BATCH quests this
-- character is missing words for; they whisper back whatever their store
-- holds. What arrives goes into this account's store, marked with the
-- sender's name and realm ("Text retrieved from player Name-Realm").
--
-- Quiet by design: never in combat or instances, one ask per player per
-- ASK_COOLDOWN and no more than one ask every ASK_GAP seconds, answers
-- capped at ANSWER_MAX per request and sent at BULK priority. Words are
-- only taken for quests we asked that player about, in our language, whose
-- name matches our own record. Off with "Share quest text with other
-- players" (BlackacreDB.shareQuestText == false).

local Ambiguate, GetTime, UnitIsPlayer, UnitIsUnit = Ambiguate, GetTime, UnitIsPlayer, UnitIsUnit
local UnitFactionGroup, UnitIsConnected, UnitFullName = UnitFactionGroup, UnitIsConnected, UnitFullName
local issecretvalue = issecretvalue

local ASK_BATCH = 20          -- quest ids per ask (fits one whisper)
local ASK_COOLDOWN = 30 * 60  -- seconds before asking the same player again
local ASK_GAP = 20            -- seconds between any two asks
local ASK_TTL = 120           -- seconds an ask waits for its answers
local ANSWER_COOLDOWN = 5 * 60
local ANSWER_MAX = 10         -- quests sent back per ask
local MAX_FIELD = 4000        -- longest text accepted for one field

local askedAt = {}      -- player -> GetTime() of our last ask
local pendingAsk = {}   -- player -> { at, ids = { [questID] = true } }
local answeredAt = {}   -- player -> GetTime() of our last answer
local lastAskAt = -1000
local missing, cursor = nil, 1

local function SharingOn()
    return Blackacre.DB ~= nil and Blackacre.DB.shareQuestText ~= false and Blackacre.Comms ~= nil
end

local function Busy()
    return InCombatLockdown() or (Blackacre.InInstance and Blackacre.InInstance())
end

local function MyQuests()
    local log = Blackacre.CharDB and Blackacre.CharDB.questLog
    return log and log.quests
end

local function Key(name)
    return Ambiguate(name, "none")
end

local function BuildMissing()
    missing, cursor = {}, 1
    local quests, store = MyQuests(), Store()
    if not (quests and store) then return end
    for id, rec in pairs(quests) do
        if rec.completedAt and not rec.untitled and not store[id] and NeedsText(rec) then
            missing[#missing + 1] = id
        end
    end
end

--- Next ids to ask about, as "1,2,3" plus a set; nil when nothing is missing.
local function NextAsk()
    if not missing or cursor > #missing then BuildMissing() end
    local quests, store = MyQuests(), Store()
    if not (quests and store) then return nil end
    local list, set, n = {}, {}, 0
    while cursor <= #missing and n < ASK_BATCH do
        local id = missing[cursor]
        cursor = cursor + 1
        local rec = quests[id]
        if rec and not store[id] and NeedsText(rec) then
            n = n + 1
            list[n] = tostring(id)
            set[id] = true
        end
    end
    if n == 0 then return nil end
    return table.concat(list, ","), set
end

local function Ask(target)
    local key = Key(target)
    local now = GetTime()
    if askedAt[key] and now - askedAt[key] < ASK_COOLDOWN then return end
    local ids, set = NextAsk()
    if not ids then return end
    askedAt[key], lastAskAt = now, now
    pendingAsk[key] = { at = now, ids = set }
    Blackacre.Comms.SendQuestWant(target, GetLocale(), ids)
end

local function OnUnit(unit)
    -- Mouseover fires constantly in a city: the cheap checks come first.
    if GetTime() - lastAskAt < ASK_GAP or not SharingOn() or Busy() then return end
    if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") or not UnitIsConnected(unit) then return end
    -- Add-on whispers don't cross factions.
    if UnitFactionGroup(unit) ~= UnitFactionGroup("player") then return end
    local name, realm = UnitFullName(unit)
    if not name or (issecretvalue and (issecretvalue(name) or issecretvalue(realm))) then return end
    if realm and realm ~= "" then name = name .. "-" .. realm end
    Ask(name)
end

local unitFrame = CreateFrame("Frame")
unitFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
unitFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
unitFrame:SetScript("OnEvent", function(_, event)
    OnUnit(event == "UPDATE_MOUSEOVER_UNIT" and "mouseover" or "target")
end)

--- Someone asked us for quest words.
function Blackacre.QuestText.OnWant(sender, locale, ids)
    if not SharingOn() or Busy() or locale ~= GetLocale() then return end
    local key = Key(sender)
    local now = GetTime()
    if answeredAt[key] and now - answeredAt[key] < ANSWER_COOLDOWN then return end
    answeredAt[key] = now
    local store = Store()
    if not store then return end
    local sent, seen = 0, 0
    for idText in ids:gmatch("%d+") do
        seen = seen + 1
        if seen > ASK_BATCH or sent >= ANSWER_MAX then break end
        local id = tonumber(idText)
        local saved = store[id]
        if saved and saved.t then
            sent = sent + 1
            Blackacre.Comms.SendQuestText(sender, {
                loc = locale, id = id, t = saved.t,
                s = saved.s, o = saved.o, p = saved.p, e = saved.e,
            })
        end
    end
    -- They use the add-on too: ask them back while we're at it.
    if GetTime() - lastAskAt >= ASK_GAP then Ask(sender) end
end

local function FieldOk(v)
    return v == nil or (type(v) == "string" and #v <= MAX_FIELD)
end

--- One quest's words from another player.
function Blackacre.QuestText.OnText(sender, data)
    if not SharingOn() or type(data) ~= "table" or data.loc ~= GetLocale() then return end
    local id = tonumber(data.id)
    local key = Key(sender)
    local ask = pendingAsk[key]
    if not (id and ask and ask.ids[id]) then return end
    if GetTime() - ask.at > ASK_TTL then pendingAsk[key] = nil return end
    ask.ids[id] = nil
    local quests, store = MyQuests(), Store()
    local rec = quests and quests[id]
    if not (rec and store) or store[id] or rec.title ~= data.t then return end
    if not (FieldOk(data.s) and FieldOk(data.o) and FieldOk(data.p) and FieldOk(data.e)) then return end
    if not (data.s or data.o or data.p or data.e) then return end
    local name, realm = sender:match("^(.-)%-(.+)$")
    if not name then name, realm = sender, GetNormalizedRealmName and GetNormalizedRealmName() or "" end
    store[id] = { t = data.t, s = data.s, o = data.o, p = data.p, e = data.e, by = name, realm = realm }
    if Fill(store, rec) and Blackacre.QuestIndex and Blackacre.QuestIndex.Refresh then
        Blackacre.QuestIndex.Refresh()
    end
end
