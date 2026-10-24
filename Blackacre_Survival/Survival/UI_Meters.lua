-- In Character Forever: Survival - Meters

Blackacre = Blackacre or {}
Blackacre.Survival = Blackacre.Survival or {}
Blackacre.Survival.UI = {}

local panel
local icons = {}
local collapsed = false
local prepared = false -- food or water on hand: show the Prepared icon
local spirit = false -- dead or a ghost: show Spirit Form, hide Prepared

-- Same as Blizzard's own buff/debuff buttons (BuffFrame): 30px icon, and the
-- collapse arrow is a 15x30 button holding a 10x16 bag-arrow.
local ICON_SIZE = 30
local ICON_INSET = 2 -- the icon sits inside the round-cornered outline, not under it
local ARROW_SIZE = 15
local ARROW_H = 30
local ARROW_ART_W, ARROW_ART_H = 10, 16
-- Spirit Form wears a disease debuff's border: Blizzard's own atlas
-- (AuraUtil.lua), drawn 40px around the 30px icon as in BuffFrameTemplates.xml.
local DISEASE_BORDER = "ui-debuff-border-disease-noicon"
local DEBUFF_BORDER_SIZE = 40
local SPIRIT_ICON = { "Spell_Holy_GuardianSpirit" }

local ICONS = {
    hunger = {
        high = { "inv_tradeskill_cooking_feastofblood", "INV_Misc_Food_15" },
        mid = { "inv_misc_food_95_grainbread", "INV_Misc_Food_95_Grainbread", "INV_Misc_Food_15" },
        low = { "spell_holy_painsupression", "Spell_Holy_PainSupression", "Spell_Holy_PainSuppression", "Spell_Shadow_ShadowWordPain" },
    },
    thirst = {
        high = { "inv_drink_waterskin_01", "INV_Drink_Waterskin_01" },
        mid = { "inv_drink_waterskin_05", "INV_Drink_Waterskin_05", "INV_Drink_Waterskin_01" },
        low = { "inv_drink_waterskin_10", "INV_Drink_Waterskin_10", "INV_Drink_Waterskin_01" },
    },
    exposure = {
        high = { "ui_embercourt-emoji-happy", "Spell_Nature_DryadDispelMagic" },
        mid = { "ui_embercourt-emoji-miserable", "Spell_Frost_FrostShock" },
        low = { "ui_embercourt-emoji-uncomfortable", "Spell_Frost_IceStorm" },
    },
}

-- Why exposure is moving the way it is (Engine.ExposureMode). Open air: no line.
local EXPOSURE_TIP = {
    camp = { "At camp: recovering quickly", 0.4, 0.9, 0.4 },
    cozy = { "By the fire: recovering", 0.4, 0.9, 0.4 },
    rested = { "Resting: recovering", 0.4, 0.9, 0.4 },
    sheltered = { "Sheltered: holding steady", 0.8, 0.8, 0.8 },
    wet = { "Soaked: draining twice as fast", 0.45, 0.7, 1 },
}

local ARROW_ATLASES = {
    "bag-arrow",
    "Bag-arrow",
    "bags-arrow",
    "BagSlots2x-bag-arrow",
    "bagslots2x-bag-arrow",
}

local function HasAtlas(name)
    return name and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end

local function ApplyNamedIcon(tex, names)
    if not tex or not names then return end
    if type(names) == "string" then names = { names } end
    for i = 1, #names do
        local n = names[i]
        if HasAtlas(n) then
            tex:SetAtlas(n, false)
            return
        end
    end
    tex:SetTexture("Interface\\Icons\\" .. names[1])
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

local function BandFor(v)
    v = math.floor((v or 0) + 0.5)
    if v <= 10 then return "low" end
    if v <= 50 then return "mid" end
    return "high"
end

local function DebuffBorder(tex)
    if not tex then return end
    tex:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
    tex:Show()
end

local function FaceArrow(expanded)
    if not panel or not panel.arrowTex then return end
    local tex = panel.arrowTex
    -- Native bag-arrow faces left. Flip when expanded so it points right.
    if expanded then
        tex:SetTexCoord(1, 0, 0, 1)
    else
        tex:SetTexCoord(0, 1, 0, 1)
    end
end

-- The arrow art is looked up once; afterwards only its facing changes.
local arrowAtlas -- atlas name, or false for the NextPage texture fallback

local function PaintArrow()
    if not panel or not panel.arrowTex then return end
    local tex = panel.arrowTex
    if arrowAtlas == nil then
        arrowAtlas = false
        for i = 1, #ARROW_ATLASES do
            if HasAtlas(ARROW_ATLASES[i]) then
                arrowAtlas = ARROW_ATLASES[i]
                tex:SetAtlas(arrowAtlas, false)
                break
            end
        end
        if not arrowAtlas then
            tex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        end
    end
    if arrowAtlas then
        FaceArrow(not collapsed)
    elseif collapsed then
        -- NextPage points right; flip when collapsed so it points left.
        tex:SetTexCoord(1, 0, 0, 1)
    else
        tex:SetTexCoord(0, 1, 0, 1)
    end
end

local function Layout()
    if not panel then return end
    local gap = 4
    if collapsed then
        for _, b in pairs(icons) do b:Hide() end
        panel:SetSize(ARROW_SIZE + 4, ARROW_H)
        panel.arrow:ClearAllPoints()
        panel.arrow:SetPoint("CENTER", panel, "CENTER", 0, 0)
    else
        -- A spirit has no use for provisions, so Spirit Form takes Prepared's place.
        local prep = prepared and not spirit
        icons.prepared:SetShown(prep)
        icons.spirit:SetShown(spirit)
        local count = (prep or spirit) and 4 or 3
        local rowW = count * ICON_SIZE + (count - 1) * gap
        panel:SetSize(rowW + gap + ARROW_SIZE, ARROW_H)
        icons.hunger:Show()
        icons.thirst:Show()
        icons.exposure:Show()
        icons.hunger:ClearAllPoints()
        icons.thirst:ClearAllPoints()
        icons.exposure:ClearAllPoints()
        icons.hunger:SetPoint("LEFT", panel, "LEFT", 0, 0)
        icons.thirst:SetPoint("LEFT", icons.hunger, "RIGHT", gap, 0)
        icons.exposure:SetPoint("LEFT", icons.thirst, "RIGHT", gap, 0)
        local anchor = icons.exposure
        local extra = (prep and icons.prepared) or (spirit and icons.spirit)
        if extra then
            extra:ClearAllPoints()
            extra:SetPoint("LEFT", icons.exposure, "RIGHT", gap, 0)
            anchor = extra
        end
        panel.arrow:ClearAllPoints()
        panel.arrow:SetPoint("LEFT", anchor, "RIGHT", gap, 0)
    end
    PaintArrow()
end

-- Action-bar icon outline drawn over the icon's edge.
local function AddIconFrame(btn)
    local tex = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    tex:SetAllPoints(btn)
    if HasAtlas("UI-HUD-ActionBar-IconFrame") then
        tex:SetAtlas("UI-HUD-ActionBar-IconFrame", false)
    else
        tex:Hide()
    end
    btn.iconFrame = tex
end

local function MakeAura(parent, key, label)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(ICON_SIZE, ICON_SIZE)
    btn.key = key
    btn.label = label

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
    btn.icon:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
    ApplyNamedIcon(btn.icon, ICONS[key].high)

    AddIconFrame(btn)

    -- Low-meter red border, same size as the icon frame.
    btn.border = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    btn.border:SetAllPoints(btn)
    btn.border:Hide()

    btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    btn.count:SetPoint("BOTTOMRIGHT", 1, 0)

    function btn:SetMeter(v)
        v = math.max(0, math.min(100, v or 0))
        local stacks = math.floor(v + 0.5)
        if self._stacks == stacks then return end
        local band = BandFor(stacks)
        local bandChanged = self._band ~= band
        self._stacks = stacks
        self._band = band
        self.count:SetText(tostring(stacks))
        if bandChanged then
            ApplyNamedIcon(self.icon, ICONS[self.key][band])
            self.icon:SetVertexColor(1, 1, 1)
        end
        if stacks <= 10 then
            if not self._debuff then
                DebuffBorder(self.border)
                self._debuff = true
            end
        elseif self._debuff then
            self.border:Hide()
            self._debuff = false
        end
    end

    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function()
        if panel then panel:StartMoving() end
    end)
    btn:SetScript("OnDragStop", function()
        if panel then panel:StopMovingOrSizing() end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(label)
        local state = Blackacre.Survival.GetState and Blackacre.Survival.GetState()
        if state then
            local n = math.floor((state[key] or 0) + 0.5)
            GameTooltip:AddLine(n .. " stacks", 0.9, 0.9, 0.9)
            if state.spiritForm then
                -- Paused: no climate, no shelter, nothing moves.
                GameTooltip:AddLine("You are in spirit form", 0.85, 0.75, 0.45)
            else
                if state.climate and state.climate.title then
                    GameTooltip:AddLine(state.climate.title .. " climate", 0.85, 0.75, 0.45)
                end
                local why = key == "exposure" and EXPOSURE_TIP[Blackacre.Survival.Engine.ExposureMode()]
                if why then GameTooltip:AddLine(why[1], why[2], why[3], why[4]) end
                if key == "hunger" and state.wellFed then
                    GameTooltip:AddLine("Well Fed: hunger holds steady", 0.4, 0.9, 0.4)
                elseif key == "thirst" and state.drinking then
                    GameTooltip:AddLine("Drinking: recovering", 0.4, 0.9, 0.4)
                end
            end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    return btn
end

-- A status icon beside the meters (Prepared, Spirit Form): no stacks, just a
-- title and one line of text. Hidden until Layout shows it.
local function MakeBadge(parent, iconNames, title, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(ICON_SIZE, ICON_SIZE)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", ICON_INSET, -ICON_INSET)
    btn.icon:SetPoint("BOTTOMRIGHT", -ICON_INSET, ICON_INSET)
    ApplyNamedIcon(btn.icon, iconNames)
    AddIconFrame(btn)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function()
        if panel then panel:StartMoving() end
    end)
    btn:SetScript("OnDragStop", function()
        if panel then panel:StopMovingOrSizing() end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(title)
        GameTooltip:AddLine(text, 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    btn:Hide()
    return btn
end

local function Build()
    panel = CreateFrame("Frame", "BlackacreSurvivalMeters", UIParent)
    panel:SetSize(3 * ICON_SIZE + 2 * 4 + 4 + ARROW_SIZE, ARROW_H)
    panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -40, -180)
    panel:SetFrameStrata("MEDIUM")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetClampedToScreen(true)

    panel.arrow = CreateFrame("Button", nil, panel)
    panel.arrow:SetSize(ARROW_SIZE, ARROW_H)
    panel.arrowTex = panel.arrow:CreateTexture(nil, "ARTWORK")
    panel.arrowTex:SetSize(ARROW_ART_W, ARROW_ART_H)
    panel.arrowTex:SetPoint("CENTER")
    panel.arrow:RegisterForDrag("LeftButton")
    panel.arrow:SetScript("OnDragStart", function()
        panel:StartMoving()
    end)
    panel.arrow:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
    end)
    panel.arrow:SetScript("OnClick", function()
        collapsed = not collapsed
        Layout()
    end)
    panel.arrow:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(collapsed and "Expand" or "Collapse")
        GameTooltip:Show()
    end)
    panel.arrow:SetScript("OnLeave", GameTooltip_Hide)

    icons.hunger = MakeAura(panel, "hunger", "Hunger")
    icons.thirst = MakeAura(panel, "thirst", "Thirst")
    icons.exposure = MakeAura(panel, "exposure", "Exposure")

    icons.prepared = MakeBadge(panel, { "inv_misc_food_15", "INV_Misc_Food_15" },
        "Prepared", "Your preparation keeps you sated.")
    -- Prepared says how much the provisions on hand slow each meter.
    icons.prepared:SetScript("OnEnter", function(self)
        local engine = Blackacre.Survival.Engine
        local food, water, fTier, wTier = engine.ScanProvisions()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Prepared")
        if food then
            GameTooltip:AddLine("Food on hand: hunger drains " .. engine.TierSlowPct(fTier) .. "% slower", 0.9, 0.9, 0.9, true)
        end
        if water then
            GameTooltip:AddLine("Water on hand: thirst drains " .. engine.TierSlowPct(wTier) .. "% slower", 0.9, 0.9, 0.9, true)
        end
        GameTooltip:Show()
    end)

    local ghost = MakeBadge(panel, SPIRIT_ICON, "Spirit Form",
        "You are currently traveling in spirit form. Hunger, thirst and exposure are paused,"
        .. " and you will return to your body hungry and thirsty.")
    if HasAtlas(DISEASE_BORDER) then
        ghost.border = ghost:CreateTexture(nil, "OVERLAY", nil, 2)
        ghost.border:SetSize(DEBUFF_BORDER_SIZE, DEBUFF_BORDER_SIZE)
        ghost.border:SetPoint("CENTER")
        ghost.border:SetAtlas(DISEASE_BORDER, false)
    end
    icons.spirit = ghost
    Layout()
end

function Blackacre.Survival.UI.Init()
    Build()
    Blackacre.Survival.UI.Refresh()
end

-- Runs on every survival tick and zone change: re-anchor the row only when
-- the Prepared or Spirit Form icon appears or goes, and allocate nothing.
function Blackacre.Survival.UI.Refresh()
    if not panel then return end
    local s = Blackacre.CharDB and Blackacre.CharDB.survival
    if not s or s.enabled == false or s.hideMeters then
        panel:Hide()
        return
    end
    panel:Show()
    local hasFood, hasWater = Blackacre.Survival.Engine.ScanProvisions()
    local prep = (hasFood or hasWater) and true or false
    local ghost = s.spiritForm == true
    if prep ~= prepared or ghost ~= spirit then
        prepared, spirit = prep, ghost
        Layout()
    end
    icons.hunger:SetMeter(s.hunger)
    icons.thirst:SetMeter(s.thirst)
    icons.exposure:SetMeter(s.exposure)
end

--- One meter icon ("hunger", "thirst", "exposure", "prepared", "spirit"), for the tour to spotlight.
function Blackacre.Survival.UI.GetIcon(key)
    return icons[key]
end

function Blackacre.Survival.UI.Toggle()
    if not panel then Build() end
    local s = Blackacre.CharDB.survival
    if panel:IsShown() then
        s.hideMeters = true
        panel:Hide()
    else
        s.hideMeters = false
        Blackacre.Survival.UI.Refresh()
        panel:Show()
    end
end

function Blackacre.Survival.UI.ShowPanel()
    if not panel then Build() end
    Blackacre.CharDB.survival.hideMeters = false
    Blackacre.Survival.UI.Refresh()
    panel:Show()
end
