-- In Character Forever: Journal - Quest Lines

Blackacre = Blackacre or {}
Blackacre.QuestLines = Blackacre.QuestLines or {}

local function EnsureDB()
    Blackacre.CharDB = Blackacre.CharDB or {}
    Blackacre.CharDB.chronicleStory = Blackacre.CharDB.chronicleStory or {
        chains = {},
        repStanding = {},
        renown = {},
    }
    return Blackacre.CharDB.chronicleStory
end

local function QuestTitle(questID)
    local name
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        name = C_QuestLog.GetTitleForQuestID(questID)
    end
    if not name or name == "" then
        name = "Quest #" .. tostring(questID)
    end
    return name
end

local function IsComplete(questID)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(questID)
    end
    return false
end

function Blackacre.QuestLines.GetLineInfo(questID)
    if not questID or not C_QuestLine then return nil end
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local info
    if C_QuestLine.GetQuestLineInfo then
        local ok, result = pcall(C_QuestLine.GetQuestLineInfo, questID, mapID)
        if ok then info = result end
        if not info then
            ok, result = pcall(C_QuestLine.GetQuestLineInfo, questID)
            if ok then info = result end
        end
    end
    return info
end

function Blackacre.QuestLines.GetLineQuests(lineId)
    if not lineId or not C_QuestLine or not C_QuestLine.GetQuestLineQuests then
        return {}
    end
    local ok, list = pcall(C_QuestLine.GetQuestLineQuests, lineId)
    if ok and type(list) == "table" then
        return list
    end
    return {}
end

function Blackacre.QuestLines.RememberBeat(questID, questName, zoneName, scene)
    local info = Blackacre.QuestLines.GetLineInfo(questID)
    if not info then
        return nil
    end
    local lineId = info.questLineId or info.questLineID or info.id
    if not lineId then return info, nil end
    local db = EnsureDB()
    local row = db.chains[lineId] or {
        id = lineId,
        name = info.questLineName or info.name or "an unnamed road",
        quests = {},
    }
    row.name = info.questLineName or info.name or row.name
    row.quests[#row.quests + 1] = {
        id = questID,
        name = questName or QuestTitle(questID),
        zone = zoneName,
        at = time(),
        scene = scene,
    }
    db.chains[lineId] = row
    return info, row
end

--- True when every other quest in the line is already flagged complete.
function Blackacre.QuestLines.IsFinale(questID)
    local info = Blackacre.QuestLines.GetLineInfo(questID)
    if not info then return false, info, nil end
    local lineId = info.questLineId or info.questLineID or info.id
    local ids = Blackacre.QuestLines.GetLineQuests(lineId)
    if #ids == 0 then
        return false, info, lineId
    end
    for i = 1, #ids do
        local id = ids[i]
        if id ~= questID and not IsComplete(id) then
            return false, info, lineId
        end
    end
    return true, info, lineId
end

function Blackacre.QuestLines.BuildOnePager(lineId, finaleName, zoneName, snapshot)
    local db = EnsureDB()
    local row = lineId and db.chains[lineId]
    local chain = {}
    if row then
        for i = 1, #row.quests do
            local q = row.quests[i]
            if q.scene and q.scene.opening then
                chain[#chain + 1] = q.scene.opening
                if q.scene.npc then
                    chain[#chain + 1] = q.scene.npc
                end
            end
        end
    end
    local title, body
    if Blackacre.Chronicle and Blackacre.Chronicle.Prompt and Blackacre.Chronicle.Prompt.Build then
        title, body = Blackacre.Chronicle.Prompt.Build(snapshot, { chain = chain })
    else
        title = (row and row.name) or zoneName or "A road"
        body = table.concat(chain, "\n")
    end
    return title, body, {
        lineId = lineId,
        lineName = row and row.name,
        finaleName = finaleName,
        beatCount = row and #row.quests or 0,
    }
end
