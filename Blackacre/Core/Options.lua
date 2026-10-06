-- In Character Forever - Settings

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

Blackacre = Blackacre or {}
Blackacre.Options = Blackacre.Options or {}

local ipairs, next, math_floor, format, strtrim = ipairs, next, math.floor, string.format, strtrim

local function L(key)
    local locale = Blackacre.L
    if locale and locale[key] then
        return locale[key]
    end
    return key
end

local function GetProfileSettings()
    return Blackacre.GetProfileSettings and Blackacre.GetProfileSettings() or nil
end

--- key -> name for every font in Theme's catalog (both font menus list the same faces).
local function FontChoices()
    local t = {}
    local cat = Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.GetBodyFontCatalog
        and Blackacre.UI.Theme.GetBodyFontCatalog()
        or {}
    for _, row in ipairs(cat) do
        t[row.key] = row.name
    end
    if not next(t) then
        t.default = "Default (WoW mail)"
    end
    return t
end

local function CharSettings()
    Blackacre.CharDB = Blackacre.CharDB or {}
    Blackacre.CharDB.settings = Blackacre.CharDB.settings or {}
    return Blackacre.CharDB.settings
end

local function Identity()
    if Blackacre.YearCalendar and Blackacre.YearCalendar.EnsureIdentity then
        return Blackacre.YearCalendar.EnsureIdentity()
    end
    Blackacre.CharDB = Blackacre.CharDB or {}
    Blackacre.CharDB.identity = Blackacre.CharDB.identity or {}
    return Blackacre.CharDB.identity
end

local function RefreshJournalTitle()
    if Blackacre.TomeHub and Blackacre.TomeHub.RefreshTitle then
        Blackacre.TomeHub.RefreshTitle()
    end
end

local function Voice()
    return Blackacre.Voice
end

local function VoiceSettings()
    local v = Voice()
    return v and v.GetSettings and v.GetSettings() or nil
end

local function VoiceValues(listFn, labelFn)
    local v = Voice()
    local out = {}
    if v and v[listFn] then
        for _, id in ipairs(v[listFn]()) do
            out[id] = v[labelFn] and v[labelFn](id) or id
        end
    end
    if not next(out) then out.auto = "Auto" end
    return out
end

local function HonorStatusText()
    local hc = Blackacre.Hardcore
    if not (hc and hc.GetStatus) then return "" end
    local s = hc.GetStatus()
    return format(
        "Deaths recorded: %d\nEncumbrance active: %s (events: %d)\nMount violations: %d\nGround Rite: %s\n",
        s.deathCount or 0,
        s.encumbranceActive and "yes" or "no",
        s.encumbranceViolations or 0,
        s.mountViolations or 0,
        s.groundGate and "Completed" or "Incomplete"
    )
end

local function BuildOptions()
    return {
        type = "group",
        name = L("OPTIONS_TITLE"),
        args = {
            desc = {
                type = "description",
                name = L("OPTIONS_DESC"),
                order = 1,
                fontSize = "medium",
            },
            general = {
                type = "group",
                name = "General",
                order = 2,
                inline = true,
                args = {
                    minimap = {
                        type = "toggle",
                        name = L("OPT_MINIMAP"),
                        desc = L("OPT_MINIMAP_DESC"),
                        order = 1,
                        get = function()
                            local p = GetProfileSettings()
                            return not (p and p.minimap and p.minimap.hide)
                        end,
                        set = function(_, v)
                            local p = GetProfileSettings()
                            if not p then return end
                            p.minimap = p.minimap or {}
                            p.minimap.hide = not v
                            if Blackacre.MinimapButton and Blackacre.MinimapButton.Refresh then
                                Blackacre.MinimapButton.Refresh()
                            end
                        end,
                    },
                    quiet = {
                        type = "toggle",
                        name = L("OPT_QUIET"),
                        desc = L("OPT_QUIET_DESC"),
                        order = 2,
                        get = function()
                            local p = GetProfileSettings()
                            return p and p.quietNotifications
                        end,
                        set = function(_, v)
                            local p = GetProfileSettings()
                            if not p then return end
                            p.quietNotifications = v and true or false
                            if Blackacre.CharDB and Blackacre.CharDB.settings then
                                Blackacre.CharDB.settings.quietNotifications = v and true or false
                            end
                        end,
                    },
                    survival = {
                        type = "toggle",
                        name = "Survival tracking",
                        desc = "",
                        order = 3,
                        get = function()
                            local s = Blackacre.CharDB and Blackacre.CharDB.survival
                            if s and s.enabled == false then return false end
                            return true
                        end,
                        set = function(_, v)
                            if Blackacre.Survival and Blackacre.Survival.Engine and Blackacre.Survival.Engine.SetEnabled then
                                Blackacre.Survival.Engine.SetEnabled(v and true or false)
                            else
                                Blackacre.CharDB = Blackacre.CharDB or {}
                                Blackacre.CharDB.survival = Blackacre.CharDB.survival or {}
                                Blackacre.CharDB.survival.enabled = v and true or false
                            end
                            if Blackacre.Survival and Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
                                Blackacre.Survival.UI.Refresh()
                            end
                        end,
                    },
                    chromeSkin = {
                        type = "select",
                        name = "Journal skin",
                        desc = "",
                        order = 4,
                        values = {
                            auto = "Auto (character faction)",
                            Alliance = "Alliance",
                            Horde = "Horde",
                            Dragonflight = "Dragonflight",
                            Metal = "Metal",
                            Kyrian = "Kyrian",
                            Seafarer = "Seafarer",
                            Workshop = "Workshop",
                            Scholomance = "Scholomance",
                            Tavern = "Tavern",
                            Skyborne = "Skyborne",
                            Slate = "Slate",
                            Ornate = "Ornate",
                            Ironforge = "Ironforge",
                            Forsaken = "Forsaken",
                            Void = "Void",
                        },
                        sorting = {
                            "auto", "Alliance", "Horde", "Dragonflight", "Metal",
                            "Kyrian", "Seafarer", "Workshop", "Scholomance", "Tavern",
                            "Skyborne", "Slate", "Ornate", "Ironforge", "Forsaken",
                            "Void",
                        },
                        get = function()
                            local p = GetProfileSettings()
                            return (p and p.chromeSkin) or "auto"
                        end,
                        set = function(_, key)
                            if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.SetActiveSkin then
                                Blackacre.UI.Theme.SetActiveSkin(key)
                            elseif GetProfileSettings() then
                                GetProfileSettings().chromeSkin = key
                            end
                        end,
                    },
                },
            },
            journal = {
                type = "group",
                name = "Journal Settings",
                order = 3,
                inline = true,
                args = {
                    title = {
                        type = "input",
                        name = "Journal title",
                        desc = "Shown across the top of your journal. Leave blank to use \"<Name Surname>'s Journal\".",
                        order = 1,
                        width = "double",
                        get = function() return CharSettings().journalTitle or "" end,
                        set = function(_, value)
                            value = strtrim(value or "")
                            CharSettings().journalTitle = (value ~= "") and value or nil
                            RefreshJournalTitle()
                        end,
                    },
                    surname = {
                        type = "input",
                        name = "Surname",
                        desc = "Your character's family name, used in the default journal title.",
                        order = 2,
                        get = function() return Identity().surname or "" end,
                        set = function(_, value)
                            value = strtrim(value or "")
                            Identity().surname = (value ~= "") and value or nil
                            RefreshJournalTitle()
                        end,
                    },
                    titlePreview = {
                        type = "description",
                        order = 3,
                        fontSize = "medium",
                        name = function()
                            return "Title now: |cffffffff" .. (Blackacre.GetJournalTitle and Blackacre.GetJournalTitle() or "") .. "|r\n"
                        end,
                    },
                    bodyFont = {
                        type = "select",
                        name = "Journal Font",
                        desc = "The handwriting on journal pages, the table of contents and sticky notes. \"By race\" uses your race's script.",
                        order = 4,
                        values = function()
                            local t = FontChoices()
                            local th = Blackacre.UI and Blackacre.UI.Theme
                            if th and th.RaceJournalFontKey then
                                t[th.RACE_FONT_KEY] = "By race (" .. (t[th.RaceJournalFontKey()] or "Default") .. ")"
                            end
                            return t
                        end,
                        get = function()
                            local p = GetProfileSettings()
                            if p and p.bodyFontKey then
                                return p.bodyFontKey
                            end
                            if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Fonts then
                                return Blackacre.UI.Theme.Fonts.activeKey or "default"
                            end
                            return "default"
                        end,
                        set = function(_, key)
                            if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.SetBodyFontKey then
                                Blackacre.UI.Theme.SetBodyFontKey(key, false)
                            elseif GetProfileSettings() then
                                GetProfileSettings().bodyFontKey = key
                            end
                        end,
                    },
                    addonFont = {
                        type = "select",
                        name = "Add-on Text Font",
                        desc = "Titles, headings and labels in In Character windows. Buttons and typing boxes keep the game's font.",
                        order = 4.5,
                        values = FontChoices,
                        get = function()
                            local p = GetProfileSettings()
                            return p and p.addonFontKey or "default"
                        end,
                        set = function(_, key)
                            if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.SetAddonFontKey then
                                Blackacre.UI.Theme.SetAddonFontKey(key)
                            elseif GetProfileSettings() then
                                GetProfileSettings().addonFontKey = key
                            end
                        end,
                    },
                    bodyFontNote = {
                        type = "description",
                        order = 5,
                        name = "",
                        fontSize = "medium",
                    },
                    importQuests = {
                        type = "execute",
                        name = "Import earlier quests",
                        desc = "Use this to add quests you completed before downloading the add on. It can only pull the name of the quest, no the quest text.",
                        order = 7,
                        disabled = function() return not Blackacre.QuestLog or Blackacre.QuestLog.IsImporting() end,
                        func = function() Blackacre.QuestLog.ImportCompleted() end,
                    },
                    promptEveryQuest = {
                        type = "toggle",
                        name = "Active Journaling",
                        desc = "Write a journal page for every quest you turn in. Off by default: every quest is always kept in the Quest Index, and you choose which ones become pages.",
                        order = 6,
                        width = "full",
                        get = function()
                            return CharSettings().promptEveryQuest == true
                        end,
                        set = function(_, v)
                            CharSettings().promptEveryQuest = v and true or false
                        end,
                    },
                },
            },
            voice = {
                type = "group",
                name = "Voice",
                order = 10,
                disabled = function() return not Voice() end,
                args = {
                    note = {
                        type = "description", order = 1, fontSize = "medium",
                        name = function()
                            if not Voice() then
                                return "Enable In Character Forever: Journal to set your voice.\n"
                            end
                            return "The auto prompts generate in the spirit of the accent of your choice using the in game and other imported language parsers.\n"
                        end,
                    },
                    language = {
                        type = "select", name = "Language", order = 2,
                        values = function() return VoiceValues("ListLanguages", "LanguageLabel") end,
                        get = function() local s = VoiceSettings(); return s and s.language or "auto" end,
                        set = function(_, id) local s = VoiceSettings(); if s then s.language = id end end,
                    },
                    accent = {
                        type = "select", name = "Accent", order = 3,
                        values = function() return VoiceValues("ListAccents", "AccentLabel") end,
                        get = function() local s = VoiceSettings(); return s and s.accent or "auto" end,
                        set = function(_, id) local s = VoiceSettings(); if s then s.accent = id end end,
                    },
                    applyChronicle = {
                        type = "toggle", name = "Apply to journal pages", order = 4,
                        get = function() local s = VoiceSettings(); return not s or s.applyToChronicle ~= false end,
                        set = function(_, v) local s = VoiceSettings(); if s then s.applyToChronicle = v and true or false end end,
                    },
                    applyBulletins = {
                        type = "toggle", name = "Apply to bulletins", order = 5,
                        get = function() local s = VoiceSettings(); return s and s.applyToBulletins == true end,
                        set = function(_, v) local s = VoiceSettings(); if s then s.applyToBulletins = v and true or false end end,
                    },
                    sample = {
                        type = "description", order = 6, fontSize = "medium",
                        name = function()
                            local v = Voice()
                            if not (v and v.Apply and v.Resolve) then return "" end
                            local language, accent = v.Resolve()
                            return "\nSample: " .. v.Apply("I am looking for the thing near the mountain, yes?")
                                .. "\nGreeting: " .. v.Apply("Hello, I am looking for the thing, yes?")
                                .. "\nSlang: " .. v.Apply("I'm gonna look for the thing, yeah?") .. "\n"
                        end,
                    },
                },
            },
            honor = {
                type = "group",
                name = "Survival",
                order = 11,
                disabled = function() return not (Blackacre.Hardcore and Blackacre.Hardcore.GetStatus) end,
                args = {
                    note = {
                        type = "description", order = 1, fontSize = "medium",
                        name = "Survival has baked in rules to immerse you in the adventure. See your stats on survival below.\n",
                    },
                    status = {
                        type = "description", order = 2, fontSize = "medium",
                        name = HonorStatusText,
                    },
                    meters = {
                        type = "description", order = 3, fontSize = "medium",
                        name = function()
                            local sv = Blackacre.Survival and Blackacre.Survival.GetState and Blackacre.Survival.GetState()
                            if not (sv and sv.enabled ~= false) then return "Survival meters off.\n" end
                            return format("Hunger %d   Thirst %d   Exposure %d\n",
                                math_floor(sv.hunger or 0), math_floor(sv.thirst or 0), math_floor(sv.exposure or 0))
                        end,
                    },
                    groundRite = {
                        type = "toggle", name = "Ground Rite completed", order = 4, width = "full",
                        desc = "Mark once your character has earned the right to ride. Riding before then counts as a mount violation.",
                        get = function()
                            local gate = Blackacre.CharDB and Blackacre.CharDB.gate
                            return gate and gate.ground == true
                        end,
                        set = function(_, v)
                            if Blackacre.Hardcore and Blackacre.Hardcore.SetGroundGate then
                                Blackacre.Hardcore.SetGroundGate(v)
                            end
                        end,
                    },
                    bags = {
                        type = "description", order = 5, fontSize = "medium",
                        name = "\nMax bag size, 6 slots.",
                    },
                },
            },
            profiles = {
                type = "group",
                name = L("OPT_PROFILES"),
                order = 90,
                args = {
                    note = {
                        type = "description", order = 1,
                        name = "",
                        fontSize = "medium",
                    },
                    active = {
                        type = "select", name = "Active profile", order = 2,
                        values = function()
                            local values = {}
                            if Blackacre.db then
                                for _, profile in ipairs(Blackacre.GetProfiles()) do
                                    values[profile.id] = profile.name
                                end
                            end
                            return values
                        end,
                        get = function()
                            return Blackacre.db and Blackacre.db:GetCurrentProfile() or Blackacre.ActiveProfileID
                        end,
                        set = function(_, id)
                            if not Blackacre.SetActiveProfile(id) then
                                Blackacre.Print("That profile could not be opened; your current profile is unchanged.")
                            end
                        end,
                    },
                    newName = {
                        type = "input", name = "New profile name", order = 3,
                        get = function() return Blackacre._newProfileName or "" end,
                        set = function(_, value) Blackacre._newProfileName = strtrim(value or "") end,
                    },
                    create = {
                        type = "execute", name = "Create copy of current profile", order = 4,
                        func = function()
                            local name = strtrim(Blackacre._newProfileName or "")
                            if name == "" then Blackacre.Print("Enter a profile name first."); return end
                            if #name > 48 then Blackacre.Print("Profile names must be 48 characters or fewer."); return end
                            local profile = Blackacre.CreateProfile(name)
                            if not profile then Blackacre.Print("That profile name is invalid or already in use; nothing was changed."); return end
                            Blackacre._newProfileName = ""
                            Blackacre.Print("Created a separate copy named " .. name .. ".")
                        end,
                    },
                    export = {
                        type = "execute", name = "Export full profile backup", order = 5,
                        func = function() Blackacre.ExportProfileBackup() end,
                    },
                    restore = {
                        type = "execute", name = "Restore or import a backup...", order = 6,
                        func = function() Blackacre.Backup.ShowWindow() end,
                    },
                },
            },
            credits = {
                type = "group",
                name = "Credits",
                order = 95,
                args = {
                    thanks = {
                        type = "description", order = 1, fontSize = "medium",
                        name = "|cffd9b340Thanks|r\n",
                    },
                    libraries = {
                        type = "description", order = 2, fontSize = "medium",
                        name = "|cffd9b340Libraries|r\n"
                            .. "Ace3 (WowAce team), LibStub, CallbackHandler, ChatThrottleLib, LibDeflate (Haoqian He), "
                            .. "LibDataBroker-1.1, LibDBIcon-1.0, HereBeDragons (Hendrik Leppkes).\n",
                    },
                    blizzard = {
                        type = "description", order = 3, fontSize = "medium",
                        name = "|cffd9b340World of Warcraft|r\n"
                            .. "A free fan-made addon, not affiliated with or endorsed by Blizzard Entertainment. "
                            .. "World of Warcraft, Warcraft and all in-game art are trademarks or property of Blizzard Entertainment.\n",
                    },
                },
            },
        },
    }
end

function Blackacre.Options.Init(addon)
    if not addon or not Blackacre.db then return end

    local options = BuildOptions()
    AceConfig:RegisterOptionsTable("Blackacre", options)
    AceConfigDialog:AddToBlizOptions("Blackacre", L("OPTIONS_TITLE"))

    -- /ba config
    if addon.RegisterChatCommand then
        addon:RegisterChatCommand("ba_config", function()
            AceConfigDialog:Open("Blackacre")
        end)
    end
end

--- Open Settings, optionally on one section ("voice", "honor", "journal", ...).
function Blackacre.Options.Open(section)
    if section == "survival" then section = "honor" end
    AceConfigDialog:Open("Blackacre")
    if section then
        AceConfigDialog:SelectGroup("Blackacre", section)
    end
end

--- Redraw an open Settings window after data changed elsewhere.
function Blackacre.Options.Notify()
    AceConfigRegistry:NotifyChange("Blackacre")
end
