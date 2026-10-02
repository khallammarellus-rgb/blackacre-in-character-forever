-- In Character Forever: Journal - Age and Origin

Blackacre = Blackacre or {}
Blackacre.Birthpath = {}

local function Identity()
    return Blackacre.YearCalendar.EnsureIdentity()
end

function Blackacre.Birthpath.GetEffectiveAge()
    local id = Identity()
    local birth = Blackacre.YearCalendar.GetBirthADP()
    if birth == nil then return nil end
    local present = Blackacre.YearCalendar.GetPresentADP()
    local chrono = present - birth

    if id.originMode == "stasis" and id.stasisUntilADP then
        local wake = tonumber(id.stasisUntilADP)
        if wake then
            -- conscious years this age since wake; pre-stasis life optional footnote
            local conscious = present - wake
            if conscious < 0 then conscious = 0 end
            return conscious, chrono, "stasis"
        end
    end
    if id.originMode == "awakened" and id.rebirthYearADP then
        local wake = tonumber(id.rebirthYearADP)
        if wake then
            return math.max(0, present - wake), chrono, "awakened"
        end
    end
    if id.originMode == "raised" and id.rebirthYearADP then
        local re = tonumber(id.rebirthYearADP)
        if re then
            return math.max(0, present - re), chrono, "raised"
        end
    end
    return chrono, chrono, id.originMode or "born"
end

function Blackacre.Birthpath.FormatAge()
    local eff, chrono, mode = Blackacre.Birthpath.GetEffectiveAge()
    if eff == nil then return "Age unknown (set birth year)" end
    local band = Blackacre.GetAgeBand(eff)
    local ageStr
    if eff >= 1000 then
        ageStr = string.format("~%d years", math.floor(eff + 0.5))
    else
        ageStr = string.format("%d years", math.floor(eff + 0.5))
    end
    if mode == "stasis" and chrono and chrono > eff + 10 then
        return string.format("%s conscious (%s) · %s chronological · %s", ageStr, band.text, Blackacre.Birthpath.FormatYears(chrono), mode)
    end
    return string.format("%s · %s", ageStr, band.text)
end

function Blackacre.Birthpath.FormatYears(n)
    n = math.floor(tonumber(n) or 0)
    if n >= 1000 then
        return string.format("~%d years", n)
    end
    return tostring(n) .. " years"
end

function Blackacre.Birthpath.GetSummary()
    local birth = Blackacre.YearCalendar.GetBirthADP()
    local present = Blackacre.YearCalendar.GetPresentADP()
    if birth == nil then
        return "No birth year set. Open Lineage (/ic birth) to begin the long count of your days."
    end
    local _, profileId = Blackacre.GetLongevityProfile()
    local profile = Blackacre.GetLongevityProfile()
    local birthEra = Blackacre.GetEraAtYear(birth)
    local presentEra = Blackacre.GetEraAtYear(present)
    local ageLine = Blackacre.Birthpath.FormatAge()
    return string.format(
        "Born %s (%s). Present %s (%s). %s. Longevity: %s.",
        Blackacre.YearCalendar.FormatYearADP(birth),
        birthEra and birthEra.name or "unknown era",
        Blackacre.YearCalendar.FormatYearADP(present),
        presentEra and presentEra.name or "present",
        ageLine,
        profile.label or profileId
    )
end

function Blackacre.Birthpath.BuildFlavor(era, year)
    local id = Identity()
    local race = UnitRace("player") or "soul"
    local place = id.birthPlace
    local eraName = era and era.name or "an unnamed age"
    local blurb = era and era.blurb or ""
    local yearBit = year and (" in the year " .. Blackacre.YearCalendar.FormatYearADP(year)) or ""
    local placeBit = (place and place ~= "") and (" at " .. place) or ""
    return string.format(
        "I, a %s, came into the world%s%s during %s. %s",
        race, yearBit, placeBit, eraName, blurb
    )
end

function Blackacre.Birthpath.RefreshFlavor()
    local id = Identity()
    local year = Blackacre.YearCalendar.GetBirthADP()
    local era = nil
    if year and Blackacre.GetEraAtYear then
        era = Blackacre.GetEraAtYear(year)
    end
    if not era and id.birthEraId and Blackacre.GetEraById then
        era = Blackacre.GetEraById(id.birthEraId)
    end
    id.lineageFlavor = Blackacre.Birthpath.BuildFlavor(era, year)
    return id.lineageFlavor
end

function Blackacre.Birthpath.GetFlavor()
    local id = Identity()
    if id.lineageFlavor and id.lineageFlavor ~= "" then
        return id.lineageFlavor
    end
    if Blackacre.YearCalendar.GetBirthADP() then
        return Blackacre.Birthpath.RefreshFlavor()
    end
    return nil
end
