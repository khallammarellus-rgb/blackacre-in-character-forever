-- Blackacre core bootstrap (Ace3).
-- AceDB owns profile settings and shareable profile records. The Tome journal
-- and feature data live in the active profile's characterData. The old
-- per-character table is retained as a recovery mirror for existing installs.

-- Hot-path upvalues (DBM-Core style): direct register reads, not global lookups.
local type, pairs, ipairs, next, tostring = type, pairs, ipairs, next, tostring
local time, GetTime, strtrim = time, GetTime, strtrim
local UnitName, GetRealmName, GetSubZoneText = UnitName, GetRealmName, GetSubZoneText
local UnitAffectingCombat, CreateFrame = UnitAffectingCombat, CreateFrame
local C_Map, C_Timer = C_Map, C_Timer

local AceAddon = LibStub("AceAddon-3.0")

Blackacre = Blackacre or {}
Blackacre.VERSION = "2.0.0-dev"
Blackacre.PREFIX = "BA_RP"
Blackacre.CHANNEL_NAME = "Blackacre"
Blackacre.SEP = "\031"
Blackacre._loadedPackages = Blackacre._loadedPackages or {}
Blackacre._pendingPackages = Blackacre._pendingPackages or {}
Blackacre._databaseReady = false

-- Locale table filled after Locales/enUS.lua loads (AceLocale).
local function L(key)
    local locale = Blackacre.L
    if locale and locale[key] then
        return locale[key]
    end
    return key
end

Blackacre.STATUS = {
    ACTIVE = "ACTIVE",
    EXPIRED = "EXPIRED",
    DRAFT = "DRAFT",
    REMOVED = "REMOVED",
}

Blackacre.SCOPE = {
    INDIVIDUAL = "INDIVIDUAL",
    GROUP = "GROUP",
    GUILD = "GUILD",
    FACTION = "FACTION",
}

-- Defaults used only when no saved data exists (new install).
local function DefaultAccountDB()
    return {
        beacons = {},
        bulletins = {},
        notices = {}, -- legacy alias migrated to bulletins
        cache = {},
        mutes = {},
        history = {},
    }
end

local function DefaultCharDB()
    return {
        residence = "",
        filters = { hardExclude = {}, softPriority = {} },
        settings = {
            noticeTTLDays = 3,
            bulletinTTLDays = 3,
            quietNotifications = false,
            yearKCBase = 42,
            yearKCOffset = 0,
            promptEveryQuest = nil,
        },
        chronicle = {
            entries = {},
        },
        gate = {
            ground = false,
            flying = false,
        },
        hardcore = {
            deathCount = 0,
            encumbranceActive = false,
            mountViolations = 0,
            flyViolations = 0,
            encumbranceViolations = 0,
        },
        survival = {
            enabled = true,
            hunger = 85,
            thirst = 85,
            exposure = 90,
            hideMeters = false,
        },
        afterlife = {
            active = nil,
            history = {},
            promptOnDeath = true,
        },
        roadmap = {
            active = nil,
            history = {},
            lockPrompts = true,
        },
        pvp = {
            enabled = true,
            lastReports = {},
        },
        identity = {
            birthYearADP = nil,
            birthEraId = nil,
            birthPlace = "",
            presentYearADP = (Blackacre.Compat and Blackacre.Compat.DefaultPresentADP and Blackacre.Compat.DefaultPresentADP()) or 42,
            calendarDisplay = "AUTO",
            longevityProfile = "auto",
            originMode = "born",
            stasisUntilADP = nil,
            deathYearADP = nil,
            rebirthYearADP = nil,
        },
        setup = {
            completed = false,
            version = 1,
        },
        presence = {
            receiveBeacons = true,
            seekingEnabled = true,
            emitEnabled = false,
            lastEmitAt = nil,
            activeBeaconId = nil,
            showNameZone = true,
            showNameProximity = true,
            savedBeacons = {},
            draftBeacon = nil,
            heardBeacons = {},
            innToastDay = {},
            lastPingByName = {},
        },
    }
end

--- One-time pull from old "In Character" SavedVariables (if still present in WTF).
--- TOC still lists InCharacterDB / InCharacterCharDB so Blizzard loads them for migration.
local function MigrateFromInCharacter()
    if type(InCharacterDB) == "table" and (not BlackacreDB or not BlackacreDB._migratedFromIC) then
        -- Prefer old data when new table is empty/unmarked
        local newEmpty = not BlackacreDB or not next(BlackacreDB) or (BlackacreDB.beacons and not next(BlackacreDB.beacons) and not BlackacreDB._migratedFromIC)
        if newEmpty or not BlackacreDB._migratedFromIC then
            BlackacreDB = InCharacterDB
            BlackacreDB._migratedFromIC = true
        end
    end
    if type(InCharacterCharDB) == "table" and (not BlackacreCharDB or not BlackacreCharDB._migratedFromIC) then
        local newEmpty = not BlackacreCharDB or not next(BlackacreCharDB) or (BlackacreCharDB.chronicle and not BlackacreCharDB._migratedFromIC)
        if newEmpty or not BlackacreCharDB._migratedFromIC then
            BlackacreCharDB = InCharacterCharDB
            BlackacreCharDB._migratedFromIC = true
        end
    end
end

MigrateFromInCharacter()

BlackacreDB = BlackacreDB or DefaultAccountDB()
BlackacreCharDB = BlackacreCharDB or DefaultCharDB()
if not BlackacreDB._migratedFromIC and type(InCharacterDB) ~= "table" then
    -- Fresh install under Blackacre name only
    BlackacreDB._migratedFromIC = true
end

-- Ace mixins: events, comms, console, timer. AceBucket is not loaded (nothing registers a bucket).
local addon = AceAddon:NewAddon("Blackacre", "AceEvent-3.0", "AceComm-3.0", "AceConsole-3.0", "AceTimer-3.0")
Blackacre.addon = addon

local function DefaultVoice()
    return {
        language = "auto",
        accent = "auto",
        applyToChronicle = true,
        applyToBulletins = false,
    }
end

-- All character-facing data is nested in this profile.  AceDB owns the
-- profile key for each character, so reloads and logouts do not require a
-- second pointer table to reconnect the character to its data.
local function DefaultProfile()
    return {
        minimap = { hide = false },
        quietNotifications = false,
        bodyFontKey = "default",
        chromeSkin = "auto",
        voice = DefaultVoice(),
        characterData = DefaultCharDB(),
    }
end

local aceDefaults = {
    profile = DefaultProfile(),
}

local function CopyTable(source)
    if type(source) ~= "table" then return source end
    local copy = {}
    for key, value in pairs(source) do
        copy[CopyTable(key)] = CopyTable(value)
    end
    return copy
end

-- AceDB profile.characterData is the canonical feature store. The old
-- per-character table remains as a compatibility mirror and carries the
-- explicit profile pointer, so older installs can be repaired without
-- replacing the active profile or erasing pages.
local function EnsureTomeChronicle(profile, importCharacterData)
    BlackacreCharDB = BlackacreCharDB or {}
    local legacyChronicle = BlackacreCharDB.chronicle
    local profileData = profile and profile.characterData
    if type(profileData) ~= "table" then
        return type(legacyChronicle) == "table" and legacyChronicle or { entries = {} }
    end

    local target = profileData.chronicle
    if type(target) ~= "table" then
        if importCharacterData and type(legacyChronicle) == "table" then
            target = legacyChronicle
        else
            target = { entries = {} }
        end
    end
    target.entries = target.entries or {}

    local function MergeEntries(source)
        local sourceEntries = source and source.entries
        if type(sourceEntries) ~= "table" or source == target then return end
        local byID = {}
        for _, entry in ipairs(target.entries) do
            if type(entry) == "table" and entry.id then
                byID[entry.id] = entry
            end
        end
        for _, entry in ipairs(sourceEntries) do
            if type(entry) == "table" then
                local existing = entry.id and byID[entry.id]
                if not existing then
                    local copy = CopyTable(entry)
                    target.entries[#target.entries + 1] = copy
                    if copy.id then byID[copy.id] = copy end
                elseif (entry.editedAt or 0) > (existing.editedAt or 0) then
                    for key in pairs(existing) do existing[key] = nil end
                    for key, value in pairs(entry) do existing[key] = CopyTable(value) end
                end
            end
        end
    end

    -- Import the old per-character journal only during the initial bind. A
    -- later manual profile switch must not copy the previous profile's pages.
    if importCharacterData then
        MergeEntries(legacyChronicle)
    end
    profileData.chronicle = target
    BlackacreCharDB.chronicle = target
    return target
end

local RefreshProfileViews

local function CharacterProfileName()
    local name = UnitName("player") or "Character"
    local scope = Blackacre.Compat and Blackacre.Compat.GetProfileScope
        and Blackacre.Compat.GetProfileScope() or (GetRealmName and GetRealmName() or "Realm")
    return name .. " - " .. scope
end

local function ProfileBelongsToCurrentCharacter(profileName)
    if type(profileName) ~= "string" then return false end
    local name = UnitName("player")
    if type(name) ~= "string" or name == "" then return false end
    return profileName == name or profileName:sub(1, #name + 3) == name .. " - "
end

local function ProfileHasCharacterData(profile)
    return type(profile) == "table" and type(profile.characterData) == "table"
        and next(profile.characterData) ~= nil
end

local function EnsureActiveProfile()
    local profile = Blackacre.db and Blackacre.db.profile
    if not profile then return nil end
    profile.minimap = profile.minimap or { hide = false }
    if profile.minimap.hide == nil then profile.minimap.hide = false end
    if profile.quietNotifications == nil then profile.quietNotifications = false end
    if profile.bodyFontKey == nil then profile.bodyFontKey = "default" end
    if profile.chromeSkin == nil then profile.chromeSkin = "auto" end
    profile.voice = profile.voice or DefaultVoice()
    profile.characterData = profile.characterData or DefaultCharDB()
    return profile
end

local function BindAceProfile(importCharacterData)
    local profile = EnsureActiveProfile()
    if not profile then return false end
    Blackacre.Profile = profile
    Blackacre.ActiveProfileID = Blackacre.db:GetCurrentProfile()
    Blackacre.CharDB = profile.characterData
    EnsureTomeChronicle(profile, importCharacterData)
    return true
end

-- AceDB stores the mapping in account SavedVariables. Keep a small explicit
-- per-character pointer as well, following the profile/character split used
-- by TRP3. This protects a manual profile choice during migration and gives
-- us a recovery path if a client writes a stale profileKeys entry.
local function RestoreExplicitProfilePointer(db)
    if type(BlackacreCharDB) ~= "table"
        or BlackacreCharDB._profilePointerVersion ~= 1 then
        return false
    end
    local profileName = BlackacreCharDB._activeProfileID
    if type(profileName) ~= "string" or type(db.profiles[profileName]) ~= "table" then
        return false
    end
    if db:GetCurrentProfile() ~= profileName then
        db:SetProfile(profileName)
    end
    return true
end

-- AceDB's native key includes GetRealmName(). Forever test realms can change
-- that suffix between builds, leaving the old profile orphaned under the
-- previous key. Recover it by matching the stable player-name prefix when the
-- per-character pointer is unavailable.
local function RestoreProfileByCharacterName(db)
    if not db or type(BlackacreAceDB) ~= "table"
        or type(BlackacreAceDB.profileKeys) ~= "table" then
        return false
    end
    local playerName = UnitName("player")
    if type(playerName) ~= "string" or playerName == "" then return false end
    local prefix = playerName .. " - "
    local candidate
    for storedKey, profileName in pairs(BlackacreAceDB.profileKeys) do
        if type(storedKey) == "string"
            and (storedKey == playerName or storedKey:sub(1, #prefix) == prefix)
            and type(profileName) == "string" and type(db.profiles[profileName]) == "table" then
            if candidate and candidate ~= profileName then
                -- More than one ruleset/realm used this character name. Keep
                -- the current profile selection rather than guessing.
                return false
            end
            candidate = profileName
        end
    end
    if not candidate then return false end
    if db:GetCurrentProfile() ~= candidate then
        db:SetProfile(candidate)
    end
    return true
end

local function SaveExplicitProfilePointer(profileName)
    if type(profileName) ~= "string" then return end
    -- Update only the pointer. Replacing this table used to erase the
    -- character-owned Chronicle pages whenever a profile was created or
    -- selected.
    BlackacreCharDB = BlackacreCharDB or {}
    BlackacreCharDB._migratedFromIC = true
    BlackacreCharDB._profilePointerVersion = 1
    BlackacreCharDB._activeProfileID = profileName
end

local function UniqueAceProfileName(base, db)
    base = tostring(base or "Profile")
    local name = base
    local suffix = 2
    while db.profiles[name] do
        name = base .. " (" .. suffix .. ")"
        suffix = suffix + 1
    end
    return name
end

-- Convert the previous custom profile records into ordinary AceDB profiles.
-- This runs only once and leaves the old table intact as a recovery copy.
local function ImportLegacyProfiles(db)
    local legacy = type(BlackacreProfiles) == "table" and BlackacreProfiles.profiles
    if type(legacy) ~= "table" or BlackacreProfiles._aceDBMigrated then
        return nil
    end

    local requestedID = type(BlackacreCharDB) == "table" and BlackacreCharDB._activeProfileID
    local requestedName
    local onlyName
    local validCount = 0
    local characterName = CharacterProfileName()

    for id, record in pairs(legacy) do
        if type(record) == "table" and type(record.data) == "table" then
            validCount = validCount + 1
            local baseName = type(record.name) == "string" and record.name or tostring(id)
            local profileName = db.profiles[baseName] and baseName ~= db:GetCurrentProfile()
                and UniqueAceProfileName(baseName, db) or baseName
            local target = db.profiles[profileName]
            if not ProfileHasCharacterData(target) then
                target = CopyTable(record.settings or {})
                target.characterData = CopyTable(record.data)
                if not target.voice and target.characterData.voice then
                    target.voice = CopyTable(target.characterData.voice)
                end
                target.characterData.voice = nil
                db.profiles[profileName] = target
            end
            record._aceDBProfileName = profileName
            if id == requestedID then requestedName = profileName end
            if record.name == characterName or ProfileBelongsToCurrentCharacter(record.name) then
                requestedName = profileName
            end
            if validCount == 1 then onlyName = profileName end
        end
    end

    if not requestedName and validCount == 1 then requestedName = onlyName end
    BlackacreProfiles._aceDBMigrated = true
    return requestedName
end

local function BindLegacyCharacterProfile(db)
    local legacy = type(BlackacreProfiles) == "table" and BlackacreProfiles.profiles
    local legacyID = type(BlackacreCharDB) == "table" and BlackacreCharDB._activeProfileID
    local record = type(legacy) == "table" and type(legacyID) == "string" and legacy[legacyID]
    local profileName = record and (record._aceDBProfileName or record.name)
    if type(profileName) ~= "string" or not db.profiles[profileName] then return false end
    if db:GetCurrentProfile() ~= profileName then
        db:SetProfile(profileName)
    end
    return true
end

local function EnsureCharacterDefaultProfile(db)
    -- Earlier Blackacre builds passed `true` to AceDB, making every character
    -- use the shared "Default" profile.  Split that legacy choice into the
    -- normal AceDB character profile before seeding old character data.
    if db:GetCurrentProfile() ~= "Default" then return end
    local characterName = CharacterProfileName()
    if characterName == "Default" then return end
    if not db.profiles[characterName] then
        db.profiles[characterName] = CopyTable(db.profiles.Default or {})
    end
    db:SetProfile(characterName)
end

local function SeedFromLegacyCharDB(db)
    local rawProfile = db.profiles[db:GetCurrentProfile()]
    if type(rawProfile) ~= "table" or type(BlackacreCharDB) ~= "table" then return end

    local legacyData = CopyTable(BlackacreCharDB)
    legacyData._activeProfileID = nil
    legacyData._profilePointerVersion = nil
    legacyData._migratedFromIC = nil
    if rawProfile.voice == nil and type(legacyData.voice) == "table" then
        rawProfile.voice = CopyTable(legacyData.voice)
    end
    legacyData.voice = nil

    rawProfile.characterData = rawProfile.characterData or {}
    local function MergeMissing(target, source)
        for key, value in pairs(source) do
            if key ~= "chronicle" then
                if target[key] == nil then
                    target[key] = value
                elseif type(target[key]) == "table" and type(value) == "table" then
                    MergeMissing(target[key], value)
                end
            end
        end
    end
    if next(legacyData) then
        -- Chronicle has timestamp-aware merging in EnsureTomeChronicle.
        -- Other feature tables only fill fields missing from the AceDB copy.
        MergeMissing(rawProfile.characterData, legacyData)
    end
end

local function ClearLegacyCharDB()
    -- Keep the migration marker, compatibility mirror, and explicit pointer.
    BlackacreCharDB = BlackacreCharDB or {}
    BlackacreCharDB._migratedFromIC = true
    -- The pointer is now written for every character after AceDB has resolved
    -- its profile, so a later realm-name change still has a stable recovery
    -- target on the next login.
    BlackacreCharDB._profilePointerVersion = 1
    BlackacreCharDB._activeProfileID = Blackacre.ActiveProfileID
end

-- Forever beta has had SavedVariables load timing regressions.  AceDB keeps a
-- reference to the table it receives in :New(); if the client replaces the
-- global after that call, the DB object can remain attached to an empty table
-- while the loaded global still contains the user's data. Recreate the object
-- once at PLAYER_LOGIN, when all globals are unquestionably available.
-- Only when the global really was swapped (or `force` from /ba storage):
-- rebuilding unconditionally strands any module that already holds the old
-- profile tables, and whatever it writes afterwards is never saved.
local function RebindAceDatabase(addon, force)
    if type(BlackacreAceDB) ~= "table" then return false end
    if not force and addon.db and addon.db.sv == BlackacreAceDB then
        return false
    end

    local aceDB = LibStub("AceDB-3.0")
    if addon.db and aceDB.db_registry then
        aceDB.db_registry[addon.db] = nil
    end

    addon.db = aceDB:New("BlackacreAceDB", aceDefaults, CharacterProfileName())
    Blackacre.db = addon.db

    BindLegacyCharacterProfile(addon.db)
    EnsureCharacterDefaultProfile(addon.db)
    if not RestoreExplicitProfilePointer(addon.db) then
        RestoreProfileByCharacterName(addon.db)
    end
    SeedFromLegacyCharDB(addon.db)
    BindAceProfile(true)
    SaveExplicitProfilePointer(Blackacre.ActiveProfileID)
    return true
end

function Blackacre.GetProfileSettings()
    return Blackacre.db and Blackacre.db.profile or nil
end

function Blackacre.GetProfiles()
    local list = {}
    if not Blackacre.db then return list end
    local seen = {}
    for name in pairs(Blackacre.db.profiles or {}) do
        if type(name) == "string" then
            seen[name] = true
            list[#list + 1] = { id = name, name = name }
        end
    end
    local current = Blackacre.db:GetCurrentProfile()
    if type(current) == "string" and not seen[current] then
        list[#list + 1] = { id = current, name = current }
    end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

function Blackacre.CreateProfile(name)
    name = strtrim(name or "")
    if name == "" or #name > 48 or not Blackacre.db then return nil end
    if Blackacre.db.profiles[name] or name == Blackacre.db:GetCurrentProfile() then return nil end
    Blackacre.db.profiles[name] = CopyTable(Blackacre.db.profile)
    Blackacre.db:SetProfile(name)
    BindAceProfile()
    SaveExplicitProfilePointer(name)
    if RefreshProfileViews then RefreshProfileViews() end
    LibStub("AceConfigRegistry-3.0"):NotifyChange("Blackacre")
    return { id = name, name = name }
end

function Blackacre.SetActiveProfile(id)
    if not Blackacre.db or type(id) ~= "string" then return false end
    if id ~= Blackacre.db:GetCurrentProfile() and not Blackacre.db.profiles[id] then
        return false
    end
    if id ~= Blackacre.db:GetCurrentProfile() then
        Blackacre.db:SetProfile(id)
    end
    BindAceProfile()
    SaveExplicitProfilePointer(id)
    if RefreshProfileViews then RefreshProfileViews() end
    LibStub("AceConfigRegistry-3.0"):NotifyChange("Blackacre")
    return true
end

RefreshProfileViews = function(silent)
    local theme = Blackacre.UI and Blackacre.UI.Theme
    if theme and theme.LoadBodyFontFromDB then theme.LoadBodyFontFromDB(silent) end
    if theme and theme.RefreshChrome then theme.RefreshChrome() end
    if Blackacre.MinimapButton and Blackacre.MinimapButton.Refresh then Blackacre.MinimapButton.Refresh() end
    local function Refresh(target)
        if target and type(target.Refresh) == "function" then target.Refresh() end
    end
    Refresh(Blackacre.Chronicle and Blackacre.Chronicle.UI)
    Refresh(Blackacre.Afterlife and Blackacre.Afterlife.UI)
    Refresh(Blackacre.Roadmap and Blackacre.Roadmap.UI)
    Refresh(Blackacre.Survival and Blackacre.Survival.UI)
    Refresh(Blackacre.Hardcore and Blackacre.Hardcore.UI)
    Refresh(Blackacre.LineageUI)
    Refresh(Blackacre.PathUI)
end

--- Child packages call this after their files load (RequiredDeps: Blackacre).
--- They must wait until the core has bound AceDB, because a child package can
--- otherwise create a temporary empty CharDB during TOC loading.
function Blackacre.RegisterPackage(name, initFn)
    if not name or not initFn then return end
    if Blackacre._loadedPackages[name] then return end
    if not Blackacre._databaseReady then
        Blackacre._pendingPackages[name] = initFn
        return
    end
    Blackacre._loadedPackages[name] = true
    initFn()
end

function Blackacre.InitializePackages()
    local pending = Blackacre._pendingPackages
    Blackacre._pendingPackages = {}
    local names = {}
    for name in pairs(pending) do
        names[#names + 1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
        if not Blackacre._loadedPackages[name] then
            Blackacre._loadedPackages[name] = true
            pending[name]()
        end
    end
end

function Blackacre.HasPackage(name)
    return Blackacre._loadedPackages[name] == true
end

function Blackacre.NewID()
    return string.format("%08x%04x", time(), math.random(0, 0xFFFF))
end

-- Map APIs are not free. Many callers ask in the same moment (tick, tooltip, proximity).
-- Reuse one snapshot for a short window, but always return a fresh coords table:
-- beacons store coords, and must not alias the live snapshot.
local zoneSnap = { zoneId = 0, subzone = "", zoneName = "", x = 0, y = 0 }
local zoneSnapAt = -1000

local zoneWatch = CreateFrame("Frame")
zoneWatch:RegisterEvent("ZONE_CHANGED")
zoneWatch:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneWatch:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneWatch:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneWatch:SetScript("OnEvent", function()
    zoneSnapAt = -1000
    zoneSnap.zoneId = 0
end)

function Blackacre.GetZoneContext()
    local now = GetTime()
    -- Don't pin a failed lookup (map id 0 during load) for the whole window.
    if zoneSnap.zoneId == 0 or (now - zoneSnapAt) > 0.25 then
        zoneSnapAt = now
        local mapID
        if C_Map and C_Map.GetBestMapForUnit then
            mapID = C_Map.GetBestMapForUnit("player")
        end
        zoneSnap.zoneId = mapID or 0
        zoneSnap.subzone = GetSubZoneText() or ""
        zoneSnap.zoneName = ""
        if mapID and C_Map.GetMapInfo then
            local info = C_Map.GetMapInfo(mapID)
            zoneSnap.zoneName = (info and info.name) or ""
        end
        zoneSnap.x, zoneSnap.y = 0, 0
        if mapID and C_Map.GetPlayerMapPosition then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos and pos.GetXY then
                local x, y = pos:GetXY()
                zoneSnap.x = x or 0
                zoneSnap.y = y or 0
            end
        end
    end
    return {
        zoneId = zoneSnap.zoneId,
        subzone = zoneSnap.subzone,
        zoneName = zoneSnap.zoneName,
        coords = { x = zoneSnap.x, y = zoneSnap.y },
    }
end

-- One watcher for "the player is walking" work (boards, beacon distance).
-- Idle players pay nothing. Clients without the move events fall back to a slow tick.
local moveCallbacks = {}
local moveTicker
local moveFrame

local function RunMoveCallbacks()
    for i = 1, #moveCallbacks do
        moveCallbacks[i]()
    end
end

function Blackacre.OnPlayerMove(callback)
    if type(callback) ~= "function" then return end
    moveCallbacks[#moveCallbacks + 1] = callback
    if moveFrame then return end
    moveFrame = CreateFrame("Frame")
    local startedOK = pcall(moveFrame.RegisterEvent, moveFrame, "PLAYER_STARTED_MOVING")
    local stoppedOK = pcall(moveFrame.RegisterEvent, moveFrame, "PLAYER_STOPPED_MOVING")
    if not startedOK or not stoppedOK then
        moveFrame:UnregisterAllEvents()
        C_Timer.NewTicker(10, RunMoveCallbacks)
        return
    end
    moveFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_STOPPED_MOVING" then
            if moveTicker then
                moveTicker:Cancel()
                moveTicker = nil
            end
            RunMoveCallbacks()
            return
        end
        RunMoveCallbacks()
        if not moveTicker then
            moveTicker = C_Timer.NewTicker(2, RunMoveCallbacks)
        end
    end)
end

function Blackacre.IsMuted(ownerGUID)
    return BlackacreDB.mutes[ownerGUID] == true
end

function Blackacre.GetCharName()
    if Blackacre.TRP3Bridge and Blackacre.TRP3Bridge.IsAvailable and Blackacre.TRP3Bridge.IsAvailable() then
        local trpName = Blackacre.TRP3Bridge.GetCharacterName()
        if trpName and trpName ~= "" then
            return trpName
        end
    end
    return UnitName("player")
end

function Blackacre.Print(msg)
    local prefix = L("PRINT_PREFIX")
    if prefix == "PRINT_PREFIX" then
        prefix = "|cffc9a227Blackacre:|r "
    end
    print(prefix .. msg)
end

local function NeedPackage(pkg, feature)
    local fmt = L("NEED_PACKAGE")
    if fmt == "NEED_PACKAGE" then
        fmt = "%s requires the |cffc9a227%s|r package (enable it in AddOns)."
    end
    Blackacre.Print(string.format(fmt, feature, pkg))
end

function addon:OnInitialize()
    -- Locale (enUS is default true in NewLocale)
    Blackacre.L = LibStub("AceLocale-3.0"):GetLocale("Blackacre", true)

    -- Re-run migration in case SavedVariables finished loading after file parse
    MigrateFromInCharacter()
    BlackacreDB = BlackacreDB or DefaultAccountDB()
    BlackacreCharDB = BlackacreCharDB or DefaultCharDB()
    BlackacreProfiles = BlackacreProfiles or {}
    BlackacreProfiles.profiles = BlackacreProfiles.profiles or {}

    Blackacre.DB = BlackacreDB

    -- AceDB owns the account-wide profile records. Manual profile changes also
    -- write the explicit per-character pointer below, so the active profile is
    -- restored even if a client writes a stale profileKeys entry.
    -- The third argument is a default profile name, not `true`: true means
    -- the shared AceDB profile named Default. Forever has rulesets rather
    -- than user-facing realms, so seed new characters with our stable scope
    -- and then let the saved pointer/manual selection take precedence.
    self.db = LibStub("AceDB-3.0"):New("BlackacreAceDB", aceDefaults, CharacterProfileName())
    Blackacre.db = self.db

    local migratedProfileName = ImportLegacyProfiles(self.db)
    if migratedProfileName and migratedProfileName ~= self.db:GetCurrentProfile() then
        self.db:SetProfile(migratedProfileName)
    end
    BindLegacyCharacterProfile(self.db)
    EnsureCharacterDefaultProfile(self.db)
    if not RestoreExplicitProfilePointer(self.db) then
        RestoreProfileByCharacterName(self.db)
    end
    -- Older installs without BlackacreProfiles still have their data in the
    -- per-character table. Seed the current AceDB profile once before clearing
    -- that stale duplicate.
    SeedFromLegacyCharDB(self.db)
    BindAceProfile(true)
    -- Persist the resolved profile immediately.  If a later optional setup
    -- hook fails, the next login still has the character's recovery target.
    SaveExplicitProfilePointer(Blackacre.ActiveProfileID)

    local profileSettings = Blackacre.GetProfileSettings()
    if type(Blackacre.CharDB.voice) == "table" and profileSettings.voice == nil then
        profileSettings.voice = CopyTable(Blackacre.CharDB.voice)
    end
    -- Voice is profile settings, not a second character-data copy.
    Blackacre.CharDB.voice = nil
    -- Preserve earlier character-scoped settings when creating its first profile.
    if Blackacre.CharDB.settings and Blackacre.CharDB.settings.quietNotifications ~= nil and profileSettings.quietNotifications == false then
        profileSettings.quietNotifications = Blackacre.CharDB.settings.quietNotifications and true or false
    end
    -- Prefer AceDB minimap hide over legacy BlackacreDB.minimap if both exist
    if BlackacreDB.minimap and BlackacreDB.minimap.hide ~= nil and profileSettings.minimap then
        -- one-way: first AceDB profile inherits old hide flag
        if profileSettings.minimap.hide == false and BlackacreDB.minimap.hide then
            profileSettings.minimap.hide = true
        end
    end

    ClearLegacyCharDB()

    Blackacre._databaseReady = true
    Blackacre.InitializePackages()

    if Blackacre.Options and Blackacre.Options.Init then
        Blackacre.Options.Init(self)
    end

    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.LoadBodyFontFromDB then
        Blackacre.UI.Theme.LoadBodyFontFromDB()
    end

    -- Core only — Presence / Tome / Survival self-init via RegisterPackage
    Blackacre.Comms.Init(self)
    Blackacre.Lifecycle.Init()
    Blackacre.History.Init()
    Blackacre.MinimapButton.Init()
end

function addon:OnEnable()
    RebindAceDatabase(self)
    Blackacre.Comms.Enable()
    -- Packages build their UI during ADDON_LOADED; refresh once at login after
    -- all child packages are ready and the account-wide character profile is bound.
    RefreshProfileViews(true)
end

-- Primary: /ba and /blackacre. Alias: /ic (old In Character muscle memory).
SLASH_BLACKACRE1 = "/ba"
SLASH_BLACKACRE2 = "/blackacre"
SLASH_BLACKACRE3 = "/ic"
SlashCmdList["BLACKACRE"] = function(msg)
    local rawMsg = strtrim(msg or "")
    msg = rawMsg:lower()
    if msg == "storage" then
        local function CountEntries(db)
            local entries = db and db.chronicle and db.chronicle.entries
            return type(entries) == "table" and #entries or 0
        end
        local active = Blackacre.db and Blackacre.db.profile
        local current = Blackacre.db and Blackacre.db:GetCurrentProfile() or "(unavailable)"
        local profileEntries = CountEntries(active and active.characterData)
        local rawProfile = BlackacreAceDB and BlackacreAceDB.profiles and BlackacreAceDB.profiles[current]
        local rawEntries = CountEntries(rawProfile and rawProfile.characterData)
        local backingProfile = Blackacre.db and Blackacre.db.sv and Blackacre.db.sv.profiles
            and Blackacre.db.sv.profiles[current]
        local backingEntries = CountEntries(backingProfile and backingProfile.characterData)
        local characterEntries = CountEntries(BlackacreCharDB)
        local pointer = BlackacreCharDB and BlackacreCharDB._activeProfileID
        local bindingMismatch = profileEntries == 0 and (
            rawEntries > 0 or backingEntries > 0 or characterEntries > 0
            or (type(pointer) == "string" and pointer ~= current)
        )
        if bindingMismatch then
            RebindAceDatabase(addon, true)
            active = Blackacre.db and Blackacre.db.profile
            current = Blackacre.db and Blackacre.db:GetCurrentProfile() or "(unavailable)"
            profileEntries = CountEntries(active and active.characterData)
            rawProfile = BlackacreAceDB and BlackacreAceDB.profiles and BlackacreAceDB.profiles[current]
            rawEntries = CountEntries(rawProfile and rawProfile.characterData)
            backingProfile = Blackacre.db and Blackacre.db.sv and Blackacre.db.sv.profiles
                and Blackacre.db.sv.profiles[current]
            backingEntries = CountEntries(backingProfile and backingProfile.characterData)
            characterEntries = CountEntries(BlackacreCharDB)
        end
        local listedEntries = characterEntries
        local newestTitle = "(none)"
        local newestBodyChars = 0
        if Blackacre.Chronicle and Blackacre.Chronicle.Store and Blackacre.Chronicle.Store.List then
            local ok, entries = pcall(Blackacre.Chronicle.Store.List, {})
            if ok and type(entries) == "table" then
                listedEntries = #entries
                if entries[1] then
                    newestTitle = tostring(entries[1].title or "(untitled)")
                    newestBodyChars = #(tostring(entries[1].body or ""))
                end
            end
        end
        local voice = active and active.voice or {}
        Blackacre.Print(string.format(
            "Storage: profile=%s; profile pages=%d; character pages=%d; journal list=%d; newest=%s; body chars=%d",
            tostring(current), profileEntries, characterEntries, listedEntries, newestTitle, newestBodyChars))
        Blackacre.Print(string.format(
            "Binding: global profile pages=%d; AceDB backing pages=%d; same table=%s",
            rawEntries, backingEntries,
            tostring(active and rawProfile and active.characterData == rawProfile.characterData)))
        Blackacre.Print(string.format("Saved preferences: skin=%s; font=%s; voice=%s/%s",
            tostring(active and active.chromeSkin or "(none)"),
            tostring(active and active.bodyFontKey or "(none)"),
            tostring(voice.language or "(default)"),
            tostring(voice.accent or "(default)")))
        local flavor = Blackacre.Compat and Blackacre.Compat.GetFlavor and Blackacre.Compat.GetFlavor() or {}
        local charKey = (UnitName("player") or "(unknown)") .. " - " .. (GetRealmName and GetRealmName() or "(unknown realm)")
        local profileScope = Blackacre.Compat and Blackacre.Compat.GetProfileScope
            and Blackacre.Compat.GetProfileScope() or "(unknown scope)"
        local knownKeys = {}
        for key in pairs(BlackacreAceDB and BlackacreAceDB.profileKeys or {}) do
            knownKeys[#knownKeys + 1] = tostring(key)
        end
        table.sort(knownKeys)
        Blackacre.Print(string.format(
            "Runtime: flavor=%s/%s; aceKey=%s; scope=%s; pointer=%s; profileKeys=%s",
            tostring(flavor.version or "?"), tostring(flavor.interface or "?"), charKey,
            tostring(profileScope),
            tostring(BlackacreCharDB and BlackacreCharDB._activeProfileID or "(none)"),
            #knownKeys > 0 and table.concat(knownKeys, " | ") or "(none)"))
    elseif msg == "profile" or msg == "profiles" or msg:match("^profile%s+") then
        local target = rawMsg:match("^%S+%s+(.+)$")
        if target and target ~= "" then
            local resolved = target
            for _, profile in ipairs(Blackacre.GetProfiles()) do
                if profile.name:lower() == target:lower() then
                    resolved = profile.id
                    break
                end
            end
            if Blackacre.SetActiveProfile(resolved) then
                Blackacre.Print("Active profile: " .. resolved)
            else
                Blackacre.Print("Profile not found: " .. target)
            end
        else
            local current = Blackacre.db and Blackacre.db:GetCurrentProfile() or "(unavailable)"
            local names = {}
            for _, profile in ipairs(Blackacre.GetProfiles()) do
                names[#names + 1] = profile.name
            end
            Blackacre.Print("Active profile: " .. current .. " | Available: " .. (#names > 0 and table.concat(names, ", ") or "(none)"))
        end
    elseif msg == "ping" then
        Blackacre.Comms.SendPing()
    elseif msg == "beacon" then
        if Blackacre.PostEditor and Blackacre.PostEditor.ShowBeaconEditor then
            Blackacre.PostEditor.ShowBeaconEditor()
        else
            NeedPackage("Blackacre Presence", "Beacons")
        end
    elseif msg == "bulletin" then
        if Blackacre.PostEditor and Blackacre.PostEditor.ShowBulletinEditor then
            Blackacre.PostEditor.ShowBulletinEditor()
        else
            NeedPackage("Blackacre Presence", "Bulletins")
        end
    elseif msg == "history" then
        Blackacre.History.Show()
    elseif msg == "tome" or msg == "chronicle" or msg == "log" or msg == "journal" then
        if Blackacre.TomeHub and Blackacre.TomeHub.Toggle then
            Blackacre.TomeHub.Toggle(msg == "tome" and nil or "chronicle")
        elseif Blackacre.Chronicle and Blackacre.Chronicle.UI then
            Blackacre.Chronicle.UI.Toggle()
        else
            NeedPackage("Blackacre Tome", "The Tome")
        end
    elseif msg == "setup" or msg == "tutorial" or msg == "onboard" then
        if Blackacre.SetupWizard and Blackacre.SetupWizard.Show then
            Blackacre.SetupWizard.Show()
        else
            NeedPackage("Blackacre Tome", "Setup")
        end
    elseif msg == "voice" or msg == "accent" then
        if Blackacre.TomeHub and Blackacre.TomeHub.Show then
            Blackacre.TomeHub.Show("voice")
        else
            NeedPackage("Blackacre Tome", "Voice")
        end
    elseif msg == "sample" then
        if Blackacre.Chronicle and Blackacre.Chronicle.Capture then
            Blackacre.Chronicle.Capture.DebugAddSample()
        else
            NeedPackage("Blackacre Tome", "Chronicle")
        end
    elseif msg == "hardcore" or msg == "gates" or msg == "hc" then
        if Blackacre.TomeHub and Blackacre.TomeHub.Show then
            Blackacre.TomeHub.Show("honor")
        elseif Blackacre.Hardcore and Blackacre.Hardcore.UI then
            Blackacre.Hardcore.UI.Toggle()
        else
            NeedPackage("Blackacre Tome", "Hardcore")
        end
    elseif msg == "tools" or msg == "toolbox" then
        if Blackacre.ToolBox and Blackacre.ToolBox.Toggle then
            Blackacre.ToolBox.Toggle()
        end
    elseif msg == "survival" or msg == "meters" or msg == "condition" then
        if Blackacre.Survival and Blackacre.Survival.UI then
            Blackacre.Survival.UI.Toggle()
        else
            NeedPackage("Blackacre Survival", "Survival")
        end
    elseif msg == "eat" then
        if Blackacre.Survival and Blackacre.Survival.Engine then
            Blackacre.Survival.Engine.Recover("eat", 22)
        else
            NeedPackage("Blackacre Survival", "Survival")
        end
    elseif msg == "drink" then
        if Blackacre.Survival and Blackacre.Survival.Engine then
            Blackacre.Survival.Engine.Recover("drink", 22)
        else
            NeedPackage("Blackacre Survival", "Survival")
        end
    elseif msg == "rest" then
        if not (Blackacre.Survival and Blackacre.Survival.Engine) then
            NeedPackage("Blackacre Survival", "Survival")
        elseif UnitAffectingCombat and UnitAffectingCombat("player") then
            Blackacre.Print("Recover is unavailable in combat")
        else
            Blackacre.Survival.Engine.Recover("rest", 18)
        end
    elseif msg == "survival off" then
        if Blackacre.Survival and Blackacre.Survival.Engine then
            Blackacre.Survival.Engine.SetEnabled(false)
            Blackacre.Print("Survival meters disabled for this character.")
            if Blackacre.Survival.UI then Blackacre.Survival.UI.Refresh() end
        else
            NeedPackage("Blackacre Survival", "Survival")
        end
    elseif msg == "survival on" then
        if Blackacre.Survival and Blackacre.Survival.Engine then
            Blackacre.Survival.Engine.SetEnabled(true)
            Blackacre.Print("Survival meters enabled.")
            if Blackacre.Survival.UI then Blackacre.Survival.UI.ShowPanel() end
        else
            NeedPackage("Blackacre Survival", "Survival")
        end
    elseif msg == "afterlife" or msg == "death" or msg == "return" then
        if Blackacre.TomeHub and Blackacre.TomeHub.Show then
            Blackacre.TomeHub.Show("realms")
        elseif Blackacre.Afterlife and Blackacre.Afterlife.UI then
            Blackacre.Afterlife.UI.Toggle()
        else
            NeedPackage("Blackacre Tome", "Afterlife")
        end
    elseif msg == "realms" then
        if Blackacre.TomeHub and Blackacre.TomeHub.Show then
            Blackacre.TomeHub.Show("realms")
            if Blackacre.Afterlife and Blackacre.Afterlife.UI and Blackacre.Afterlife.UI.ShowRealmPicker then
                Blackacre.Afterlife.UI.ShowRealmPicker()
            end
        else
            NeedPackage("Blackacre Tome", "Afterlife")
        end
    elseif msg == "roadmap" or msg == "road" or msg == "expedition" or msg == "chart" then
        if Blackacre.TomeHub and Blackacre.TomeHub.Show then
            Blackacre.TomeHub.Show("road")
        elseif Blackacre.Roadmap and Blackacre.Roadmap.UI then
            Blackacre.Roadmap.UI.Toggle()
        else
            NeedPackage("Blackacre Tome", "Roadmap")
        end
    elseif msg == "birth" or msg == "identity" or msg == "lineage" or msg == "age" then
        if Blackacre.TomeHub and Blackacre.TomeHub.Show then
            Blackacre.TomeHub.Show("lineage")
        elseif Blackacre.LineageUI then
            Blackacre.LineageUI.Toggle()
        else
            NeedPackage("Blackacre Tome", "Lineage")
        end
    elseif msg == "birth human" then
        if Blackacre.Birthpath then Blackacre.Birthpath.DebugSampleHuman() else NeedPackage("Blackacre Tome", "Lineage") end
    elseif msg == "birth elf" then
        if Blackacre.Birthpath then Blackacre.Birthpath.DebugSampleElf() else NeedPackage("Blackacre Tome", "Lineage") end
    elseif msg == "birth dracthyr" then
        if Blackacre.Birthpath then Blackacre.Birthpath.DebugSampleDracthyr() else NeedPackage("Blackacre Tome", "Lineage") end
    elseif msg == "export profile" then
        if Blackacre.Share and Blackacre.Share.Export and Blackacre.Share.Export.CopyFullProfile then
            Blackacre.Share.Export.CopyFullProfile()
        else
            NeedPackage("Blackacre Tome", "Profile export")
        end
    elseif msg == "export" then
        if Blackacre.Share and Blackacre.Share.Export then
            Blackacre.Share.Export.CopyToClipboard()
        else
            NeedPackage("Blackacre Tome", "Share")
        end
    elseif msg:match("^share%s+") then
        local target = msg:match("^share%s+(.+)$")
        Blackacre.Comms.RequestSummary(strtrim(target or ""))
    elseif msg == "share" then
        if Blackacre.Compat and Blackacre.Compat.SupportsTRP3 and Blackacre.Compat.SupportsTRP3() then
            Blackacre.Print("Usage: /ic share PlayerName  — or /ic export for TRP3 paste")
        else
            Blackacre.Print("Usage: /ic share PlayerName  — or /ic export to copy a summary")
        end
    elseif msg == "pvpsample" then
        if Blackacre.PvP and Blackacre.PvP.AfterAction then
            Blackacre.PvP.AfterAction.DebugSample()
        else
            NeedPackage("Blackacre Tome", "PvP")
        end
    elseif msg == "pvp off" then
        if Blackacre.PvP and Blackacre.PvP.AfterAction then
            Blackacre.PvP.AfterAction.SetEnabled(false)
            Blackacre.Print("After Action Reports disabled")
        else
            NeedPackage("Blackacre Tome", "PvP")
        end
    elseif msg == "pvp on" then
        if Blackacre.PvP and Blackacre.PvP.AfterAction then
            Blackacre.PvP.AfterAction.SetEnabled(true)
            Blackacre.Print("After Action Reports enabled")
        else
            NeedPackage("Blackacre Tome", "PvP")
        end
    elseif msg == "beacons off" then
        Blackacre.Lifecycle.EnsurePresenceDB().receiveBeacons = false
        Blackacre.Print("Beacon receive off.")
        if Blackacre.BeaconPins then Blackacre.BeaconPins.Refresh() end
    elseif msg == "beacons on" then
        Blackacre.Lifecycle.EnsurePresenceDB().receiveBeacons = true
        Blackacre.Print("Beacon receive on.")
    elseif msg == "packages" or msg == "version" then
        local list = {}
        for name in pairs(Blackacre._loadedPackages) do
            table.insert(list, name)
        end
        table.sort(list)
        local flavor = (Blackacre.Compat and Blackacre.Compat.FlavorLabel and Blackacre.Compat.FlavorLabel()) or "unknown client"
        Blackacre.Print(string.format("v%s core · %s · packages: %s",
            Blackacre.VERSION,
            flavor,
            (#list > 0) and table.concat(list, ", ") or "(none — enable Presence/Tome/Survival)"))
    elseif msg:match("^toast") then
        if not (Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast) then
            Blackacre.Print("Toast not ready.")
        else
            local rest = msg:match("^toast%s+(.-)%s*$") or ""
            if rest == "hold" then
                Blackacre.UI.Theme.Toast("Thirst grows dire (12).", "evergreen", true, true)
                Blackacre.Print("Toast held. /ba skin for T1/T2. /ba toast go to release.")
            elseif rest == "go" or rest == "release" then
                if Blackacre.UI.Theme.ToastHold then Blackacre.UI.Theme.ToastHold(false) end
            else
                local kit = rest
                if kit == "" then kit = "evergreen" end
                local resolved, spec = nil, nil
                if Blackacre.UI.Theme.GetToastKitSpec then
                    resolved, spec = Blackacre.UI.Theme.GetToastKitSpec(kit)
                else
                    resolved = kit
                    spec = Blackacre.UI.Theme.ToastKits and Blackacre.UI.Theme.ToastKits[kit]
                end
                Blackacre.UI.Theme.Toast("Sample: " .. tostring(resolved or kit), kit, false, true)
                if spec and spec.atlas then
                    Blackacre.Print("Toast kit |cffc9a227" .. tostring(resolved) .. "|r  atlas " .. spec.atlas)
                else
                    local keys = {}
                    if Blackacre.UI.Theme.ToastKits then
                        for k in pairs(Blackacre.UI.Theme.ToastKits) do
                            keys[#keys + 1] = k
                        end
                        table.sort(keys)
                    end
                    Blackacre.Print("Unknown kit '" .. tostring(kit) .. "'. Have: " .. (#keys > 0 and table.concat(keys, " ") or "(none)"))
                end
            end
        end
    elseif msg == "skin" then
        if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.ToggleTomeSkinGuide then
            Blackacre.UI.Theme.ToggleTomeSkinGuide()
        else
            Blackacre.Print("Theme skin guide not ready.")
        end
    elseif msg == "bookart" then
        local path = Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.GetBookArtPath
            and Blackacre.UI.Theme.GetBookArtPath()
            or "Interface\\EncounterJournal\\UI-EJ-JournalBG"
        Blackacre.Print("Book art = Adventure Journal (dungeon journal) texture:")
        print("|cffffffff" .. path .. "|r")
        Blackacre.Print("Set in Theme.Textures.bookArt (same as Theme.Textures.ejJournalBG).")
    elseif msg == "config" or msg == "options" or msg == "opt" then
        if Blackacre.Options and Blackacre.Options.Open then
            Blackacre.Options.Open()
        else
            Blackacre.Print("Options not ready.")
        end
    elseif msg == "" then
        if Blackacre.Flyout and Blackacre.Flyout.Toggle then
            Blackacre.Flyout.Toggle()
        else
            Blackacre.Print("Enable |cffc9a227Blackacre Presence|r for the presence panel. /ba packages")
        end
    else
        Blackacre.Print("Commands: /ba, /ba config, /ba setup, /ba tome, /ba skin, /ba toast, /ba survival, /ba packages")
    end
end
