-- In Character Forever - Theme

Blackacre = Blackacre or {}
Blackacre.UI = Blackacre.UI or {}
Blackacre.UI.Theme = {}

Blackacre.UI.Theme.Layer = {
    BACKGROUND = "BACKGROUND", -- fills, washes, paper
    BORDER = "BORDER",         -- edge art
    ARTWORK = "ARTWORK",       -- spine, ornaments, card art
    OVERLAY = "OVERLAY",       -- text, primary icons, controls chrome
    HIGHLIGHT = "HIGHLIGHT",   -- mouse hover (auto show/hide)
}

--- Create a font string on OVERLAY by default (text must sit above art).
function Blackacre.UI.Theme.CreateLayeredFontString(frame, layer, inherits)
    if not frame then return nil end
    layer = layer or Blackacre.UI.Theme.Layer.OVERLAY
    return frame:CreateFontString(nil, layer, inherits or "BlackacreFont_GameFontHighlight")
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
    -- Tree nodes (family tree / Arc): passed-away grey, selection ring
    deceased = { 0.55, 0.55, 0.55 },
    highlight = { 1.00, 0.82, 0.00 },
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
    -- Beacon minimap hint (Pass A placeholder: gold disc cut by this mask).
    -- Confirmed in the Forever art export: Interface/Common/CommonMaskCircle.BLP
    beaconHintMask = "Interface\\Common\\CommonMaskCircle",
    -- Report button (owner-named; Interface/GMChat/UIFrameGMChat, used by
    -- Blizzard_StatusUI.xml). An atlas name, not a file path.
    reportIconAtlas = "gmchat-icon-blizz",
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
    marble = "Interface\\FrameGeneral\\UI-Background-Marble",
    -- Quest Index base layer (owner TAV pull: FileID 8216846). Confirmed atlas
    -- name via Blizzard_CharacterCreate / CharacterSelectListBackground.xml
    -- (stretched full-bleed fill, no native atlas size).
    questIndexBaseAtlas = "heavybronze-frame-background",
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
    -- The Backstory window only ("talent" = hero-class popup art, Interface/TalentFrame/
    -- TalentsHeroClass). Dark, so tab text (dark ink) needs re-inking light.
    -- Set "questlog" to go back to parchment. Other windows keep backstoryB1Mode.
    backstoryMenuMode = "talent",
    backstoryTalentAtlas = "talents-heroclass-choicepopup-background",
    -- Outer shell border for every Backstory tab (Interface/Garrison/AdventureMissionsFrame2).
    backstoryShellAtlas = "Adventures-CombatLog-Frame",
    -- B2 header card (Interface/Journeys/JourneysFrame2x), drawn at its own size.
    backstoryHeaderAtlas = "UI-Journeys-Delve-Card",
    -- Section divider, e.g. L9 on Lineage (same sheet).
    backstoryDividerAtlas = "UI-Journeys-Renown-divider",
    -- B4F tree viewport (Interface/MOTHER_TalentTree/MOTHERtalenttree), drawn rotated 90 degrees.
    treeBackgroundAtlas = "talenttree-mother-background",
    backstoryQuestLogAtlas = "QuestLog-frame",
    -- Forever's art dump names this file with the -TOPLEFT suffix.
    backstoryQuestLogFile = "Interface\\QuestFrame\\UI-QUESTLOG-EMPTY-TOPLEFT",
    spellbookPage = "Interface\\Spellbook\\Spellbook-Page-1",
    spellbookPage2 = "Interface\\Spellbook\\Spellbook-Page-2",
}

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
        chromePad = 14, -- footer; the title bar copies Forsaken (below the table)
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

-- Title bar (2F) + footer (11F) TopHUD variant per skin (owner-assigned).
do
    local HUD_BAR = {
        Alliance = "dis", Horde = "plain", Dragonflight = "dis", Metal = "dis",
        Kyrian = "dis", Seafarer = "plain", Workshop = "plain", Scholomance = "dis",
        Tavern = "plain", Skyborne = "dis", Slate = "dis", Ornate = "dis",
        Ironforge = "plain", Forsaken = "dis", Void = "dis",
    }
    for id, variant in pairs(HUD_BAR) do
        local skin = Blackacre.UI.Theme.Skins[id]
        if skin then skin.hudBar = variant end
    end
end

-- Title bar layout: journal title (2F), add page (+F) and close (3F),
-- owner-matched by eye. Ironforge copies Forsaken's (the plain defaults);
-- Dragonflight, Slate, Skyborne and Scholomance copy Void's. Set here, after
-- the table, because FrameGeneralSkin only carries art names through.
do
    local LIKE = {
        Ironforge = "Forsaken",
        Dragonflight = "Void", Slate = "Void", Skyborne = "Void", Scholomance = "Void",
    }
    local skins = Blackacre.UI.Theme.Skins
    for id, from in pairs(LIKE) do
        local skin, src = skins[id], skins[from]
        skin.headerPad = src.headerPad or src.chromePad or 18
        skin.titleOffsetX = src.titleOffsetX
        skin.closeButtonOffsetX = src.closeButtonOffsetX
    end
end

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
  Only bundle a font whose license allows redistribution (free for personal use
  alone does not); record it in Media/Fonts/FONTS.txt.
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
        { key = "frizGame", path = WOW_FRIZ, name = "Friz (native)", full = true },
        { key = "frizCyr", path = WOW_FRIZ_CYR, name = "Friz Cyrillic (native)", full = true },
        { key = "morpheusGame", path = WOW_MORPHEUS, name = "Morpheus (native)", full = true },
        { key = "skurri", path = WOW_SKURRI, name = "Skurri (native)", full = true },
        -- Bundled fonts: only ones whose designers allow redistribution.
        -- Credits and license notes: Media/Fonts/FONTS.txt.
        { key = "freebooter", path = FONT .. "FREEBOOTERUPDATED.TTF", name = "Freebooter", full = false },
        { key = "magicSchool", path = FONT .. "MagicSchoolOne-ovYz.ttf", name = "Magic School", full = false },
        -- sizeScale / spacing: journal size multiplier and extra px between lines
        -- (ApplyReadableBodyFont). WoW draws only the top ~1 em of each glyph, so the traced
        -- fonts are built shrunk to fit inside 1 em and sizeScale brings them back up; that
        -- also sets the line spacing (scripts/fonts/build_font.py prints the factor).
        { key = "khaz", path = FONT .. "BlackacreKhaz.ttf", name = "Khaz", full = false,
          sizeScale = 1.111 },
        { key = "highborne", path = FONT .. "BlackacreHighborne.ttf", name = "Highborne", full = false,
          sizeScale = 1.662 },
        { key = "highborneText", path = FONT .. "BlackacreHighborneText.ttf", name = "Highborne Text", full = false,
          sizeScale = 1.662 },
        { key = "oldGilnean", path = FONT .. "BlackacreOldGilnean.ttf", name = "Old Gilnean", full = false,
          sizeScale = 1.111, spacing = 2 },
        { key = "learnedHand", path = FONT .. "BlackacreLearnedHand.ttf", name = "Learned Hand", full = false,
          sizeScale = 1.662 },
        { key = "peon", path = FONT .. "BlackacrePeon.ttf", name = "Peon", full = false,
          sizeScale = 1.913 },
        { key = "tolvir", path = FONT .. "BlackacreTolvir.ttf", name = "Tol'vir", full = false,
          sizeScale = 1.45, spacing = 2 },
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

-- Fonts that are no longer bundled. A saved choice moves to the closest face we still have:
-- Friz/Morpheus to the game's own copy (no redistribution license, 2026-10-02); the rune,
-- Dwarven SC, Monarch and Wrath faces (missing digits/marks, and their licenses don't allow
-- adding them, 2026-10-05) to the nearest Blackacre font.
local RETIRED_FONT_KEYS = {
    friz = "frizGame", morpheus = "morpheusGame",
    dwarven = "khaz", darnassian = "highborneText", thalassian = "highborneText",
    shalassian = "highborneText", monarch = "learnedHand", wrath = "oldGilnean",
}

-- "By race": the journal font a character starts with, by UnitRace file token. A profile
-- keeps "race" until the player picks a font; every lookup resolves it here.
local RACE_JOURNAL_FONT = {
    Human = "learnedHand", Dwarf = "khaz", Gnome = "magicSchool",
    NightElf = "highborneText", Skyborne = "highborneText", Troll = "highborneText",
    Orc = "peon", Tauren = "tolvir", Scourge = "oldGilnean",
}
Blackacre.UI.Theme.RACE_FONT_KEY = "race"

--- The font key "By race" means for this character ("default" for an unlisted race).
function Blackacre.UI.Theme.RaceJournalFontKey()
    local _, raceFile = UnitRace("player")
    return RACE_JOURNAL_FONT[raceFile] or "default"
end

--- Catalog row for a font key, or nil.
local function CatalogRow(key)
    key = RETIRED_FONT_KEYS[key] or key
    for _, row in ipairs(Blackacre.UI.Theme.Fonts.catalog or {}) do
        if row.key == key then return row end
    end
    return nil
end

--- Apply body font key (tome body + sticky notes only). Persists to AceDB when available.
function Blackacre.UI.Theme.SetBodyFontKey(key, silent)
    local fonts = Blackacre.UI.Theme.Fonts
    key = RETIRED_FONT_KEYS[key] or key or "default"
    -- Persist the player's choice ("race" stays "race"); draw with what it resolves to.
    local choice = key
    if key == Blackacre.UI.Theme.RACE_FONT_KEY then
        key = Blackacre.UI.Theme.RaceJournalFontKey()
    end
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
    if settings then settings.bodyFontKey = choice end
    if not silent and Blackacre.Print then
        Blackacre.Print("Tome Font Enabled: " .. tostring(label))
    end
    RefreshOpenTome()
    -- Lay out once more after the face has surely loaded (see PreloadCatalogFonts).
    C_Timer.After(0.5, RefreshOpenTome)
    return true
end

-- Add-on text styles: copies of WoW's text styles that every add-on label uses instead of
-- the originals, so the "Add-on Text Font" setting restyles add-on windows without touching
-- buttons, other add-ons or the game, which keep the originals. They're named globals
-- (BlackacreFont_<WoW style>) because CreateFontString takes its template by name.
local ADDON_FONT_TEMPLATES = {
    "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge", "GameFontNormalHuge",
    "GameFontHighlight", "GameFontHighlightSmall", "GameFontHighlightLarge", "GameFontDisableSmall",
    "QuestTitleFont", "QuestFont", "QuestFontNormalSmall",
}
local addonFonts = {}
for _, name in ipairs(ADDON_FONT_TEMPLATES) do
    local base = _G[name]
    if base then
        local obj = CreateFont("BlackacreFont_" .. name)
        obj:CopyFontObject(base)
        addonFonts[name] = obj
    end
end

--- Restyle add-on text with a catalog font ("default" = WoW's own). Labels pick it up at
--- once: a FontString follows its font object. Sizes keep WoW's, times the row's sizeScale.
function Blackacre.UI.Theme.SetAddonFontKey(key)
    key = RETIRED_FONT_KEYS[key] or key or "default"
    local row = CatalogRow(key)
    local path = row and row.path
    if path and not Blackacre.UI.Theme.ProbeBodyFont(path) then
        path, key = nil, "default"
    end
    for name, obj in pairs(addonFonts) do
        local base = _G[name]
        obj:CopyFontObject(base)
        if path then
            local _, size, flags = base:GetFont()
            obj:SetFont(path, (size or 12) * (row.sizeScale or 1), flags or "")
        end
    end
    local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    if settings then settings.addonFontKey = key end
end

--- Font path for one catalog key (nil for "default" = WoW mail font).
--- Used for a single page's own font choice from the Journaling toolbar;
--- does not touch the Tome-wide setting.
function Blackacre.UI.Theme.GetBodyFontPathForKey(key)
    key = RETIRED_FONT_KEYS[key] or key
    for _, row in ipairs(Blackacre.UI.Theme.Fonts.catalog or {}) do
        if row.key == key then return row.path end
    end
    return nil
end

-- WoW reads a font file the first time something uses it. One-line text set while it is
-- still loading can come out blank (Highborne's table of contents and meta line after a
-- restart, 2026-10-04), so every bundled face is loaded once at login, off screen.
local fontPreloadHost

function Blackacre.UI.Theme.PreloadCatalogFonts()
    if fontPreloadHost then return end
    fontPreloadHost = CreateFrame("Frame", nil, UIParent)
    fontPreloadHost:SetSize(1, 1)
    fontPreloadHost:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 100)
    fontPreloadHost:SetAlpha(0)
    for _, row in ipairs(Blackacre.UI.Theme.Fonts.catalog or {}) do
        if row.path then
            local fs = fontPreloadHost:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            if TrySetFont(fs, row.path, 14) then
                fs:SetPoint("TOPLEFT")
                fs:SetText("Aa")
            end
        end
    end
end

function Blackacre.UI.Theme.LoadBodyFontFromDB(silent)
    Blackacre.UI.Theme.PreloadCatalogFonts()
    local key = "default"
    local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    Blackacre.UI.Theme.SetAddonFontKey(settings and settings.addonFontKey)
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
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    tinsert(UISpecialFrames, name)
    Blackacre.UI.Focus.Register(frame)

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

    frame.title = Blackacre.UI.Theme.CreateLayeredFontString(frame.header, Layer.OVERLAY, "BlackacreFont_GameFontNormalHuge")
    frame.title:SetPoint("LEFT", 14, 0)
    frame.title:SetJustifyH("LEFT")
    if frame.title.SetWordWrap then frame.title:SetWordWrap(false) end
    frame.title:SetText(titleText or "Journal")
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
        GameTooltip:AddLine("At the end, or right after the page you have open.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    addPage:SetScript("OnLeave", function() GameTooltip:Hide() end)
    addPage:SetScript("OnClick", function(self)
        Blackacre.UI.Theme.PlayUISound("toolClick")
        if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.OnAddPageClicked then
            Blackacre.Chronicle.UI.OnAddPageClicked(self)
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

    -- Footer page jump reads right-to-left: [box] of N [Go] | Backstory.
    -- Chained from the right so "of N" growing (of 9 -> of 120) just slides
    -- the box and Add note left instead of overlapping Go.
    frame.pageJumpBtn = CreateFrame("Button", nil, frame.footer, "UIPanelButtonTemplate")
    frame.pageJumpBtn:SetSize(36, 24)
    frame.pageJumpBtn:SetPoint("RIGHT", frame.backstoryBtn, "LEFT", -6, 0)

    frame.pageJumpOf = frame.footer:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalSmall")
    frame.pageJumpOf:SetPoint("RIGHT", frame.pageJumpBtn, "LEFT", -4, 0)
    frame.pageJumpOf:SetText("of 1")

    frame.pageJump = CreateFrame("EditBox", nil, frame.footer, "InputBoxTemplate")
    frame.pageJump:SetSize(36, 20)
    frame.pageJump:SetPoint("RIGHT", frame.pageJumpOf, "LEFT", -6, 0)
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
        if rail.SetHorizTile then rail:SetHorizTile(false) end
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
        local fs = holder:CreateFontString(nil, Layer.OVERLAY, "BlackacreFont_GameFontNormal")
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

function Blackacre.UI.Theme.InkFont(fontString, size)
    if not fontString then return end
    local c = Blackacre.UI.Theme.Colors.ink
    if size == "title" then
        fontString:SetFontObject(BlackacreFont_GameFontNormalHuge or BlackacreFont_GameFontNormalLarge)
    elseif size == "header" then
        fontString:SetFontObject(BlackacreFont_GameFontNormalLarge)
    else
        fontString:SetFontObject(BlackacreFont_GameFontHighlightLarge or BlackacreFont_GameFontHighlight)
    end
    fontString:SetTextColor(c[1], c[2], c[3])
end

function Blackacre.UI.Theme.GoldTitle(fontString)
    if not fontString then return end
    fontString:SetFontObject(BlackacreFont_GameFontNormalHuge or BlackacreFont_GameFontNormalLarge)
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

--- fontKey (optional): a page's own font from the Journaling toolbar;
--- nil = the Tome-wide font from Options.
function Blackacre.UI.Theme.ApplyReadableBodyFont(region, extraSize, fontKey)
    if not region then return end
    extraSize = extraSize or 1
    local size = 14 + extraSize
    local custom
    if fontKey then
        custom = Blackacre.UI.Theme.GetBodyFontPathForKey(fontKey)
    else
        custom = Blackacre.UI.Theme.GetBodyFontPath and Blackacre.UI.Theme.GetBodyFontPath()
    end
    local row = CatalogRow(fontKey or Blackacre.UI.Theme.Fonts.activeKey)
    local applied, spacing = false, 0
    if custom then
        -- sizeScale: a face that runs small (a script) is drawn larger than the plain fonts
        applied = TrySetFont(region, custom, size * (row and row.sizeScale or 1))
        if applied then
            spacing = row and row.spacing or 0
        else
            -- If fancy font failed to load entirely, fall back to game Friz (full charset)
            applied = TrySetFont(region, WOW_FRIZ, size)
        end
    end
    if not applied then
        Blackacre.UI.Theme.ApplyMailBodyFont(region, extraSize)
    end
    -- WoW spaces lines by font size alone, so a face with tall stems and long tails needs
    -- extra room; 0 resets it when the page switches back to a plain font.
    if region.SetSpacing then
        region:SetSpacing(spacing)
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
    -- Tiling used to draw the skin art at its native pixel width, which left
    -- a sliver of the tabBar's own backdrop color exposed at the edge for
    -- any skin whose art didn't evenly divide the bar's width. Stretching
    -- instead guarantees the art always covers the full 9S field, for every
    -- skin, regardless of that skin's native texture size.
    if rail.SetHorizTile then rail:SetHorizTile(false) end
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

        -- Caps overscan 2px top / 4px bottom too, matching the middle rail,
        -- so all three 9S pieces (left cap, middle, right cap) share the
        -- same thickness and the bar backdrop can't peek through under
        -- either cap.
        bar.titleLeft:ClearAllPoints()
        bar.titleLeft:SetPoint("LEFT", bar, "LEFT", 0, 0)
        bar.titleLeft:SetPoint("TOP", bar, "TOP", 0, 2)
        bar.titleLeft:SetSize(capW, h + 6)

        bar.titleRight:ClearAllPoints()
        bar.titleRight:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
        bar.titleRight:SetPoint("TOP", bar, "TOP", 0, 2)
        bar.titleRight:SetSize(capW, h + 6)

        -- An atlas name that fails to resolve used to leave the cap texture
        -- blank, exposing the bar's backdrop color underneath it instead of
        -- art. If either cap can't be painted, drop caps entirely for this
        -- render so the rail spans the full width instead of leaving a hole.
        local leftOk = leftAtlas and Blackacre.UI.Theme.TrySetAtlas(bar.titleLeft, leftAtlas, false)
        local rightOk = rightAtlas and Blackacre.UI.Theme.TrySetAtlas(bar.titleRight, rightAtlas, false)

        if leftOk and rightOk then
            bar.titleLeft:Show()
            bar.titleRight:Show()

            -- Center rail overscans 2px top / 4px bottom past the bar's own
            -- height so no sliver of whatever sits behind it (bar backdrop
            -- or a sibling region) can peek through above or below.
            rail:ClearAllPoints()
            rail:SetPoint("LEFT", bar.titleLeft, "RIGHT", 0, 0)
            rail:SetPoint("RIGHT", bar.titleRight, "LEFT", 0, 0)
            rail:SetHeight(h + 6)
            rail:SetPoint("TOP", bar, "TOP", 0, 2)
        else
            bar.titleLeft:Hide()
            bar.titleRight:Hide()
            rail:ClearAllPoints()
            rail:SetPoint("LEFT", bar, "LEFT", 0, 0)
            rail:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
            rail:SetPoint("TOP", bar, "TOP", 0, 2)
            rail:SetPoint("BOTTOM", bar, "BOTTOM", 0, -4)
        end
    else
        if bar.titleLeft then bar.titleLeft:Hide() end
        if bar.titleRight then bar.titleRight:Hide() end

        -- Spans the full 9S field, overscanning 2px top / 4px bottom so
        -- whatever sits behind the rail (bar backdrop, or a sibling region)
        -- can't peek through above or below it.
        rail:ClearAllPoints()
        rail:SetPoint("LEFT", bar, "LEFT", 0, 0)
        rail:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
        rail:SetPoint("TOP", bar, "TOP", 0, 2)
        rail:SetPoint("BOTTOM", bar, "BOTTOM", 0, -4)
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

-- Owner-named atlas -> texture, with its native size. SetAtlas on a missing
-- name fails silently (blank texture), so GetAtlasInfo is checked first.
-- Returns native width, height, or nil if the atlas isn't in this client.
local function SetNamedAtlas(tex, atlas)
    local info = tex and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    if not info then return nil end
    if not Blackacre.UI.Theme.TrySetAtlas(tex, atlas, false) then return nil end
    return info.width or 0, info.height or 0
end

-- TopHUD 3-slice, owner-named, from
-- Interface/Glues/CharacterSelect/UICharacterSelectGlues2xC60:
--   "plain" = glues-characterSelect-TopHUD-left-BG / -middle-BG / -right-BG
--   "dis"   = glues-characterSelect-TopHUD-left-dis-BG / -middle-dis-BG / -right-dis-BG
-- Caps keep their native aspect at the strip's height; only the middle piece
-- stretches, and only sideways -- nothing is squashed.
local HUD_PIECES = {
    plain = { "glues-characterSelect-TopHUD-left-BG", "glues-characterSelect-TopHUD-middle-BG", "glues-characterSelect-TopHUD-right-BG" },
    dis = { "glues-characterSelect-TopHUD-left-dis-BG", "glues-characterSelect-TopHUD-middle-dis-BG", "glues-characterSelect-TopHUD-right-dis-BG" },
}

-- height: strip height to draw at (nil = native, capped at maxH).
-- Returns height, left cap width, right cap width; nil if a piece is missing.
-- outset: extra px drawn past the frame's top AND bottom edges (0 = flush).
-- offsetY: shifts the whole strip (negative = down).
-- outsetX: extra px drawn past the frame's left AND right edges.
local function ApplyHudStrip(frame, variant, height, maxH, outset, offsetY, outsetX)
    if not frame then return nil end
    local hud = frame._baHud
    if not hud then
        hud = {
            l = frame:CreateTexture(nil, "BACKGROUND"),
            m = frame:CreateTexture(nil, "BACKGROUND"),
            r = frame:CreateTexture(nil, "BACKGROUND"),
        }
        frame._baHud = hud
    end
    local names = HUD_PIECES[variant] or HUD_PIECES.plain
    local lw, lh = SetNamedAtlas(hud.l, names[1])
    local mw, mh = SetNamedAtlas(hud.m, names[2])
    local rw, rh = SetNamedAtlas(hud.r, names[3])
    if not (lw and mw and rw) or lh <= 0 or mh <= 0 or rh <= 0 then
        hud.l:Hide() hud.m:Hide() hud.r:Hide()
        return nil
    end
    outset = outset or 0
    offsetY = offsetY or 0
    outsetX = outsetX or 0
    local h = (height or math.min(mh, maxH or mh)) + outset * 2
    local capL, capR = lw * (h / lh), rw * (h / rh)
    hud.l:ClearAllPoints()
    hud.l:SetPoint("TOPLEFT", -outsetX, outset + offsetY)
    hud.l:SetPoint("BOTTOMLEFT", -outsetX, -outset + offsetY)
    hud.l:SetWidth(capL)
    hud.r:ClearAllPoints()
    hud.r:SetPoint("TOPRIGHT", outsetX, outset + offsetY)
    hud.r:SetPoint("BOTTOMRIGHT", outsetX, -outset + offsetY)
    hud.r:SetWidth(capR)
    hud.m:ClearAllPoints()
    hud.m:SetPoint("TOPLEFT", hud.l, "TOPRIGHT")
    hud.m:SetPoint("BOTTOMRIGHT", hud.r, "BOTTOMLEFT")
    hud.l:Show() hud.m:Show() hud.r:Show()
    return h, capL, capR
end

--- Journaling toolbar strip (handoff item 2, Pass B): always the plain
--- TopHUD set (owner's pick for the toolbar, independent of skin).
function Blackacre.UI.Theme.ApplyToolbarStrip(frame, maxH)
    return ApplyHudStrip(frame, "plain", nil, maxH)
end

--- Font picker shell (handoff item 2, Pass B). Owner-named:
--- background GarrLanding-FollowerFrame (Interface/Garrison/GarrisonLandingPage),
--- border QuestLog-frame (Interface/QuestFrame/QuestLogFrame2x).
--- Returns the border's native width, height so the caller can keep the
--- frame at that aspect ratio (no stretch); nil if the border is missing.
function Blackacre.UI.Theme.ApplyFontListShell(frame)
    if not frame then return nil end
    if not frame._baShellBg then
        frame._baShellBg = frame:CreateTexture(nil, "BACKGROUND")
        frame._baShellBorder = frame:CreateTexture(nil, "BORDER")
    end
    local bg, border = frame._baShellBg, frame._baShellBorder
    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT", 8, -8)
    bg:SetPoint("BOTTOMRIGHT", -8, 8)
    if not SetNamedAtlas(bg, "GarrLanding-FollowerFrame") then
        bg:SetColorTexture(0.1, 0.08, 0.06, 0.95)
    end
    border:SetAllPoints(frame)
    local bw, bh = SetNamedAtlas(border, "QuestLog-frame")
    if not bw or bw <= 0 or bh <= 0 then
        border:Hide()
        return nil
    end
    border:Show()
    return bw, bh
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
    -- headerPad lets a skin place the title bar (2F) without moving the footer.
    local headerPad = skin.headerPad or pad
    frame.header:ClearAllPoints()
    frame.header:SetPoint("TOPLEFT", headerPad, -headerPad)
    frame.header:SetPoint("TOPRIGHT", -headerPad, -headerPad)
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
    if frame.pageJumpBtn and frame.backstoryBtn and frame.pageJumpOf and frame.pageJump then
        frame.pageJumpBtn:ClearAllPoints()
        -- The Backstory button only shows when that add-on is installed;
        -- without it the page-jump row sits at the footer's right edge.
        if frame.backstoryBtn:IsShown() then
            frame.pageJumpBtn:SetPoint("RIGHT", frame.backstoryBtn, "LEFT", -6, 0)
        else
            frame.pageJumpBtn:SetPoint("RIGHT", skin.footerRightOffsetX or -10, 0)
        end
        frame.pageJumpOf:ClearAllPoints()
        frame.pageJumpOf:SetPoint("RIGHT", frame.pageJumpBtn, "LEFT", -4, 0)
        frame.pageJump:ClearAllPoints()
        frame.pageJump:SetPoint("RIGHT", frame.pageJumpOf, "LEFT", -6, 0)
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

--- Backdrop for a pannable tree viewport (B4F): the Mother talent tree art,
--- rotated a quarter turn so its long side runs sideways. Rotating a texture
--- doesn't swap its box, so the region is sized (height x width) to match.
function Blackacre.UI.Theme.ApplyTreeBackground(viewport)
    if not viewport then return end
    local T = Blackacre.UI.Theme.Textures
    local tex = viewport._baTreeBg
    if not tex then
        tex = viewport:CreateTexture(nil, "BACKGROUND", nil, -8)
        viewport._baTreeBg = tex
        viewport:HookScript("OnSizeChanged", function(vp, w, h)
            if vp._baTreeBgRotated then vp._baTreeBg:SetSize(h, w) end
        end)
    end
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", viewport, "CENTER", 0, 0)
    -- SetAtlas doesn't fail loudly on an unknown name, so ask the client first.
    local known = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(T.treeBackgroundAtlas)
    if known and Blackacre.UI.Theme.TrySetAtlas(tex, T.treeBackgroundAtlas, false) then
        viewport._baTreeBgRotated = true
        tex:SetRotation(math.pi / 2)
        tex:SetSize(viewport:GetHeight(), viewport:GetWidth())
    else
        viewport._baTreeBgRotated = false
        -- Atlas missing: plain dark fill, never a guessed crop.
        tex:SetColorTexture(0.05, 0.05, 0.08, 1)
        tex:SetAllPoints(viewport)
        if Blackacre.Print then
            Blackacre.Print("Tree background atlas '" .. tostring(T.treeBackgroundAtlas) .. "' was not found in this client.")
        end
    end
    tex:Show()
end

--- B2: the Backstory header card, at the atlas's own size, centered on the
--- header bar (it doesn't have to span the window). Returns false if the
--- atlas isn't in this client so the caller can keep its plain bar.
function Blackacre.UI.Theme.ApplyBackstoryHeader(header)
    local T = Blackacre.UI.Theme.Textures
    if not (header and C_Texture and C_Texture.GetAtlasInfo(T.backstoryHeaderAtlas)) then return false end
    local card = header._baCard
    if not card then
        card = header:CreateTexture(nil, "BACKGROUND", nil, 2)
        header._baCard = card
    end
    card:ClearAllPoints()
    card:SetPoint("CENTER", header, "CENTER", 0, 0)
    card:SetAtlas(T.backstoryHeaderAtlas, true)
    card:Show()
    return true
end

--- A section divider: stretched across, at the atlas's own height. Returns
--- false (leaving `tex` alone) if the atlas isn't in this client.
function Blackacre.UI.Theme.ApplyDividerArt(tex)
    local T = Blackacre.UI.Theme.Textures
    local info = C_Texture and C_Texture.GetAtlasInfo(T.backstoryDividerAtlas)
    if not (tex and info) then return false end
    tex:SetAtlas(T.backstoryDividerAtlas, false)
    tex:SetHeight(info.height)
    return true
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

--- Wooden nine-slice border only (no fill) using the Tavern skin's own atlas
--- pieces (Neutral-NineSlice-*), independent of the player's chosen chrome
--- skin (Blackacre.UI.Theme.GetActiveSkin()) — for windows that always want
--- this specific look (e.g. a corkboard/notice frame), not whatever skin is
--- currently active. Same mirrored-corner technique as ApplyBookShellChrome's
--- own non-unique-corner branch, just standalone and skin-independent.
function Blackacre.UI.Theme.ApplyTavernFrameBorder(frame)
    if not frame then return end
    local host = frame._baTavernBorder
    if not host then
        host = CreateFrame("Frame", nil, frame)
        frame._baTavernBorder = host
    end
    host:ClearAllPoints()
    host:SetAllPoints(frame)
    host:EnableMouse(false)
    host.layoutTextureLayer = "OVERLAY"
    host.layoutTextureSubLevel = 7

    local corner = "Neutral-NineSlice-Corner"
    local edgeH = "_Neutral-NineSlice-EdgeTop"
    local edgeV = "!Neutral-NineSlice-EdgeLeft"
    local layout = {
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
    if NineSliceUtil and NineSliceUtil.ApplyLayout then
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
            piece:Show()
        end
    end
    host:SetFrameLevel((frame:GetFrameLevel() or 1) + 70)
    return host
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
            -- Both directions: NineSliceUtil.ApplyLayout never calls Show(), so
            -- pieces hidden by a single-shell skin (Ironforge/Void) stayed hidden
            -- after switching to a nine-slice skin (seen on Forsaken, next in list).
            piece:SetShown(not skin.shellAtlas)
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

    local bg = tex("_baParchBg", "BACKGROUND", -5)
    local function layoutFill()
        local w, h = frame:GetWidth(), frame:GetHeight()
        if not w or w == 0 then w = 640 end
        if not h or h == 0 then h = 720 end
        bg:ClearAllPoints()
        bg:SetPoint("CENTER", frame, "CENTER", 0, 0)
        bg:SetSize((w - 36) * 0.92, (h - 36) * 0.92)
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

--- TAV's actual outer-shell border: TAV_CoreFrame inherits PortraitFrameTemplate
--- unmodified. The PortraitFrameTemplate layout names a portrait-shaped
--- TopLeftCorner (notched for a round character portrait) — we have no
--- portrait, so we use the plain Metal corner instead. Right-side pieces use
--- their own real atlas names (owner-confirmed via TAV on the live frame,
--- from Interface/FrameGeneral/UIFrameMetal2xC60): what looked like a mirror
--- bug earlier was actually the shell being too narrow for these pieces —
--- see the +3px width bump on the Quest Index frame.
function Blackacre.UI.Theme.ApplyMetalShellBorder(frame)
    if not frame then return end
    local TrySetAtlas = Blackacre.UI.Theme.TrySetAtlas
    local function tex(key, sub)
        local t = frame[key]
        if not t then
            t = frame:CreateTexture(nil, "OVERLAY", nil, sub)
            frame[key] = t
        end
        return t
    end

    local tl = tex("_baMetalTL", 0)
    tl:ClearAllPoints()
    tl:SetPoint("TOPLEFT", -13, 16)
    TrySetAtlas(tl, "UI-Frame-Metal-CornerTopLeft", true)

    local tr = tex("_baMetalTR", 0)
    tr:ClearAllPoints()
    tr:SetPoint("TOPRIGHT", 4, 16)
    TrySetAtlas(tr, "UI-Frame-Metal-CornerTopRightDouble", true)

    local bl = tex("_baMetalBL", 0)
    bl:ClearAllPoints()
    bl:SetPoint("BOTTOMLEFT", -13, -3)
    TrySetAtlas(bl, "UI-Frame-Metal-CornerBottomLeft", true)

    local br = tex("_baMetalBR", 0)
    br:ClearAllPoints()
    br:SetPoint("BOTTOMRIGHT", 4, -3)
    TrySetAtlas(br, "UI-Frame-Metal-CornerBottomRight", true)

    local top = tex("_baMetalTop", 0)
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
    top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
    TrySetAtlas(top, "_UI-Frame-Metal-EdgeTop", true)

    local bot = tex("_baMetalBot", 0)
    bot:ClearAllPoints()
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0)
    bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    TrySetAtlas(bot, "_UI-Frame-Metal-EdgeBottom", true)

    local left = tex("_baMetalLeft", 0)
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
    TrySetAtlas(left, "!UI-Frame-Metal-EdgeLeft", true)

    local right = tex("_baMetalRight", 0)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    TrySetAtlas(right, "!UI-Frame-Metal-EdgeRight", true)
end

--- Quest Index outer window base layer: heavybronze-frame-background stretched
--- full-bleed, in place of the flat "page" cream fill. No backdrop border —
--- ApplyMetalShellBorder draws the real TAV border on top of this.
function Blackacre.UI.Theme.ApplyHeavyBronzeBase(frame)
    if not frame then return end
    local T = Blackacre.UI.Theme.Textures
    frame:SetBackdrop(nil)

    local bg = frame._baHeavyBronzeBg
    if not bg then
        bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        frame._baHeavyBronzeBg = bg
    end
    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT", 5, -5)
    bg:SetPoint("BOTTOMRIGHT", -5, 5)
    Blackacre.UI.Theme.TrySetAtlas(bg, T.questIndexBaseAtlas, false)

    Blackacre.UI.Theme.ApplyMetalShellBorder(frame)
end

--- Quest Index history list panel (owner TAV pull): the real Quest Log frame
--- chrome (questlog-frame, confirmed via Blizzard_UIPanels_Game/QuestMapFrame.xml
--- as a full-bleed "Border" overlay) over the Journeys background
--- (ui-journeys-bg, confirmed via Blizzard_Journeys.lua), rotated a quarter
--- turn since that art is native landscape and this panel runs tall — same
--- rotation technique as ApplyTreeBackground.
function Blackacre.UI.Theme.ApplyQuestLogListPanel(frame)
    if not frame then return end
    local TrySetAtlas = Blackacre.UI.Theme.TrySetAtlas

    -- Clipping host: the background is scaled up proportionally (never
    -- stretched off its own aspect ratio) to cover this panel, then
    -- whatever hangs past the panel's own edges is clipped here instead of
    -- bleeding into neighboring chrome.
    local clip = frame._baQLClip
    if not clip then
        clip = CreateFrame("Frame", nil, frame)
        frame._baQLClip = clip
        if clip.SetClipsChildren then clip:SetClipsChildren(true) end
        -- A child frame defaults to parent level + 1, which would draw its
        -- background on top of the panel's own border/title regions (and
        -- any sibling controls added afterward, like dropdowns and labels,
        -- that pick up that same default). Pin it to the panel's own level
        -- so it always sits under both.
        clip:SetFrameLevel(frame:GetFrameLevel() or 1)
    end
    clip:ClearAllPoints()
    clip:SetAllPoints(frame)

    -- Background, rotated to fit tall.
    local bg = frame._baQLBg
    if not bg then
        bg = clip:CreateTexture(nil, "BACKGROUND", nil, -8)
        frame._baQLBg = bg
        frame:HookScript("OnSizeChanged", function(f)
            if f._baQLBgRotated then Blackacre.UI.Theme.ApplyQuestLogListPanel(f) end
        end)
    end
    bg:ClearAllPoints()
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("ui-journeys-bg")
    if info and info.width and info.height and TrySetAtlas(bg, "ui-journeys-bg", false) then
        frame._baQLBgRotated = true
        -- Rotating 90° swaps the on-screen bounding box (w<->h), so the
        -- "cover" scale is measured against the frame's dimensions crossed
        -- with the texture's native ones, not matched straight across.
        local fw, fh = frame:GetWidth(), frame:GetHeight()
        local k = math.max(fw / info.height, fh / info.width)
        bg:SetSize(info.width * k, info.height * k)
        bg:SetPoint("CENTER", clip)
        bg:SetRotation(math.pi / 2)
    else
        frame._baQLBgRotated = false
        bg:SetColorTexture(0.12, 0.12, 0.14, 1)
        bg:SetAllPoints(clip)
    end
    bg:Show()

    -- Frame chrome on top, outset 2px past the panel's own edges so its
    -- drawn frame line covers the rotated background instead of the
    -- background peeking past it (child frames like the scroll list still
    -- draw above this regardless of layer name).
    local border = frame._baQLBorder
    if not border then
        border = frame:CreateTexture(nil, "BORDER")
        frame._baQLBorder = border
    end
    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    TrySetAtlas(border, "questlog-frame", false)
end

--- Resizes a UIPanelScrollFrameTemplate's thumb proportionally to how much of
--- the content is visible, like a modern scrollbar, instead of the template's
--- fixed 24px knob — and paints it with the real proportional-scrollbar knob
--- art (owner TAV pull, confirmed in Blizzard_SharedXML's TrimScrollBar.xml:
--- UI-ScrollBar-Knob-EndCap-Top/Bottom + UI-ScrollBar-Knob-Center). The center
--- piece is TILED, not stretched — copying WowScrollBarThumbScriptsMixin:
--- OnSizeChanged's own technique (SetHeight then SetTexCoord(0,1,0,height/
--- info.height)) — a stretch was what made the three pieces look like
--- separate blobs with a mismatched gradient instead of one continuous bar.
--- The native ThumbTexture stays (alpha 0) so drag/click keeps working; our
--- 3-piece overlay just tracks its position and size.
--- Call whenever the scroll child's height changes.
function Blackacre.UI.Theme.UpdateProportionalScrollThumb(scrollFrame, contentFrame, minThumbH)
    local bar = scrollFrame and scrollFrame.ScrollBar
    local thumb = bar and bar.ThumbTexture
    if not (thumb and contentFrame) then return end
    minThumbH = minThumbH or 40
    local trackH = bar:GetHeight() or 0
    local contentH = contentFrame:GetHeight() or 0
    local h
    if trackH <= 0 or contentH <= trackH then
        h = trackH
    else
        h = math.max(minThumbH, math.min(trackH, trackH * (trackH / contentH)))
    end
    thumb:SetHeight(h)
    thumb:SetAlpha(0)

    local TrySetAtlas = Blackacre.UI.Theme.TrySetAtlas
    local top = bar._baThumbTop
    if not top then
        top = bar:CreateTexture(nil, "OVERLAY")
        bar._baThumbTop = top
        TrySetAtlas(top, "UI-ScrollBar-Knob-EndCap-Top", true)
    end
    local bot = bar._baThumbBot
    if not bot then
        bot = bar:CreateTexture(nil, "OVERLAY")
        bar._baThumbBot = bot
        TrySetAtlas(bot, "UI-ScrollBar-Knob-EndCap-Bottom", true)
    end
    local mid = bar._baThumbMid
    if not mid then
        mid = bar:CreateTexture(nil, "OVERLAY")
        bar._baThumbMid = mid
        TrySetAtlas(mid, "UI-ScrollBar-Knob-Center", true)
    end

    local function Reposition()
        top:ClearAllPoints()
        top:SetPoint("TOP", thumb, "TOP", 0, 0)
        bot:ClearAllPoints()
        bot:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)

        local midH = math.max(1, (thumb:GetHeight() or 0) - (top:GetHeight() or 0) - (bot:GetHeight() or 0))
        mid:ClearAllPoints()
        mid:SetPoint("TOP", top, "BOTTOM", 0, 0)
        mid:SetPoint("LEFT", thumb, "LEFT", 0, 0)
        mid:SetPoint("RIGHT", thumb, "RIGHT", 0, 0)
        mid:SetHeight(midH)
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("UI-ScrollBar-Knob-Center")
        if info and info.height and info.height > 0 then
            mid:SetTexCoord(0, 1, 0, midH / info.height)
        end
    end
    Reposition()
    if not bar._baThumbHooked then
        bar:HookScript("OnValueChanged", Reposition)
        bar._baThumbHooked = true
    end
end

--- Backstory B1. Neutral nineslice kept for regress (Textures.backstoryB1Mode = "neutral").
function Blackacre.UI.Theme.ApplyFactionFrameChrome(frame)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(nil)
    end
    local T = Blackacre.UI.Theme.Textures
    local mode = frame.chromeMode or T.backstoryB1Mode or "questlog"

    if frame._baShell then frame._baShell:Hide() end
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

    if mode == "talent" then
        qlog:ClearAllPoints()
        qlog:SetAllPoints(frame)
        if C_Texture and C_Texture.GetAtlasInfo(T.backstoryTalentAtlas)
            and Blackacre.UI.Theme.TrySetAtlas(qlog, T.backstoryTalentAtlas, false) then
            qlog:Show()
            -- Outer shell border over the fill. Stretched to the window; if the
            -- corners look squashed the next step is a proper nine-slice.
            local shell = frame._baShell
            if not shell then
                shell = frame:CreateTexture(nil, "BORDER")
                frame._baShell = shell
            end
            shell:ClearAllPoints()
            shell:SetAllPoints(frame)
            if C_Texture.GetAtlasInfo(T.backstoryShellAtlas)
                and Blackacre.UI.Theme.TrySetAtlas(shell, T.backstoryShellAtlas, false) then
                shell:Show()
            else
                shell:Hide()
            end
            return
        end
        mode = "questlog" -- atlas missing: fall back rather than show a blank window
    end

    if mode == "questlog" then
        Blackacre.UI.Theme.ApplyParchmentPopupFill(frame)
        qlog:ClearAllPoints()
        qlog:SetAllPoints(frame)
        -- Stretch to sidecar size; do not useAtlasSize (that would keep native thickness).
        if not Blackacre.UI.Theme.TrySetAtlas(qlog, T.backstoryQuestLogAtlas or "QuestLog-frame", false) then
            if not Blackacre.UI.Theme.TrySetAtlas(qlog, "QuestLog-Frame", false) then
                if not Blackacre.UI.Theme.TrySetAtlas(qlog, "QuestLogBackground", false) then
                    qlog:SetTexture(T.backstoryQuestLogFile)
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
    -- GetHeight() is 0 (truthy) before the frame is sized; see LESSONS-LEARNED.
    local h = frame:GetHeight()
    if not h or h == 0 then h = 34 end
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

--- Title bar (2F) and footer (11F). Owner-picked TopHUD strip per skin
--- (skin.hudBar = "plain" | "dis"); the old parchment backdrop is only a
--- fallback when that art is missing from the client.
-- Owner: 2F art drawn 4px thicker above and below the bar itself.
-- 11F (footer) 4px more again (8), then nudged down so its top edge
-- clears the 9S rail above it.
local CHROME_BAR_OUTSET = 4
local FOOTER_BAR_OUTSET = 8
local FOOTER_BAR_NUDGE_Y = 0 -- centered on the buttons (owner, after screenshot)
local FOOTER_BAR_OUTSET_X = 4 -- 11F art 4px wider on each side

function Blackacre.UI.Theme.ApplyBookChromeBar(frame, which)
    if not frame or not frame.SetBackdrop then return end
    local skin = Blackacre.UI.Theme.GetActiveSkin and Blackacre.UI.Theme.GetActiveSkin()
    local h = frame:GetHeight()
    if skin and skin.hudBar and h and h > 0 and ApplyHudStrip(frame, skin.hudBar, h, nil,
            which == "footer" and FOOTER_BAR_OUTSET or CHROME_BAR_OUTSET,
            which == "footer" and FOOTER_BAR_NUDGE_Y or 0,
            which == "footer" and FOOTER_BAR_OUTSET_X or 0) then
        frame:SetBackdrop(nil)
        return
    end
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

--- Alliance = K.C. only; Horde = ADP/BDP only (never both for the player).
--- Older pages stored K.C. years (> 200); those are converted first.
function Blackacre.UI.Theme.FormatFactionYear(yearValue)
    local cal = Blackacre.YearCalendar
    if not cal then return tostring(yearValue or "?") end
    local adp = tonumber(yearValue)
    if adp and adp > 200 then adp = cal.FromKC(adp) end
    adp = adp or cal.GetPresentADP()
    return cal.FormatYearADP(adp, cal.FactionCalendar())
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
    midnight     = { atlas = "midnight-scenario-titlebg", file = "Interface\\Scenarios\\ScenarioMidnight2x" },
    legion       = { atlas = "legioninvasion-title-bg", file = "Interface\\Scenarios\\LegionInvasion" },
    maw          = { atlas = "jailerstower-scenario-TitleBG", file = "Interface\\Scenarios\\ScenarioJailerstower" },
    kyrian       = { atlas = "kyrian-scenario-TitleBG", file = "Interface\\Scenarios\\ScenarioKyrian" },
    revendreth   = { atlas = "EmberCourtScenario-TitleBG", file = "Interface\\Scenarios\\ScenarioEmberCourt" },
    nzoth        = { atlas = "NzothScenario-TitleBG", file = "Interface\\Scenarios\\Scenario0Nzoth2x" },
    -- Owner-named Tome toast art (per skin, see TOME_TOAST_BY_SKIN). No
    -- whole-sheet file fallback on these: a missing atlas shows a flat banner.
    scholomance  = { atlas = "plunderstorm-toast-finish-lose", scale = 0.8 },     -- owner: 20% smaller             -- Interface/HUD/UIWoWLabsActionBar
    seafarer     = { atlas = "plunderstorm-toast-finish-matchend", scale = 0.8 }, -- owner: 20% smaller         -- Interface/HUD/UIWoWLabsActionBar
    ornate       = { atlas = "themed-scenario-titlebg-2x" },                 -- Interface/Scenarios/UIThemedScenario2x
    slate        = { atlas = "titleprestige-title-bg" },                     -- Interface/PVPFrame/TitlePrestige
    tavern       = { atlas = "islands-queue-difficultyselector-backboard" }, -- Interface/Scenarios/IslandsQueue
    skyborne     = { atlas = "CovenantSanctum-Renown-FinalToast-Nightfae" }, -- Interface/CovenantRenown/CovenantRenownNightFae
    -- Interface/Store/BoostPopup: a framed popup built from pieces, not one
    -- banner. No bottom-left piece was named; it's the bottom-right mirrored.
    services     = { pieces = {
        tl = "services-popup-topleft", t = "services-popup-top", tr = "services-popup-topright",
        r = "services-popup-right", br = "services-popup-botright", b = "services-popup-bot",
        l = "services-popup-left",
    } },
}

-- Tome toasts ("tome" / "journal" kit) follow the active chrome skin.
local TOME_TOAST_BY_SKIN = {
    Alliance = "alliance", Horde = "horde", Dragonflight = "dragonflight",
    Kyrian = "kyrian", Scholomance = "scholomance", Void = "midnight",
    Ironforge = "warwithin", Seafarer = "seafarer", Forsaken = "revendreth",
    Workshop = "services", Metal = "services", Ornate = "ornate",
    Slate = "slate", Tavern = "tavern", Skyborne = "skyborne",
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
    if kit == "journal" or kit == "tome" then
        local skinId = Blackacre.UI.Theme.GetActiveSkinId and Blackacre.UI.Theme.GetActiveSkinId()
        kit = TOME_TOAST_BY_SKIN[skinId] or "evergreen"
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

-- Pieced toast frame (services kit): corners at native size, edges stretch
-- along their own length only. Pieces live on the toast frame's BORDER
-- layer so the title (OVERLAY) always draws above them.
local TOAST_PIECE_KEYS = { "tl", "t", "tr", "r", "br", "b", "l", "bl" }

local function ToastPieces(f)
    local p = f._baPieces
    if not p then
        p = {}
        for i = 1, #TOAST_PIECE_KEYS do
            p[TOAST_PIECE_KEYS[i]] = f:CreateTexture(nil, "BORDER")
        end
        f._baPieces = p
    end
    return p
end

local function HideToastPieces(f)
    local p = f._baPieces
    if not p then return end
    for i = 1, #TOAST_PIECE_KEYS do p[TOAST_PIECE_KEYS[i]]:Hide() end
end

-- Returns frame width, height, label; nil if any piece is missing.
local function ApplyPiecedToast(f, names)
    local p = ToastPieces(f)
    local size = {}
    for key, atlas in pairs(names) do
        local w, h = SetNamedAtlas(p[key], atlas)
        if not w then
            HideToastPieces(f)
            return nil
        end
        size[key] = { w, h }
    end
    -- Bottom-left = bottom-right mirrored (no bottom-left atlas named).
    local br = size.br
    SetNamedAtlas(p.bl, names.br)
    local info = C_Texture.GetAtlasInfo(names.br)
    p.bl:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.topTexCoord, info.bottomTexCoord)
    -- Owner: the named left piece is oversized/out of place on the toast;
    -- draw the left edge as the right edge mirrored instead.
    SetNamedAtlas(p.l, names.r)
    info = C_Texture.GetAtlasInfo(names.r)
    p.l:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.topTexCoord, info.bottomTexCoord)
    size.l = size.r

    local tl, tr = size.tl, size.tr
    local w = 520
    local h = math.max(84, tl[2] + br[2] + 20)
    local function corner(tex, sz, point)
        tex:ClearAllPoints()
        tex:SetPoint(point)
        tex:SetSize(sz[1], sz[2])
    end
    corner(p.tl, tl, "TOPLEFT")
    corner(p.tr, tr, "TOPRIGHT")
    corner(p.br, br, "BOTTOMRIGHT")
    corner(p.bl, br, "BOTTOMLEFT")
    p.t:ClearAllPoints()
    p.t:SetPoint("TOPLEFT", p.tl, "TOPRIGHT")
    p.t:SetPoint("TOPRIGHT", p.tr, "TOPLEFT")
    p.t:SetHeight(size.t[2])
    p.b:ClearAllPoints()
    p.b:SetPoint("BOTTOMLEFT", p.bl, "BOTTOMRIGHT")
    p.b:SetPoint("BOTTOMRIGHT", p.br, "BOTTOMLEFT")
    p.b:SetHeight(size.b[2])
    p.l:ClearAllPoints()
    p.l:SetPoint("TOPLEFT", p.tl, "BOTTOMLEFT")
    p.l:SetPoint("BOTTOMLEFT", p.bl, "TOPLEFT")
    p.l:SetWidth(size.l[1])
    p.r:ClearAllPoints()
    p.r:SetPoint("TOPRIGHT", p.tr, "BOTTOMRIGHT")
    p.r:SetPoint("BOTTOMRIGHT", p.br, "TOPRIGHT")
    p.r:SetWidth(size.r[1])
    for i = 1, #TOAST_PIECE_KEYS do p[TOAST_PIECE_KEYS[i]]:Show() end
    return w, h, "services-popup"
end

-- Dresses the whole toast frame for a kit. Returns width, height, label.
local function ApplyToastBanner(f, kit)
    kit = ResolveToastKit(kit)
    local spec = Blackacre.UI.Theme.ToastKits[kit] or Blackacre.UI.Theme.ToastKits.evergreen
    local tex = f.bg
    if spec.pieces then
        local w, h, used = ApplyPiecedToast(f, spec.pieces)
        if w then
            -- No center piece named: dark fill across the whole interior,
            -- tucked just under the border pieces (BORDER draws above it).
            tex:SetColorTexture(0.06, 0.05, 0.04, 0.92)
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
            tex:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
            return w, h, used
        end
        spec = Blackacre.UI.Theme.ToastKits.evergreen
    end
    HideToastPieces(f)
    tex:ClearAllPoints()
    tex:SetAllPoints(f)
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
        if spec.scale then w, h = w * spec.scale, h * spec.scale end
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
    f.title = f:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalLarge")
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

-- Banner art (single texture or pieces) fades together.
local function SetToastArtAlpha(f, a)
    f.bg:SetAlpha(a)
    local p = f._baPieces
    if p then
        for i = 1, #TOAST_PIECE_KEYS do p[TOAST_PIECE_KEYS[i]]:SetAlpha(a) end
    end
end

-- One shared handler (no per-toast closure); only runs while a toast shows.
-- Banner fade in, then text fade in, then hold, then all fade out.
local function Toast_OnUpdate(self, elapsed)
    local t = (self._t or 0) + elapsed
    self._t = t
    if t < 0.4 then
        SetToastArtAlpha(self, t / 0.4)
        self.title:SetAlpha(0)
    elseif t < 0.85 then
        SetToastArtAlpha(self, 1)
        self.title:SetAlpha((t - 0.4) / 0.45)
    elseif toastHold or t < 3.6 then
        SetToastArtAlpha(self, 1)
        self.title:SetAlpha(1)
    elseif t < 4.4 then
        local p = 1 - ((t - 3.6) / 0.8)
        SetToastArtAlpha(self, p)
        self.title:SetAlpha(p)
    else
        self:SetScript("OnUpdate", nil)
        self:Hide()
        toastBusy = false
        toastHold = false
        PlayNextToast()
    end
end

local function RunToast(item)
    local f = EnsureToastFrame()
    local w, h, used = ApplyToastBanner(f, item.kit)
    f:SetSize(w or 520, h or 84)
    f._baKit = item.kit
    f._baAtlas = used
    f.fx:Hide()
    f.title:SetText(item.message or "")
    f:SetAlpha(1)
    SetToastArtAlpha(f, 0)
    f.title:SetAlpha(0)
    f:Show()
    toastBusy = true
    toastHold = item.hold and true or false
    f._t = 0
    f:SetScript("OnUpdate", Toast_OnUpdate)
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
            local fs = ov:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalHuge")
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

-- Region registry for /ba skin. Any screen calls RegisterSkinRegion once per
-- area it wants a polish label on (e.g. "O4" for Origin's option list); the
-- guide shows every label while it's on. The tag is parented to the region,
-- so it appears and hides with that screen or step. Gold = skin (art),
-- white = function (layout/clicks).
local skinRegions = {}
local skinGuideOn = false

local function MakeSkinTag(e)
    -- Anchors can be FontStrings/Textures (regions); those can't parent a
    -- frame, so parent to their owner frame and overlay the region itself.
    local owner = e.anchor
    if not owner.GetFrameLevel then owner = owner:GetParent() end
    if not owner then return end
    local holder = CreateFrame("Frame", nil, owner)
    holder:SetAllPoints(e.anchor)
    holder:SetFrameStrata("DIALOG")
    holder:SetFrameLevel((owner:GetFrameLevel() or 1) + 80)
    holder:EnableMouse(false)
    local fs = holder:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalHuge")
    fs:SetPoint("CENTER", holder, "CENTER", e.ox or 0, e.oy or 0)
    fs:SetText((e.kind == "S" and "|cffffcc00" or "|cffffffff") .. e.code .. e.kind .. "|r")
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
    e.tag = holder
end

--- Label a region for /ba skin. kind: "S" skin/art, "F" function/layout.
function Blackacre.UI.Theme.RegisterSkinRegion(anchor, code, kind, ox, oy)
    if not anchor then return end
    local e = { anchor = anchor, code = code, kind = kind or "F", ox = ox, oy = oy }
    skinRegions[#skinRegions + 1] = e
    if skinGuideOn then
        MakeSkinTag(e)
        if e.tag then e.tag:Show() end
    end
end

local function ShowRegisteredSkinTags(shown)
    skinGuideOn = shown and true or false
    for _, e in ipairs(skinRegions) do
        if skinGuideOn and not e.tag then MakeSkinTag(e) end
        if e.tag then e.tag:SetShown(skinGuideOn) end
    end
end

local function EnsureBackstorySkinGuide(shown)
    ShowRegisteredSkinTags(shown)
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
            local fs = mOverlay:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalHuge")
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
            local fs = ov:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalHuge")
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
        local fs = overlay:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalHuge")
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

    local legend = overlay:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormal")
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

-- Window focus: click any In Character window and it comes to the front, the
-- others drop behind it. Every window registers here and shares one strata
-- (frame strata beats frame level, so a window left in a higher strata would
-- otherwise stay on top no matter what you click). Pop-up menus stay in
-- DIALOG, above all of them.
--
-- The stacking is ours, not the client's. Raise() (and toplevel windows,
-- which call it on every click) lifts a window's own level but leaves any
-- child that was given an explicit level (page text, list panels, borders)
-- behind, so the shell jumped forward while its insides stayed under the
-- other window. Raising also crept levels toward the client's ceiling, where
-- they got squashed together. Instead, `windows` is kept in back-to-front
-- order, and bringing one forward re-levels every open window from a low
-- base: each window and everything inside it, keeping each piece's level
-- relative to its parent. Levels stay small, and nothing gets left behind.
Blackacre.UI.Focus = {}

local WINDOW_STRATA = "HIGH"
local BASE_LEVEL = 100 -- bottom window's level; the rest stack above it
local WINDOW_GAP = 2
local windows, known = {}, {} -- windows: back to front

-- Topmost registered window under the mouse, or nil.
local function WindowUnderMouse()
    for i = #windows, 1, -1 do
        local f = windows[i]
        if f:IsShown() and f:IsMouseOver() then return f end
    end
    return nil
end

-- Scratch arrays for one window's subtree, reused for every re-level.
local subFrames, subParent, subRel, subNew = {}, {}, {}, {}

-- Record every descendant of frame (subFrames[idx]) after position n, with
-- its level relative to its parent, read before anything moves.
local function Collect(frame, idx, n)
    local level = frame:GetFrameLevel()
    local kids = { frame:GetChildren() }
    for i = 1, #kids do
        local c = kids[i]
        n = n + 1
        subFrames[n], subParent[n] = c, idx
        -- 0 is allowed: some pieces sit at their parent's own level on
        -- purpose (the list panel's background, so its border draws on top).
        local rel = c:GetFrameLevel() - level
        subRel[n] = rel > 0 and rel or 0
        n = Collect(c, n, n)
    end
    return n
end

-- Put a window at `base` with all its pieces in the same order as before.
-- Returns how many levels the window spans.
local function SetWindowLevel(w, base)
    subFrames[1] = w
    local n = Collect(w, 1, 1)
    w:SetFrameLevel(base)
    subNew[1] = base
    local top = base
    for i = 2, n do
        local lvl = subNew[subParent[i]] + subRel[i]
        subNew[i] = lvl
        subFrames[i]:SetFrameLevel(lvl)
        if lvl > top then top = lvl end
    end
    for i = 1, n do subFrames[i] = nil end -- don't hold frames between calls
    return top - base
end

local function FrontmostShown()
    for i = #windows, 1, -1 do
        if windows[i]:IsShown() then return windows[i] end
    end
    return nil
end

-- force: re-level even if f is already in front (a window that just opened
-- still has its default level).
local function BringToFront(f, force)
    if not force and FrontmostShown() == f then return end
    for i = #windows, 1, -1 do
        if windows[i] == f then
            table.remove(windows, i)
            break
        end
    end
    windows[#windows + 1] = f
    local base = BASE_LEVEL
    for i = 1, #windows do
        local w = windows[i]
        if w:IsShown() then
            base = base + SetWindowLevel(w, base) + WINDOW_GAP
        end
    end
    -- Let the window re-assert anything it layers by hand.
    if f._baOnRaised then f._baOnRaised(f) end
end

-- GLOBAL_MOUSE_DOWN fires on every click anywhere in the game, so it is only
-- registered while at least one In Character window is open.
local watcher = CreateFrame("Frame")
watcher:SetScript("OnEvent", function()
    local top = WindowUnderMouse()
    if top then BringToFront(top) end
end)

local function Window_OnShow(self)
    -- A window that just opened sits in front.
    BringToFront(self, true)
    watcher:RegisterEvent("GLOBAL_MOUSE_DOWN")
end

local function Window_OnHide()
    if not FrontmostShown() then watcher:UnregisterEvent("GLOBAL_MOUSE_DOWN") end
end

function Blackacre.UI.Focus.Register(frame)
    if not frame or known[frame] then return frame end
    known[frame] = true
    windows[#windows + 1] = frame
    frame:SetFrameStrata(WINDOW_STRATA)
    -- Not toplevel: the client would Raise() it on every click.
    frame:SetToplevel(false)
    frame:HookScript("OnShow", Window_OnShow)
    frame:HookScript("OnHide", Window_OnHide)
    if frame:IsShown() then watcher:RegisterEvent("GLOBAL_MOUSE_DOWN") end
    return frame
end
