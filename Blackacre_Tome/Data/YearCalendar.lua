-- In Character Forever: Journal - Calendar

Blackacre = Blackacre or {}
Blackacre.YearCalendar = {}
Blackacre.YearCalendar.PORTAL_YEAR_KC = 592
Blackacre.YearCalendar.DEFAULT_PRESENT_ADP = Blackacre.Compat.PRESENT_ADP

function Blackacre.YearCalendar.EnsureIdentity()
    Blackacre.CharDB = Blackacre.CharDB or BlackacreCharDB
    Blackacre.CharDB.identity = Blackacre.CharDB.identity or {
        birthYearADP = nil,
        birthEraId = nil,
        birthPlace = "",
        presentYearADP = Blackacre.YearCalendar.DEFAULT_PRESENT_ADP,
        calendarDisplay = "AUTO",
        longevityProfile = "auto",
        originMode = "born",
        stasisUntilADP = nil,
        deathYearADP = nil,
        rebirthYearADP = nil,
    }
    local id = Blackacre.CharDB.identity
    if id.presentYearADP == nil then
        id.presentYearADP = Blackacre.YearCalendar.DEFAULT_PRESENT_ADP
    end
    -- Migrate old yearKCBase flavor into presentYearADP once
    if id.birthYearADP == nil and Blackacre.CharDB.settings and Blackacre.CharDB.settings.yearKCBase then
        -- old default 42 was already portal-ish flavor
        id.presentYearADP = Blackacre.CharDB.settings.yearKCBase or id.presentYearADP
    end
    return id
end

function Blackacre.YearCalendar.GetPresentADP()
    local id = Blackacre.YearCalendar.EnsureIdentity()
    return tonumber(id.presentYearADP) or Blackacre.YearCalendar.DEFAULT_PRESENT_ADP
end

function Blackacre.YearCalendar.SetPresentADP(year)
    local id = Blackacre.YearCalendar.EnsureIdentity()
    id.presentYearADP = tonumber(year) or Blackacre.YearCalendar.DEFAULT_PRESENT_ADP
end

function Blackacre.YearCalendar.GetBirthADP()
    local id = Blackacre.YearCalendar.EnsureIdentity()
    return id.birthYearADP ~= nil and tonumber(id.birthYearADP) or nil
end

function Blackacre.YearCalendar.SetBirthADP(year, eraId)
    local id = Blackacre.YearCalendar.EnsureIdentity()
    id.birthYearADP = tonumber(year)
    if eraId then id.birthEraId = eraId end
end

function Blackacre.YearCalendar.ToKC(yearADP)
    yearADP = tonumber(yearADP)
    if yearADP == nil then return nil end
    return Blackacre.YearCalendar.PORTAL_YEAR_KC + yearADP
end

function Blackacre.YearCalendar.FromKC(yearKC)
    yearKC = tonumber(yearKC)
    if yearKC == nil then return nil end
    return yearKC - Blackacre.YearCalendar.PORTAL_YEAR_KC
end

-- The player's own calendar (owner rule): the Alliance counts years by the
-- King's Calendar, the Horde from the Dark Portal. Returns "KC" or "ADP".
function Blackacre.YearCalendar.FactionCalendar()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Horde" then return "ADP" end
    return "KC"
end

--- One year in the player's calendar. Both calendars have a year 0.
---   King's Calendar: 0 K.C. is its first year; before it, -1 K.C., -2 K.C. ...
---   Dark Portal:     0 ADP is the year the Portal opens; the year before is
---                    -1 BDP, then -2 BDP ...
--- displayMode: nil/"AUTO" = the player's faction calendar; "KC", "ADP" or
--- "BOTH" force one.
function Blackacre.YearCalendar.FormatYearADP(yearADP, displayMode)
    yearADP = tonumber(yearADP)
    if yearADP == nil then return "?" end
    displayMode = displayMode or (Blackacre.YearCalendar.EnsureIdentity().calendarDisplay or "AUTO")
    if displayMode == "AUTO" then displayMode = Blackacre.YearCalendar.FactionCalendar() end

    local adpStr
    if yearADP < 0 then
        adpStr = string.format("%d BDP", yearADP)
    else
        adpStr = string.format("%d ADP", yearADP)
    end
    local kcStr = string.format("%d K.C.", Blackacre.YearCalendar.ToKC(yearADP))

    if displayMode == "KC" then
        return kcStr
    elseif displayMode == "BOTH" then
        return adpStr .. " · " .. kcStr
    end
    return adpStr
end

-- Back-compat for chronicle hooks that still call GetYearKC / FormatYear
--- Faction year plus the calendar month and day, for journal sentences.
function Blackacre.YearCalendar.JournalStamp()
    local year = "?"
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.FormatFactionYear then
        year = Blackacre.UI.Theme.FormatFactionYear(Blackacre.YearCalendar.GetPresentADP())
    else
        year = Blackacre.YearCalendar.FormatYearADP(Blackacre.YearCalendar.GetPresentADP(), "ADP")
    end
    local month, day = "this month", "this day"
    if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
        local t = C_DateAndTime.GetCurrentCalendarTime()
        if t and t.month then
            local names = CALENDAR_FULLDATE_MONTH_NAMES
            month = (names and names[t.month]) or tostring(t.month)
            day = tostring(t.monthDay or t.day or "")
        end
    end
    if month == "this month" then
        month = date("%B")
        day = tostring(tonumber(date("%d")) or "")
    end
    return year, month, day
end

function Blackacre.YearCalendar.GetYearKC()
    return Blackacre.YearCalendar.ToKC(Blackacre.YearCalendar.GetPresentADP())
end

function Blackacre.YearCalendar.FormatYear(year)
    -- Prefer faction-aware display (Alliance K.C. / Horde ADP only)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.FormatFactionYear then
        return Blackacre.UI.Theme.FormatFactionYear(year)
    end
    if year and year > 200 then
        local adp = Blackacre.YearCalendar.FromKC(year)
        return Blackacre.YearCalendar.FormatYearADP(adp)
    end
    return Blackacre.YearCalendar.FormatYearADP(year or Blackacre.YearCalendar.GetPresentADP())
end
