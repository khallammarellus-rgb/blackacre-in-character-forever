-- Blackacre UI Theme
--
-- FRAME / LAYER MODEL (Mayron Ep. 5 — use this for all Tome & Menu chrome):
--   Frame = canvas (parent + unlimited children)
--   Draw layers on a frame, back → front:
--     BACKGROUND → BORDER → ARTWORK → OVERLAY → HIGHLIGHT
--   Sublevel (-8..7) orders regions inside the same layer.
-- Full write-up: docs/FRAME-LAYERS.md

Blackacre = Blackacre or {}
Blackacre.UI = Blackacre.UI or {}
Blackacre.UI.Theme = {}

--- Canonical draw-layer names (engine strings). Prefer these constants in new code.
Blackacre.UI.Theme.Layer = {
    BACKGROUND = "BACKGROUND", -- fills, washes, paper
    BORDER = "BORDER",         -- edge art
    ARTWORK = "ARTWORK",       -- spine, ornaments, card art
    OVERLAY = "OVERLAY",       -- text, primary icons, controls chrome
    HIGHLIGHT = "HIGHLIGHT",   -- mouse hover (auto show/hide)
}

--- Create a texture on a frame at a known layer/sublevel (defaults: BACKGROUND, 0).
function Blackacre.UI.Theme.CreateLayeredTexture(frame, layer, sublevel)
    if not frame then return nil end
    layer = layer or Blackacre.UI.Theme.Layer.BACKGROUND
    return frame:CreateTexture(nil, layer, nil, sublevel)
end

--- Create a font string on OVERLAY by default (text must sit above art).
function Blackacre.UI.Theme.CreateLayeredFontString(frame, layer, inherits)
    if not frame then return nil end
    layer = layer or Blackacre.UI.Theme.Layer.OVERLAY
    return frame:CreateFontString(nil, layer, inherits or "GameFontHighlight")
end

Blackacre.UI.Theme.Colors = {
    -- Graphite pencil-lead ink (cool grey-black) for chronicle body / TOC
    ink = { 0.20, 0.21, 0.23 },
    inkSoft = { 0.32, 0.33, 0.36 },
    gold = { 0.85, 0.70, 0.25 },
    parchment = { 0.92, 0.86, 0.72 },
    page = { 0.97, 0.93, 0.82 },
    pageFill = { 0.94, 0.88, 0.74 },
    edge = { 0.55, 0.42, 0.22 },
    edgeGold = { 0.75, 0.60, 0.28 },
    spine = { 0.22, 0.14, 0.08 },
    tabIdle = { 0.42, 0.30, 0.14 },
    tabActive = { 0.72, 0.55, 0.22 },
    cover = { 0.22, 0.16, 0.10 },
    headerFill = { 0.18, 0.14, 0.10 },
    footerFill = { 0.16, 0.12, 0.09 },
}

Blackacre.UI.Theme.Seals = {
    INDIVIDUAL = { label = "Personal", color = { 0.55, 0.45, 0.30 }, short = "P" },
    GROUP = { label = "Company", color = { 0.35, 0.50, 0.65 }, short = "C" },
    GUILD = { label = "Guild", color = { 0.55, 0.35, 0.65 }, short = "G" },
    FACTION = { label = "Realm", color = { 0.70, 0.30, 0.25 }, short = "R" },
}

Blackacre.UI.Theme.Textures = {
    parchment = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
    parchmentVert = "Interface\\AchievementFrame\\UI-Achievement-Parchment",
    questBG = "Interface\\QuestFrame\\QuestBG",
    dialogEdge = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tooltipEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
    goldEdge = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    -- Owner polish pack (Interface paths; Desktop PNGs = name reference only)
    achievementBorders = "Interface\\AchievementFrame\\UI-Achievement-Borders",
    goldBorderTile = "Interface\\Common\\UI-Goldborder-_tile",
    alertBackground = "Interface\\AchievementFrame\\UI-Achievement-Alert-Background",
    rewardBackground = "Interface\\AchievementFrame\\UI-Achievement-Reward-Background",
    pageNumGlow = "Interface\\Glues\\Models\\UI_MainMenu_Legion\\UI_Warlords_SkyGLow_Left_01",
    stickyFill = "Interface\\Spellbook\\Spellbook-Page-1",
    mapPinCursor = "Interface\\Cursor\\MapPinCursor",
    mapPinCursorCross = "Interface\\Cursor\\Crosshairs\\MapPinCursor",
    commonIcons = "Interface\\Common\\CommonIcons",
    statusOffline = "Interface\\FriendsFrame\\StatusIcon-Offline",
    noteMenuIcon = "Interface\\GossipFrame\\HealerGossipIcon",
    noteLockIcon = "Interface\\ChatFrame\\UI-ChatFrame-LockIcon",
    tocBanner = "Interface\\PVPFrame\\PVP-Banner-5-Border-2",
    toastCentaur = "Interface\\CovenantRenown\\DragonflightMajorFactionsCentaur",
    frameAlliance = "Interface\\FrameGeneral\\UIFrameAlliance",
    frameHorde = "Interface\\FrameGeneral\\UIFrameHorde",
    guildBankTab = "Interface\\GuildBankFrame\\UI-GuildBankFrame-Tab",
    -- Icon chrome: Achievement icon frame wraps Interface\\Icons\\* (owner E0)
    iconFrame = "Interface\\AchievementFrame\\UI-Achievement-IconFrame",
    microSpellbook = "Interface\\Buttons\\UI-MicroButton-Spellbook-Down",
    optionsGear = "Interface\\Buttons\\UI-OptionsButton",
    bookIcon = "Interface\\Spellbook\\Spellbook-Icon",
    questBook = "Interface\\QuestFrame\\UI-QuestLog-BookIcon",
    stone = "Interface\\FrameGeneral\\UI-Background-Rock",
    white = "Interface\\Buttons\\WHITE8x8",
    -- Adventure Journal open-book (Shift+J)
    ejJournalBG = "Interface\\EncounterJournal\\UI-EJ-JournalBG",
    bookArt = "Interface\\EncounterJournal\\UI-EJ-JournalBG",
    bookArtTexCoords = { left = 0, right = 0.766601562, top = 0, bottom = 0.830078125 },
    -- EJ atlas (bookmark tabs, buttons) — name reference from owner desktop library
    ejTextures = "Interface\\EncounterJournal\\UI-EncounterJournalTextures",
    ejTexturesTile = "Interface\\EncounterJournal\\UI-EncounterJournalTextures_Tile",
    -- Map-frame chrome (Borders and Polish name family → Blizzard paths)
    ejMapFrameLeft = "Interface\\EncounterJournal\\UI-EJ-MapFrame-Cata-Left",
    ejMapFrameMid = "Interface\\EncounterJournal\\UI-EJ-MapFrame-Cata-Mid",
    -- Faction mission frame polish (OOC menu flair later)
    allianceMissionFrame = "Interface\\Garrison\\AllianceBfAMissionFrame",
    hordeMissionFrame = "Interface\\Garrison\\HordeBfAMissionFrame",
    -- Backstory sidecar (not faction; both skins)
    backstoryFrame = "Interface\\Glues\\AccountUpgrade\\ClassTrialThanksFrame",
    backstoryFrameAtlas = "ClassTrial-End-Frame",
    backstoryFillAtlas = "islands-queue-background",
    backstoryFillFile = "Interface\\Scenarios\\IslandsQueueBackground",
    backstoryNeutralFile = "Interface\\FrameGeneral\\UIFrameNeutral",
    backstoryTab = "Interface\\Spellbook\\UIFrameTabsSpellbook",
    backstoryIconMask = "Interface\\Spellbook\\SpellbookElementsIconMask",
    backstoryTabHover = "Interface\\Spellbook\\SpellbookElementsAutoCastMask",
    -- B1 trial shell. "neutral" / "questlog" kept for regress.
    backstoryB1Mode = "questlog",
    backstoryQuestLogAtlas = "QuestLog-frame",
    backstoryQuestLogFile = "Interface\\QuestFrame\\UI-QuestLog-Empty-Top",
    spellbookPage = "Interface\\Spellbook\\Spellbook-Page-1",
    spellbookPage2 = "Interface\\Spellbook\\Spellbook-Page-2",
}

if Blackacre.Compat and Blackacre.Compat.ApplyTextureRemaps then
    Blackacre.Compat.ApplyTextureRemaps(Blackacre.UI.Theme.Textures)
end

--- Art tokens only. Function (buttons, sizes, clicks) never lives here.
--- Shared ornaments (add-page, delete, glow, stickies) stay on Theme.Textures, not per skin.
local function FrameGeneralSkin(kit, extra)
    extra = extra or {}
    -- Bookmark (region 8) = evergreen ribbon. Title header (region 9) = kit Ribbon.
    -- Unique NineSlice corners are tried first; mirrored Corner is fallback.
    return {
        kit = kit,
        ninesliceCornerTL = extra.tl,
        ninesliceCornerTR = extra.tr,
        ninesliceCornerBL = extra.bl,
        ninesliceCornerBR = extra.br,
        ninesliceCorner = extra.corner or ("UI-Frame-" .. kit .. "-Corner"),
        ninesliceCornerAlt = kit .. "-NineSlice-Corner",
        ninesliceTileH = extra.edgeTop or ("_UI-Frame-" .. kit .. "-EdgeTop"),
        ninesliceTileHBottom = extra.edgeBottom or ("_UI-Frame-" .. kit .. "-EdgeBottom"),
        ninesliceTileV = extra.edgeLeft or ("!UI-Frame-" .. kit .. "-EdgeLeft"),
        ninesliceTileVRight = extra.edgeRight or ("!UI-Frame-" .. kit .. "-EdgeRight"),
        ninesliceTileHAlt = extra.edgeTopAlt or ("_" .. kit .. "-NineSlice-EdgeTop"),
        ninesliceTileVAlt = extra.edgeLeftAlt or ("!" .. kit .. "-NineSlice-EdgeLeft"),
        ninesliceTileHBottomAlt = extra.edgeBottomAlt or ("_" .. kit .. "-NineSlice-EdgeBottom"),
        ninesliceTileVRightAlt = extra.edgeRightAlt or ("!" .. kit .. "-NineSlice-EdgeRight"),
        tocBanner = extra.toc or "spellbook-background-evergreen-ribbon",
        tocUvStart = extra.tocUvStart or 0,
        tocUvWidth = extra.tocUvWidth or 1,
        rail = extra.rail or ("UI-Frame-" .. kit .. "-Ribbon"),
        tocTitleLeft = extra.titleLeft or ("UI-Frame-" .. kit .. "-TitleLeft"),
        tocTitleMid = extra.titleMid or ("UI-Frame-" .. kit .. "-Ribbon"),
        tocTitleRight = extra.titleRight or ("UI-Frame-" .. kit .. "-TitleRight"),
        ninesliceLayout = extra.layout,
        uniqueCorners = extra.uniqueCorners and true or false,
        thick = extra.thick ~= false,
    }
end

Blackacre.UI.Theme.Skins = {
    Alliance = {
        ninesliceCorner = "AllianceFrameCorner-TopLeft",
        ninesliceTileH = "_AllianceFrameTile-Top",
        ninesliceTileV = "!AllianceFrameTile-Left",
        ninesliceLayout = "BFAMissionAlliance",
        tocBanner = "AlliedRaces-AllianceHordeBanner",
        tocUvStart = 0,
        tocUvWidth = 0.41268,
        rail = "_AllianceFrame_ParchmentHeader-Mid",
        tocTitleLeft = nil,
        tocTitleMid = "_AllianceFrame_ParchmentHeader-Mid",
        tocTitleRight = nil,
    },
    Horde = {
        ninesliceCorner = "HordeFrame-Corner-TopLeft",
        ninesliceTileH = "_HordeFrameTile-Top",
        ninesliceTileV = "!HordeFrameTile-Left",
        ninesliceLayout = "BFAMissionHorde",
        tocBanner = "AlliedRaces-AllianceHordeBanner",
        tocUvStart = 0.50,
        tocUvWidth = 0.41268,
        rail = "_HordeFrame_ParchmentHeader-Mid",
        tocTitleLeft = nil,
        tocTitleMid = "_HordeFrame_ParchmentHeader-Mid",
        tocTitleRight = nil,
    },
    Dragonflight = FrameGeneralSkin("Dragonflight", {
        uniqueCorners = true,
        tl = "Dragonflight-NineSlice-CornerTopLeft",
        tr = "Dragonflight-NineSlice-CornerTopRight",
        bl = "Dragonflight-NineSlice-CornerBottomLeft",
        br = "Dragonflight-NineSlice-CornerBottomRight",
        edgeTop = "_Dragonflight-Nineslice-EdgeTop",
        edgeBottom = "_Dragonflight-Nineslice-EdgeBottom",
        edgeLeft = "!Dragonflight-NineSlice-EdgeLeft",
        edgeRight = "!Dragonflight-NineSlice-EdgeRight",
        toc = "spellbook-background-evergreen-ribbon",
        tocUvWidth = 1,
        titleLeft = "UI-Frame-Dragonflight-TitleLeft",
        titleRight = "UI-Frame-Dragonflight-TitleRight",
        titleMid = "_UI-Frame-Dragonflight-TitleMiddle",
        rail = "_UI-Frame-Dragonflight-TitleMiddle",
        ninesliceTopNudge = -6,
        chromePad = 14,
        titleOffsetX = 48,
        closeButtonOffsetX = -30,
    }),
    Metal = FrameGeneralSkin("GenericMetal", {
        corner = "UI-Frame-GenericMetal-Corner",
        edgeTop = "_UI-Frame-GenericMetal-EdgeTop",
        edgeBottom = "_UI-Frame-GenericMetal-EdgeBottom",
        edgeLeft = "!UI-Frame-GenericMetal-EdgeLeft",
        edgeRight = "!UI-Frame-GenericMetal-EdgeRight",
        toc = "spellbook-background-evergreen-ribbon",
        tocUvWidth = 1,
        rail = "_UI-Frame-GenericMetal-EdgeTop",
        titleMid = "_UI-Frame-GenericMetal-EdgeTop",
        titleLeft = nil,
        titleRight = nil,
    }),
    Kyrian = FrameGeneralSkin("Kyrian", {
        titleLeft = "UI-Frame-Kyrian-TitleLeft",
        titleMid = "_UI-Frame-Kyrian-TitleMiddle",
        titleRight = "UI-Frame-Kyrian-TitleRight",
        rail = "_UI-Frame-Kyrian-TitleMiddle",
    }),
    Seafarer = FrameGeneralSkin("Marine", {
        titleLeft = "UI-Frame-Marine-TitleLeft",
        titleMid = "_UI-Frame-Marine-TitleMiddle",
        titleRight = "UI-Frame-Marine-TitleRight",
        rail = "_UI-Frame-Marine-TitleMiddle",
    }),
    Workshop = FrameGeneralSkin("Mechagon", {
        titleLeft = "UI-Frame-Mechagon-TitleLeft",
        titleMid = "_UI-Frame-Mechagon-TitleMiddle",
        titleRight = "UI-Frame-Mechagon-TitleRight",
        rail = "_UI-Frame-Mechagon-TitleMiddle",
    }),
    Scholomance = FrameGeneralSkin("Necrolord", {
        titleLeft = "UI-Frame-Necrolord-TitleLeft",
        titleMid = "_UI-Frame-Necrolord-TitleMiddle",
        titleRight = "UI-Frame-Necrolord-TitleRight",
        rail = "_UI-Frame-Necrolord-TitleMiddle",
    }),
    Tavern = FrameGeneralSkin("Neutral", {
        corner = "Neutral-NineSlice-Corner",
        edgeTop = "_Neutral-NineSlice-EdgeTop",
        edgeBottom = "_Neutral-NineSlice-EdgeBottom",
        edgeLeft = "!Neutral-NineSlice-EdgeLeft",
        edgeRight = "!Neutral-NineSlice-EdgeRight",
        edgeTopAlt = "_Neutral-NineSlice-EdgeTop",
        edgeLeftAlt = "!Neutral-NineSlice-EdgeLeft",
        titleLeft = "UI-Frame-Neutral-TitleLeft",
        titleMid = "_UI-Frame-Neutral-TitleMiddle",
        titleRight = "UI-Frame-Neutral-TitleRight",
        rail = "_UI-Frame-Neutral-TitleMiddle",
    }),
    Skyborne = FrameGeneralSkin("NightFae", {
        titleLeft = "UI-Frame-NightFae-TitleLeft",
        titleMid = "_UI-Frame-NightFae-TitleMiddle",
        titleRight = "UI-Frame-NightFae-TitleRight",
        rail = "_UI-Frame-NightFae-TitleMiddle",
    }),
    Slate = FrameGeneralSkin("Oribos", {
        titleLeft = "UI-Frame-Oribos-TitleLeft",
        titleMid = "_UI-Frame-Oribos-TitleMiddle",
        titleRight = "UI-Frame-Oribos-TitleRight",
        rail = "_UI-Frame-Oribos-TitleMiddle",
    }),
    Ornate = FrameGeneralSkin("Plunderstorm", {
        titleLeft = "plunderstorm-wavesright",
        titleMid = "_plunderstorm-nineslice-edgebottom",
        titleRight = "plunderstorm-wavesleft",
        rail = "_plunderstorm-nineslice-edgebottom",
        railHeight = 16,
    }),
    Ironforge = {
        kit = "TheWarWithin",
        shellAtlas = "ui-frame-thewarwithin-border",
        shellScale = 1.02,
        tocBanner = "spellbook-background-evergreen-ribbon",
        tocUvStart = 0,
        tocUvWidth = 1,
        titleLeft = "ui-frame-thewarwithin-titleleft",
        titleMid = "_ui-frame-thewarwithin-titlemiddle",
        titleRight = "ui-frame-thewarwithin-titleright",
        tocTitleLeft = "ui-frame-thewarwithin-titleleft",
        tocTitleMid = "_ui-frame-thewarwithin-titlemiddle",
        tocTitleRight = "ui-frame-thewarwithin-titleright",
        rail = "_ui-frame-thewarwithin-titlemiddle",
        chromePad = 14,
        titleOffsetX = 61,
        closeButtonOffsetX = -69,
        journalToggleOffsetX = 36,
        footerRightOffsetX = -34,
    },
    Forsaken = FrameGeneralSkin("Venthyr", {
        uniqueCorners = true,
        tl = "Venthyr-NineSlice-CornerTopLeft",
        tr = "Venthyr-NineSlice-CornerTopRight",
        bl = "Venthyr-NineSlice-CornerBottomLeft",
        br = "Venthyr-NineSlice-CornerBottomRight",
        edgeTop = "_Venthyr-NineSlice-EdgeTop",
        edgeBottom = "_Venthyr-NineSlice-EdgeBottom",
        edgeLeft = "!Venthyr-NineSlice-EdgeLeft",
        edgeRight = "!Venthyr-NineSlice-EdgeRight",
        titleLeft = "UI-Frame-Venthyr-TitleLeft",
        titleMid = "_UI-Frame-Venthyr-TitleMiddle",
        titleRight = "UI-Frame-Venthyr-TitleRight",
        rail = "_UI-Frame-Venthyr-TitleMiddle",
    }),
    Void = {
        kit = "Midnight",
        shellAtlas = "ui-frame-midnight-border",
        shellScale = 1.02,
        tocBanner = "spellbook-background-evergreen-ribbon",
        tocUvStart = 0,
        tocUvWidth = 1,
        titleLeft = "ui-frame-midnight-titleleft",
        titleMid = "_ui-frame-midnight-titlemiddle",
        titleRight = "ui-frame-midnight-titleright",
        tocTitleLeft = "ui-frame-midnight-titleleft",
        tocTitleMid = "_ui-frame-midnight-titlemiddle",
        tocTitleRight = "ui-frame-midnight-titleright",
        rail = "_ui-frame-midnight-titlemiddle",
        chromePad = 14,
        titleOffsetX = 61,
        closeButtonOffsetX = -69,
        journalToggleOffsetX = 36,
        footerRightOffsetX = -34,
    },
}

--- Piece crops (UV 0–1). Prefer Blizzard XML when found; tweak after /reload.
Blackacre.UI.Theme.TexCoords = Blackacre.UI.Theme.TexCoords or {
    commonIconsDelete = { 0.50, 0.55, 0.0, 0.10 },
    -- Guild bank side tab: trim transparent pad so face fills button (E0)
    guildBankTab = { 0.08, 0.92, 0.02, 0.98 },
}

--- EJ side-tab slices (Blizzard_EncounterJournal.xml EncounterTabTemplate family)
Blackacre.UI.Theme.EjTabCoords = {
    unselected = { 0.25585938, 0.37890625, 0.90332031, 0.95898438 },
    selected   = { 0.12890625, 0.25195313, 0.90332031, 0.95898438 },
    highlight  = { 0.00195313, 0.12500000, 0.90332031, 0.95898438 },
}

--[[
  Font library (owner request). WoW can only load fonts the game can read —
  typically TTF/OTF placed under Interface\AddOns\Blackacre\Media\Fonts\ and
  registered here. System fonts (Ink Free, Segoe Script, …) are NOT portable
  across players unless bundled.

  Drop .ttf files into Media/Fonts/ then set paths below (no extension required).
  Zips from Downloads must be extracted first (bilbo / middleearth / elven / party-business).
]]
-- Chronicle BODY + sticky notes only (not titles, headers, or Backstory menus).
-- Empty rectangles (□) = missing glyphs. WoW cannot mix two fonts inside one string
-- (so | cannot be Default while letters are Hobbiton). We sanitize symbols to safer
-- ASCII and offer full game fonts + a short decorative list.
local FONT = "Interface\\AddOns\\Blackacre\\Media\\Fonts\\"
local WOW_FRIZ = "Fonts\\FRIZQT__.TTF"
local WOW_FRIZ_CYR = "Fonts\\FRIZQT___CYR.TTF"
local WOW_MORPHEUS = "Fonts\\MORPHEUS.TTF"
local WOW_SKURRI = "Fonts\\skurri.ttf"

Blackacre.UI.Theme.Fonts = {
    catalog = {
        { key = "default", path = nil, name = "Default (WoW mail)", full = true },
        { key = "frizGame", path = WOW_FRIZ, name = "Friz (game)", full = true },
        { key = "frizCyr", path = WOW_FRIZ_CYR, name = "Friz Cyrillic (game)", full = true },
        { key = "morpheusGame", path = WOW_MORPHEUS, name = "Morpheus (game)", full = true },
        { key = "skurri", path = WOW_SKURRI, name = "Skurri (game)", full = true },
        { key = "friz", path = FONT .. "friz-quadrata-tt.ttf", name = "Friz Quadrata", full = true },
        { key = "morpheus", path = FONT .. "MORPHEUS.TTF", name = "Morpheus", full = true },
        { key = "bilbo", path = FONT .. "bilboregular.ttf", name = "Bilbo", full = false },
        { key = "bilboBold", path = FONT .. "bilbobold.ttf", name = "Bilbo Bold", full = false },
        { key = "bilboFine", path = FONT .. "bilbofine.ttf", name = "Bilbo Fine", full = false },
        { key = "hobbiton", path = FONT .. "HobbitonBrushhandhobbitonBrush-WygA.ttf", name = "Hobbiton Brush", full = false },
        { key = "middleEarth", path = FONT .. "Middleearth-ao6m.ttf", name = "Middle Earth", full = false },
        { key = "elvenCommon", path = FONT .. "Elvencommonspeak-0WXz.ttf", name = "Elven Common", full = false },
        { key = "partyBusiness", path = FONT .. "PartyBusiness-4B0K.ttf", name = "Party Business", full = false },
        { key = "angerthas", path = FONT .. "AngerthasMoria-lgLAD.ttf", name = "Angerthas Moria", full = false },
        { key = "caslon", path = FONT .. "caslon-antique.regular.ttf", name = "Caslon Antique", full = false },
        { key = "cupAndTalon", path = FONT .. "Cup_and_Talon.ttf", name = "Cup and Talon", full = false },
        { key = "damned", path = FONT .. "DAMNED.TTF", name = "Damned", full = false },
        { key = "darkBlack", path = FONT .. "Dark_Black_D.otf", name = "Dark Black", full = false },
        { key = "dwarven", path = FONT .. "DWARVESC.TTF", name = "Dwarven SC", full = false },
        { key = "freebooter", path = FONT .. "FREEBOOTERUPDATED.TTF", name = "Freebooter", full = false },
        { key = "ironclad", path = FONT .. "IRONCLADBOLTED.TTF", name = "Ironclad Bolted", full = false },
        { key = "blackadder", path = FONT .. "ITCBLKAD.TTF", name = "Blackadder", full = false },
        { key = "lifecraft", path = FONT .. "LifeCraft_Font.ttf", name = "LifeCraft", full = false },
        { key = "magicSchool", path = FONT .. "MagicSchoolOne-ovYz.ttf", name = "Magic School", full = false },
        { key = "monarch", path = FONT .. "MONARCHI.TTF", name = "Monarch", full = false },
        { key = "mord", path = FONT .. "MORD.TTF", name = "Mord", full = false },
        { key = "ravenscroft", path = FONT .. "Ravenscroft.ttf", name = "Ravenscroft", full = false },
        { key = "ringbearer", path = FONT .. "RINGM_.TTF", name = "Ringbearer", full = false },
        { key = "roland", path = FONT .. "ROLAND_.TTF", name = "Roland", full = false },
        { key = "silvus", path = FONT .. "silvus.ttf", name = "Silvus", full = false },
        { key = "plexus", path = FONT .. "WoW-plexus.ttf", name = "WoW Plexus", full = false },
        { key = "anotherDanger", path = FONT .. "Another_Danger_-_Demo.otf", name = "Another Danger", full = false },
        { key = "thalassian", path = FONT .. "Thalassian_Font.ttf", name = "Thalassian", full = false },
        { key = "darnassian", path = FONT .. "DarnassianRunes-Regular_2.ttf", name = "Darnassian Runes", full = false },
        { key = "moonRunes", path = FONT .. "MoonRunes-9Ymej.ttf", name = "Moon Runes", full = false },
        { key = "shalassian", path = FONT .. "ShalassianFont-Regular.ttf", name = "Shalassian", full = false },
        { key = "wrath", path = FONT .. "b_wrath.ttf", name = "Wrath", full = false },
        { key = "ww2black", path = FONT .. "WW2BLACKLTRALT.TTF", name = "WW2 Black Letter", full = false },
        { key = "nightmarePills", path = FONT .. "NIGHTMARE_PILLS_-_DEMO.TTF", name = "Nightmare Pills", full = false },
    },
    activeKey = "default",
    activeBody = nil,
}

function Blackacre.UI.Theme.GetBodyFontCatalog()
    return Blackacre.UI.Theme.Fonts.catalog
end

function Blackacre.UI.Theme.GetBodyFontPath()
    local fonts = Blackacre.UI.Theme.Fonts
    if fonts.activeBody and fonts.activeBody ~= "" then
        return fonts.activeBody
    end
    local key = fonts.activeKey or "default"
    for _, row in ipairs(fonts.catalog or {}) do
        if row.key == key then
            return row.path
        end
    end
    return nil
end

local fontProbe

local function TrySetFont(region, path, size)
    if not region or not path or path == "" or not region.SetFont then
        return false
    end
    size = size or 14
    local ok = pcall(function() region:SetFont(path, size, "") end)
    if ok then
        return true
    end
    ok = pcall(function() region:SetFont(path, size) end)
    if ok then
        return true
    end
    local bare = path:gsub("%.[tT][tT][fF]$", ""):gsub("%.[oO][tT][fF]$", "")
    if bare ~= path then
        ok = pcall(function() region:SetFont(bare, size, "") end)
        if ok then
            return true
        end
        ok = pcall(function() region:SetFont(bare, size) end)
        if ok then
            return true
        end
    end
    return false
end

local function FontFileBase(path)
    path = (path or ""):gsub("/", "\\"):lower()
    local name = path:match("([^\\]+)$") or path
    return name:gsub("%.ttf$", ""):gsub("%.otf$", "")
end

--- True when the client actually bound this file (silent fallback is a failed load).
function Blackacre.UI.Theme.ProbeBodyFont(path)
    if not path or path == "" then
        return true
    end
    if not fontProbe then
        local host = CreateFrame("Frame", nil, UIParent)
        host:Hide()
        fontProbe = host:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    end
    return TrySetFont(fontProbe, path, 14)
end

local function FontLabel(key)
    for _, row in ipairs(Blackacre.UI.Theme.Fonts.catalog or {}) do
        if row.key == key then
            return row.name
        end
    end
    return key or "Default (WoW mail)"
end

local function RefreshOpenTome()
    if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.Refresh then
        pcall(Blackacre.Chronicle.UI.Refresh)
    end
    if Blackacre.TomeHub and Blackacre.TomeHub.Refresh then
        pcall(Blackacre.TomeHub.Refresh)
    end
end

--- Apply body font key (tome body + sticky notes only). Persists to AceDB when available.
function Blackacre.UI.Theme.SetBodyFontKey(key, silent)
    local fonts = Blackacre.UI.Theme.Fonts
    key = key or "default"
    local path = nil
    local found = false
    for _, row in ipairs(fonts.catalog or {}) do
        if row.key == key then
            path = row.path
            found = true
            break
        end
    end
    if not found then
        key = "default"
        path = nil
    end
    local label = FontLabel(key)
    if path and not Blackacre.UI.Theme.ProbeBodyFont(path) then
        fonts.activeKey = "default"
        fonts.activeBody = nil
        local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
        if settings then settings.bodyFontKey = "default" end
        if Blackacre.Print then
            Blackacre.Print("Tome Font failed to load: " .. tostring(label) .. " — kept Default")
        end
        RefreshOpenTome()
        return false
    end
    fonts.activeKey = key
    fonts.activeBody = path
    local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    if settings then settings.bodyFontKey = key end
    if not silent and Blackacre.Print then
        Blackacre.Print("Tome Font Enabled: " .. tostring(label))
    end
    RefreshOpenTome()
    return true
end

function Blackacre.UI.Theme.LoadBodyFontFromDB(silent)
    local key = "default"
    local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    if settings and settings.bodyFontKey then key = settings.bodyFontKey end
    -- Announce after /reload when a non-default face is saved.
    Blackacre.UI.Theme.SetBodyFontKey(key, silent or key == "default")
end

--- Solid filled panel (no stretched quest art gaps).
function Blackacre.UI.Theme.ApplyFilledPanel(frame, alpha, style)
    alpha = alpha or 0.96
    style = style or "page"
    local bg = Blackacre.UI.Theme.Textures.white
    local edge = Blackacre.UI.Theme.Textures.tooltipEdge
    local edgeSize = 14
    local c
    if style == "book" then
        edge = Blackacre.UI.Theme.Textures.dialogEdge
        edgeSize = 24
        c = Blackacre.UI.Theme.Colors.pageFill
    elseif style == "panel" then
        c = Blackacre.UI.Theme.Colors.parchment
    else
        c = Blackacre.UI.Theme.Colors.page
    end
    frame:SetBackdrop({
        bgFile = bg,
        edgeFile = edge,
        tile = true,
        tileSize = 16,
        edgeSize = edgeSize,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    frame:SetBackdropColor(c[1], c[2], c[3], alpha)
    local e = Blackacre.UI.Theme.Colors.edge
    frame:SetBackdropBorderColor(e[1], e[2], e[3], 1)
end

function Blackacre.UI.Theme.ApplyParchmentBackdrop(frame, alpha)
    Blackacre.UI.Theme.ApplyFilledPanel(frame, alpha or 0.95, "panel")
end

function Blackacre.UI.Theme.ApplyBookBackdrop(frame, alpha)
    alpha = alpha or 0.98
    local Layer = Blackacre.UI.Theme.Layer
    -- Backdrop = frame chrome (fill + edge). Extra art uses explicit layers (Ep. 5 model).
    -- Solid cover fill (never stretch QuestBG — that left empty corners)
    frame:SetBackdrop({
        bgFile = Blackacre.UI.Theme.Textures.white,
        edgeFile = Blackacre.UI.Theme.Textures.dialogEdge,
        tile = true,
        tileSize = 32,
        edgeSize = 28,
        insets = { left = 10, right = 10, top = 10, bottom = 10 },
    })
    local cover = Blackacre.UI.Theme.Colors.cover
    frame:SetBackdropColor(cover[1], cover[2], cover[3], alpha)
    local g = Blackacre.UI.Theme.Colors.gold
    frame:SetBackdropBorderColor(g[1] * 0.75, g[2] * 0.65, g[3] * 0.4, 1)

    if not frame._baSpine then
        -- BACKGROUND sublevel -8: spine (further back)
        local spine = Blackacre.UI.Theme.CreateLayeredTexture(frame, Layer.BACKGROUND, -8)
        spine:SetPoint("TOPLEFT", 6, -8)
        spine:SetPoint("BOTTOMLEFT", 6, 8)
        spine:SetWidth(22)
        local s = Blackacre.UI.Theme.Colors.spine
        spine:SetColorTexture(s[1], s[2], s[3], 1)
        frame._baSpine = spine

        -- BACKGROUND sublevel -6: page wash (in front of spine, still behind ARTWORK)
        local wash = Blackacre.UI.Theme.CreateLayeredTexture(frame, Layer.BACKGROUND, -6)
        wash:SetPoint("TOPLEFT", 28, -12)
        wash:SetPoint("BOTTOMRIGHT", -12, 12)
        local p = Blackacre.UI.Theme.Colors.pageFill
        wash:SetColorTexture(p[1], p[2], p[3], 0.97)
        frame._baWash = wash

        -- ARTWORK: ribbon ornament (above background washes)
        local ribbon = Blackacre.UI.Theme.CreateLayeredTexture(frame, Layer.ARTWORK, 0)
        ribbon:SetPoint("TOP", frame, "TOP", 48, 4)
        ribbon:SetSize(26, 40)
        ribbon:SetColorTexture(0.55, 0.12, 0.12, 0.9)
        frame._baRibbon = ribbon
    end
end

function Blackacre.UI.Theme.ApplyPagePanel(frame, alpha)
    Blackacre.UI.Theme.ApplyFilledPanel(frame, alpha or 0.92, "page")
end

--- Pass A skeleton chrome: plain box + border only (no spine/ribbon/parchment art).
--- Use until owner approves layout; Pass B swaps to Achievement-frame art.
function Blackacre.UI.Theme.ApplySkeletonPanel(frame, alpha)
    alpha = alpha or 0.95
    frame:SetBackdrop({
        bgFile = Blackacre.UI.Theme.Textures.white,
        edgeFile = Blackacre.UI.Theme.Textures.tooltipEdge,
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    -- Neutral gray fill so regions read as structure, not final art
    frame:SetBackdropColor(0.18, 0.18, 0.20, alpha)
    frame:SetBackdropBorderColor(0.55, 0.55, 0.58, 1)
end

local function SkeletonRegionLabel(parent, text)
    local fs = Blackacre.UI.Theme.CreateLayeredFontString(parent, Blackacre.UI.Theme.Layer.OVERLAY, "GameFontDisableSmall")
    fs:SetPoint("TOPRIGHT", -6, -4)
    fs:SetText(text)
    fs:SetTextColor(0.65, 0.65, 0.7, 0.85)
    return fs
end

--- Outer Tome: Adventure Guide–inspired open book.
--- Returns: .header, .tabBar (horizontal EJ-style), .chronicleBookmark,
---          .bookOpen, .leftPage, .rightPage, .pageHost (alias rightPage for mounts),
---          .prevPageBtn, .nextPageBtn, .footer, .title, .closeButton
--- Outer Tome shell: single centered book art, bottom tabs, parent footer tools, one close X.
--- Returns: header, tabBar, bookOpen, leftPage, rightPage, pageHost, chronicleBookmark,
---          prevPageBtn, nextPageBtn, pageLabel, footer, toolStrip, title, closeButton
function Blackacre.UI.Theme.CreateBookShell(name, titleText)
    local Layer = Blackacre.UI.Theme.Layer

    -- Taller shell so region 4 (book art) is not cropped by header/rail/footer.
    local WIDTH, HEIGHT = 980, 720
    local HEADER_H = 34
    local TAB_H = 22
    local FOOTER_H = 36
    local PAD = 12
    local GAP = 4

    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    tinsert(UISpecialFrames, name)

    frame._baShellPass = "B"
    Blackacre.UI.Theme.ApplyBookShellChrome(frame)

    -- HEADER
    frame.header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.header:SetPoint("TOPLEFT", PAD, -PAD)
    frame.header:SetPoint("TOPRIGHT", -PAD, -PAD)
    frame.header:SetHeight(HEADER_H)
    frame.header:EnableMouse(true)
    frame.header:RegisterForDrag("LeftButton")
    frame.header:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    Blackacre.UI.Theme.ApplyBookChromeBar(frame.header, "header")
    frame.header:SetFrameLevel((frame:GetFrameLevel() or 1) + 30)

    frame.title = Blackacre.UI.Theme.CreateLayeredFontString(frame.header, Layer.OVERLAY, "GameFontNormalHuge")
    frame.title:SetPoint("LEFT", 14, 0)
    frame.title:SetJustifyH("LEFT")
    if frame.title.SetWordWrap then frame.title:SetWordWrap(false) end
    frame.title:SetText(titleText or "Traveler's Chronicle")
    Blackacre.UI.Theme.GoldTitle(frame.title)

    -- Stock labeled close (no experimental icon BLP)
    local close = CreateFrame("Button", nil, frame.header, "UIPanelButtonTemplate")
    close:SetSize(32, 26)
    close:SetPoint("RIGHT", -8, 0)
    close:SetFrameLevel((frame.header:GetFrameLevel() or 1) + 5)
    close:SetText("X")
    close:SetScript("OnClick", function() frame:Hide() end)
    frame.closeButton = close
    close:Show()

    -- Add blank chronicle page. Same header row as X; smaller than the close button.
    local addPage = CreateFrame("Button", nil, frame.header)
    addPage:SetSize(22, 22)
    addPage:SetPoint("RIGHT", close, "LEFT", -6, 0)
    addPage:SetFrameLevel((frame.header:GetFrameLevel() or 1) + 5)
    local addTex = addPage:CreateTexture(nil, "ARTWORK")
    addTex:SetAllPoints(addPage)
    if not Blackacre.UI.Theme.TrySetAtlas(addTex, "GarrMission_MissionIcon-Logistics", false) then
        addTex:SetTexture("Interface\\Garrison\\GarrisonMissionTypeIcons")
    end
    addPage.icon = addTex
    local addHi = addPage:CreateTexture(nil, "HIGHLIGHT")
    addHi:SetAllPoints(addPage)
    if Blackacre.UI.Theme.TrySetAtlas(addHi, "GarrMission_MissionIcon-Logistics", false) then
        addHi:SetAlpha(0.35)
    else
        addHi:SetColorTexture(1, 1, 1, 0.2)
    end
    addPage:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Add page")
        GameTooltip:Show()
    end)
    addPage:SetScript("OnLeave", function() GameTooltip:Hide() end)
    addPage:SetScript("OnClick", function()
        Blackacre.UI.Theme.PlayUISound("toolClick")
        if Blackacre.Chronicle and Blackacre.Chronicle.Capture and Blackacre.Chronicle.Capture.AddManual then
            Blackacre.Chronicle.Capture.AddManual("Untitled", "")
        end
        if frame.journalToggle and not frame.journalToggle._baOn then
            frame.journalToggle:Click()
        end
    end)
    frame.addPageBtn = addPage
    addPage:Show()
    frame.title:SetPoint("RIGHT", addPage, "LEFT", -8, 0)

    -- FOOTER — raised above book art so tools never disappear
    frame.footer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.footer:SetPoint("BOTTOMLEFT", PAD, PAD)
    frame.footer:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    frame.footer:SetHeight(FOOTER_H)
    Blackacre.UI.Theme.ApplyBookChromeBar(frame.footer, "footer")
    frame.footer:SetFrameLevel((frame:GetFrameLevel() or 1) + 30)

    -- Labeled stock buttons (same layout/function as E0; no framed BLP icons)
    local fl = (frame.footer:GetFrameLevel() or 1) + 5
    local function Tip(btn, title, body)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(title)
            if body then GameTooltip:AddLine(body, 0.85, 0.85, 0.85, true) end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    frame.journalToggle = CreateFrame("Button", nil, frame.footer, "UIPanelButtonTemplate")
    -- "Journaling: Locked" is wider than the old "Journal: Off" label.
    frame.journalToggle:SetSize(200, 26)
    frame.journalToggle:SetPoint("LEFT", 12, 0)
    frame.journalToggle:SetFrameLevel(fl)
    frame.journalToggle:SetText("Journaling: Locked")
    frame.journalToggle._baOn = false
    Tip(frame.journalToggle, "Edit Journal", "Edits save automatically as you type")
    frame.journalToggle:SetScript("OnClick", function(self)
        local wasOn = self._baOn
        self._baOn = not self._baOn
        self:SetText(self._baOn and "Journaling: On" or "Journaling: Locked")
        if wasOn and not self._baOn then
            if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.SaveSelected then
                Blackacre.Chronicle.UI.SaveSelected()
            end
        end
        Blackacre.UI.Theme.PlayUISound("journalToggle")
        if Blackacre.TomeHub and Blackacre.TomeHub.OnJournalToggle then
            Blackacre.TomeHub.OnJournalToggle(self._baOn)
        end
    end)

    frame.backstoryBtn = CreateFrame("Button", nil, frame.footer, "UIPanelButtonTemplate")
    frame.backstoryBtn:SetSize(90, 26)
    frame.backstoryBtn:SetPoint("RIGHT", -10, 0)
    frame.backstoryBtn:SetFrameLevel(fl)
    frame.backstoryBtn:SetText("Backstory")
    Tip(frame.backstoryBtn, "Backstory Menus")
    frame.backstoryBtn:SetScript("OnClick", function()
        Blackacre.UI.Theme.PlayUISound("toolClick")
        if Blackacre.TomeHub and Blackacre.TomeHub.ToggleBackstoryMenu then
            Blackacre.TomeHub.ToggleBackstoryMenu()
        end
    end)

    frame.pageJump = CreateFrame("EditBox", nil, frame.footer, "InputBoxTemplate")
    frame.pageJump:SetSize(36, 20)
    frame.pageJump:SetPoint("RIGHT", frame.backstoryBtn, "LEFT", -44, 0)
    frame.pageJump:SetAutoFocus(false)
    frame.pageJump:SetNumeric(true)
    frame.pageJump:SetMaxLetters(4)
    frame.pageJump:SetText("1")
    frame.pageJump:SetFrameLevel(fl)
    frame.pageJump:SetScript("OnEnterPressed", function(self)
        local n = tonumber(self:GetText())
        if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.GoToPage then
            Blackacre.Chronicle.UI.GoToPage(n)
        end
        self:ClearFocus()
    end)

    frame.pageJumpBtn = CreateFrame("Button", nil, frame.footer, "UIPanelButtonTemplate")
    frame.pageJumpBtn:SetSize(36, 24)
    frame.pageJumpBtn:SetPoint("LEFT", frame.pageJump, "RIGHT", 2, 0)
    frame.pageJumpBtn:SetFrameLevel(fl)
    frame.pageJumpBtn:SetText("Go")
    Tip(frame.pageJumpBtn, "Jump to page")
    frame.pageJumpBtn:SetScript("OnClick", function()
        Blackacre.UI.Theme.PlayUISound("toolClick")
        local n = tonumber(frame.pageJump:GetText())
        if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.GoToPage then
            Blackacre.Chronicle.UI.GoToPage(n)
        end
    end)

    frame.addNoteBtn = CreateFrame("Button", nil, frame.footer, "UIPanelButtonTemplate")
    frame.addNoteBtn:SetSize(80, 26)
    frame.addNoteBtn:SetPoint("RIGHT", frame.pageJump, "LEFT", -8, 0)
    frame.addNoteBtn:SetFrameLevel(fl)
    frame.addNoteBtn:SetText("Add note")
    Tip(frame.addNoteBtn, "Add note", "Click and place a scrap note")
    frame.addNoteBtn:SetScript("OnClick", function()
        Blackacre.UI.Theme.PlayUISound("toolClick")
        if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.BeginPinMode then
            Blackacre.Chronicle.UI.BeginPinMode()
        end
    end)
    frame.pinHereBtn = nil

    frame.toolStrip = CreateFrame("Frame", nil, frame.footer)
    frame.toolStrip:SetPoint("LEFT", frame.journalToggle, "RIGHT", 8, 0)
    frame.toolStrip:SetPoint("RIGHT", frame.addNoteBtn, "LEFT", -8, 0)
    frame.toolStrip:SetHeight(30)
    frame.toolStrip:SetFrameLevel((frame.footer:GetFrameLevel() or 1) + 2)

    -- Slim rail above footer (no IC feature tabs — reserved for page tools strip spacing)
    frame.tabBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.tabBar:SetPoint("BOTTOMLEFT", frame.footer, "TOPLEFT", 0, GAP)
    frame.tabBar:SetPoint("BOTTOMRIGHT", frame.footer, "TOPRIGHT", 0, GAP)
    frame.tabBar:SetHeight(TAB_H)
    frame.tabBar:SetBackdrop({
        bgFile = Blackacre.UI.Theme.Textures.white,
        edgeFile = nil,
        tile = true, tileSize = 8, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame.tabBar:SetBackdropColor(0.12, 0.09, 0.06, 0.5)
    frame.tabRail = frame.tabBar
    -- Region 9: under-book rail (skin pack)
    do
        local rail = frame.tabBar:CreateTexture(nil, "ARTWORK")
        rail:SetAllPoints(frame.tabBar)
        if rail.SetHorizTile then rail:SetHorizTile(true) end
        if rail.SetVertTile then rail:SetVertTile(false) end
        if rail.SetDrawLayer then rail:SetDrawLayer("ARTWORK", 0) end
        frame.tabBar:SetBackdropColor(0.12, 0.09, 0.06, 0.5)
        frame.tabBar.atlasFill = rail
        Blackacre.UI.Theme.ApplyRail(frame)
    end

    -- BOOK OPEN between header and tabs (fills middle of shell)
    frame.bookOpen = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.bookOpen:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 0, -GAP)
    frame.bookOpen:SetPoint("BOTTOMRIGHT", frame.tabBar, "TOPRIGHT", 0, GAP)
    frame.bookOpen:SetScript("OnSizeChanged", function(self)
        Blackacre.UI.Theme.FitBookArtToFrame(self)
    end)
    frame.bookOpen:SetScript("OnShow", function(self)
        Blackacre.UI.Theme.FitBookArtToFrame(self)
    end)
    Blackacre.UI.Theme.FitBookArtToFrame(frame.bookOpen)
    -- Region 9 sits above the book art and behind the NineSlice border.
    frame.tabBar:SetFrameLevel((frame:GetFrameLevel() or 1) + 40)

    -- Region 8: TOC tab. Size locked (50% of Alliance crop). Top aligned to bookOpen.
    frame.chronicleBookmark = CreateFrame("Button", nil, frame, "BackdropTemplate")
    frame.chronicleBookmark:SetSize(36, 128)
    frame.chronicleBookmark:SetPoint("TOPLEFT", frame.bookOpen, "TOPLEFT", -4, 0)
    frame.chronicleBookmark:SetFrameLevel((frame:GetFrameLevel() or 1) + 62)
    frame.chronicleBookmark:SetBackdrop({
        bgFile = Blackacre.UI.Theme.Textures.white,
        edgeFile = Blackacre.UI.Theme.Textures.tooltipEdge,
        tile = true, tileSize = 8, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame.chronicleBookmark:SetBackdropColor(0.45, 0.28, 0.12, 0.98)
    frame.chronicleBookmark:SetBackdropBorderColor(0.95, 0.80, 0.35, 1)
    -- Region 8: TOC tab (skin pack UV crop)
    do
        local banner = frame.chronicleBookmark:CreateTexture(nil, "ARTWORK")
        banner:SetAllPoints(frame.chronicleBookmark)
        banner:SetAlpha(1)
        if banner.SetVertexColor then banner:SetVertexColor(1, 1, 1, 1) end
        frame.chronicleBookmark.banner = banner
        Blackacre.UI.Theme.ApplyTocBookmark(frame)
    end
    local bmLabel = frame.chronicleBookmark:CreateFontString(nil, Layer.OVERLAY, "GameFontNormalSmall")
    bmLabel:SetPoint("CENTER", 0, 0)
    bmLabel:SetWidth(12)
    bmLabel:SetWordWrap(true)
    bmLabel:SetText("")
    bmLabel:SetTextColor(1, 1, 1, 1)
    frame.chronicleBookmark.label = bmLabel
    frame.chronicleBookmark:SetScript("OnClick", function()
        Blackacre.UI.Theme.PlayUISound("pageTurn")
        if Blackacre.TomeHub and Blackacre.TomeHub.Show then
            Blackacre.TomeHub.Show("chronicle")
        end
        if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.GoToToc then
            Blackacre.Chronicle.UI.GoToToc()
        end
    end)
    frame.chronicleBookmark:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Table of Contents")
        GameTooltip:Show()
    end)
    frame.chronicleBookmark:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Gutter buffer ~50px each side so graphite text stays clear of the spine
    local GUTTER_PAD = 50

    -- Two equal leaves — above bookmark chrome so TOC rows receive clicks
    frame.leftPage = CreateFrame("Frame", nil, frame.bookOpen)
    frame.leftPage:SetPoint("TOPLEFT", frame.bookOpen, "TOPLEFT", 28, -20)
    frame.leftPage:SetPoint("BOTTOMRIGHT", frame.bookOpen, "BOTTOM", -GUTTER_PAD, 36)
    if frame.leftPage.SetClipsChildren then frame.leftPage:SetClipsChildren(true) end
    frame.leftPage:SetFrameLevel((frame.bookOpen:GetFrameLevel() or 1) + 10)
    frame.leftPage:EnableMouse(false)

    frame.rightPage = CreateFrame("Frame", nil, frame.bookOpen)
    frame.rightPage:SetPoint("TOPLEFT", frame.bookOpen, "TOP", GUTTER_PAD, -20)
    frame.rightPage:SetPoint("BOTTOMRIGHT", frame.bookOpen, "BOTTOMRIGHT", -28, 36)
    if frame.rightPage.SetClipsChildren then frame.rightPage:SetClipsChildren(true) end
    frame.rightPage:SetFrameLevel((frame.bookOpen:GetFrameLevel() or 1) + 10)
    frame.rightPage:EnableMouse(false)

    -- Soft center gutter
    frame.gutter = frame.bookOpen:CreateTexture(nil, Layer.ARTWORK)
    frame.gutter:SetColorTexture(0.05, 0.04, 0.03, 0.35)
    frame.gutter:SetWidth(6)
    frame.gutter:SetPoint("TOP", frame.bookOpen, "TOP", 0, -24)
    frame.gutter:SetPoint("BOTTOM", frame.bookOpen, "BOTTOM", 0, 40)

    frame.pageHost = CreateFrame("Frame", nil, frame.bookOpen)
    frame.pageHost:SetPoint("TOPLEFT", 28, -20)
    frame.pageHost:SetPoint("BOTTOMRIGHT", -28, 36)
    if frame.pageHost.SetClipsChildren then frame.pageHost:SetClipsChildren(true) end
    frame.pageHost:SetFrameLevel((frame.bookOpen:GetFrameLevel() or 1) + 3)
    frame.pageHost:Hide()

    -- Nav: < leftNum ..... rightNum >
    frame.prevPageBtn = CreateFrame("Button", nil, frame.bookOpen, "UIPanelButtonTemplate")
    frame.prevPageBtn:SetSize(36, 24)
    frame.prevPageBtn:SetPoint("BOTTOMLEFT", frame.leftPage, "BOTTOMLEFT", 8, -28)
    frame.prevPageBtn:SetFrameLevel((frame.bookOpen:GetFrameLevel() or 1) + 20)
    frame.prevPageBtn:SetText("<")
    frame.prevPageBtn:Show()
    frame.prevPageBtn:SetScript("OnClick", function()
        if Blackacre.TomeHub and Blackacre.TomeHub.TurnPage then
            Blackacre.TomeHub.TurnPage(-1)
        end
    end)

    -- Page numbers with subtle sky-glow underlay (owner: Warlords sky glow as soft mask)
    local function MakePageNum(anchorPoint, relTo, relPoint, ox, oy)
        local holder = CreateFrame("Frame", nil, frame.bookOpen)
        holder:SetSize(36, 22)
        holder:SetPoint(anchorPoint, relTo, relPoint, ox, oy)
        holder:SetFrameLevel((frame.bookOpen:GetFrameLevel() or 1) + 7)
        local fs = holder:CreateFontString(nil, Layer.OVERLAY, "GameFontNormal")
        fs:SetPoint("CENTER", 0, 0)
        local ink = Blackacre.UI.Theme.Colors.ink
        fs:SetTextColor(ink[1], ink[2], ink[3], 1)
        holder.text = fs
        return holder, fs
    end

    local leftHold, leftFs = MakePageNum("LEFT", frame.prevPageBtn, "RIGHT", 6, 0)
    leftFs:SetText("1")
    frame.leftPageNumHolder = leftHold
    frame.leftPageNum = leftFs

    frame.nextPageBtn = CreateFrame("Button", nil, frame.bookOpen, "UIPanelButtonTemplate")
    frame.nextPageBtn:SetSize(36, 24)
    frame.nextPageBtn:SetPoint("BOTTOMRIGHT", frame.rightPage, "BOTTOMRIGHT", -8, -28)
    frame.nextPageBtn:SetFrameLevel((frame.bookOpen:GetFrameLevel() or 1) + 20)
    frame.nextPageBtn:SetText(">")
    frame.nextPageBtn:Show()
    frame.nextPageBtn:SetScript("OnClick", function()
        if Blackacre.TomeHub and Blackacre.TomeHub.TurnPage then
            Blackacre.TomeHub.TurnPage(1)
        end
    end)

    local rightHold, rightFs = MakePageNum("RIGHT", frame.nextPageBtn, "LEFT", -6, 0)
    rightFs:SetText("2")
    frame.rightPageNumHolder = rightHold
    frame.rightPageNum = rightFs

    -- Legacy aliases (jump lives on footer now; no center book label)
    frame.pageLabel = nil

    return frame
end

function Blackacre.UI.Theme.MountInPage(frame, parent)
    if not frame or not parent then return end
    frame:SetParent(parent)
    frame:ClearAllPoints()
    frame:SetAllPoints(parent)
    frame:SetMovable(false)
    frame:EnableMouse(true)
    frame:SetFrameStrata(parent:GetFrameStrata() or "HIGH")
    if frame.SetClipsChildren then
        frame:SetClipsChildren(true)
    end
    -- Strip freestanding chrome if present
    if frame.closeButton then frame.closeButton:Hide() end
    for _, child in ipairs({ frame:GetChildren() }) do
        if child.GetObjectType and child:GetObjectType() == "Button" then
            local n = child:GetName() or ""
            if n:find("Close") or (child.GetNormalTexture and child:GetWidth() <= 32 and child:GetHeight() <= 32
                and child:GetPoint(1) and select(1, child:GetPoint(1)) == "TOPRIGHT") then
                -- leave generic small buttons; hide UIPanelCloseButton-like
            end
        end
    end
end

function Blackacre.UI.Theme.SealLabel(scopeTier)
    local seal = Blackacre.UI.Theme.Seals[scopeTier or "INDIVIDUAL"]
        or Blackacre.UI.Theme.Seals.INDIVIDUAL
    return seal.label, seal.short, seal.color
end

function Blackacre.UI.Theme.FormatSealPrefix(scopeTier)
    local _, short, color = Blackacre.UI.Theme.SealLabel(scopeTier)
    return string.format("|cff%02x%02x%02x[%s]|r ",
        math.floor((color[1] or 0.5) * 255),
        math.floor((color[2] or 0.5) * 255),
        math.floor((color[3] or 0.5) * 255),
        short)
end

function Blackacre.UI.Theme.InkFont(fontString, size)
    if not fontString then return end
    local c = Blackacre.UI.Theme.Colors.ink
    if size == "title" then
        fontString:SetFontObject(GameFontNormalHuge or GameFontNormalLarge)
    elseif size == "header" then
        fontString:SetFontObject(GameFontNormalLarge)
    else
        fontString:SetFontObject(GameFontHighlightLarge or GameFontHighlight)
    end
    fontString:SetTextColor(c[1], c[2], c[3])
end

function Blackacre.UI.Theme.GoldTitle(fontString)
    if not fontString then return end
    fontString:SetFontObject(GameFontNormalHuge or GameFontNormalLarge)
    local g = Blackacre.UI.Theme.Colors.gold
    fontString:SetTextColor(g[1], g[2], g[3])
end

--- In-game letter / mail style body text (larger, readable).
function Blackacre.UI.Theme.ApplyMailBodyFont(region, extraSize)
    if not region then return end
    extraSize = extraSize or 2
    local fontPath, fontSize, fontFlags
    if MailTextFontNormal and MailTextFontNormal.GetFont then
        fontPath, fontSize, fontFlags = MailTextFontNormal:GetFont()
    elseif QuestFontNormalLarge and QuestFontNormalLarge.GetFont then
        fontPath, fontSize, fontFlags = QuestFontNormalLarge:GetFont()
    elseif QuestFont and QuestFont.GetFont then
        fontPath, fontSize, fontFlags = QuestFont:GetFont()
    else
        fontPath, fontSize, fontFlags = GameFontHighlight:GetFont()
    end
    if fontPath then
        region:SetFont(fontPath, (fontSize or 14) + extraSize, fontFlags or "")
    end
    local c = Blackacre.UI.Theme.Colors.ink
    if region.SetTextColor then
        region:SetTextColor(c[1], c[2], c[3])
    end
end


--- Active book-art path for inspection (/ba bookart also prints this).
function Blackacre.UI.Theme.GetBookArtPath()
    return Blackacre.UI.Theme.Textures.bookArt
        or Blackacre.UI.Theme.Textures.ejJournalBG
        or "Interface\\EncounterJournal\\UI-EJ-JournalBG"
end

--- Fit Adventure Journal texture to bookOpen.
--- File: Interface\EncounterJournal\UI-EJ-JournalBG
---
--- Blizzard does NOT use the full BLP: they SetTexCoord to crop packing grey.
--- From Gethe/wow-ui-source Blizzard_EncounterJournal.xml (Mainline):
---   <Texture file="Interface\EncounterJournal\UI-EJ-JournalBG">
---     <TexCoords left="0" right="0.766601562" top="0" bottom="0.830078125"/>
--- That is ~23% off the right and ~17% off the bottom of the source image.
--- We use the same coords, then stretch that region to fill bookOpen.
function Blackacre.UI.Theme.FitBookArtToFrame(host)
    if not host then return end
    local path = Blackacre.UI.Theme.GetBookArtPath()
    local tc = Blackacre.UI.Theme.Textures.bookArtTexCoords or {
        left = 0, right = 0.766601562, top = 0, bottom = 0.830078125,
    }

    if host._baBookArtFrame then
        host._baBookArtFrame:Hide()
        host._baBookArtFrame:SetParent(nil)
        host._baBookArtFrame = nil
    end
    host._baFixedBookW = nil
    host._baFixedBookH = nil

    if host.SetBackdrop then
        host:SetBackdrop(nil)
    end

    local Layer = Blackacre.UI.Theme.Layer
    local tex = host._baBookArt
    if not tex then
        tex = host:CreateTexture(nil, Layer.ARTWORK, nil, -8)
        host._baBookArt = tex
    end
    if tex.SetDrawLayer then
        tex:SetDrawLayer(Layer.ARTWORK, -8)
    end
    tex:SetTexture(path)
    tex:SetVertexColor(1, 1, 1, 1)
    tex:SetAlpha(1)
    if tex.SetHorizTile then tex:SetHorizTile(false) end
    if tex.SetVertTile then tex:SetVertTile(false) end

    -- Blizzard official crop (not full 0–1 of the BLP)
    tex:SetTexCoord(tc.left or 0, tc.right or 1, tc.top or 0, tc.bottom or 1)

    tex:ClearAllPoints()
    tex:SetAllPoints(host)
    tex:Show()
end

--- Back-compat name used by older call sites / OnSizeChanged.
function Blackacre.UI.Theme.ApplyCenteredBookArt(host)
    Blackacre.UI.Theme.FitBookArtToFrame(host)
end

--- Map symbols fancy fonts often lack to plain ASCII letters/spaces.
--- (Cannot use Default font for | only — WoW draws each string in ONE font.)
function Blackacre.UI.Theme.SanitizeBodyText(text)
    if not text or text == "" then return text end
    if not Blackacre.UI.Theme.GetBodyFontPath or not Blackacre.UI.Theme.GetBodyFontPath() then
        return text
    end
    -- Unicode / fancy punctuation
    text = text:gsub("–", "-")
    text = text:gsub("—", "-")
    text = text:gsub("…", "...")
    text = text:gsub("·", " - ")
    text = text:gsub("•", "*")
    text = text:gsub("“", "\"")
    text = text:gsub("”", "\"")
    text = text:gsub("‘", "'")
    text = text:gsub("’", "'")
    -- ASCII symbols that often become □ in script fonts → word-safe substitutes
    text = text:gsub("|", " / ")
    text = text:gsub("\\", "/")
    text = text:gsub("%[", "(")
    text = text:gsub("%]", ")")
    text = text:gsub("%{", "(")
    text = text:gsub("%}", ")")
    text = text:gsub("<", "(")
    text = text:gsub(">", ")")
    text = text:gsub("~", "-")
    text = text:gsub("`", "'")
    text = text:gsub("@", " at ")
    text = text:gsub("#", " no.")
    text = text:gsub("%^", " ")
    text = text:gsub("_", " ")
    return text
end

function Blackacre.UI.Theme.ApplyReadableBodyFont(region, extraSize)
    if not region then return end
    extraSize = extraSize or 1
    local size = 14 + extraSize
    local custom = Blackacre.UI.Theme.GetBodyFontPath and Blackacre.UI.Theme.GetBodyFontPath()
    local applied = false
    if custom then
        applied = TrySetFont(region, custom, size)
        -- If fancy font failed to load entirely, fall back to game Friz (full charset)
        if not applied then
            applied = TrySetFont(region, WOW_FRIZ, size)
        end
    end
    if not applied then
        Blackacre.UI.Theme.ApplyMailBodyFont(region, extraSize)
    end
    -- Graphite pencil-lead (titles use GoldTitle separately — not this)
    local c = Blackacre.UI.Theme.Colors.ink
    if region.SetTextColor then
        region:SetTextColor(c[1], c[2], c[3], 1)
    end
    if region.SetShadowColor then
        region:SetShadowColor(1, 1, 1, 0.15)
    end
end

function Blackacre.UI.Theme.GetChromeFaction()
    local f = UnitFactionGroup and UnitFactionGroup("player")
    if f == "Horde" then return "Horde" end
    return "Alliance"
end

--- Saved options id: "auto" | "Alliance" | "Horde" | future pack names.
function Blackacre.UI.Theme.GetActiveSkinId()
    local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    local saved = settings and settings.chromeSkin
    if saved and saved ~= "auto" and Blackacre.UI.Theme.Skins[saved] then
        return saved
    end
    return Blackacre.UI.Theme.GetChromeFaction()
end

function Blackacre.UI.Theme.GetActiveSkin()
    local id = Blackacre.UI.Theme.GetActiveSkinId()
    return Blackacre.UI.Theme.Skins[id] or Blackacre.UI.Theme.Skins.Alliance
end

function Blackacre.UI.Theme.SetActiveSkin(id)
    local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    if not settings then return end
    if id ~= "auto" and not Blackacre.UI.Theme.Skins[id] then return end
    settings.chromeSkin = id or "auto"
    if Blackacre.UI.Theme.RefreshChrome then
        Blackacre.UI.Theme.RefreshChrome()
    end
end

function Blackacre.UI.Theme.ApplyRail(frame)
    if not frame or not frame.tabBar then return end
    local rail = frame.tabBar.atlasFill
    if not rail then return end
    local skin = Blackacre.UI.Theme.GetActiveSkin()
    local bar = frame.tabBar
    local h = skin.railHeight or 22
    bar:SetHeight(h)

    local railAtlas = Blackacre.UI.Theme.PickAtlas({
        skin.tocTitleMid, skin.rail, "_Neutral-NineSlice-EdgeBottom",
    })
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(railAtlas)
    if info then
        Blackacre.UI.Theme.TrySetAtlas(rail, railAtlas, false)
    elseif not Blackacre.UI.Theme.TrySetAtlas(rail, railAtlas, false) then
        rail:SetTexture("Interface\\QuestionFrame\\Warboard")
    end
    -- Atlas names beginning with '_' are defined as horizontal tiles. ApplyRail
    -- sizes the strip to the exact 9S field; tiling preserves the middle art
    -- instead of stretching it across the full window width.
    if rail.SetHorizTile then rail:SetHorizTile(true) end
    if rail.SetVertTile then rail:SetVertTile(false) end

    local factionSkin = skin.ninesliceLayout == "BFAMissionAlliance" or skin.ninesliceLayout == "BFAMissionHorde"
    local hasCaps = (not factionSkin) and (skin.tocTitleLeft or skin.titleLeft or skin.tocTitleRight or skin.titleRight)

    if hasCaps then
        bar.titleLeft = bar.titleLeft or bar:CreateTexture(nil, "OVERLAY")
        bar.titleRight = bar.titleRight or bar:CreateTexture(nil, "OVERLAY")

        local leftAtlas = Blackacre.UI.Theme.PickAtlas({ skin.tocTitleLeft, skin.titleLeft, skin.ninesliceCornerTL, skin.ninesliceCorner })
        local rightAtlas = Blackacre.UI.Theme.PickAtlas({ skin.tocTitleRight, skin.titleRight, skin.ninesliceCornerTR, skin.ninesliceCorner })

        local leftInfo = leftAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(leftAtlas)
        local rightInfo = rightAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(rightAtlas)

        local capW = math.max(32, math.floor(h * 1.5))
        if leftInfo and leftInfo.width and leftInfo.height and leftInfo.height > 0 then
            capW = math.floor(h * (leftInfo.width / leftInfo.height))
        end

        bar.titleLeft:ClearAllPoints()
        bar.titleLeft:SetPoint("LEFT", bar, "LEFT", 0, 0)
        bar.titleLeft:SetSize(capW, h)

        bar.titleRight:ClearAllPoints()
        bar.titleRight:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
        bar.titleRight:SetSize(capW, h)

        -- An atlas name that fails to resolve used to leave the cap texture
        -- blank, exposing the bar's backdrop color underneath it instead of
        -- art. If either cap can't be painted, drop caps entirely for this
        -- render so the rail spans the full width instead of leaving a hole.
        local leftOk = leftAtlas and Blackacre.UI.Theme.TrySetAtlas(bar.titleLeft, leftAtlas, false)
        local rightOk = rightAtlas and Blackacre.UI.Theme.TrySetAtlas(bar.titleRight, rightAtlas, false)

        if leftOk and rightOk then
            bar.titleLeft:Show()
            bar.titleRight:Show()

            -- Center rail matches exact width between caps flush
            rail:ClearAllPoints()
            rail:SetPoint("LEFT", bar.titleLeft, "RIGHT", 0, 0)
            rail:SetPoint("RIGHT", bar.titleRight, "LEFT", 0, 0)
            rail:SetHeight(h)
        else
            bar.titleLeft:Hide()
            bar.titleRight:Hide()
            rail:ClearAllPoints()
            rail:SetAllPoints(bar)
        end
    else
        if bar.titleLeft then bar.titleLeft:Hide() end
        if bar.titleRight then bar.titleRight:Hide() end

        -- Spans entire width of 9S field
        rail:ClearAllPoints()
        rail:SetAllPoints(bar)
    end
end

--- Page bookmark tab (region: gutter edge of a bookmarked Chronicle page).
--- Owner-confirmed atlas: AlliedRace-UnlockingFrame-RaceBanner
--- (Interface/AlliedRaces/AlliedRacesUnlockingFramePart2). Full length, no
--- crop -- native aspect ratio scaled to whatever page height it's given.
--- flipH mirrors it for the left page, so it drapes toward the gutter from
--- the correct side instead of showing the same edge on both pages.
--- Returns the width the caller should reserve at the gutter, or nil if the
--- atlas didn't resolve (caller should fall back to a placeholder).
function Blackacre.UI.Theme.ApplyBookmarkTab(tex, targetHeight, flipH)
    if not tex then return nil end
    local atlasName = "AlliedRace-UnlockingFrame-RaceBanner"
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlasName)
    local file = info and (info.filename or info.file)
    if file then
        tex:SetTexture(file)
    elseif not Blackacre.UI.Theme.TrySetAtlas(tex, atlasName, false) then
        return nil
    end
    if tex.SetHorizTile then tex:SetHorizTile(false) end
    if tex.SetVertTile then tex:SetVertTile(false) end
    local l = (info and (info.leftTexCoord or info.left)) or 0
    local r = (info and (info.rightTexCoord or info.right)) or 1
    local t = (info and (info.topTexCoord or info.top)) or 0
    local b = (info and (info.bottomTexCoord or info.bottom)) or 1
    if flipH then
        tex:SetTexCoord(r, l, t, b)
    else
        tex:SetTexCoord(l, r, t, b)
    end
    local iw = (info and info.width) or 64
    local ih = (info and info.height) or 256
    local aspect = (ih > 0) and (iw / ih) or 0.25
    targetHeight = targetHeight or ih
    local width = math.max(4, targetHeight * aspect)
    return width, targetHeight
end

function Blackacre.UI.Theme.ApplyTocBookmark(frame)
    if not frame or not frame.chronicleBookmark then return end
    local banner = frame.chronicleBookmark.banner
    if not banner then return end
    local skin = Blackacre.UI.Theme.GetActiveSkin()
    local atlasName = Blackacre.UI.Theme.PickAtlas({
        skin.tocBanner, "spellbook-background-evergreen-ribbon", "AlliedRaces-AllianceHordeBanner",
    }) or "AlliedRaces-AllianceHordeBanner"
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlasName)
    local file = info and (info.filename or info.file)
    if file then
        banner:SetTexture(file)
    elseif not Blackacre.UI.Theme.TrySetAtlas(banner, atlasName, false) then
        return
    end
    local cropW = skin.tocUvWidth or 0.41268
    local startFrac = skin.tocUvStart or 0
    local l = (info and (info.leftTexCoord or info.left)) or 0
    local r = (info and (info.rightTexCoord or info.right)) or 1
    local t = (info and (info.topTexCoord or info.top)) or 0
    local b = (info and (info.bottomTexCoord or info.bottom)) or 1
    local span = r - l
    local s = l + span * startFrac
    local e = math.min(r, s + span * cropW)
    banner:SetTexCoord(s, e, t, b)
    local iw = (info and info.width) or 80
    local ih = (info and info.height) or 128
    local bw = math.max(28, math.min(48, (iw or 80) * (cropW or 1) * 0.5))
    -- Raised floor/ceiling: this regressed shorter at some point (per owner
    -- report), and it now also needs to be reliably taller than the page
    -- bookmark tab that stacks on top of it, so its tail still peeks out
    -- below as a clickable tongue instead of being fully covered.
    local bh = math.max(180, math.min(320, (ih or 128) * 0.5))
    frame.chronicleBookmark:SetSize(bw, bh)
    banner:SetAlpha(1)
    banner:ClearAllPoints()
    banner:SetAllPoints(frame.chronicleBookmark)
    if frame.chronicleBookmark.SetBackdrop then
        frame.chronicleBookmark:SetBackdrop(nil)
    end
    banner:Show()
end

function Blackacre.UI.Theme.RefreshChrome()
    local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
    if hub then
        Blackacre.UI.Theme.ApplyBookShellChrome(hub)
        Blackacre.UI.Theme.ApplyRail(hub)
        Blackacre.UI.Theme.ApplyTocBookmark(hub)
        if hub.header then Blackacre.UI.Theme.ApplyBookChromeBar(hub.header, "header") end
        if hub.footer then Blackacre.UI.Theme.ApplyBookChromeBar(hub.footer, "footer") end
    end
    local menu = _G.BlackacreBackstoryMenu
    if menu then
        Blackacre.UI.Theme.ApplyFactionFrameChrome(menu)
        if menu.header then Blackacre.UI.Theme.ApplyNeutralTitleBar(menu.header) end
    end
    if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.RenderSpread then
        Blackacre.Chronicle.UI.RenderSpread()
    end
end

function Blackacre.UI.Theme.ApplyChromeInset(frame, pad)
    pad = pad or 12
    if not frame or not frame.header then return end
    local skin = Blackacre.UI.Theme.GetActiveSkin()
    frame._baChromePad = pad
    frame.header:ClearAllPoints()
    frame.header:SetPoint("TOPLEFT", pad, -pad)
    frame.header:SetPoint("TOPRIGHT", -pad, -pad)
    if frame.footer then
        frame.footer:ClearAllPoints()
        frame.footer:SetPoint("BOTTOMLEFT", pad, pad)
        frame.footer:SetPoint("BOTTOMRIGHT", -pad, pad)
    end
    local closeOffX = skin.closeButtonOffsetX or -8
    if frame.closeButton then
        frame.closeButton:ClearAllPoints()
        frame.closeButton:SetPoint("RIGHT", closeOffX, 0)
    end
    if frame.addPageBtn and frame.closeButton then
        frame.addPageBtn:ClearAllPoints()
        frame.addPageBtn:SetPoint("RIGHT", frame.closeButton, "LEFT", -6, 0)
    end
    local titleOffX = (skin.titleOffsetX or 0) + 14
    if frame.title and frame.addPageBtn then
        frame.title:ClearAllPoints()
        frame.title:SetPoint("LEFT", titleOffX, 0)
        frame.title:SetPoint("RIGHT", frame.addPageBtn, "LEFT", -8, 0)
    end
    if frame.journalToggle then
        frame.journalToggle:ClearAllPoints()
        frame.journalToggle:SetPoint("LEFT", skin.journalToggleOffsetX or 12, 0)
    end
    if frame.backstoryBtn then
        frame.backstoryBtn:ClearAllPoints()
        frame.backstoryBtn:SetPoint("RIGHT", skin.footerRightOffsetX or -10, 0)
    end
    if frame.pageJump and frame.backstoryBtn then
        frame.pageJump:ClearAllPoints()
        frame.pageJump:SetPoint("RIGHT", frame.backstoryBtn, "LEFT", -44, 0)
    end
    if frame.pageJumpBtn and frame.pageJump then
        frame.pageJumpBtn:ClearAllPoints()
        frame.pageJumpBtn:SetPoint("LEFT", frame.pageJump, "RIGHT", 2, 0)
    end
    if frame.addNoteBtn and frame.pageJump then
        frame.addNoteBtn:ClearAllPoints()
        frame.addNoteBtn:SetPoint("RIGHT", frame.pageJump, "LEFT", -8, 0)
    end
    -- Title (2F) and footer (11F) stay behind the outer NineSlice so the shell overlaps them.
    local base = frame:GetFrameLevel() or 1
    if frame.header then frame.header:SetFrameLevel(base + 30) end
    if frame.footer then frame.footer:SetFrameLevel(base + 30) end
    if frame.tabBar then frame.tabBar:SetFrameLevel(base + 40) end
    if frame.chronicleBookmark then
        frame.chronicleBookmark:SetFrameLevel(base + 75)
    end
end

function Blackacre.UI.Theme.TrySetAtlas(tex, atlas, useAtlasSize)
    if not tex or not atlas or not tex.SetAtlas then return false end
    local ok = pcall(function()
        tex:SetAtlas(atlas, useAtlasSize and true or false)
    end)
    return ok
end

function Blackacre.UI.Theme.PickAtlas(names)
    if type(names) == "string" then
        names = { names }
    end
    if not names then return nil end
    for i = 1, #names do
        local n = names[i]
        if n and n ~= "" and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(n) then
            return n
        end
    end
    return names[1]
end

--- Region 1: Alliance BFA mission NineSlice, pushed out so it sits around (not under) children.
function Blackacre.UI.Theme.ApplyBookShellChrome(frame)
    if not frame or not frame.SetBackdrop then return end
    local T = Blackacre.UI.Theme.Textures
    frame:SetBackdrop({
        bgFile = T.white,
        edgeFile = nil,
        tile = true,
        tileSize = 32,
        edgeSize = 0,
        insets = { left = 12, right = 12, top = 12, bottom = 12 },
    })
    local cover = Blackacre.UI.Theme.Colors.cover
    frame:SetBackdropColor(cover[1], cover[2], cover[3], 0.97)
    if frame._baAchBorder then
        frame._baAchBorder:Hide()
    end

    local host = frame._baNineSlice
    if not host then
        host = CreateFrame("Frame", nil, frame)
        frame._baNineSlice = host
    end
    host:ClearAllPoints()
    host:EnableMouse(false)
    host:SetFrameLevel((frame:GetFrameLevel() or 1) + 70)
    host.layoutTextureLayer = "OVERLAY"
    host.layoutTextureSubLevel = 7

    local skin = Blackacre.UI.Theme.GetActiveSkin()
    local pick = Blackacre.UI.Theme.PickAtlas
    local kit = skin.kit or ""
    local factionSkin = (not kit or kit == "") and (skin.ninesliceLayout == "BFAMissionAlliance" or skin.ninesliceLayout == "BFAMissionHorde")
    local function exists(name)
        return name and name ~= "" and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
    end
    local layout
    local shellTexture = host._baShellAtlas
    if skin.shellAtlas then
        if not shellTexture then
            shellTexture = host:CreateTexture(nil, "OVERLAY", nil, 7)
            host._baShellAtlas = shellTexture
        end
        host:SetAllPoints(frame)
        shellTexture:ClearAllPoints()
        shellTexture:SetPoint("CENTER", host, "CENTER")
        local shellScale = skin.shellScale or 1
        shellTexture:SetSize(
            (frame:GetWidth() or 0) * shellScale,
            (frame:GetHeight() or 0) * shellScale
        )
        frame._baShellTexture = shellTexture
        if not frame._baShellScaleHooked then
            frame:HookScript("OnSizeChanged", function(self)
                local tex = self._baShellTexture
                if not tex then return end
                local activeSkin = Blackacre.UI.Theme.GetActiveSkin()
                local scale = activeSkin.shellScale or 1
                tex:SetSize(
                    (self:GetWidth() or 0) * scale,
                    (self:GetHeight() or 0) * scale
                )
            end)
            frame._baShellScaleHooked = true
        end
        if not Blackacre.UI.Theme.TrySetAtlas(shellTexture, skin.shellAtlas, false) then
            shellTexture:Hide()
        else
            shellTexture:Show()
        end
        host.layoutType = "SingleShellAtlasLayout"
    elseif factionSkin then
        if shellTexture then shellTexture:Hide() end
        -- Original Alliance / Horde chrome: one mirrored corner, matching edge tiles.
        local corner = skin.ninesliceCorner
        local edgeH = skin.ninesliceTileH
        local edgeV = skin.ninesliceTileV
        layout = {
            mirrorLayout = true,
            TopLeftCorner = { atlas = corner, layer = "OVERLAY", subLevel = 7, x = -12, y = 12 },
            TopRightCorner = { atlas = corner, layer = "OVERLAY", subLevel = 7, x = 12, y = 12 },
            BottomLeftCorner = { atlas = corner, layer = "OVERLAY", subLevel = 7, x = -12, y = -12 },
            BottomRightCorner = { atlas = corner, layer = "OVERLAY", subLevel = 7, x = 12, y = -12 },
            TopEdge = { atlas = edgeH, layer = "OVERLAY", subLevel = 7 },
            BottomEdge = { atlas = edgeH, layer = "OVERLAY", subLevel = 7 },
            LeftEdge = { atlas = edgeV, layer = "OVERLAY", subLevel = 7 },
            RightEdge = { atlas = edgeV, layer = "OVERLAY", subLevel = 7 },
        }
        host.layoutType = skin.ninesliceLayout or "BFAMissionAlliance"
        host:SetAllPoints(frame)
    else
        if shellTexture then shellTexture:Hide() end
        local tlU = pick({
            skin.ninesliceCornerTL,
            kit ~= "" and (kit .. "-NineSlice-CornerTopLeft") or nil,
            kit ~= "" and ("UI-Frame-" .. kit .. "-CornerTopLeft") or nil,
        })
        local trU = pick({
            skin.ninesliceCornerTR,
            kit ~= "" and (kit .. "-NineSlice-CornerTopRight") or nil,
            kit ~= "" and ("UI-Frame-" .. kit .. "-CornerTopRight") or nil,
        })
        local blU = pick({
            skin.ninesliceCornerBL,
            kit ~= "" and (kit .. "-NineSlice-CornerBottomLeft") or nil,
            kit ~= "" and ("UI-Frame-" .. kit .. "-CornerBottomLeft") or nil,
        })
        local brU = pick({
            skin.ninesliceCornerBR,
            kit ~= "" and (kit .. "-NineSlice-CornerBottomRight") or nil,
            kit ~= "" and ("UI-Frame-" .. kit .. "-CornerBottomRight") or nil,
        })
        local hasUnique = exists(tlU) and exists(trU) and exists(blU) and exists(brU)
            and tlU ~= trU and tlU ~= blU and tlU ~= brU
        local shared = pick({ skin.ninesliceCorner, skin.ninesliceCornerAlt, "Neutral-NineSlice-Corner" })
        local tl = hasUnique and tlU or shared
        local tr = hasUnique and trU or shared
        local bl = hasUnique and blU or shared
        local br = hasUnique and brU or shared
        local edgeH = pick({ skin.ninesliceTileH, skin.ninesliceTileHAlt, "_Neutral-NineSlice-EdgeTop" })
        local edgeHB = pick({ skin.ninesliceTileHBottom, skin.ninesliceTileHBottomAlt, hasUnique and skin.ninesliceTileH or nil, "_Neutral-NineSlice-EdgeBottom" })
        local edgeV = pick({ skin.ninesliceTileV, skin.ninesliceTileVAlt, "!Neutral-NineSlice-EdgeLeft" })
        local edgeVR = pick({ skin.ninesliceTileVRight, skin.ninesliceTileVRightAlt, hasUnique and skin.ninesliceTileV or nil, "!Neutral-NineSlice-EdgeRight" })
        if not hasUnique then
            edgeHB = edgeH
            edgeVR = edgeV
        end
        layout = {
            mirrorLayout = not hasUnique,
            TopLeftCorner = { atlas = tl, layer = "OVERLAY", subLevel = 7, x = -12, y = 12 },
            TopRightCorner = { atlas = tr, layer = "OVERLAY", subLevel = 7, x = 12, y = 12 },
            BottomLeftCorner = { atlas = bl, layer = "OVERLAY", subLevel = 7, x = -12, y = -12 },
            BottomRightCorner = { atlas = br, layer = "OVERLAY", subLevel = 7, x = 12, y = -12 },
            TopEdge = { atlas = edgeH, layer = "OVERLAY", subLevel = 7 },
            BottomEdge = { atlas = edgeHB, layer = "OVERLAY", subLevel = 7 },
            LeftEdge = { atlas = edgeV, layer = "OVERLAY", subLevel = 7 },
            RightEdge = { atlas = edgeVR, layer = "OVERLAY", subLevel = 7 },
        }
        host.layoutType = hasUnique and "UniqueCornersLayout" or (skin.ninesliceLayout or "BFAMissionAlliance")
        local topNudge = skin.ninesliceTopNudge or 0
        host:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, topNudge)
        host:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    end
    if layout and NineSliceUtil and NineSliceUtil.ApplyLayout then
        NineSliceUtil.ApplyLayout(host, layout)
    end
    local names = {
        "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
        "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
    }
    for _, name in ipairs(names) do
        local piece = host[name]
        if piece and piece.SetDrawLayer then
            piece:SetDrawLayer("OVERLAY", 7)
            if skin.shellAtlas then piece:Hide() end
        end
    end
    host:SetFrameLevel((frame:GetFrameLevel() or 1) + 70)
    if Blackacre.UI.Theme.ApplyChromeInset then
        local pad = 12
        if not factionSkin then
            pad = skin.chromePad or 18
        end
        Blackacre.UI.Theme.ApplyChromeInset(frame, pad)
    end
end

local function GarrSetAtlas(tex, names, useSize)
    if not tex then return false end
    for i = 1, #names do
        if Blackacre.UI.Theme.TrySetAtlas(tex, names[i], useSize and true or false) then
            return true
        end
    end
    return false
end

--- Middle fill (inset) behind parchmentpopup corners/edges.
--- Edges: atlas first, then inner-corner anchors, then thickness capped at 24 (fat atlas = cross).
function Blackacre.UI.Theme.ApplyParchmentPopupFill(frame)
    if not frame then return end
    local function tex(key, layer, sub)
        local t = frame[key]
        if not t then
            t = frame:CreateTexture(nil, layer, nil, sub)
            frame[key] = t
        end
        return t
    end
    local function atlasInfo(name)
        return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
    end
    local function setAtlas(t, name, useSize)
        if not name or not t then return false end
        if not atlasInfo(name) then
            t:Hide()
            return false
        end
        local ok = Blackacre.UI.Theme.TrySetAtlas(t, name, useSize and true or false)
        if not ok then
            t:Hide()
            return false
        end
        t:Show()
        return true
    end
    local function stripThick(info, dim)
        local v = (info and info[dim]) or 48
        return v
    end

    local bg = tex("_baParchBg", "BACKGROUND", -5)
    local function layoutFill()
        local w = frame:GetWidth() or 640
        local h = frame:GetHeight() or 720
        bg:ClearAllPoints()
        bg:SetPoint("CENTER", frame, "CENTER", 0, 0)
        bg:SetSize((w - 36) * 0.75, (h - 36) * 0.75)
    end
    layoutFill()
    if not frame._baParchBgHooked then
        frame:HookScript("OnSizeChanged", layoutFill)
        frame._baParchBgHooked = true
    end
    if not setAtlas(bg, "parchmentpopup-background", false) then
        bg:Hide()
    end

    local tl = tex("_baParchTL", "BACKGROUND", -3)
    tl:ClearAllPoints()
    tl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    setAtlas(tl, "parchmentpopup-topleft", true)

    local tr = tex("_baParchTR", "BACKGROUND", -3)
    tr:ClearAllPoints()
    tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    setAtlas(tr, "parchmentpopup-topright", true)

    local bl = tex("_baParchBL", "BACKGROUND", -3)
    bl:ClearAllPoints()
    bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    setAtlas(bl, "parchmentpopup-bottomleft", true)

    local br = tex("_baParchBR", "BACKGROUND", -3)
    br:ClearAllPoints()
    br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    setAtlas(br, "parchmentpopup-bottomright", true)

    -- parchmentpopup-top is NOT a tile (no _ prefix). HorizTile + SetTexCoord-after-SetAtlas
    -- is what looked like striation / empty vs TAV.
    local top = tex("_baParchTop", "BACKGROUND", -3)
    local topInfo = atlasInfo("parchmentpopup-top")
    if topInfo and (topInfo.filename or topInfo.file) then
        top:SetTexture(topInfo.filename or topInfo.file)
        top:SetTexCoord(
            topInfo.leftTexCoord or topInfo.left or 0,
            topInfo.rightTexCoord or topInfo.right or 1,
            topInfo.topTexCoord or topInfo.top or 0,
            topInfo.bottomTexCoord or topInfo.bottom or 1
        )
        if top.SetHorizTile then top:SetHorizTile(false) end
        if top.SetVertTile then top:SetVertTile(false) end
        top:ClearAllPoints()
        top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
        top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
        top:SetHeight(167)
        top:Show()
    else
        top:Hide()
    end

    local bot = tex("_baParchBot", "BACKGROUND", -3)
    local botInfo = atlasInfo("parchmentpopup-bottom")
    if botInfo and (botInfo.filename or botInfo.file) then
        bot:SetTexture(botInfo.filename or botInfo.file)
        bot:SetTexCoord(
            botInfo.leftTexCoord or botInfo.left or 0,
            botInfo.rightTexCoord or botInfo.right or 1,
            botInfo.topTexCoord or botInfo.top or 0,
            botInfo.bottomTexCoord or botInfo.bottom or 1
        )
        if bot.SetHorizTile then bot:SetHorizTile(false) end
        if bot.SetVertTile then bot:SetVertTile(false) end
        bot:ClearAllPoints()
        bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
        bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
        bot:SetHeight(167)
        bot:Show()
    else
        bot:Hide()
    end

    local left = tex("_baParchLeft", "BACKGROUND", -3)
    local leftInfo = atlasInfo("parchmentpopup-left")
    if leftInfo and (leftInfo.filename or leftInfo.file) then
        left:SetTexture(leftInfo.filename or leftInfo.file)
        left:SetTexCoord(
            leftInfo.leftTexCoord or leftInfo.left or 0,
            leftInfo.rightTexCoord or leftInfo.right or 1,
            leftInfo.topTexCoord or leftInfo.top or 0,
            leftInfo.bottomTexCoord or leftInfo.bottom or 1
        )
        if left.SetHorizTile then left:SetHorizTile(false) end
        if left.SetVertTile then left:SetVertTile(false) end
        left:ClearAllPoints()
        left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
        left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
        left:SetWidth(167)
        left:Show()
    else
        left:Hide()
    end

    local right = tex("_baParchRight", "BACKGROUND", -3)
    local rightInfo = atlasInfo("parchmentpopup-right")
    if rightInfo and (rightInfo.filename or rightInfo.file) then
        right:SetTexture(rightInfo.filename or rightInfo.file)
        right:SetTexCoord(
            rightInfo.leftTexCoord or rightInfo.left or 0,
            rightInfo.rightTexCoord or rightInfo.right or 1,
            rightInfo.topTexCoord or rightInfo.top or 0,
            rightInfo.bottomTexCoord or rightInfo.bottom or 1
        )
        if right.SetHorizTile then right:SetHorizTile(false) end
        if right.SetVertTile then right:SetVertTile(false) end
        right:ClearAllPoints()
        right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0)
        right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
        right:SetWidth(167)
        right:Show()
    else
        right:Hide()
    end
end

--- B1: Garrison Landing Page fill + corners + edges. Neutral/QuestLog modes still exist.
function Blackacre.UI.Theme.ApplyGarrisonLandingB1(frame)
    if not frame then return end
    local host = frame._baGarrHost
    if not host then
        host = CreateFrame("Frame", nil, frame)
        frame._baGarrHost = host
    end
    host:Show()
    host:ClearAllPoints()
    host:SetAllPoints(frame)
    host:EnableMouse(false)
    host:SetFrameLevel((frame:GetFrameLevel() or 1) + 8)

    local function piece(key, layer, sub)
        local t = host[key]
        if not t then
            t = host:CreateTexture(nil, layer, nil, sub)
            host[key] = t
        end
        t:Show()
        return t
    end

    local fill = piece("fill", "BACKGROUND", -2)
    fill:ClearAllPoints()
    fill:SetAllPoints(host)
    GarrSetAtlas(fill, { "GarrLanding-FollowerFrame" }, false)

    local ul = piece("ul", "ARTWORK", 0)
    ul:ClearAllPoints()
    ul:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    GarrSetAtlas(ul, { "GarrLanding-upperleft", "GarrLanding-UpperLeft" }, true)

    local ur = piece("ur", "ARTWORK", 0)
    ur:ClearAllPoints()
    ur:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0)
    GarrSetAtlas(ur, { "GarrLanding-upperright", "GarrLanding-UpperRight" }, true)

    local ll = piece("ll", "ARTWORK", 0)
    ll:ClearAllPoints()
    ll:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 0)
    GarrSetAtlas(ll, { "GarrLanding-lowerleft", "GarrLanding-LowerLeft" }, true)

    local lr = piece("lr", "ARTWORK", 0)
    lr:ClearAllPoints()
    lr:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    GarrSetAtlas(lr, { "GarrLanding-lowerright", "GarrLanding-LowerRight" }, true)

    local top = piece("top", "ARTWORK", 1)
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", ul, "TOPRIGHT", 0, 0)
    top:SetPoint("TOPRIGHT", ur, "TOPLEFT", 0, 0)
    if top.SetHorizTile then top:SetHorizTile(true) end
    GarrSetAtlas(top, { "GarrLanding-Top" }, false)

    local bot = piece("bot", "ARTWORK", 1)
    bot:ClearAllPoints()
    bot:SetPoint("BOTTOMLEFT", ll, "BOTTOMRIGHT", 0, 0)
    bot:SetPoint("BOTTOMRIGHT", lr, "BOTTOMLEFT", 0, 0)
    if bot.SetHorizTile then bot:SetHorizTile(true) end
    GarrSetAtlas(bot, { "GarrLanding-Bottom", "GarLanding-Bottom" }, false)

    local left = piece("left", "ARTWORK", 1)
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", ul, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", ll, "TOPLEFT", 0, 0)
    if left.SetVertTile then left:SetVertTile(true) end
    GarrSetAtlas(left, { "GarrLanding-Left", "GarLanding-Left" }, false)

    local right = piece("right", "ARTWORK", 1)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", ur, "BOTTOMRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", lr, "TOPRIGHT", 0, 0)
    if right.SetVertTile then right:SetVertTile(true) end
    GarrSetAtlas(right, { "GarrLanding-Right", "GarLanding-Right" }, false)
end

--- Backstory B1. Neutral nineslice kept for regress (Textures.backstoryB1Mode = "neutral").
function Blackacre.UI.Theme.ApplyFactionFrameChrome(frame)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(nil)
    end
    local T = Blackacre.UI.Theme.Textures
    local mode = T.backstoryB1Mode or "questlog"

    if frame._baGarrHost then
        frame._baGarrHost:Hide()
    end
    if frame._baNineSlice then frame._baNineSlice:Hide() end
    if frame._baIslandsFill then frame._baIslandsFill:Hide() end
    if frame._baClassTrialBg then frame._baClassTrialBg:Hide() end

    local qlog = frame._baQuestLogBg
    if not qlog then
        qlog = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
        frame._baQuestLogBg = qlog
    end

    if mode == "questlog" then
        Blackacre.UI.Theme.ApplyParchmentPopupFill(frame)
        qlog:ClearAllPoints()
        qlog:SetAllPoints(frame)
        -- Stretch to sidecar size; do not useAtlasSize (that would keep native thickness).
        if not Blackacre.UI.Theme.TrySetAtlas(qlog, T.backstoryQuestLogAtlas or "QuestLog-frame", false) then
            if not Blackacre.UI.Theme.TrySetAtlas(qlog, "QuestLog-Frame", false) then
                if not Blackacre.UI.Theme.TrySetAtlas(qlog, "QuestLogBackground", false) then
                    qlog:SetTexture(T.backstoryQuestLogFile or "Interface\\QuestFrame\\UI-QuestLog-Empty-Top")
                end
            end
        end
        qlog:Show()
        return
    end
    qlog:Hide()

    local fill = frame._baIslandsFill
    if not fill then
        fill = frame:CreateTexture(nil, "BACKGROUND", nil, -2)
        frame._baIslandsFill = fill
    end
    fill:ClearAllPoints()
    fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    if not Blackacre.UI.Theme.TrySetAtlas(fill, "islands-queue-background", false) then
        fill:SetTexture(Blackacre.UI.Theme.Textures.backstoryFillFile)
    end
    fill:Show()
    if frame._baClassTrialBg then
        frame._baClassTrialBg:Hide()
    end

    local host = frame._baNineSlice
    if not host then
        host = CreateFrame("Frame", nil, frame)
        frame._baNineSlice = host
    end
    host:Show()
    host:ClearAllPoints()
    host:SetAllPoints(frame)
    host:EnableMouse(false)
    host:SetFrameLevel((frame:GetFrameLevel() or 1) + 45)
    host.layoutTextureLayer = "OVERLAY"
    host.layoutTextureSubLevel = 7
    -- Official WoodenNeutralFrameTemplate offsets (x=±6). PAD=12 was Alliance-corner size and left gaps.
    local corner = "Neutral-NineSlice-Corner"
    local layout = {
        mirrorLayout = true,
        TopLeftCorner = { atlas = corner, x = -6, y = 6, layer = "OVERLAY", subLevel = 7 },
        TopRightCorner = { atlas = corner, x = 6, y = 6, layer = "OVERLAY", subLevel = 7 },
        BottomLeftCorner = { atlas = corner, x = -6, y = -6, layer = "OVERLAY", subLevel = 7 },
        BottomRightCorner = { atlas = corner, x = 6, y = -6, layer = "OVERLAY", subLevel = 7 },
        TopEdge = { atlas = "_Neutral-NineSlice-EdgeTop", layer = "OVERLAY", subLevel = 7 },
        BottomEdge = { atlas = "_Neutral-NineSlice-EdgeBottom", mirrorLayout = false, layer = "OVERLAY", subLevel = 7 },
        LeftEdge = { atlas = "!Neutral-NineSlice-EdgeLeft", layer = "OVERLAY", subLevel = 7 },
        RightEdge = { atlas = "!Neutral-NineSlice-EdgeRight", mirrorLayout = false, layer = "OVERLAY", subLevel = 7 },
    }
    host.layoutType = "WoodenNeutralFrameTemplate"
    if NineSliceUtil and NineSliceUtil.ApplyLayout then
        NineSliceUtil.ApplyLayout(host, layout)
    elseif NineSliceUtil and NineSliceUtil.ApplyLayoutByName then
        NineSliceUtil.ApplyLayoutByName(host, "WoodenNeutralFrameTemplate")
    end
    local names = {
        "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
        "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
    }
    for _, name in ipairs(names) do
        local piece = host[name]
        if piece then
            if piece.SetDrawLayer then piece:SetDrawLayer("OVERLAY", 7) end
            if piece.SetHorizTile and (name == "TopEdge" or name == "BottomEdge") then
                piece:SetHorizTile(true)
            end
            if piece.SetVertTile and (name == "LeftEdge" or name == "RightEdge") then
                piece:SetVertTile(true)
            end
        end
    end
    -- Edges 10px into each corner so they sit flush with Neutral-NineSlice-Corner.
    local tl, tr = host.TopLeftCorner, host.TopRightCorner
    local bl, br = host.BottomLeftCorner, host.BottomRightCorner
    if host.TopEdge and tl and tr then
        host.TopEdge:ClearAllPoints()
        host.TopEdge:SetPoint("TOPLEFT", tl, "TOPRIGHT", -10, 0)
        host.TopEdge:SetPoint("TOPRIGHT", tr, "TOPLEFT", 10, 0)
    end
    if host.BottomEdge and bl and br then
        host.BottomEdge:ClearAllPoints()
        host.BottomEdge:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", -10, 0)
        host.BottomEdge:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 10, 0)
    end
    if host.LeftEdge and tl and bl then
        host.LeftEdge:ClearAllPoints()
        host.LeftEdge:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 10)
        host.LeftEdge:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, -10)
    end
    if host.RightEdge and tr and br then
        host.RightEdge:ClearAllPoints()
        host.RightEdge:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 10)
        host.RightEdge:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, -10)
    end
end

--- B2: Neutral title left / tiled mid / right (not parchment).
function Blackacre.UI.Theme.ApplyNeutralTitleBar(frame)
    if not frame then return end
    if frame.SetBackdrop then frame:SetBackdrop(nil) end
    local h = frame:GetHeight() or 34
    local left = frame._baTitleLeft
    if not left then
        left = frame:CreateTexture(nil, "ARTWORK")
        frame._baTitleLeft = left
    end
    local right = frame._baTitleRight
    if not right then
        right = frame:CreateTexture(nil, "ARTWORK")
        frame._baTitleRight = right
    end
    local mid = frame._baTitleMid
    if not mid then
        mid = frame:CreateTexture(nil, "ARTWORK")
        frame._baTitleMid = mid
    end
    -- Mid fills the whole bar first; caps overlay the ends so their gradient sits on the tile, not a hard seam.
    if mid.SetDrawLayer then mid:SetDrawLayer("ARTWORK", 0) end
    if left.SetDrawLayer then left:SetDrawLayer("ARTWORK", 2) end
    if right.SetDrawLayer then right:SetDrawLayer("ARTWORK", 2) end
    mid:ClearAllPoints()
    mid:SetPoint("LEFT", frame, "LEFT", 0, 0)
    mid:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    mid:SetHeight(h)
    if mid.SetHorizTile then mid:SetHorizTile(true) end
    Blackacre.UI.Theme.TrySetAtlas(mid, "_UI-Frame-Neutral-TitleMiddle", false)
    left:ClearAllPoints()
    left:SetPoint("LEFT", frame, "LEFT", 0, 0)
    left:SetHeight(h)
    left:SetWidth(math.max(36, h * 1.6))
    Blackacre.UI.Theme.TrySetAtlas(left, "UI-Frame-Neutral-TitleLeft", false)
    right:ClearAllPoints()
    right:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    right:SetHeight(h)
    right:SetWidth(math.max(36, h * 1.6))
    Blackacre.UI.Theme.TrySetAtlas(right, "UI-Frame-Neutral-TitleRight", false)
    left:Show()
    right:Show()
    mid:Show()
end

function Blackacre.UI.Theme.ApplyBookChromeBar(frame, which)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = Blackacre.UI.Theme.Textures.parchment,
        edgeFile = Blackacre.UI.Theme.Textures.tooltipEdge,
        tile = false,
        tileSize = 0,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    local fill = (which == "footer") and Blackacre.UI.Theme.Colors.footerFill or Blackacre.UI.Theme.Colors.headerFill
    frame:SetBackdropColor(fill[1], fill[2], fill[3], 0.98)
    local eg = Blackacre.UI.Theme.Colors.edgeGold
    frame:SetBackdropBorderColor(eg[1] * 0.85, eg[2] * 0.85, eg[3] * 0.85, 1)
end

--- Style a tool button for the book footer (still uses panel template for clickability).
function Blackacre.UI.Theme.ApplyBookToolButton(btn)
    if not btn then return end
    if btn.SetNormalFontObject then btn:SetNormalFontObject(GameFontNormal) end
    if btn.SetHighlightFontObject then btn:SetHighlightFontObject(GameFontHighlight) end
end

--- Small floating menus (sticky pin, add-note confirm) — one Theme path for edges.
function Blackacre.UI.Theme.ApplyChromeMenuFrame(frame)
    if not frame or not frame.SetBackdrop then return end
    local T = Blackacre.UI.Theme.Textures
    frame:SetBackdrop({
        bgFile = T.white,
        edgeFile = T.tooltipEdge,
        tile = true,
        tileSize = 8,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.12, 0.10, 0.08, 0.97)
    frame:SetBackdropBorderColor(0.85, 0.70, 0.30, 1)
end

function Blackacre.UI.Theme.GetParchmentPath()
    return Blackacre.UI.Theme.Textures.parchment
        or "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"
end

--- Local UI sounds only (PlaySound = this client; never broadcasts).
Blackacre.UI.Theme.Sounds = {
    pageTurn = (SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN) or 836,
    -- Soft adventure flourish when opening the tome (local)
    bookOpen = (SOUNDKIT and SOUNDKIT.UI_70_BOOST_THANKSFORPLAYING_SMALLER)
        or (SOUNDKIT and SOUNDKIT.UI_PERSONAL_LOOT_BANNER)
        or (SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN)
        or 829,
    bookClose = (SOUNDKIT and SOUNDKIT.IG_SPELLBOOK_CLOSE) or 830,
    writeQuill = (SOUNDKIT and SOUNDKIT.IG_WRITE_QUILL) or 839,
    checkbox = (SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) or 856,
    toolClick = (SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION) or 852,
    menuTab = (SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB) or 841,
    menuOpen = (SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_OPEN) or 850,
    -- Soft neutral flourish (sidecar open)
    softFlourish = (SOUNDKIT and SOUNDKIT.UI_70_BOOST_THANKSFORPLAYING_SMALLER)
        or (SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN)
        or 850,
    -- Soft pin / paper (no dedicated paper-tear kit — closest UI paper)
    pinSoft = (SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN) or 836,
    paperTear = (SOUNDKIT and SOUNDKIT.IG_MAINMENU_CLOSE) or 799,
    journalToggle = (SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) or 856,
}

function Blackacre.UI.Theme.PlayUISound(which)
    local sounds = Blackacre.UI.Theme.Sounds
    local kit = sounds and sounds[which]
    if not kit or not PlaySound then return end
    pcall(PlaySound, kit, "SFX", true)
end

--- Icon helper: atlas name or Interface\\Icons\\ path.
function Blackacre.UI.Theme.SetIconTexture(tex, iconRef, size)
    if not tex then return end
    size = size or 25
    if not iconRef or iconRef == "" then return end
    if not iconRef:find("\\") and not iconRef:find("/") then
        if tex.SetAtlas then
            local ok = pcall(function() tex:SetAtlas(iconRef, true) end)
            if ok then return end
        end
        tex:SetTexture("Interface\\Icons\\" .. iconRef)
        return
    end
    tex:SetTexture(iconRef)
end

--- Apply path or atlas to a texture; returns true if something stuck.
function Blackacre.UI.Theme.ApplyTextureOrAtlas(tex, ref)
    if not tex or not ref then return false end
    if type(ref) == "table" then
        if ref.atlas and tex.SetAtlas then
            local ok = pcall(function() tex:SetAtlas(ref.atlas, true) end)
            if ok then return true end
        end
        if ref.path then
            tex:SetTexture(ref.path)
            if ref.coords then
                tex:SetTexCoord(ref.coords[1], ref.coords[2], ref.coords[3], ref.coords[4])
            end
            return true
        end
        return false
    end
    -- bare atlas name (no backslash)
    if not tostring(ref):find("\\") and not tostring(ref):find("/") and tex.SetAtlas then
        local ok = pcall(function() tex:SetAtlas(ref, true) end)
        if ok then return true end
        tex:SetTexture("Interface\\Icons\\" .. ref)
        return true
    end
    tex:SetTexture(ref)
    return true
end

--- Icon button: Achievement IconFrame border with icon BLP nested inside (owner E0).
--- outerSize = full button including frame; icon sits inset. opts: { noFrame=true, w=, h= }
function Blackacre.UI.Theme.CreateIconButton(parent, outerSize, ref, tooltipTitle, tooltipBody, opts)
    opts = opts or {}
    local ow = opts.w or outerSize or 36
    local oh = opts.h or outerSize or ow
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(ow, oh)
    b:EnableMouse(true)
    b:RegisterForClicks("LeftButtonUp")

    local useFrame = not opts.noFrame
    local T = Blackacre.UI.Theme.Textures
    local inset = useFrame and 6 or 0
    local iconW = math.max(12, ow - inset * 2)
    local iconH = math.max(12, oh - inset * 2)

    -- ARTWORK: icon face (nested inside frame)
    local normal = b:CreateTexture(nil, "ARTWORK")
    normal:SetSize(iconW, iconH)
    normal:SetPoint("CENTER", 0, 0)
    Blackacre.UI.Theme.ApplyTextureOrAtlas(normal, ref)
    if type(ref) == "string" and ref:find("Interface\\Icons\\") then
        normal:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    b.icon = normal

    -- OVERLAY: Achievement icon frame around any Interface\\Icons style face
    if useFrame and T.iconFrame then
        local frameTex = b:CreateTexture(nil, "OVERLAY")
        frameTex:SetAllPoints(b)
        frameTex:SetTexture(T.iconFrame)
        -- IconFrame sheet often has usable ring in full UV; leave 0–1 unless XML crop needed
        frameTex:SetTexCoord(0, 1, 0, 1)
        b.iconFrame = frameTex
    end

    local pushed = b:CreateTexture(nil, "ARTWORK")
    pushed:SetSize(iconW, iconH)
    pushed:SetPoint("CENTER", 1, -1)
    Blackacre.UI.Theme.ApplyTextureOrAtlas(pushed, ref)
    if type(ref) == "string" and ref:find("Interface\\Icons\\") then
        pushed:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    pushed:SetVertexColor(0.8, 0.8, 0.8, 1)
    b:SetPushedTexture(pushed)
    -- Keep normal as child art (SetNormalTexture can fight with custom layout)
    b:SetScript("OnMouseDown", function()
        normal:SetPoint("CENTER", 1, -1)
        normal:SetVertexColor(0.85, 0.85, 0.85, 1)
    end)
    b:SetScript("OnMouseUp", function()
        normal:SetPoint("CENTER", 0, 0)
        normal:SetVertexColor(1, 1, 1, 1)
    end)

    local hi = b:CreateTexture(nil, "HIGHLIGHT")
    hi:SetPoint("CENTER", 0, 0)
    hi:SetSize(iconW + 2, iconH + 2)
    hi:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hi:SetBlendMode("ADD")
    b:SetHighlightTexture(hi)

    if tooltipTitle then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipTitle)
            if tooltipBody then
                GameTooltip:AddLine(tooltipBody, 0.85, 0.85, 0.85, true)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return b
end

--- Minimap / map pin face for Pin Here (atlas first, path fallbacks).
function Blackacre.UI.Theme.GetMapPinIconRef()
    return {
        -- try modern waypoint pin, then classic minimap-style paths
        atlas = "Waypoint-MapPin-Tracked",
        path = (Blackacre.Compat and Blackacre.Compat.ResolveTexture and Blackacre.Compat.ResolveTexture("Interface\\MINIMAP\\UI-Minimap-Pin")) or "Interface\\MINIMAP\\UI-Minimap-Pin",
        fallbackPath = "Interface\\Cursor\\MapPinCursor",
        fallbackIcon = "Interface\\Icons\\INV_Misc_Map_01",
    }
end

function Blackacre.UI.Theme.ApplyMapPinIcon(tex)
    if not tex then return end
    local r = Blackacre.UI.Theme.GetMapPinIconRef()
    if tex.SetAtlas and r.atlas then
        local ok = pcall(function() tex:SetAtlas(r.atlas, true) end)
        if ok then return end
    end
    for _, path in ipairs({ r.path, r.fallbackPath, r.fallbackIcon }) do
        if path then
            tex:SetTexture(path)
            if path:find("Icons\\") then
                tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            else
                tex:SetTexCoord(0, 1, 0, 1)
            end
            return
        end
    end
end

--- Alliance = K.C. only; Horde = ADP only (never both for the player).
function Blackacre.UI.Theme.FormatFactionYear(yearValue)
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "Alliance"
    local adp = yearValue
    if yearValue and yearValue > 200 and Blackacre.YearCalendar and Blackacre.YearCalendar.FromKC then
        adp = Blackacre.YearCalendar.FromKC(yearValue)
    end
    if not Blackacre.YearCalendar then
        return tostring(yearValue or "?")
    end
    adp = adp or Blackacre.YearCalendar.GetPresentADP()
    if faction == "Horde" then
        return Blackacre.YearCalendar.FormatYearADP(adp, "ADP")
    end
    local kc = Blackacre.YearCalendar.ToKC(adp)
    if kc then
        return string.format("%d K.C.", kc)
    end
    return Blackacre.YearCalendar.FormatYearADP(adp, "KC")
end

--- Keep for callers that still paint a single leaf; uses parchment only (no dual images).
function Blackacre.UI.Theme.ApplyOpenBookPage(frame)
    if not frame then return end
    if frame.SetBackdrop then frame:SetBackdrop(nil) end
    -- Leaves stay transparent; parent bookOpen owns the single art texture.
end

local toastFrame
local toastQueue = {}
local toastBusy = false

-- Scenario-style title banners. Survival / pre-Legion / unknown = evergreen.
-- atlas = TAV member; file = the Y in "X from Y" (used if GetAtlasInfo misses).
Blackacre.UI.Theme.ToastKits = {
    evergreen    = { atlas = "evergreen-scenario-titlebg", file = "Interface\\Scenarios\\ScenarioEvergreen2x" },
    alliance     = { atlas = "AllianceScenario-TitleBG", file = "Interface\\Scenarios\\ScenarioHordeAlliance" },
    horde        = { atlas = "HordeScenario-TitleBG", file = "Interface\\Scenarios\\ScenarioHordeAlliance" },
    dragonflight = { atlas = "dragonflight-scenario-TitleBG", file = "Interface\\Scenarios\\ScenarioDragonflight" },
    warwithin    = { atlas = "thewarwithin-scenario-titlebg", file = "Interface\\Scenarios\\ScenarioTheWarWithin2x" },
    midnight     = { atlas = "midnight-scenario-titlebg", file = "Interface\\Scenarios\\ScenarioMidnight" },
    legion       = { atlas = "legioninvasion-title-bg", file = "Interface\\Scenarios\\LegionInvasion" },
    maw          = { atlas = "jailerstower-scenario-TitleBG", file = "Interface\\Scenarios\\ScenarioJailerstower" },
    kyrian       = { atlas = "kyrian-scenario-TitleBG", file = "Interface\\Scenarios\\ScenarioKyrian" },
    revendreth   = { atlas = "EmberCourtScenario-TitleBG", file = "Interface\\Scenarios\\ScenarioEmberCourt" },
    nzoth        = { atlas = "NzothScenario-TitleBG", file = "Interface\\Scenarios\\Scenario0Nzoth2x" },
}

local TOAST_ALIASES = {
    df = "dragonflight",
    tww = "warwithin",
    kyria = "kyrian",
    ember = "revendreth",
    jailer = "maw",
    oldgod = "nzoth",
    n = "nzoth",
}

function Blackacre.UI.Theme.ResolveToastKit(kit)
    kit = strlower(strtrim(tostring(kit or "")))
    if kit == "journal" then
        local f = UnitFactionGroup and UnitFactionGroup("player")
        kit = (f == "Horde") and "horde" or "alliance"
    end
    kit = TOAST_ALIASES[kit] or kit
    if kit == "" or not Blackacre.UI.Theme.ToastKits[kit] then
        kit = "evergreen"
    end
    return kit
end

local function ResolveToastKit(kit)
    return Blackacre.UI.Theme.ResolveToastKit(kit)
end

function Blackacre.UI.Theme.GetToastKitSpec(kit)
    kit = Blackacre.UI.Theme.ResolveToastKit(kit)
    return kit, Blackacre.UI.Theme.ToastKits[kit]
end

local function ApplyToastBanner(tex, kit)
    kit = ResolveToastKit(kit)
    local spec = Blackacre.UI.Theme.ToastKits[kit] or Blackacre.UI.Theme.ToastKits.evergreen
    local atlasName = spec.atlas
    local file = spec.file
    if tex.SetHorizTile then tex:SetHorizTile(false) end
    if tex.SetVertTile then tex:SetVertTile(false) end
    local info = atlasName and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlasName)
    if info and (info.filename or info.file) then
        tex:SetTexture(info.filename or info.file)
        tex:SetTexCoord(
            info.leftTexCoord or info.left or 0,
            info.rightTexCoord or info.right or 1,
            info.topTexCoord or info.top or 0,
            info.bottomTexCoord or info.bottom or 1
        )
        local w = info.width or 512
        local h = info.height or 80
        if w > 720 then
            local s = 720 / w
            w, h = w * s, h * s
        end
        return w, h, atlasName
    end
    if atlasName and tex.SetAtlas then
        local ok = pcall(function() tex:SetAtlas(atlasName, true) end)
        if ok then
            return tex:GetWidth() or 520, tex:GetHeight() or 84, atlasName
        end
    end
    -- Last resort: the file you named (may be a whole sheet if atlas lookup failed).
    if file then
        tex:SetTexture(file)
        tex:SetTexCoord(0, 1, 0, 1)
        return 520, 84, file
    end
    tex:SetColorTexture(0.08, 0.07, 0.05, 0.92)
    return 520, 84, "fallback"
end

local function EnsureToastFrame()
    if toastFrame then return toastFrame end
    local f = CreateFrame("Frame", "BlackacreToast", UIParent)
    f:SetSize(520, 84)
    f:SetPoint("TOP", UIParent, "TOP", 0, -72)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(false)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.fx = f:CreateTexture(nil, "ARTWORK")
    f.fx:SetAllPoints()
    if f.fx.SetBlendMode then f.fx:SetBlendMode("ADD") end
    f.fx:Hide()
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("LEFT", 48, 2)
    f.title:SetPoint("RIGHT", -48, 2)
    f.title:SetJustifyH("CENTER")
    f.title:SetTextColor(1, 0.95, 0.75, 1)
    f:Hide()
    toastFrame = f
    return f
end

local PlayNextToast
local toastHold = false

local function RunToast(item)
    local f = EnsureToastFrame()
    local w, h, used = ApplyToastBanner(f.bg, item.kit)
    f:SetSize(w or 520, h or 84)
    f._baKit = item.kit
    f._baAtlas = used
    f.fx:Hide()
    f.title:SetText(item.message or "")
    f:SetAlpha(1)
    f.bg:SetAlpha(0)
    f.title:SetAlpha(0)
    f:Show()
    toastBusy = true
    toastHold = item.hold and true or false
    f._t = 0
    -- Banner fade in, then text fade in, then hold, then all fade out. No width wipe (that looked like typewriter).
    f:SetScript("OnUpdate", function(self, elapsed)
        self._t = (self._t or 0) + elapsed
        local t = self._t
        if t < 0.4 then
            local p = t / 0.4
            self.bg:SetAlpha(p)
            self.title:SetAlpha(0)
        elseif t < 0.85 then
            self.bg:SetAlpha(1)
            self.title:SetAlpha((t - 0.4) / 0.45)
        elseif toastHold then
            self.bg:SetAlpha(1)
            self.title:SetAlpha(1)
        elseif t < 3.6 then
            self.bg:SetAlpha(1)
            self.title:SetAlpha(1)
        elseif t < 4.4 then
            local p = 1 - ((t - 3.6) / 0.8)
            self.bg:SetAlpha(p)
            self.title:SetAlpha(p)
        else
            self:SetScript("OnUpdate", nil)
            self:Hide()
            toastBusy = false
            toastHold = false
            PlayNextToast()
        end
    end)
end

PlayNextToast = function()
    if toastBusy then return end
    local next = table.remove(toastQueue, 1)
    if next then
        RunToast(next)
    end
end

--- Scenario-style banner. kit = evergreen|alliance|horde|dragonflight|warwithin|midnight|legion|maw|kyrian|revendreth|nzoth|journal
function Blackacre.UI.Theme.Toast(message, kit, hold, replace)
    if not message or message == "" then return end
    kit = ResolveToastKit(kit)
    if replace then
        for i = #toastQueue, 1, -1 do toastQueue[i] = nil end
        toastBusy = false
        toastHold = false
        if toastFrame then
            toastFrame:SetScript("OnUpdate", nil)
            toastFrame:Hide()
        end
    end
    toastQueue[#toastQueue + 1] = { message = message, kit = kit, hold = hold and true or false }
    PlayNextToast()
end

function Blackacre.UI.Theme.ToastHold(on)
    toastHold = on and true or false
    if not on and toastFrame and toastBusy then
        toastFrame._t = 3.55
    end
end

function Blackacre.UI.Theme.EnsureToastSkinGuide(shown)
    local f = toastFrame
    if not f then return end
    if not f._baSkinGuide then
        local ov = CreateFrame("Frame", nil, f)
        ov:SetAllPoints(f)
        ov:SetFrameStrata("TOOLTIP")
        ov:EnableMouse(false)
        f._baSkinGuide = ov
        local function Tag(anchor, label, kind)
            local fs = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
            fs:SetPoint("CENTER", anchor, "CENTER", 0, 0)
            fs:SetText((kind == "S" and "|cffffcc00" or "|cffffffff") .. label .. (kind == "S" and "S|r" or "F|r"))
            fs:SetShadowColor(0, 0, 0, 1)
            fs:SetShadowOffset(1, -1)
        end
        Tag(f, "T1", "S")
        Tag(f.title, "T2", "F")
    end
    f._baSkinGuide:SetShown(shown and true or false)
end

local function EnsureBackstorySkinGuide(shown)
    local menu = _G.BlackacreBackstoryMenu
    if not menu then return end
    if not menu._baSkinGuide then
        local mOverlay = CreateFrame("Frame", nil, menu)
        mOverlay:SetAllPoints(menu)
        mOverlay:SetFrameStrata("DIALOG")
        mOverlay:SetFrameLevel((menu:GetFrameLevel() or 1) + 80)
        mOverlay:EnableMouse(false)
        menu._baSkinGuide = mOverlay
        local function MTag(anchor, label, kind, ox, oy)
            if not anchor then return end
            local fs = mOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
            fs:SetPoint("CENTER", anchor, "CENTER", ox or 0, oy or 0)
            if kind == "S" then
                fs:SetText("|cffffcc00" .. label .. "S|r")
            else
                fs:SetText("|cffffffff" .. label .. "F|r")
            end
            fs:SetShadowColor(0, 0, 0, 1)
            fs:SetShadowOffset(1, -1)
        end
        MTag(menu, "B1", "S", 0, 0)
        MTag(menu.header, "B2", "F", -40, 0)
        MTag(menu.closeButton, "B3", "F", 0, 0)
        MTag(menu.content, "B4", "F", 0, 0)
        if menu.sideTabs and menu.sideTabs[1] then
            MTag(menu.sideTabs[1], "B5", "F", 0, 0)
        end
    end
    menu._baSkinGuide:SetShown(shown and true or false)
    local lin = _G.BlackacreLineage
    local ov = menu._baSkinGuide
    if shown and lin and ov and not menu._baLinTags then
        local function LTag(anchor, label, ox, oy)
            if not anchor then return end
            local fs = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
            fs:SetPoint("CENTER", anchor, "CENTER", ox or 0, oy or 0)
            fs:SetText("|cffffffff" .. label .. "F|r")
            fs:SetShadowColor(0, 0, 0, 1)
            fs:SetShadowOffset(1, -1)
        end
        LTag(lin.left, "L3", 0, 0)
        LTag(lin.right, "L4", 0, 0)
        LTag(lin.saveBtn, "L5", 0, 0)
        menu._baLinTags = true
    end
end

--- Numbered Tome map for TAV talk: /ba skin
function Blackacre.UI.Theme.ToggleTomeSkinGuide()
    local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
    if not hub then
        if Blackacre.Print then Blackacre.Print("Open the Tome first: /ba tome") end
        return
    end
    if not hub:IsShown() then hub:Show() end

    if hub._baSkinGuide then
        local show = not hub._baSkinGuide:IsShown()
        hub._baSkinGuide:SetShown(show)
        EnsureBackstorySkinGuide(show)
        if Blackacre.UI.Theme.EnsureToastSkinGuide then
            Blackacre.UI.Theme.EnsureToastSkinGuide(show)
        end
        if Blackacre.Print then
            Blackacre.Print(show and "Skin guide ON — send REGION + ATLAS." or "Skin guide OFF.")
        end
        return
    end

    local overlay = CreateFrame("Frame", nil, hub)
    overlay:SetAllPoints(hub)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel((hub:GetFrameLevel() or 1) + 80)
    overlay:EnableMouse(false)
    hub._baSkinGuide = overlay

    -- Gold = skin (art pack). White = function (layout/clicks; same on every skin).
    local function Tag(anchor, label, kind, ox, oy)
        local fs = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        fs:SetPoint("CENTER", anchor, "CENTER", ox or 0, oy or 0)
        if kind == "S" then
            fs:SetText("|cffffcc00" .. label .. "S|r")
        else
            fs:SetText("|cffffffff" .. label .. "F|r")
        end
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
        return fs
    end

    local legend = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    legend:SetPoint("TOP", overlay, "TOP", 0, -4)
    legend:SetText("|cffffcc00#S skin (art)|r   |cffffffff#F function (clicks/layout)|r")

    Tag(hub, "1", "S", 0, 0)
    if hub.header then Tag(hub.header, "2", "F", -40, 0) end
    if hub.closeButton then Tag(hub.closeButton, "3", "F", 0, 0) end
    if hub.addPageBtn then Tag(hub.addPageBtn, "+", "F", 0, 0) end
    if hub.bookOpen then Tag(hub.bookOpen, "4", "F", 0, 40) end
    if hub.leftPage then Tag(hub.leftPage, "5", "F", 0, 0) end
    if hub.rightPage then Tag(hub.rightPage, "6", "F", 0, 0) end
    if hub.gutter then
        Tag(hub.bookOpen, "7", "F", 0, 0)
    end
    if hub.chronicleBookmark then Tag(hub.chronicleBookmark, "8", "S", 0, 0) end
    if hub.tabBar then Tag(hub.tabBar, "9", "S", 0, 0) end
    if hub.footer then Tag(hub.footer, "10", "F", -80, 0) end
    if hub.toolStrip then Tag(hub.toolStrip, "11", "F", 0, 0) end
    if hub.prevPageBtn then Tag(hub.prevPageBtn, "12", "F", 20, 0) end
    EnsureBackstorySkinGuide(true)
    if Blackacre.UI.Theme.EnsureToastSkinGuide then
        Blackacre.UI.Theme.EnsureToastSkinGuide(true)
    end

    if Blackacre.Print then
        Blackacre.Print("Skin guide ON. Copy: REGION:  ATLAS:  NOTE:")
    end
end
