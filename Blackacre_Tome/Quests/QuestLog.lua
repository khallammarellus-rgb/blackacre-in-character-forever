-- In Character Forever: Journal - Quest Records

Blackacre = Blackacre or {}
Blackacre.QuestLog = {}

local ipairs, pairs, time, tostring, format = ipairs, pairs, time, tostring, string.format
local GetTime, C_Timer, UnitName, UnitExists = GetTime, C_Timer, UnitName, UnitExists
local CreateFrame = CreateFrame

local FOLLOW_UP_WINDOW = 30 -- seconds after a turn-in in which the same giver's next offer continues the chain

local pending = {}            -- last QUEST_DETAIL, reused
local lastTurnIn = { id = nil, giver = nil, at = -1000 }
local journalBtn

local function DB()
    local c = Blackacre.CharDB
    c.questLog = c.questLog or { quests = {}, order = {} }
    local q = c.questLog
    q.quests = q.quests or {}
    q.order = q.order or {}
    return q
end

local function Notify()
    if Blackacre.QuestIndex and Blackacre.QuestIndex.Refresh then
        Blackacre.QuestIndex.Refresh()
    end
end

local function NpcName()
    if UnitExists("npc") then return UnitName("npc") end
    if UnitExists("questnpc") then return UnitName("questnpc") end
    return nil
end

local function QuestTitle(questID, fallback)
    local t = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
    if t and t ~= "" then return t end
    return fallback or ("Quest #" .. tostring(questID))
end

local function Get(questID, fallbackTitle)
    local quests = DB().quests
    local rec = quests[questID]
    if not rec then
        rec = { id = questID, title = QuestTitle(questID, fallbackTitle) }
        quests[questID] = rec
    end
    return rec
end

---------------------------------------------------------------------------
-- Time stamps (server calendar, so it matches the in-game calendar)
---------------------------------------------------------------------------

local function ServerStamp()
    local d = C_DateAndTime.GetCurrentCalendarTime()
    if d and d.month then
        return { month = d.month, day = d.monthDay, hour = d.hour, minute = d.minute, year = d.year }
    end
    local t = date("*t")
    return { month = t.month, day = t.day, hour = t.hour, minute = t.min, year = t.year }
end

--- "26 September, 8:42 PM"
function Blackacre.QuestLog.StampText(stamp)
    if not stamp then return "" end
    local months = Blackacre.Chronicle.Capture.MONTH_NAMES
    local h = stamp.hour or 0
    local suffix = h >= 12 and "PM" or "AM"
    local h12 = h % 12
    if h12 == 0 then h12 = 12 end
    return format("%d %s, %d:%02d %s", stamp.day or 1, months[stamp.month] or "", h12, stamp.minute or 0, suffix)
end

--- "the 26th of September"
local function DayText(stamp)
    local months = Blackacre.Chronicle.Capture.MONTH_NAMES
    return "the " .. Blackacre.Chronicle.Capture.Ordinal(stamp.day or 1) .. " of " .. (months[stamp.month] or "")
end

---------------------------------------------------------------------------
-- Chains
---------------------------------------------------------------------------

local function ChainFor(questID, followsFrom)
    local info = Blackacre.QuestLines.GetLineInfo(questID)
    local lineId = info and (info.questLineId or info.questLineID or info.id)
    if lineId then
        return "L" .. tostring(lineId)
    end
    local prev = followsFrom and DB().quests[followsFrom]
    if prev then
        prev.chain = prev.chain or ("Q" .. tostring(followsFrom))
        return prev.chain
    end
    return nil
end

---------------------------------------------------------------------------
-- Journal pages
---------------------------------------------------------------------------

function Blackacre.QuestLog.GetEntry(questID)
    local rec = DB().quests[questID]
    return rec and rec.entryId and Blackacre.Chronicle.Store.GetById(rec.entryId) or nil
end

--- Write this quest into the journal, placed at the moment it was completed.
function Blackacre.QuestLog.LogToJournal(questID)
    local rec = DB().quests[questID]
    -- Imported quests live in the Index only; they never become pages.
    if not rec or rec.imported then return nil end
    local existing = Blackacre.QuestLog.GetEntry(questID)
    if existing then return existing end

    rec.dayText = DayText(rec.stamp or ServerStamp())
    local title, body = Blackacre.Chronicle.Prompt.BuildQuestPage(rec)
    local now = time()
    local entry = Blackacre.Chronicle.Capture.AddPreparedEntry({
        kind = "QUEST_PAGE",
        source = "quest",
        title = title,
        body = body,
        facts = {
            questId = questID,
            questName = rec.title,
            title = title,
            promptTitle = title,
            promptBody = body,
            playerChose = true,
        },
        zoneName = rec.zone,
        yearKC = rec.yearADP or Blackacre.YearCalendar.GetPresentADP(),
        createdAt = now,
        storyAt = rec.completedAt or now,
        editedAt = now,
        pinned = false,
        tags = {},
        editable = true,
    })
    rec.entryId = entry.id
    Notify()
    return entry
end

---------------------------------------------------------------------------
-- The "Journal This" button on the quest reward panel
---------------------------------------------------------------------------

local function RefreshJournalButton(questID)
    if not journalBtn then return end
    local logged = questID and Blackacre.QuestLog.GetEntry(questID)
    journalBtn:SetText(logged and "In Journal" or "Journal This")
    journalBtn:SetEnabled(questID ~= nil and not logged)
end

local function EnsureJournalButton()
    if journalBtn then return journalBtn end
    local complete = QuestFrameCompleteQuestButton
    if not complete then return nil end
    journalBtn = CreateFrame("Button", "BlackacreJournalThisButton", complete:GetParent(), "UIPanelButtonTemplate")
    journalBtn:SetSize(120, 22)
    journalBtn:SetPoint("LEFT", complete, "RIGHT", 6, 0)
    journalBtn:SetFrameLevel((complete:GetFrameLevel() or 1) + 1)
    journalBtn:SetScript("OnClick", function(self)
        local questID = self.questID
        if not questID then return end
        local rec = Get(questID)
        -- Not turned in yet: the page is dated now, the moment of handing it over.
        rec.scene = rec.scene or Blackacre.Chronicle.Prompt.Snapshot()
        rec.stamp = rec.stamp or ServerStamp()
        Blackacre.QuestLog.LogToJournal(questID)
        RefreshJournalButton(questID)
    end)
    journalBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Journal This")
        GameTooltip:AddLine("Write this quest into your journal, with the words you were given.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    journalBtn:SetScript("OnLeave", GameTooltip_Hide)
    return journalBtn
end

---------------------------------------------------------------------------
-- Quest events
---------------------------------------------------------------------------

local function IgnoreQuest(questID)
    if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) then return true end
    if C_QuestLog.IsQuestTask and C_QuestLog.IsQuestTask(questID) then return true end
    return false
end

local function OnDetail()
    local questID = GetQuestID()
    pending.id = questID
    pending.title = GetTitleText()
    pending.text = GetQuestText()
    pending.objective = GetObjectiveText()
    pending.giver = NpcName()
    pending.followsFrom = nil
    if lastTurnIn.id and lastTurnIn.id ~= questID and pending.giver
        and pending.giver == lastTurnIn.giver and GetTime() - lastTurnIn.at <= FOLLOW_UP_WINDOW then
        pending.followsFrom = lastTurnIn.id
    end
end

local function OnAccepted(questID)
    if not questID or IgnoreQuest(questID) then return end
    local fromDetail = pending.id == questID
    local rec = Get(questID, fromDetail and pending.title or nil)
    if fromDetail then
        rec.startText = pending.text ~= "" and pending.text or rec.startText
        rec.objective = pending.objective ~= "" and pending.objective or rec.objective
        rec.giver = pending.giver or rec.giver
    end
    rec.acceptedAt = time()
    rec.level = C_QuestLog.GetQuestDifficultyLevel(questID) or rec.level
    rec.abandoned = nil
    local zone = Blackacre.GetZoneContext()
    rec.zone = zone.subzone ~= "" and zone.subzone or zone.zoneName
    rec.chain = rec.chain or ChainFor(questID, fromDetail and pending.followsFrom or nil)
    Notify()
end

local function OnProgress()
    local questID = GetQuestID()
    if not questID or questID == 0 or IgnoreQuest(questID) then return end
    local rec = Get(questID, GetTitleText())
    local text = GetProgressText()
    if text and text ~= "" then rec.progressText = text end
    rec.giverEnd = NpcName() or rec.giverEnd
end

local function OnComplete()
    local questID = GetQuestID()
    local btn = EnsureJournalButton()
    if not questID or questID == 0 or IgnoreQuest(questID) then
        if btn then btn.questID = nil; RefreshJournalButton(nil) end
        return
    end
    local rec = Get(questID, GetTitleText())
    local text = GetRewardText()
    if text and text ~= "" then rec.endText = text end
    rec.giverEnd = NpcName() or rec.giverEnd
    if btn then
        btn.questID = questID
        btn:Show()
        RefreshJournalButton(questID)
    end
end

local function OnTurnedIn(questID)
    if not questID or IgnoreQuest(questID) then return end
    local q = DB()
    local rec = Get(questID)
    if rec.completedAt then
        -- Repeatable: move it to the end of the history.
        rec.timesDone = (rec.timesDone or 1) + 1
        for i = #q.order, 1, -1 do
            if q.order[i] == questID then table.remove(q.order, i) break end
        end
    end
    q.order[#q.order + 1] = questID
    rec.completedAt = time()
    rec.level = rec.level or C_QuestLog.GetQuestDifficultyLevel(questID)
    rec.stamp = ServerStamp()
    rec.yearADP = Blackacre.YearCalendar.GetPresentADP()
    rec.scene = Blackacre.Chronicle.Prompt.Snapshot()
    rec.abandoned = nil
    local giver = rec.giverEnd or rec.giver
    lastTurnIn.id, lastTurnIn.giver, lastTurnIn.at = questID, giver, GetTime()

    local wroteFinale = Blackacre.Chronicle.Capture.OnQuestTurnedIn(questID, rec.title, rec.scene)
    local settings = Blackacre.CharDB.settings
    if not wroteFinale and settings and settings.promptEveryQuest == true then
        Blackacre.QuestLog.LogToJournal(questID)
    end
    Notify()
end

local function OnRemoved(questID)
    -- Also fires on turn-in; only a quest that was never finished counts as abandoned.
    C_Timer.After(1, function()
        local rec = DB().quests[questID]
        if rec and not rec.completedAt then
            DB().quests[questID] = nil
            Notify()
        end
    end)
end

function Blackacre.QuestLog.Init()
    DB()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_ACCEPTED")
    frame:RegisterEvent("QUEST_PROGRESS")
    frame:RegisterEvent("QUEST_COMPLETE")
    frame:RegisterEvent("QUEST_TURNED_IN")
    frame:RegisterEvent("QUEST_REMOVED")
    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "QUEST_DETAIL" then
            Blackacre.Chronicle.Prompt.CaptureGiver()
            OnDetail()
        elseif event == "QUEST_ACCEPTED" then
            OnAccepted(...)
        elseif event == "QUEST_PROGRESS" then
            Blackacre.Chronicle.Prompt.CaptureGiver()
            OnProgress()
        elseif event == "QUEST_COMPLETE" then
            Blackacre.Chronicle.Prompt.CaptureGiver()
            OnComplete()
        elseif event == "QUEST_TURNED_IN" then
            OnTurnedIn(...)
        elseif event == "QUEST_REMOVED" then
            OnRemoved(...)
        elseif event == "QUEST_DATA_LOAD_RESULT" then
            Blackacre.QuestLog.OnQuestDataLoaded(...)
        elseif event == "GOSSIP_SHOW" then
            Blackacre.Chronicle.Prompt.CaptureGiver()
        end
    end)
end

---------------------------------------------------------------------------
-- Read access for the Quest Index window
---------------------------------------------------------------------------

function Blackacre.QuestLog.Get(questID)
    return DB().quests[questID]
end

--- Completed quest ids in the order they were finished (oldest first).
function Blackacre.QuestLog.CompletedOrder()
    return DB().order
end

--- Quests accepted but not yet finished, oldest first (fills `out`).
function Blackacre.QuestLog.Underway(out)
    for i = #out, 1, -1 do out[i] = nil end
    for _, rec in pairs(DB().quests) do
        if rec.acceptedAt and not rec.completedAt then
            out[#out + 1] = rec
        end
    end
    table.sort(out, function(a, b) return (a.acceptedAt or 0) < (b.acceptedAt or 0) end)
    return out
end

--- The texts a quest has, as pages: { heading, text } pairs, filled into `out`.
function Blackacre.QuestLog.Pages(rec, out)
    for i = #out, 1, -1 do out[i] = nil end
    if rec.startText or rec.objective then
        local text = rec.startText or ""
        if rec.objective and rec.objective ~= "" then
            text = (text ~= "" and (text .. "\n\n") or "") .. "Objective: " .. rec.objective
        end
        out[#out + 1] = "Quest Start"
        out[#out + 1] = text
    end
    if rec.progressText then
        out[#out + 1] = "Progress Update"
        out[#out + 1] = rec.progressText
    end
    if rec.endText then
        out[#out + 1] = "Quest Complete"
        out[#out + 1] = rec.endText
    end
    return out
end

---------------------------------------------------------------------------
-- Import quests finished before the add-on was installed
---------------------------------------------------------------------------
-- The game knows which quests are done, but not when or in what order, and
-- not their words. Imported quests are placed by level: a lower-level quest
-- is assumed to have been done earlier. Real, dated history is never
-- reordered; imported quests slot in before the first recorded quest of a
-- higher level. They stay in the Index only and never become journal pages;
-- the estimated time between neighbors just keeps later imports in order.

local IMPORT_BATCH = 25       -- quests handled per step
local IMPORT_STEP = 0.1       -- seconds between steps (no frame hitch)
local LOAD_TIMEOUT = 10       -- seconds to wait for the game to load quest data

local importQueue, importWaiting, importDone
local importRunning = false
local importCount = 0

local function LevelOf(rec)
    if not rec.level then
        local lvl = C_QuestLog.GetQuestDifficultyLevel(rec.id)
        if lvl and lvl > 0 then rec.level = lvl end
    end
    return rec.level or 0
end

local function MakeImported(questID)
    -- Reuse a record that was left "underway" (turned in while the add-on
    -- was off) so the words it already captured are kept.
    local rec = DB().quests[questID] or { id = questID }
    local title = C_QuestLog.GetTitleForQuestID(questID)
    if title and title ~= "" then rec.title = title end
    rec.title = rec.title or ("Quest #" .. tostring(questID))
    rec.imported = true
    local lvl = C_QuestLog.GetQuestDifficultyLevel(questID)
    if lvl and lvl > 0 then rec.level = lvl end
    rec.chain = rec.chain or ChainFor(questID, nil)
    DB().quests[questID] = rec
    importCount = importCount + 1
    return rec
end

function Blackacre.QuestLog.OnQuestDataLoaded(questID)
    if importWaiting and importWaiting[questID] then
        importWaiting[questID] = nil
        MakeImported(questID)
    end
end

-- Merge imported quests into the completion order by level.
local function PlaceImported(newRecs)
    local q = DB()
    local existing = {}
    for _, id in ipairs(q.order) do
        local rec = q.quests[id]
        if rec then existing[#existing + 1] = rec end
    end
    -- Slot = number of existing quests that come before it.
    local slotOf = {}
    for _, rec in ipairs(newRecs) do
        local lvl = LevelOf(rec)
        local slot = #existing
        for i, e in ipairs(existing) do
            if LevelOf(e) > lvl then slot = i - 1 break end
        end
        slotOf[rec] = slot
    end
    table.sort(newRecs, function(a, b)
        if slotOf[a] ~= slotOf[b] then return slotOf[a] < slotOf[b] end
        local la, lb = LevelOf(a), LevelOf(b)
        if la ~= lb then return la < lb end
        return a.id < b.id
    end)

    -- Earliest real journal time, for imports that come before everything.
    local earliest = time()
    for _, e in ipairs(Blackacre.Chronicle.Store.GetAll()) do
        local t = Blackacre.Chronicle.Store.StoryTime(e)
        if t < earliest then earliest = t end
    end

    local order, n = {}, 1
    local i = 1
    for slot = 0, #existing do
        local group = {}
        while newRecs[i] and slotOf[newRecs[i]] == slot do
            group[#group + 1] = newRecs[i]
            i = i + 1
        end
        if #group > 0 then
            local prevAt = slot > 0 and existing[slot].completedAt or nil
            local nextAt = existing[slot + 1] and existing[slot + 1].completedAt or nil
            local k = #group
            for j, rec in ipairs(group) do
                if prevAt and nextAt then
                    rec.completedAt = prevAt + (nextAt - prevAt) * j / (k + 1)
                elseif nextAt then
                    rec.completedAt = math.min(nextAt, earliest) - (k - j + 1)
                elseif prevAt then
                    rec.completedAt = prevAt + j
                else
                    rec.completedAt = earliest - (k - j + 1)
                end
                order[n] = rec.id
                n = n + 1
            end
        end
        if existing[slot + 1] then
            order[n] = existing[slot + 1].id
            n = n + 1
        end
    end
    q.order = order
end

local function FinishImport()
    local newRecs = {}
    for _, rec in pairs(DB().quests) do
        if rec.imported and not rec.placed then
            rec.placed = true
            newRecs[#newRecs + 1] = rec
        end
    end
    if #newRecs > 0 then PlaceImported(newRecs) end
    importRunning = false
    Blackacre.Print(#newRecs > 0
        and ("Imported " .. #newRecs .. " earlier quest(s) into your Quest Index, ordered by level.")
        or "No earlier quests to import.")
    if importDone then importDone(#newRecs) end
    Notify()
end

local function ImportStep()
    local handled = 0
    while importQueue[1] and handled < IMPORT_BATCH do
        local questID = table.remove(importQueue)
        handled = handled + 1
        if C_QuestLog.GetTitleForQuestID(questID) then
            MakeImported(questID)
        else
            importWaiting[questID] = true
            C_QuestLog.RequestLoadQuestByID(questID)
        end
    end
    if importQueue[1] then
        C_Timer.After(IMPORT_STEP, ImportStep)
        return
    end
    -- Give the game time to answer load requests, then keep what's left
    -- under its number so nothing is silently dropped.
    C_Timer.After(next(importWaiting) and LOAD_TIMEOUT or 0, function()
        for questID in pairs(importWaiting) do MakeImported(questID) end
        importWaiting = {}
        FinishImport()
    end)
end

--- Bring in every quest the game says this character has already finished.
--- Safe to run again: known quests are skipped.
function Blackacre.QuestLog.ImportCompleted(onDone)
    if importRunning then return false end
    local known = DB().quests
    importQueue, importWaiting, importDone = {}, {}, onDone
    importCount = 0
    for _, questID in ipairs(C_QuestLog.GetAllCompletedQuestIDs() or {}) do
        local rec = known[questID]
        if not (rec and rec.completedAt) and not IgnoreQuest(questID) then
            importQueue[#importQueue + 1] = questID
        end
    end
    importRunning = true
    Blackacre.Print("Importing " .. #importQueue .. " earlier quest(s)...")
    ImportStep()
    return true
end

function Blackacre.QuestLog.IsImporting()
    return importRunning
end
