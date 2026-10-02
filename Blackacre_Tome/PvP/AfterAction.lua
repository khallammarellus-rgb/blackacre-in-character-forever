-- In Character Forever: Journal - Battle Reports

Blackacre = Blackacre or {}
Blackacre.PvP = Blackacre.PvP or {}
Blackacre.PvP.AfterAction = {}

local tonumber, type, format = tonumber, type, string.format
local C_PvP, C_Timer = C_PvP, C_Timer
local issecretvalue = issecretvalue

local pendingReport = false
local reportQueued = false
local matchWinner = nil
local frame

local function SoftToast(msg)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast(msg)
    else
        Blackacre.Print(msg)
    end
end

local function EnsureDB()
    Blackacre.CharDB.pvp = Blackacre.CharDB.pvp or {
        enabled = true,
        lastReports = {},
    }
    return Blackacre.CharDB.pvp
end

-- Score fields are secret while a match is active. A secret value can't be
-- read as a number or string here, so it counts as unknown.
local function IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

local function Num(v)
    if v == nil or IsSecret(v) then return 0 end
    return tonumber(v) or 0
end

local function Str(v, fallback)
    if v == nil or IsSecret(v) or type(v) ~= "string" then return fallback end
    return v
end

-- Our team's index (0 or 1), the same number scores and the winner use.
local function MyTeam()
    return GetBattlefieldArenaFaction and GetBattlefieldArenaFaction() or nil
end

local function GetPlayerScoreRow()
    if not (C_PvP and C_PvP.GetScoreInfoByPlayerGuid) then return nil end
    local info = C_PvP.GetScoreInfoByPlayerGuid(UnitGUID("player"))
    if not info then return nil end
    return {
        name = Str(info.name, UnitName("player")),
        killingBlows = Num(info.killingBlows),
        honorableKills = Num(info.honorableKills),
        deaths = Num(info.deaths),
        honor = Num(info.honorGained),
        faction = info.faction,
        damage = Num(info.damageDone),
        healing = Num(info.healingDone),
    }
end

local function FormatNumber(n)
    n = tonumber(n) or 0
    if n >= 1000000 then
        return format("%.1fm", n / 1000000)
    elseif n >= 1000 then
        return format("%.1fk", n / 1000)
    end
    return tostring(math.floor(n))
end

local function OutcomeForPlayer(winner)
    local team = MyTeam()
    if winner == nil or team == nil then
        return "inconclusive", "The field fell silent without a clear victor."
    end
    if winner == team then
        return "victory", "The day was won."
    end
    if winner == (team + 1) % 2 then
        return "defeat", "The day was lost — but the tale remains."
    end
    return "inconclusive", "The field fell silent without a clear victor."
end

-- Top killing-blow ally and enemy, and our side's deaths.
local function ScanTeams()
    local team = MyTeam()
    local teamDeaths = 0
    local ally, enemy, allyKB, enemyKB = nil, nil, -1, -1
    local num = GetNumBattlefieldScores and GetNumBattlefieldScores() or 0
    for i = 1, num do
        local info = C_PvP.GetScoreInfo(i)
        if info then
            local kb = Num(info.killingBlows)
            if info.faction == team then
                teamDeaths = teamDeaths + Num(info.deaths)
                if kb > allyKB then ally, allyKB = info, kb end
            elseif kb > enemyKB then
                enemy, enemyKB = info, kb
            end
        end
    end
    return teamDeaths, ally, enemy
end

local function BuildFacts(row, mapName, isArena, winner)
    local outcome, outcomeLine = OutcomeForPlayer(winner)
    local teamDeaths, ally, enemy = ScanTeams()
    local year, month, day = "this year", "this month", "this day"
    if Blackacre.YearCalendar and Blackacre.YearCalendar.JournalStamp then
        year, month, day = Blackacre.YearCalendar.JournalStamp()
    end
    local body
    if outcome == "victory" then
        body = format(
            "Let glory shine on me today at %s, not only did we make it out but we pushed the encroachers back! It was a tremendous effort today on %s, %s %s. I was inspired by a compatriot today who rallied us all, a great %s that went by the name of %s.",
            mapName or "the field",
            year, month, day,
            ally and Str(ally.className, "ally") or "ally",
            ally and Str(ally.name, "a nameless friend") or "a nameless friend"
        )
    else
        body = format(
            "I was not only witness but party to the clash at %s, I regretfully write down the misgivings of a cruel field. Steel took in measure the casualties of %d. An emboldened %s that went by the name of %s dominated the fields of strife. I held my own but it was not enough.\nDamage done: %s\nHealing done: %s\nKilling blows: %d\nHonorable kills: %d",
            mapName or "the field",
            teamDeaths,
            enemy and Str(enemy.className, "opponent") or "opponent",
            enemy and Str(enemy.name, "a nameless foe") or "a nameless foe",
            FormatNumber(row.damage),
            FormatNumber(row.healing),
            row.killingBlows,
            row.honorableKills
        )
    end
    return {
        outcome = outcome,
        outcomeLine = outcomeLine,
        mapName = mapName or "the field",
        isArena = isArena and true or false,
        damage = row.damage,
        healing = row.healing,
        deaths = row.deaths,
        killingBlows = row.killingBlows,
        damageText = FormatNumber(row.damage),
        healingText = FormatNumber(row.healing),
        pvpBody = body,
        promptBody = body,
        title = format(
            "%s — %s",
            isArena and "Arena" or "Battleground",
            outcome == "victory" and "Victory" or (outcome == "defeat" and "Defeat" or "Skirmish")
        ),
    }
end

local function StopWaiting()
    pendingReport = false
    if frame then frame:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE") end
end

function Blackacre.PvP.AfterAction.TryReport()
    reportQueued = false
    if not pendingReport then return end
    local db = EnsureDB()
    if db.enabled == false then
        StopWaiting()
        return
    end
    local winner = matchWinner
    if winner == nil and GetBattlefieldWinner then winner = GetBattlefieldWinner() end
    if winner == nil then return end
    if not GetNumBattlefieldScores or GetNumBattlefieldScores() == 0 then return end

    local row = GetPlayerScoreRow()
    if not row then return end -- scoreboard not filled yet; UPDATE_BATTLEFIELD_SCORE retries

    local mapName = GetRealZoneText and GetRealZoneText() or "the field"
    local isArena = IsActiveBattlefieldArena and IsActiveBattlefieldArena()
    local facts = BuildFacts(row, mapName, isArena, winner)
    local key = format("%s:%s:%s:%s", facts.mapName, facts.outcome, facts.damageText, facts.healingText)
    StopWaiting()
    -- Saved, so a /reload on the results screen doesn't write the page twice.
    if key == db.lastReportKey then return end
    db.lastReportKey = key

    Blackacre.Chronicle.Capture.AddEntry("PVP", facts, "auto")
    table.insert(db.lastReports, 1, { at = time(), facts = facts })
    while #db.lastReports > 20 do table.remove(db.lastReports) end
    SoftToast("After-action page written: " .. (facts.title or "PvP"))
end

-- Score updates arrive in bursts; report once per burst.
local function QueueReport(delay)
    if reportQueued then return end
    reportQueued = true
    C_Timer.After(delay, Blackacre.PvP.AfterAction.TryReport)
end

local function OnMatchComplete(winner)
    matchWinner = winner
    pendingReport = true
    frame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
    if RequestBattlefieldScoreData then RequestBattlefieldScoreData() end
    QueueReport(1)
end

function Blackacre.PvP.AfterAction.Init()
    EnsureDB()
    frame = CreateFrame("Frame")
    frame:RegisterEvent("PVP_MATCH_COMPLETE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PVP_MATCH_COMPLETE" then
            OnMatchComplete((...))
        elseif event == "UPDATE_BATTLEFIELD_SCORE" then
            QueueReport(0.5)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- A /reload on the results screen: the match is already over.
            if C_PvP and C_PvP.IsMatchComplete and C_PvP.IsMatchComplete() then
                OnMatchComplete(C_PvP.GetActiveMatchWinner and C_PvP.GetActiveMatchWinner() or nil)
            else
                matchWinner = nil
                StopWaiting()
            end
        end
    end)
end

function Blackacre.PvP.AfterAction.SetEnabled(on)
    EnsureDB().enabled = on and true or false
end
