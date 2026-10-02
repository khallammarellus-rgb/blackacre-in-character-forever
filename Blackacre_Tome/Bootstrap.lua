-- In Character Forever: Journal - Startup

Blackacre = Blackacre or {}

local DEFAULT_VOICE = {
    language = "auto",
    accent = "auto",
    applyToChronicle = true,
    applyToBulletins = false,
}

local function CopyVoice()
    local v = {}
    for k, val in pairs(DEFAULT_VOICE) do v[k] = val end
    return v
end

local function InitTome()
    -- Voice belongs to the active AceDB profile.
    local profileSettings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    if profileSettings then
        profileSettings.voice = profileSettings.voice or CopyVoice()
    else
        Blackacre.CharDB.voice = Blackacre.CharDB.voice or CopyVoice()
    end

    Blackacre.YearCalendar.EnsureIdentity()
    Blackacre.TomeHub.Init()
    Blackacre.Chronicle.Store.Init()
    Blackacre.Chronicle.Capture.Init()
    Blackacre.Chronicle.UI.Init()
    Blackacre.QuestLog.Init()
    Blackacre.Hardcore.Monitor.Init()
    Blackacre.PvP.AfterAction.Init()
end

Blackacre.RegisterPackage("Tome", InitTome)
