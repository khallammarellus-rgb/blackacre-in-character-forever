-- In Character Forever: Beacons & Bulletins - Beacon and Bulletin Editor

Blackacre = Blackacre or {}
Blackacre.PostEditor = {}

local beaconFrame
local bulletinFrame
local loadDialog

-- Owner-confirmed atlas/file pairs (TAV-checked, 2026-09-28). Label is the
-- part of the atlas name after "QuestBG-" (or "QuestLog-"), verbatim casing.
local STATIONERY = {
    { id = "parchment", label = "Parchment", atlas = "QuestBG-Parchment", file = "Interface\\QuestFrame\\QuestBackgroundParchment" },
    { id = "azurespan", label = "Azurespan", atlas = "QuestBG-Azurespan", file = "Interface\\QuestFrame\\QuestBackgroundDragonflightAzurespan" },
    { id = "dracthyrawaken", label = "Dracthyrawaken", atlas = "QuestBG-Dracthyrawaken", file = "Interface\\QuestFrame\\QuestBackgroundDragonflightDracthyrawaken" },
    { id = "dragonflight", label = "Dragonflight", atlas = "QuestBG-Dragonflight", file = "Interface\\QuestFrame\\QuestBackgroundDragonflightDragonflight" },
    { id = "emeralddream", label = "EmeraldDream", atlas = "QuestBG-EmeraldDream", file = "Interface\\QuestFrame\\QuestBackgroundDragonflightEmeralddream" },
    { id = "ohnplains", label = "Ohnplains", atlas = "QuestBG-Ohnplains", file = "Interface\\QuestFrame\\QuestBackgroundDragonflightOhnplains" },
    { id = "thaldraszus", label = "Thaldraszus", atlas = "QuestBG-Thaldraszus", file = "Interface\\QuestFrame\\QuestBackgroundDragonflightThaldraszus" },
    { id = "walkingshore", label = "Walkingshore", atlas = "QuestBG-Walkingshore", file = "Interface\\QuestFrame\\QuestBackgroundDragonflightWalkingshore" },
    { id = "zaralekcavern", label = "ZaralekCavern", atlas = "QuestBG-ZaralekCavern", file = "Interface\\QuestFrame\\QuestBackgroundDragonflightZaralekcavern" },
    { id = "exilesreach", label = "ExilesReach", atlas = "QuestBG-ExilesReach", file = "Interface\\QuestFrame\\QuestBackgroundExilesReach" },
    { id = "alliance", label = "Alliance", atlas = "QuestBG-Alliance", file = "Interface\\QuestFrame\\QuestBackgroundHordeAlliance" },
    { id = "legionfall", label = "Legionfall", atlas = "QuestBG-Legionfall", file = "Interface\\QuestFrame\\QuestBackgroundHordeAlliance" },
    { id = "thehandoffate", label = "TheHandofFate", atlas = "QuestBG-TheHandofFate", file = "Interface\\QuestFrame\\QuestBackgroundHordeAlliance" },
    { id = "horde", label = "Horde", atlas = "QuestBG-Horde", file = "Interface\\QuestFrame\\QuestBackgroundHordeAlliance" },
    { id = "legacyoftheamani", label = "LegacyoftheAmani", atlas = "QuestBG-LegacyoftheAmani", file = "Interface\\QuestFrame\\QuestBackgroundMidnightLegacyoftheamani" },
    { id = "light", label = "Light", atlas = "QuestBG-Light", file = "Interface\\QuestFrame\\QuestBackgroundMidnightLight" },
    { id = "sky", label = "Sky", atlas = "QuestBG-Sky", file = "Interface\\QuestFrame\\QuestBackgroundMidnightSky" },
    { id = "pandaria", label = "Pandaria", atlas = "QuestBG-Pandaria", file = "Interface\\QuestFrame\\QuestBackgroundPandaria" },
    { id = "alchemy", label = "alchemy", atlas = "QuestBG-alchemy", file = "Interface\\QuestFrame\\QuestBackgroundProfessionAlchemy" },
    { id = "blacksmithing", label = "blacksmithing", atlas = "QuestBG-blacksmithing", file = "Interface\\QuestFrame\\QuestBackgroundProfessionBlacksmithing" },
    { id = "cooking", label = "cooking", atlas = "QuestBG-cooking", file = "Interface\\QuestFrame\\QuestBackgroundProfessionCooking" },
    { id = "enchanting", label = "enchanting", atlas = "QuestBG-enchanting", file = "Interface\\QuestFrame\\QuestBackgroundProfessionEnchanting" },
    { id = "engineering", label = "engineering", atlas = "QuestBG-engineering", file = "Interface\\QuestFrame\\QuestBackgroundProfessionEngineering" },
    { id = "firstaid", label = "FirstAid", atlas = "QuestBG-FirstAid", file = "Interface\\QuestFrame\\QuestBackgroundProfessionFirstAid" },
    { id = "fishing", label = "fishing", atlas = "QuestBG-fishing", file = "Interface\\QuestFrame\\QuestBackgroundProfessionFishing" },
    { id = "herbalism", label = "herbalism", atlas = "QuestBG-herbalism", file = "Interface\\QuestFrame\\QuestBackgroundProfessionHerbalism" },
    { id = "inscription", label = "inscription", atlas = "QuestBG-inscription", file = "Interface\\QuestFrame\\QuestBackgroundProfessionInscription" },
    { id = "jewelcrafting", label = "jewelcrafting", atlas = "QuestBG-jewelcrafting", file = "Interface\\QuestFrame\\QuestBackgroundProfessionJewelcrafting" },
    { id = "leatherworking", label = "leatherworking", atlas = "QuestBG-leatherworking", file = "Interface\\QuestFrame\\QuestBackgroundProfessionLeatherworking" },
    { id = "mining", label = "mining", atlas = "QuestBG-mining", file = "Interface\\QuestFrame\\QuestBackgroundProfessionMining" },
    { id = "poisons", label = "Poisons", atlas = "QuestBG-Poisons", file = "Interface\\QuestFrame\\QuestBackgroundProfessionPoisons" },
    { id = "skinning", label = "skinning", atlas = "QuestBG-skinning", file = "Interface\\QuestFrame\\QuestBackgroundProfessionSkinning" },
    { id = "tailoring", label = "tailoring", atlas = "QuestBG-tailoring", file = "Interface\\QuestFrame\\QuestBackgroundProfessionTailoring" },
    { id = "shadowlands", label = "Shadowlands", atlas = "QuestBG-Shadowlands", file = "Interface\\QuestFrame\\QuestBackgroundShadowlands" },
    { id = "ardenweald", label = "Ardenweald", atlas = "QuestBG-Ardenweald", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsArdenweald" },
    { id = "bastion", label = "Bastion", atlas = "QuestBG-Bastion", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsBastion" },
    { id = "kyrian", label = "Kyrian", atlas = "QuestBG-Kyrian", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsCovenantSkyrian" },
    { id = "necrolord", label = "Necrolord", atlas = "QuestBG-Necrolord", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsCovenantsNecrolords" },
    { id = "fey", label = "Fey", atlas = "QuestBG-Fey", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsCovenantsNightfae" },
    { id = "venthyr", label = "Venthyr", atlas = "QuestBG-Venthyr", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsCovenantsVenthyr" },
    { id = "maldraxxus", label = "Maldraxxus", atlas = "QuestBG-Maldraxxus", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsMaldraxxus" },
    { id = "oribos", label = "Oribos", atlas = "QuestBG-Oribos", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsOribos" },
    { id = "revendreth", label = "Revendreth", atlas = "QuestBG-Revendreth", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsRevendreth" },
    { id = "secretsofthefirstones", label = "secretsofthefirstones", atlas = "QuestBG-secretsofthefirstones", file = "Interface\\QuestFrame\\QuestBackgroundShadowlandsSecretsofthefirstones" },
    { id = "arator", label = "Arator", atlas = "QuestBG-Arator", file = "Interface\\QuestFrame\\QuestBackgroundTheWarWithinArator" },
    { id = "candle", label = "Candle", atlas = "QuestBG-Candle", file = "Interface\\QuestFrame\\QuestBackgroundTheWarWithinCandle" },
    { id = "fist", label = "Fist", atlas = "QuestBG-Fist", file = "Interface\\QuestFrame\\QuestBackgroundTheWarWithinFist" },
    { id = "flame", label = "Flame", atlas = "QuestBG-Flame", file = "Interface\\QuestFrame\\QuestBackgroundTheWarWithinFlame" },
    { id = "planet", label = "Planet", atlas = "QuestBG-Planet", file = "Interface\\QuestFrame\\QuestBackgroundTheWarWithinPlanet" },
    { id = "rocket", label = "Rocket", atlas = "QuestBG-Rocket", file = "Interface\\QuestFrame\\QuestBackgroundTheWarWithinRocket" },
    { id = "storm", label = "Storm", atlas = "QuestBG-Storm", file = "Interface\\QuestFrame\\QuestBackgroundTheWarWithinStorm" },
    { id = "web", label = "Web", atlas = "QuestBG-Web", file = "Interface\\QuestFrame\\QuestBackgroundTheWarWithinWeb" },
    { id = "tradingpost", label = "Trading-Post", atlas = "QuestBG-Trading-Post", file = "Interface\\QuestFrame\\QuestBackgroundTradingPost" },
    { id = "legion", label = "Legion", atlas = "QuestBG-Legion", file = "Interface\\QuestFrame\\QuestBackgroundWoWLegion" },
    { id = "questlogempty", label = "empty-quest-background", atlas = "QuestLog-empty-quest-background", file = "Interface\\QuestFrame\\QuestLogBackground2x" },
}

local SEALS = {
    { id = "none", label = "No seal", atlas = nil },
    { id = "alliance", label = "Alliance wax", atlas = "Quest-Alliance-WaxSeal" },
    { id = "horde", label = "Horde wax", atlas = "Quest-Horde-WaxSeal" },
    { id = "legionfall", label = "Legionfall wax", atlas = "Quest-Legionfall-WaxSeal" },
}

local FONTS = {
    { id = "quest", label = "Quest", object = "QuestFont" },
    { id = "questTitle", label = "Quest title", object = "QuestTitleFont" },
    { id = "mail", label = "Mail", object = "MailTextFontNormal" },
    { id = "chat", label = "Chat", object = "ChatFontNormal" },
    { id = "normal", label = "Game", object = "GameFontNormal" },
    { id = "highlight", label = "Highlight", object = "GameFontHighlight" },
    { id = "black", label = "Ink", object = "GameFontBlack" },
}

local function HasAtlas(name)
    return name and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end

local function PaintNamed(tex, atlas, file)
    if not tex then return end
    if atlas and HasAtlas(atlas) then
        tex:SetAtlas(atlas, false)
        return
    end
    if atlas and HasAtlas(atlas:lower()) then
        tex:SetAtlas(atlas:lower(), false)
        return
    end
    if file then
        tex:SetTexture(file)
    end
end

function Blackacre.PostEditor.PaintStationery(tex, id)
    local spec = STATIONERY[1]
    for i = 1, #STATIONERY do
        if STATIONERY[i].id == id then spec = STATIONERY[i] break end
    end
    PaintNamed(tex, spec.atlas, spec.file)
end

function Blackacre.PostEditor.PaintSeal(tex, id)
    if not tex then return end
    if not id or id == "none" then
        tex:Hide()
        return
    end
    local atlas
    for i = 1, #SEALS do
        if SEALS[i].id == id then atlas = SEALS[i].atlas break end
    end
    if atlas and HasAtlas(atlas) then
        tex:SetAtlas(atlas, false)
        tex:Show()
    else
        tex:Hide()
    end
end

function Blackacre.PostEditor.FontObject(id)
    for i = 1, #FONTS do
        if FONTS[i].id == id then
            return FONTS[i].object
        end
    end
    return "QuestFont"
end

function Blackacre.PostEditor.IsFontId(id)
    for i = 1, #FONTS do
        if FONTS[i].id == id then return true end
    end
    return false
end

-- BBCode-lite, block level only: each {tag}...{/tag} must wrap a whole line.
-- WoW's FontString can't mix fonts within one string, so a heading can't sit
-- inline mid-sentence — it always breaks onto its own line. Tags are the
-- existing FONTS ids (quest, questTitle, mail, chat, normal, highlight,
-- black) plus {b} for bold. There is no italic: the client ships exactly one
-- weight of its Latin UI font (Fonts\FRIZQT__.TTF), no slanted variant exists
-- to switch to. {b} uses the OUTLINE flag (a bolder-looking edge), not a true
-- bold font weight, since none is available either.
local function ParseBBCodeLine(line, defaultFontId)
    local tag, inner = line:match("^{(%a+)}(.-){/%1}$")
    local fontId = defaultFontId
    if tag and Blackacre.PostEditor.IsFontId(tag) then
        fontId = tag
        line = inner
    end
    local bolded = line:match("^{b}(.-){/b}$")
    local bold = false
    if bolded then
        bold = true
        line = bolded
    end
    return fontId, bold, line
end

-- Returns an array of { font = <FONTS id>, bold = bool, text = "..." }, one
-- per source line (blank lines included, so spacing is preserved).
function Blackacre.PostEditor.ParseBBCode(text, defaultFontId)
    local paragraphs = {}
    for line in ((text or "") .. "\n"):gmatch("(.-)\n") do
        local fontId, bold, plain = ParseBBCodeLine(line, defaultFontId)
        paragraphs[#paragraphs + 1] = { font = fontId, bold = bold, text = plain }
    end
    return paragraphs
end

-- Strips recognized tags for plain-text contexts (Tome journal capture).
function Blackacre.PostEditor.StripBBCode(text)
    local out = {}
    for _, p in ipairs(Blackacre.PostEditor.ParseBBCode(text, "quest")) do
        out[#out + 1] = p.text
    end
    return table.concat(out, "\n")
end

-- Board-listing label (See Postings rows, tooltips, journal heading): the
-- first non-blank line of the letter, tags stripped.
function Blackacre.PostEditor.DeriveTitle(bodyText)
    for _, p in ipairs(Blackacre.PostEditor.ParseBBCode(bodyText, "quest")) do
        local t = p.text:match("^%s*(.-)%s*$")
        if t ~= "" then
            if #t > 60 then t = t:sub(1, 57) .. "..." end
            return t
        end
    end
    return "Untitled notice"
end

local function ApplyLineStyle(fs, fontId, bold)
    fs:SetFontObject(Blackacre.PostEditor.FontObject(fontId))
    if bold then
        local path, size, flags = fs:GetFont()
        if path then
            flags = (flags and flags ~= "") and flags or ""
            if not flags:find("OUTLINE") then
                flags = (flags ~= "" and (flags .. ",OUTLINE")) or "OUTLINE"
            end
            fs:SetFont(path, size, flags)
        end
    end
end

-- Renders parsed BBCode as stacked FontStrings inside `host` (its own width
-- determines wrap), reusing `pool` across calls (DBM hygiene: no per-refresh
-- frame churn). Returns the total content height.
function Blackacre.PostEditor.RenderBBCode(host, pool, text, defaultFontId)
    local paragraphs = Blackacre.PostEditor.ParseBBCode(text, defaultFontId)
    local w = host:GetWidth()
    local y = 0
    for i, p in ipairs(paragraphs) do
        local fs = pool[i]
        if not fs then
            fs = host:CreateFontString(nil, "OVERLAY")
            fs:SetJustifyH("LEFT")
            fs:SetJustifyV("TOP")
            pool[i] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -y)
        fs:SetWidth(w)
        ApplyLineStyle(fs, p.font, p.bold)
        fs:SetText(p.text)
        local h = fs:GetStringHeight()
        if h < 1 then h = 14 end
        y = y + h + 2
        fs:Show()
    end
    for i = #paragraphs + 1, #pool do pool[i]:Hide() end
    return y
end

local function SkinBackstory(frame)
    if frame.SetBackdrop then frame:SetBackdrop(nil) end
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.ApplyFactionFrameChrome then
        Blackacre.UI.Theme.ApplyFactionFrameChrome(frame)
    end
end

local SHELL_HEADER_H = 30

-- chromeStyle "quest" gives the frame the same real Blizzard chrome as the
-- Tome Quest Index (bronze shell + metal border + a clean header strip with
-- a gold title); omitted keeps the older Backstory parchment skin.
local function CreateShell(name, width, height, chromeStyle)
    local f = CreateFrame("Frame", name, UIParent, chromeStyle == "quest" and "BackdropTemplate" or nil)
    f:SetSize(width, height)
    f:SetPoint("CENTER", 0, 20)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, name)
    Blackacre.UI.Focus.Register(f)

    if chromeStyle == "quest" then
        local th = Blackacre.UI.Theme
        th.ApplyHeavyBronzeBase(f)

        f.header = CreateFrame("Frame", nil, f)
        f.header:SetPoint("TOPLEFT", 6, -6)
        f.header:SetPoint("TOPRIGHT", -6, -6)
        f.header:SetHeight(SHELL_HEADER_H)

        f.title = f.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("CENTER", 0, 9)
        th.GoldTitle(f.title)

        local close = CreateFrame("Button", nil, f.header, "UIPanelCloseButton")
        close:SetSize(22, 22)
        close:SetPoint("RIGHT", -2, 6)
        close:SetScript("OnClick", function() f:Hide() end)
        f.closeBtn = close
    else
        SkinBackstory(f)
        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -18, -8)
        close:SetScript("OnClick", function() f:Hide() end)
        f.closeBtn = close
    end
    return f
end

local function MakeSection(parent, title, width, height, headerLarge, questStyle)
    local s = CreateFrame("Frame", nil, parent)
    s:SetSize(width, height)
    if questStyle then
        Blackacre.UI.Theme.ApplyQuestLogListPanel(s)
    else
        s.bg = s:CreateTexture(nil, "BACKGROUND")
        s.bg:SetAllPoints()
        PaintNamed(s.bg, "Adventures-CombatLog-BG", "Interface\\Garrison\\AdventureMissionsFrame2")
        s.edge = s:CreateTexture(nil, "BORDER")
        s.edge:SetAllPoints()
        PaintNamed(s.edge, "Adventures-CombatLog-Frame", "Interface\\Garrison\\AdventureMissionsFrame2")
    end
    s.title = s:CreateFontString(nil, "OVERLAY", headerLarge and "GameFontNormalLarge" or "GameFontNormal")
    s.title:SetPoint("TOPLEFT", 14, -8)
    s.title:SetText(title or "")
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.GoldTitle then
        Blackacre.UI.Theme.GoldTitle(s.title)
    end
    return s
end

local function MakeFooter(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetPoint("BOTTOMLEFT", 16, 10)
    bar:SetPoint("BOTTOMRIGHT", -16, 10)
    bar:SetHeight(28)
    return bar
end

-- UIDropDownMenu_SetWidth's frame is text width plus 25px of cap on each side.
local DD_CHROME = 50
local DD_GAP = 12

local function CreateDropdown(parent, name, items, width)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width or 140)
    dropdown.items = items
    dropdown.textWidth = width or 140
    UIDropDownMenu_Initialize(dropdown, function(self)
        local selected = UIDropDownMenu_GetSelectedID(dropdown) or 1
        for i, item in ipairs(self.items) do
            -- Fresh info each row. AddButton writes checked=1 onto the table it
            -- is given and never clears it, so a reused table paints every later
            -- row as selected.
            local info = UIDropDownMenu_CreateInfo()
            info.text = item
            info.value = item
            info.checked = (i == selected)
            info.func = function()
                UIDropDownMenu_SetSelectedID(dropdown, i)
                UIDropDownMenu_SetText(dropdown, item)
                if dropdown.onChanged then dropdown.onChanged(i) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedID(dropdown, 1)
    if items and items[1] then
        UIDropDownMenu_SetText(dropdown, items[1])
    end
    return dropdown
end

local SCROLL_DD_ROW_H = 18

-- Looks like an ordinary Blizzard dropdown box (UIDropDownMenuTemplate, same
-- chrome as every other dropdown here), but its list is a bordered scroll
-- popup instead of Blizzard's own auto-expanding menu — for a list too long
-- to read as one flat Blizzard menu. Same external shape as CreateDropdown
-- (.items, .onChanged), flagged .isScrollDropdown so GetDropdownValue/
-- SelectDropdown branch to it.
local function CreateScrollDropdown(parent, name, items, width, visibleRows)
    visibleRows = visibleRows or 10
    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, width or 140)
    dd.items = items
    dd.isScrollDropdown = true
    dd.selectedIndex = 1
    if items[1] then UIDropDownMenu_SetText(dd, items[1]) end

    -- Same two templates Blizzard's own DropDownList frame uses
    -- (UIDropDownMenuTemplates.xml's UIDropDownListTemplate: $parentBackdrop
    -- = DialogBorderDarkTemplate, $parentMenuBackdrop = TooltipBackdropTemplate),
    -- so this popup reads as the same dropdown menu as Wax seal/Font, not a
    -- differently-skinned one.
    local popupW = (width or 140) + 40
    local popup = CreateFrame("Frame", nil, dd)
    popup:SetSize(popupW, visibleRows * SCROLL_DD_ROW_H + 12)
    popup:SetPoint("TOP", dd, "BOTTOM", 0, 4)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    local border = CreateFrame("Frame", nil, popup, "DialogBorderDarkTemplate")
    border:SetAllPoints()
    local menuBg = CreateFrame("Frame", nil, popup, "TooltipBackdropTemplate")
    menuBg:SetAllPoints()
    popup:Hide()
    dd.popup = popup

    local scroll = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(popupW - 40, math.max(1, #items * SCROLL_DD_ROW_H))
    scroll:SetScrollChild(content)

    for i, label in ipairs(items) do
        local row = CreateFrame("Button", nil, content)
        row:SetSize(popupW - 40, SCROLL_DD_ROW_H)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * SCROLL_DD_ROW_H)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetText(label)
        row:SetScript("OnClick", function()
            dd.selectedIndex = i
            UIDropDownMenu_SetText(dd, label)
            popup:Hide()
            if dd.onChanged then dd.onChanged(i) end
        end)
    end

    -- The template's own clickable piece is its "Button" sub-region; swap
    -- its click handler instead of calling ToggleDropDownMenu, so it opens
    -- our scroll popup rather than Blizzard's own menu list.
    local ddButton = _G[dd:GetName() .. "Button"]
    if ddButton then
        ddButton:SetScript("OnClick", function()
            popup:SetShown(not popup:IsShown())
        end)
    end

    return dd
end

local function DropdownRowWidth(textWidths)
    local w = 22
    for i = 1, #textWidths do
        w = w + textWidths[i] + DD_CHROME
        if i > 1 then w = w + DD_GAP end
    end
    return w
end

local function PlaceDropdowns(parent, specs, y)
    local x = 8
    for i = 1, #specs do
        local spec = specs[i]
        spec.dropdown:ClearAllPoints()
        spec.dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        if spec.label then
            spec.label:ClearAllPoints()
            spec.label:SetPoint("BOTTOMLEFT", spec.dropdown, "TOPLEFT", 20, 3)
        end
        x = x + (spec.textWidth or spec.dropdown.textWidth or 140) + DD_CHROME + DD_GAP
    end
end

local BEACON_DD_WIDTHS = { 156, 112, 124, 164 }
local SECTION_W = math.max(DropdownRowWidth(BEACON_DD_WIDTHS), DropdownRowWidth({ 164, 150, 136, 118 }))
local SHELL_W = SECTION_W + 88

local function GetDropdownValue(dropdown)
    if dropdown.isScrollDropdown then
        return dropdown.items[dropdown.selectedIndex] or dropdown.items[1], dropdown.selectedIndex
    end
    local id = UIDropDownMenu_GetSelectedID(dropdown)
    return dropdown.items and dropdown.items[id] or dropdown.items[1], id
end

local function MacroBox(parent, w, h, maxLetters)
    local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    holder:SetSize(w, h)
    holder:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    holder:SetBackdropColor(0, 0, 0, 0.35)
    holder:SetBackdropBorderColor(0.6, 0.5, 0.3, 0.9)
    local scroll = CreateFrame("ScrollFrame", nil, holder, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(w - 44)
    edit:SetMaxLetters(maxLetters or 250)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    holder.edit = edit
    holder.scroll = scroll
    return holder
end

local function PlayerGrid()
    local ctx = Blackacre.GetZoneContext()
    local x = (ctx.coords and ctx.coords.x or 0) * 100
    local y = (ctx.coords and ctx.coords.y or 0) * 100
    return x, y, ctx
end

local function BuildBeaconEditor()
    beaconFrame = CreateShell("BlackacreBeaconEditor", SHELL_W, 720, "quest")
    beaconFrame.title:SetText("Beacons")

    local scroll = CreateFrame("ScrollFrame", "BlackacreBeaconScroll", beaconFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", beaconFrame.header, "BOTTOMLEFT", 22, -14)
    scroll:SetPoint("BOTTOMRIGHT", -52, 44)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(SECTION_W, 400)
    scroll:SetScrollChild(child)
    beaconFrame.scroll = scroll
    beaconFrame.scrollChild = child

    local templates = Blackacre.SentenceTemplates.GetTemplates()
    local templateNames = {}
    for _, t in ipairs(templates) do
        templateNames[#templateNames + 1] = t.label
    end

    local status = MakeSection(child, "Status", SECTION_W, 112, false, true)
    status:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    beaconFrame.templateDropdown = CreateDropdown(status, "BABeaconTemplate", templateNames, BEACON_DD_WIDTHS[1])
    local tLab = status:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tLab:SetText("Status")

    beaconFrame.slotDropdowns = {}
    local slotNames = { "disposition", "role", "intent" }
    local row = {
        { dropdown = beaconFrame.templateDropdown, label = tLab, textWidth = BEACON_DD_WIDTHS[1] },
    }
    for i, slot in ipairs(slotNames) do
        local dd = CreateDropdown(status, "BABeacon" .. slot, Blackacre.SentenceTemplates.GetSlotOptions(slot), BEACON_DD_WIDTHS[i + 1])
        beaconFrame.slotDropdowns[slot] = dd
        local lab = status:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lab:SetText(slot:sub(1, 1):upper() .. slot:sub(2))
        row[#row + 1] = { dropdown = dd, label = lab, textWidth = BEACON_DD_WIDTHS[i + 1] }
    end
    PlaceDropdowns(status, row, -46)

    local loc = MakeSection(child, "Location", SECTION_W, 64, false, true)
    loc:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -8)
    local xLab = loc:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    xLab:SetPoint("LEFT", 16, -8)
    xLab:SetText("X")
    beaconFrame.gridX = CreateFrame("EditBox", nil, loc, "InputBoxTemplate")
    beaconFrame.gridX:SetSize(64, 20)
    beaconFrame.gridX:SetPoint("LEFT", xLab, "RIGHT", 8, 0)
    beaconFrame.gridX:SetAutoFocus(false)
    local yLab = loc:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    yLab:SetPoint("LEFT", beaconFrame.gridX, "RIGHT", 10, 0)
    yLab:SetText("Y")
    beaconFrame.gridY = CreateFrame("EditBox", nil, loc, "InputBoxTemplate")
    beaconFrame.gridY:SetSize(64, 20)
    beaconFrame.gridY:SetPoint("LEFT", yLab, "RIGHT", 8, 0)
    beaconFrame.gridY:SetAutoFocus(false)
    beaconFrame.locKind = "present"

    local present = CreateFrame("Button", nil, loc, "UIPanelButtonTemplate")
    present:SetSize(130, 22)
    present:SetPoint("LEFT", beaconFrame.gridY, "RIGHT", 12, 0)
    present:SetText("Present location")
    beaconFrame.presentBtn = present
    present:SetScript("OnClick", function()
        if beaconFrame.locKind == "roving" then return end
        beaconFrame._filling = true
        local gx, gy = PlayerGrid()
        beaconFrame.gridX:SetText(string.format("%.2f", gx))
        beaconFrame.gridY:SetText(string.format("%.2f", gy))
        beaconFrame.locKind = "present"
        beaconFrame._filling = false
    end)

    local roving = CreateFrame("Button", nil, loc, "UIPanelButtonTemplate")
    roving:SetSize(90, 22)
    roving:SetPoint("LEFT", present, "RIGHT", 8, 0)
    roving:SetText("Roving")
    beaconFrame.rovingBtn = roving

    local zoneText = loc:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    zoneText:SetPoint("LEFT", roving, "RIGHT", 12, 0)
    zoneText:SetJustifyH("LEFT")
    beaconFrame.locZoneText = zoneText

    local function SetRoving(on)
        if on then
            beaconFrame.locKind = "roving"
            roving:SetText("Roving •")
            present:Disable()
            present:SetAlpha(0.45)
            beaconFrame._filling = true
            beaconFrame.gridX:SetText("")
            beaconFrame.gridY:SetText("")
            beaconFrame._filling = false
            beaconFrame.gridX:Disable()
            beaconFrame.gridY:Disable()
            beaconFrame.gridX:SetAlpha(0.4)
            beaconFrame.gridY:SetAlpha(0.4)
        else
            beaconFrame.locKind = "grid"
            roving:SetText("Roving")
            present:Enable()
            present:SetAlpha(1)
            beaconFrame.gridX:Enable()
            beaconFrame.gridY:Enable()
            beaconFrame.gridX:SetAlpha(1)
            beaconFrame.gridY:SetAlpha(1)
        end
    end
    beaconFrame.SetRoving = SetRoving
    roving:SetScript("OnClick", function()
        SetRoving(beaconFrame.locKind ~= "roving")
    end)
    beaconFrame.gridX:SetScript("OnTextChanged", function()
        if not beaconFrame._filling and beaconFrame.locKind ~= "roving" then
            beaconFrame.locKind = "grid"
        end
    end)
    beaconFrame.gridY:SetScript("OnTextChanged", function()
        if not beaconFrame._filling and beaconFrame.locKind ~= "roving" then
            beaconFrame.locKind = "grid"
        end
    end)

    local crumbs = MakeSection(child, "Breadcrumbs", SECTION_W, 360, true, true)
    crumbs:SetPoint("TOPLEFT", loc, "BOTTOMLEFT", 0, -8)

    local function Crumb(label, instruction, yOff)
        local lab = crumbs:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lab:SetPoint("TOPLEFT", 16, yOff)
        lab:SetText(label)
        local inst = crumbs:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        inst:SetPoint("TOPLEFT", 90, yOff)
        inst:SetWidth(SECTION_W - 110)
        inst:SetJustifyH("LEFT")
        inst:SetText(instruction)
        local box = MacroBox(crumbs, SECTION_W - 32, 86, 250)
        box:SetPoint("TOPLEFT", 16, yOff - 16)
        return box
    end
    -- Crumbs are narration for the seeker, in third person: what they hear or
    -- see, never the emitter speaking ("Folk at the bar mention a hooded dwarf").
    beaconFrame.rumorBox = Crumb("Rumor", "Write a rumor in the third person about yourself that might reach across the region.", -28)
    beaconFrame.leadBox = Crumb("Lead", "Write another breadcrumb narrative for the seeker to receive when they reach the same subzone as you.", -132)
    beaconFrame.foundBox = Crumb("Near", "Set a scene in the third person to walk into once they get close enough to see you or when they target you.", -236)

    local preview = MakeSection(child, "Preview", SECTION_W, 220, true, true)
    preview:SetPoint("TOPLEFT", crumbs, "BOTTOMLEFT", 0, -8)
    beaconFrame.preview = preview

    -- Title banner: the Character Select "Top HUD" 3-piece bar (fixed end
    -- caps, stretched middle), with the section's gold title centered on it
    -- instead of MakeSection's default top-left placement.
    do
        local th = Blackacre.UI.Theme
        local function AtlasSize(atlas, fallbackW, fallbackH)
            local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
            if info and info.width and info.height then return info.width, info.height end
            return fallbackW, fallbackH
        end
        local lw, lh = AtlasSize("glues-characterSelect-TopHUD-left-BG", 32, 28)
        local rw, rh = AtlasSize("glues-characterSelect-TopHUD-right-BG", 32, 28)
        -- Scaled down 20% all around from the atlas's native crop.
        lw, lh, rw, rh = lw * 0.8, lh * 0.8, rw * 0.8, rh * 0.8
        local barH = math.max(lh, rh, 28 * 0.8)
        local NUDGE_Y = -5

        -- Half as wide as the section, centered.
        local barW = SECTION_W / 2
        local barX = (SECTION_W - barW) / 2

        preview.titleBarLeft = preview:CreateTexture(nil, "ARTWORK")
        preview.titleBarLeft:SetSize(lw, barH)
        preview.titleBarLeft:SetPoint("TOPLEFT", preview, "TOPLEFT", barX, NUDGE_Y)
        th.TrySetAtlas(preview.titleBarLeft, "glues-characterSelect-TopHUD-left-BG", false)

        preview.titleBarRight = preview:CreateTexture(nil, "ARTWORK")
        preview.titleBarRight:SetSize(rw, barH)
        preview.titleBarRight:SetPoint("TOPLEFT", preview, "TOPLEFT", barX + barW - rw, NUDGE_Y)
        th.TrySetAtlas(preview.titleBarRight, "glues-characterSelect-TopHUD-right-BG", false)

        preview.titleBarMid = preview:CreateTexture(nil, "ARTWORK")
        preview.titleBarMid:SetHeight(barH)
        preview.titleBarMid:SetPoint("TOPLEFT", preview.titleBarLeft, "TOPRIGHT", 0, 0)
        preview.titleBarMid:SetPoint("TOPRIGHT", preview.titleBarRight, "TOPLEFT", 0, 0)
        th.TrySetAtlas(preview.titleBarMid, "glues-characterSelect-TopHUD-middle-BG", false)

        preview.title:ClearAllPoints()
        preview.title:SetPoint("CENTER", preview, "TOP", 0, -barH / 2 + NUDGE_Y)
        preview.bannerH = barH - NUDGE_Y
    end

    -- Row 1: Beacon (left) | Location (right). Below: Rumor / Lead / Near.
    local COL_GAP = 14
    local colW = math.floor((SECTION_W - 32 - COL_GAP * 2) / 2)

    preview.beaconHead = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    preview.beaconHead:SetWidth(colW)
    preview.beaconHead:SetJustifyH("LEFT")
    preview.beaconHead:SetText("Beacon")
    preview.beaconBody = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    preview.beaconBody:SetWidth(colW)
    preview.beaconBody:SetJustifyH("LEFT")
    preview.beaconBody:SetJustifyV("TOP")

    preview.locHead = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    preview.locHead:SetWidth(colW)
    preview.locHead:SetJustifyH("LEFT")
    preview.locHead:SetText("Location")
    preview.locBody = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    preview.locBody:SetWidth(colW)
    preview.locBody:SetJustifyH("LEFT")
    preview.locBody:SetJustifyV("TOP")

    preview.rumorHead = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    preview.rumorHead:SetWidth(SECTION_W - 36)
    preview.rumorHead:SetJustifyH("LEFT")
    preview.rumorHead:SetText("Rumor")
    preview.rumorBody = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    preview.rumorBody:SetWidth(SECTION_W - 36)
    preview.rumorBody:SetJustifyH("LEFT")
    preview.rumorBody:SetJustifyV("TOP")

    preview.leadHead = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    preview.leadHead:SetWidth(SECTION_W - 36)
    preview.leadHead:SetJustifyH("LEFT")
    preview.leadHead:SetText("Lead")
    preview.leadBody = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    preview.leadBody:SetWidth(SECTION_W - 36)
    preview.leadBody:SetJustifyH("LEFT")
    preview.leadBody:SetJustifyV("TOP")

    preview.nearHead = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    preview.nearHead:SetWidth(SECTION_W - 36)
    preview.nearHead:SetJustifyH("LEFT")
    preview.nearHead:SetText("Near")
    preview.nearBody = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    preview.nearBody:SetWidth(SECTION_W - 36)
    preview.nearBody:SetJustifyH("LEFT")
    preview.nearBody:SetJustifyV("TOP")

    for _, fs in ipairs({ preview.beaconHead, preview.locHead, preview.rumorHead, preview.leadHead, preview.nearHead }) do
        if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.GoldTitle then
            Blackacre.UI.Theme.GoldTitle(fs)
        end
    end

    local footer = MakeFooter(beaconFrame)
    local save = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    save:SetSize(96, 24)
    save:SetPoint("RIGHT", 0, 0)
    save:SetText("Save")
    local load = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    load:SetSize(96, 24)
    load:SetPoint("RIGHT", save, "LEFT", -8, 0)
    load:SetText("Load")
    -- Update: push these crumbs to the beacon that's emitting right now.
    -- Greyed out when nothing is emitting.
    local update = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    update:SetSize(96, 24)
    update:SetPoint("RIGHT", load, "LEFT", -8, 0)
    update:SetText("Update")
    update:SetMotionScriptsWhileDisabled(true)
    update:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Update your beacon")
        if self:IsEnabled() then
            GameTooltip:AddLine("Send these crumbs to the beacon you're emitting now. Its time left doesn't change.", 1, 1, 1, true)
        else
            GameTooltip:AddLine("Nothing is emitting. Save a beacon and turn Emit on first.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    update:SetScript("OnLeave", GameTooltip_Hide)
    beaconFrame.updateBtn = update

    local function CurrentSlots(template)
        local slots = {}
        for _, slot in ipairs(template.slots) do
            if slot ~= "location" then
                local dd = beaconFrame.slotDropdowns[slot]
                if dd then slots[slot] = GetDropdownValue(dd) end
            end
        end
        return slots
    end

    local function BuildBeaconFromForm()
        local ti = UIDropDownMenu_GetSelectedID(beaconFrame.templateDropdown) or 1
        local template = templates[ti]
        local gx = tonumber(beaconFrame.gridX:GetText()) or 0
        local gy = tonumber(beaconFrame.gridY:GetText()) or 0
        local ctx = Blackacre.GetZoneContext()
        local locKind = beaconFrame.locKind or "grid"
        local coords
        if locKind == "roving" then
            coords = ctx.coords
        else
            coords = { x = gx / 100, y = gy / 100 }
        end
        return Blackacre.Lifecycle.CreateBeacon(template.id, CurrentSlots(template), {
            locKind = locKind,
            coords = coords,
            zoneId = ctx.zoneId,
            zoneName = ctx.zoneName,
            subzone = ctx.subzone,
            rumor = beaconFrame.rumorBox.edit:GetText() or "",
            lead = beaconFrame.leadBox.edit:GetText() or "",
            found = beaconFrame.foundBox.edit:GetText() or "",
        })
    end
    beaconFrame.BuildBeaconFromForm = BuildBeaconFromForm

    local function ShownText(text)
        if text and text ~= "" then return text end
        return "(none)"
    end

    -- Places a head/body pair at (x, y) with the given wrap width and
    -- returns the total height consumed (head + body + gap).
    local function LayBlock(head, body, text, x, y, w)
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", x, y)
        local headH = head:GetStringHeight()
        if headH < 1 then headH = 14 end
        local by = y - headH - 2
        body:ClearAllPoints()
        body:SetPoint("TOPLEFT", x, by)
        body:SetText(text)
        local bodyH = body:GetStringHeight()
        if bodyH < 1 then
            bodyH = 16 * math.max(1, math.ceil(#(text or "") / math.max(1, math.floor(w / 6))))
        end
        return headH + 2 + bodyH
    end

    local function RefreshBeaconPreview()
        local ti = UIDropDownMenu_GetSelectedID(beaconFrame.templateDropdown) or 1
        local template = templates[ti]
        if not template then return end
        local resolved = Blackacre.SentenceTemplates.Resolve(template.id, CurrentSlots(template), Blackacre.CharDB and Blackacre.CharDB.residence)
        local ctx = Blackacre.GetZoneContext()
        local gx, gy = tonumber(beaconFrame.gridX:GetText()) or 0, tonumber(beaconFrame.gridY:GetText()) or 0

        local zoneLine = (ctx.zoneName or "") .. (ctx.subzone and ctx.subzone ~= "" and (" " .. ctx.subzone) or "")
        beaconFrame.locZoneText:SetText(zoneLine)

        local locText
        if beaconFrame.locKind == "roving" then
            locText = "Roving with you through " .. ((ctx.subzone ~= "" and ctx.subzone) or ctx.zoneName or "this region")
        else
            -- Zone (no trailing comma), grid coordinates on the line below.
            locText = string.format("%s\n(%.2f, %.2f)", zoneLine, gx, gy)
        end

        local top = -(preview.bannerH + 12)
        local beaconH = LayBlock(preview.beaconHead, preview.beaconBody, (resolved and resolved.shortText) or "", 16, top, colW)
        local locH = LayBlock(preview.locHead, preview.locBody, locText, 16 + colW + COL_GAP * 2, top, colW)
        local rowH = math.max(beaconH, locH)

        local y = top - rowH - 10

        local rumorH = LayBlock(preview.rumorHead, preview.rumorBody, ShownText(beaconFrame.rumorBox.edit:GetText()), 16, y, SECTION_W - 36)
        y = y - rumorH - 10

        local leadH = LayBlock(preview.leadHead, preview.leadBody, ShownText(beaconFrame.leadBox.edit:GetText()), 16, y, SECTION_W - 36)
        y = y - leadH - 10

        local nearH = LayBlock(preview.nearHead, preview.nearBody, ShownText(beaconFrame.foundBox.edit:GetText()), 16, y, SECTION_W - 36)
        y = y - nearH

        preview:SetHeight(-y + 8)
        child:SetHeight(112 + 8 + 64 + 8 + 360 + 8 + preview:GetHeight() + 12)
        if scroll.UpdateScrollChildRect then
            scroll:UpdateScrollChildRect()
        end
    end
    beaconFrame.RefreshBeaconPreview = RefreshBeaconPreview
    beaconFrame.templateDropdown.onChanged = RefreshBeaconPreview
    for _, dd in pairs(beaconFrame.slotDropdowns) do
        dd.onChanged = RefreshBeaconPreview
    end
    local function WatchEdit(edit)
        edit:HookScript("OnTextChanged", function()
            if not beaconFrame._filling then RefreshBeaconPreview() end
        end)
    end
    WatchEdit(beaconFrame.rumorBox.edit)
    WatchEdit(beaconFrame.leadBox.edit)
    WatchEdit(beaconFrame.foundBox.edit)
    WatchEdit(beaconFrame.gridX)
    WatchEdit(beaconFrame.gridY)
    present:HookScript("OnClick", RefreshBeaconPreview)
    roving:HookScript("OnClick", RefreshBeaconPreview)
    RefreshBeaconPreview()

    save:SetScript("OnClick", function()
        StaticPopup_Show("BLACKACRE_BEACON_SAVE")
    end)
    update:SetScript("OnClick", function()
        local beacon = BuildBeaconFromForm()
        if not beacon then return end
        local function doUpdate()
            if Blackacre.Lifecycle.UpdateActiveBeacon(beacon) then
                Blackacre.Print("Beacon updated.")
                beaconFrame:Hide()
            end
        end
        if Blackacre.ProfanityFilter.ValidateCrumbs({ beacon.rumor, beacon.lead, beacon.found }, doUpdate) then
            doUpdate()
        end
    end)
    load:SetScript("OnClick", function()
        Blackacre.PostEditor.ShowLoadDialog()
    end)

    -- /ba skin labels (E = beacon Emitter editor; "B" is already Backstory Menu).
    local Tag = Blackacre.UI.Theme.RegisterSkinRegion
    Tag(beaconFrame, "E1", "S", 0, 220)
    Tag(beaconFrame.header, "E2", "F", -60, 0)
    Tag(beaconFrame.title, "E3", "F")
    Tag(beaconFrame.closeBtn, "E4", "F")
    Tag(status, "E5", "S", -80, 0)
    Tag(loc, "E6", "S", -60, 0)
    Tag(crumbs, "E7", "S", -80, -20)
    Tag(preview, "E8", "S", -80, -20)
    Tag(beaconFrame.rumorBox, "E9", "F")
    Tag(beaconFrame.leadBox, "E10", "F")
    Tag(beaconFrame.foundBox, "E11", "F")
    Tag(present, "E12", "F")
    Tag(roving, "E13", "F")
    Tag(footer, "E14", "F", -80, 0)
    Tag(save, "E15", "F")
    Tag(load, "E16", "F")
    Tag(update, "E17", "F")
end

StaticPopupDialogs["BLACKACRE_BEACON_SAVE"] = {
    text = "Name this beacon:",
    button1 = SAVE,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 32,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        local box = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
        if box then box:SetText("Beacon") box:HighlightText() end
    end,
    OnAccept = function(self)
        if not beaconFrame then return end
        local box = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
        local name = box and box:GetText() or "Beacon"
        local beacon = beaconFrame.BuildBeaconFromForm and beaconFrame.BuildBeaconFromForm()
        if not beacon then return end
        local function doSave()
            local p = Blackacre.Lifecycle.EnsurePresenceDB()
            local slot = 1
            for i = 1, 5 do
                if not (p.savedBeacons[i] and p.savedBeacons[i].beacon) then
                    slot = i
                    break
                end
                slot = i
            end
            Blackacre.Lifecycle.SaveNamedBeacon(slot, name, beacon)
            Blackacre.Print("Saved \"" .. name .. "\" in slot " .. slot .. ". Turn Emit on to send crumbs.")
            beaconFrame:Hide()
        end
        if Blackacre.ProfanityFilter.ValidateCrumbs({ beacon.rumor, beacon.lead, beacon.found }, doSave) then
            doSave()
        end
    end,
}

local function ApplyBeaconToForm(beacon)
    if not beacon or not beaconFrame then return end
    beaconFrame.rumorBox.edit:SetText(beacon.rumor or "")
    beaconFrame.leadBox.edit:SetText(beacon.lead or "")
    beaconFrame.foundBox.edit:SetText(beacon.found or "")
    if beacon.locKind == "roving" then
        beaconFrame.SetRoving(true)
    else
        beaconFrame.SetRoving(false)
        beaconFrame.locKind = beacon.locKind or "present"
        if beacon.coords then
            beaconFrame._filling = true
            beaconFrame.gridX:SetText(string.format("%.2f", (beacon.coords.x or 0) * 100))
            beaconFrame.gridY:SetText(string.format("%.2f", (beacon.coords.y or 0) * 100))
            beaconFrame._filling = false
        end
    end
    if beaconFrame.RefreshBeaconPreview then
        beaconFrame.RefreshBeaconPreview()
    end
end

function Blackacre.PostEditor.ShowLoadDialog()
    if not loadDialog then
        loadDialog = CreateFrame("Frame", "BlackacreBeaconLoad", UIParent, "BackdropTemplate")
        loadDialog:SetSize(320, 140)
        loadDialog:SetPoint("CENTER")
        loadDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        loadDialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        local t = loadDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOP", 0, -16)
        t:SetText("Load a saved beacon")
        loadDialog.drop = CreateDropdown(loadDialog, "BABeaconLoadDrop", { "1" }, 200)
        loadDialog.drop:SetPoint("TOP", 0, -40)
        local ok = CreateFrame("Button", nil, loadDialog, "UIPanelButtonTemplate")
        ok:SetSize(80, 22)
        ok:SetPoint("BOTTOMLEFT", 40, 16)
        ok:SetText("Load")
        ok:SetScript("OnClick", function()
            local _, id = GetDropdownValue(loadDialog.drop)
            local beacon, name = Blackacre.Lifecycle.LoadNamedBeacon(id or 1)
            if not beacon then
                Blackacre.Print("That slot is empty.")
                return
            end
            ApplyBeaconToForm(beacon)
            Blackacre.Print("Loaded " .. (name or "beacon") .. ".")
            loadDialog:Hide()
        end)
        local cancel = CreateFrame("Button", nil, loadDialog, "UIPanelButtonTemplate")
        cancel:SetSize(80, 22)
        cancel:SetPoint("BOTTOMRIGHT", -40, 16)
        cancel:SetText("Cancel")
        cancel:SetScript("OnClick", function() loadDialog:Hide() end)
        tinsert(UISpecialFrames, "BlackacreBeaconLoad")
    end
    local names = {}
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    for i = 1, 5 do
        local row = p.savedBeacons[i]
        names[i] = i .. ": " .. ((row and row.name) or "(empty)")
    end
    loadDialog.drop.items = names
    UIDropDownMenu_Initialize(loadDialog.drop, function(self)
        local selected = UIDropDownMenu_GetSelectedID(loadDialog.drop) or 1
        for i, item in ipairs(self.items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item
            info.checked = (i == selected)
            info.func = function()
                UIDropDownMenu_SetSelectedID(loadDialog.drop, i)
                UIDropDownMenu_SetText(loadDialog.drop, item)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedID(loadDialog.drop, 1)
    UIDropDownMenu_SetText(loadDialog.drop, names[1])
    loadDialog:Show()
end


local function SelectDropdown(dropdown, index)
    if dropdown.isScrollDropdown then
        dropdown.selectedIndex = index
        UIDropDownMenu_SetText(dropdown, dropdown.items[index] or "")
        return
    end
    UIDropDownMenu_SetSelectedID(dropdown, index)
    UIDropDownMenu_SetText(dropdown, dropdown.items[index])
end

local function IndexById(list, id, fallback)
    for i = 1, #list do
        if list[i].id == id then return i end
    end
    return fallback or 1
end

local PAPER_NAT_W, PAPER_NAT_H = 299, 407
local BULLETIN_DD_WIDTHS = { 130, 96, 108 }

-- Compose (left) and Parchment (right) are equal-size columns side by side,
-- mirroring each other, with a plain floating toolbar above them (no boxed
-- "Style" pane) — first-pass sizes, meant to be tuned once seen in-game.
local COLUMN_W, COLUMN_H, COL_GAP = 300, 380, 16
local TOOLBAR_H, GAP = 30, 10
local FOOTER_H, BOTTOM_PAD = 46, 20
local HEADER_TOP = 42
local FONT_DD_W = 120

local BULLETIN_SECTION_W = COLUMN_W * 2 + COL_GAP
local BULLETIN_SHELL_W = BULLETIN_SECTION_W + 88
local BULLETIN_H = HEADER_TOP + TOOLBAR_H + GAP + COLUMN_H + GAP + FOOTER_H + BOTTOM_PAD

-- Parchment's own frame is 3px narrower on each side than Compose's (height
-- unchanged), and the paper art inside it is trimmed another ~2px to match.
local PREVIEW_W, PREVIEW_H = COLUMN_W - 6, COLUMN_H
-- Small margin only (was 36): fill the preview box, not float inside it.
local paperScale = math.min((PREVIEW_W - 10) / PAPER_NAT_W, (PREVIEW_H - 10) / PAPER_NAT_H)
local PAPER_FIT_W = PAPER_NAT_W * paperScale
local PAPER_FIT_H = PAPER_NAT_H * paperScale

local function StationeryNativeSize(id)
    local spec = STATIONERY[1]
    for i = 1, #STATIONERY do
        if STATIONERY[i].id == id then spec = STATIONERY[i] break end
    end
    if spec.atlas and C_Texture and C_Texture.GetAtlasInfo then
        local info = C_Texture.GetAtlasInfo(spec.atlas)
        if info and info.width and info.height and info.width > 0 and info.height > 0 then
            return info.width, info.height
        end
    end
    return PAPER_NAT_W, PAPER_NAT_H
end

-- Shared with the inn board so a posting is read at exactly the size (and
-- paper fit) the author saw in this editor's parchment preview.
Blackacre.PostEditor.PREVIEW_W, Blackacre.PostEditor.PREVIEW_H = PREVIEW_W, PREVIEW_H
Blackacre.PostEditor.StationeryNativeSize = StationeryNativeSize

local function BuildBulletinEditor()
    bulletinFrame = CreateShell("BlackacreBulletinEditor", BULLETIN_SHELL_W, BULLETIN_H, "quest")
    bulletinFrame.title:SetText("Bulletin")

    local fontNames = {}
    for _, f in ipairs(FONTS) do fontNames[#fontNames + 1] = f.label end

    -- Floating toolbar (no boxed "Style" pane): the compose box's default
    -- font centered above Compose, Stationery + Wax seal centered above the
    -- parchment column.
    local toolbar = CreateFrame("Frame", nil, bulletinFrame)
    toolbar:SetSize(BULLETIN_SECTION_W, TOOLBAR_H)
    toolbar:SetPoint("TOP", 0, -HEADER_TOP)

    -- Compose (left column): the raw letter, written with inline style tags
    -- ({quest}/{questTitle}/{mail}/{chat}/{normal}/{highlight}/{black} — the
    -- same ids as FONTS — plus {b} for bold). The parchment beside it renders
    -- the parsed result live, using the exact same renderer the reading
    -- window uses, so what you see here is what a reader sees.
    local composeSec = MakeSection(bulletinFrame, "Compose", COLUMN_W, COLUMN_H, false, true)
    composeSec:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -GAP)

    -- Parchment (right column) — same size as Compose, side by side.
    local preview = MakeSection(bulletinFrame, "", PREVIEW_W, PREVIEW_H, true, true)
    preview:SetPoint("TOPLEFT", toolbar, "BOTTOMRIGHT", -COLUMN_W + 3, -GAP)
    preview.title:SetText("")

    -- Style (default font), centered above Compose.
    bulletinFrame.styleDrop = CreateDropdown(toolbar, "BABulletinStyle", fontNames, FONT_DD_W)
    bulletinFrame.styleDrop:SetPoint("CENTER", composeSec, "TOP", 0, GAP + TOOLBAR_H / 2)

    -- Stationery + Wax seal, centered as a pair above the parchment column.
    -- Stationery is a scrollable list (55 entries, alphabetized) instead of
    -- a plain Blizzard dropdown menu — that many items as one flat menu
    -- reads as an unstructured wall rather than something you can scan.
    local paperMenu = {}
    for _, spec in ipairs(STATIONERY) do paperMenu[#paperMenu + 1] = spec end
    table.sort(paperMenu, function(a, b) return a.label:lower() < b.label:lower() end)
    local paperNames = {}
    for _, spec in ipairs(paperMenu) do
        paperNames[#paperNames + 1] = spec.label:sub(1, 1):upper() .. spec.label:sub(2)
    end
    bulletinFrame.paperMenu = paperMenu
    bulletinFrame.paperDrop = CreateScrollDropdown(toolbar, "BABulletinPaper", paperNames, BULLETIN_DD_WIDTHS[2], 12)
    bulletinFrame.paperDrop:SetPoint("RIGHT", preview, "TOP", -5, GAP + TOOLBAR_H / 2)

    local sealNames = {}
    for _, s in ipairs(SEALS) do sealNames[#sealNames + 1] = s.label end
    bulletinFrame.sealDrop = CreateDropdown(toolbar, "BABulletinSeal", sealNames, BULLETIN_DD_WIDTHS[3])
    bulletinFrame.sealDrop:SetPoint("LEFT", preview, "TOP", 5, GAP + TOOLBAR_H / 2)

    local composeBox = MacroBox(composeSec, COLUMN_W - 32, COLUMN_H - 40, 500)
    composeBox:SetPoint("TOPLEFT", composeSec, "TOPLEFT", 16, -34)
    bulletinFrame.bodyBox = composeBox
    bulletinFrame.bodyEdit = composeBox.edit

    -- Cap at 17 lines: past that, revert to the last valid text (WoW's
    -- EditBox has no native line-count limit the way SetMaxLetters caps
    -- characters).
    do
        local edit = bulletinFrame.bodyEdit
        local lastText, lastCursor = edit:GetText() or "", 0
        edit:SetScript("OnTextChanged", function(self)
            local text = self:GetText() or ""
            local _, lines = text:gsub("\n", "")
            if lines + 1 > 17 then
                self:SetText(lastText)
                self:SetCursorPosition(lastCursor)
            else
                lastText = text
                lastCursor = self:GetCursorPosition()
            end
        end)
    end

    bulletinFrame.paper = preview:CreateTexture(nil, "ARTWORK")
    bulletinFrame.paper:SetSize(PAPER_FIT_W, PAPER_FIT_H)
    bulletinFrame.paper:SetPoint("CENTER", preview, "CENTER", 0, 0)
    Blackacre.PostEditor.PaintStationery(bulletinFrame.paper, "parchment")

    -- Read-only: renders the compose box's parsed BBCode (same renderer the
    -- reading window uses), so this is exactly what a reader will see.
    bulletinFrame.bodyHost = CreateFrame("Frame", nil, preview)
    bulletinFrame.bodyPool = {}

    bulletinFrame.seal = preview:CreateTexture(nil, "OVERLAY")
    bulletinFrame.seal:SetSize(56, 56)
    bulletinFrame.seal:Hide()

    local function FitPaper(natW, natH)
        local scale = math.min(PAPER_FIT_W / natW, PAPER_FIT_H / natH)
        local w, h = natW * scale, natH * scale
        local tex = bulletinFrame.paper
        tex:ClearAllPoints()
        tex:SetSize(w, h)
        tex:SetPoint("CENTER", preview, "CENTER", 0, 0)
        local insetX = math.floor(w * 0.1)
        local insetTop = math.floor(h * 0.11)
        local insetBot = math.floor(h * 0.09)

        bulletinFrame.bodyHost:ClearAllPoints()
        bulletinFrame.bodyHost:SetPoint("TOPLEFT", tex, "TOPLEFT", insetX, -insetTop)
        bulletinFrame.bodyHost:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", -insetX, insetBot)

        bulletinFrame.seal:ClearAllPoints()
        bulletinFrame.seal:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", -math.floor(w * 0.04), math.floor(h * 0.05))
    end

    local function RefreshPreview()
        local _, pi = GetDropdownValue(bulletinFrame.paperDrop)
        local paper = paperMenu[pi or 1]
        Blackacre.PostEditor.PaintStationery(bulletinFrame.paper, paper and paper.id)
        local natW, natH = StationeryNativeSize(paper and paper.id)
        FitPaper(natW, natH)
        local _, si = GetDropdownValue(bulletinFrame.sealDrop)
        local seal = SEALS[si or 1]
        Blackacre.PostEditor.PaintSeal(bulletinFrame.seal, seal and seal.id)

        local _, sti = GetDropdownValue(bulletinFrame.styleDrop)
        local defaultFont = FONTS[sti or 1]
        Blackacre.PostEditor.RenderBBCode(bulletinFrame.bodyHost, bulletinFrame.bodyPool,
            bulletinFrame.bodyEdit:GetText() or "", defaultFont and defaultFont.id or "quest")
    end
    bulletinFrame.paperDrop.onChanged = RefreshPreview
    bulletinFrame.sealDrop.onChanged = RefreshPreview
    bulletinFrame.styleDrop.onChanged = RefreshPreview
    bulletinFrame.bodyEdit:HookScript("OnTextChanged", RefreshPreview)
    bulletinFrame.RefreshPreview = RefreshPreview

    local footer = MakeFooter(bulletinFrame)

    -- Duration, and Only this inn / Spread the word, now happen at the
    -- innkeeper's own gossip window when you post — like asking a
    -- storeowner's permission to hang a flyer for so many days — not
    -- pre-picked here.
    local save = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    save:SetSize(100, 24)
    save:SetPoint("RIGHT", 0, 0)
    save:SetText("Save draft")

    local draftsBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    draftsBtn:SetSize(100, 24)
    draftsBtn:SetPoint("RIGHT", save, "LEFT", -8, 0)
    draftsBtn:SetText("My drafts")
    draftsBtn:SetScript("OnClick", function()
        if Blackacre.MyPostings then Blackacre.MyPostings.Toggle() end
    end)

    -- Yellow Pages: an index of innkeepers you've met, to search where you
    -- can post (notices are posted in person, at the gossip window itself).
    local ypBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    ypBtn:SetSize(BULLETIN_DD_WIDTHS[1], 24)
    ypBtn:SetText("Yellow Pages")
    ypBtn:SetPoint("RIGHT", draftsBtn, "LEFT", -8, 0)
    ypBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Yellow Pages")
        GameTooltip:AddLine("This is a list of innkeepers, along with their locations, you have interacted with previously that will allow you to post bulletins.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    ypBtn:SetScript("OnLeave", GameTooltip_Hide)
    ypBtn:SetScript("OnClick", function()
        if Blackacre.YellowPages then Blackacre.YellowPages.Toggle() end
    end)

    save:SetScript("OnClick", function()
        local bodyText = bulletinFrame.bodyEdit:GetText() or ""
        if bodyText == "" then
            Blackacre.Print("Write a notice first.")
            return
        end
        StaticPopup_Show("BLACKACRE_BULLETIN_DRAFT_NAME")
    end)

    local function SaveDraftAs(draftName)
        local bodyText = bulletinFrame.bodyEdit:GetText() or ""
        local titleText = Blackacre.PostEditor.DeriveTitle(bodyText)
        local _, pi = GetDropdownValue(bulletinFrame.paperDrop)
        local _, si = GetDropdownValue(bulletinFrame.sealDrop)
        local _, sti = GetDropdownValue(bulletinFrame.styleDrop)
        local paper = paperMenu[pi or 1]
        local seal = SEALS[si or 1]
        local font = FONTS[sti or 1]
        local function doSave()
            -- Into My drafts right away; any innkeeper's Post Notice lists it.
            Blackacre.Lifecycle.SaveNamedBulletin({
                draftName = draftName,
                title = titleText,
                bodyText = bodyText,
                stationary = paper and paper.id or "parchment",
                waxSeal = seal and seal.id ~= "none" and seal.id or nil,
                font = font and font.id or "quest",
            })
            if Blackacre.InnBoard and Blackacre.InnBoard.RefreshPostButton then
                Blackacre.InnBoard.RefreshPostButton()
            end
            if Blackacre.MyPostings and Blackacre.MyPostings.Refresh then
                Blackacre.MyPostings.Refresh()
            end
            Blackacre.Print("Saved to My drafts. Post it at any innkeeper: Post Notice.")
            bulletinFrame:Hide()
        end
        -- Content checks run when drafting, so posting at the inn is one click.
        if Blackacre.ProfanityFilter and Blackacre.ProfanityFilter.ValidateBulletin then
            if Blackacre.ProfanityFilter.ValidateBulletin(titleText, bodyText, doSave) then
                doSave()
            end
        else
            doSave()
        end
    end
    bulletinFrame.SaveDraftAs = SaveDraftAs

    -- /ba skin labels (N = Notice/bulletin editor).
    local Tag = Blackacre.UI.Theme.RegisterSkinRegion
    Tag(bulletinFrame, "N1", "S", 0, 220)
    Tag(bulletinFrame.title, "N2", "F")
    Tag(bulletinFrame.closeBtn, "N3", "F")
    Tag(draftsBtn, "N4", "F")
    Tag(composeSec, "N5", "S", -60, 0)
    Tag(toolbar, "N6", "F")
    Tag(preview, "N7", "S", -40, 0)
    Tag(bulletinFrame.bodyEdit, "N8", "F")
    Tag(ypBtn, "N9", "F")
    Tag(footer, "N10", "F", -80, 0)
    Tag(save, "N11", "F")
    Tag(bulletinFrame.styleDrop, "N12", "F")
end

StaticPopupDialogs["BLACKACRE_BULLETIN_DRAFT_NAME"] = {
    text = "Name this draft:",
    button1 = SAVE,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 50, -- owner rule: draft names stop at 50 characters
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        local box = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
        if box then
            box:SetText((bulletinFrame and bulletinFrame.lastDraftName) or "Notice")
            box:HighlightText()
        end
    end,
    OnAccept = function(self)
        local box = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
        local name = strtrim(box and box:GetText() or "")
        if name == "" then name = "Notice" end
        if bulletinFrame then
            bulletinFrame.lastDraftName = name
            if bulletinFrame.SaveDraftAs then bulletinFrame.SaveDraftAs(name) end
        end
    end,
}

-- Put a saved draft back into the editor so it can be revised.
local function ApplyDraftToForm(draft)
    if not draft or not bulletinFrame then return end
    bulletinFrame.lastDraftName = draft.draftName
    bulletinFrame.bodyEdit:SetText(draft.bodyText or "")
    SelectDropdown(bulletinFrame.paperDrop, IndexById(bulletinFrame.paperMenu or {}, draft.stationary or "parchment"))
    SelectDropdown(bulletinFrame.sealDrop, IndexById(SEALS, draft.waxSeal or "none"))
    SelectDropdown(bulletinFrame.styleDrop, IndexById(FONTS, draft.font or "quest"))
    if bulletinFrame.RefreshPreview then bulletinFrame.RefreshPreview() end
end

function Blackacre.PostEditor.Init()
    BuildBeaconEditor()
    BuildBulletinEditor()
end

-- Update is live only while a beacon is emitting.
function Blackacre.PostEditor.RefreshBeaconButtons()
    if not beaconFrame or not beaconFrame.updateBtn then return end
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    local live = p.emitEnabled and Blackacre.Lifecycle.GetActiveOwnedBeacon()
    beaconFrame.updateBtn:SetEnabled(live and true or false)
end

function Blackacre.PostEditor.ShowBeaconEditor()
    if not beaconFrame then BuildBeaconEditor() end
    if beaconFrame.locKind ~= "roving" then
        local gx, gy = PlayerGrid()
        if (beaconFrame.gridX:GetText() or "") == "" then
            beaconFrame._filling = true
            beaconFrame.gridX:SetText(string.format("%.2f", gx))
            beaconFrame.gridY:SetText(string.format("%.2f", gy))
            beaconFrame._filling = false
            beaconFrame.locKind = "present"
        end
    end
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    if p.draftBeacon then
        ApplyBeaconToForm(p.draftBeacon)
    end
    beaconFrame:Show()
    if beaconFrame.RefreshBeaconPreview then
        beaconFrame.RefreshBeaconPreview()
    end
    Blackacre.PostEditor.RefreshBeaconButtons()
end

-- Opens on your newest saved draft.
function Blackacre.PostEditor.ShowBulletinEditor()
    if not bulletinFrame then BuildBulletinEditor() end
    ApplyDraftToForm(Blackacre.Lifecycle.GetSavedBulletins()[1])
    if bulletinFrame.RefreshPreview then bulletinFrame.RefreshPreview() end
    bulletinFrame:Show()
end

-- Open one saved draft for revising (My drafts: click a draft).
function Blackacre.PostEditor.EditDraft(draft)
    if not bulletinFrame then BuildBulletinEditor() end
    ApplyDraftToForm(draft)
    if bulletinFrame.RefreshPreview then bulletinFrame.RefreshPreview() end
    bulletinFrame:Show()
end

Blackacre.PostEditor.STATIONERY = STATIONERY
Blackacre.PostEditor.SEALS = SEALS
Blackacre.PostEditor.FONTS = FONTS
