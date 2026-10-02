-- In Character Forever - Tool Box

Blackacre = Blackacre or {}
Blackacre.ToolBox = {}

local frame
local buttons = {}

local SLOTS = {
    { id = "journal", label = "Journal", icon = { "inv_misc_book_07", "INV_Misc_Book_07" } },
    { id = "beacon", label = "Beacon", icon = { "ability_hunter_huntervswild", "Ability_Hunter_HunterVsWild" } },
    { id = "bulletin", label = "Bulletin", icon = { "inv_misc_groupneedmore", "INV_Misc_GroupNeedMore" } },
    { id = "emit", label = "Emit", toggle = true,
        iconOff = { "spell_animamaw_buff", "Spell_AnimaMaw_Buff", "spell_animamaw_orb" },
        iconOn = { "spell_animabastion_buff", "Spell_AnimaBastion_Buff", "spell_animabastion_orb" },
    },
    { id = "seeking", label = "Seeking", toggle = true,
        iconOff = { "spell_magic_lesserinvisibilty", "Spell_Magic_LesserInvisibilty" },
        iconOn = { "spell_holy_senseundead", "Spell_Holy_SenseUndead" },
    },
    -- Trails: the seeker's pane. Icon confirmed in the Forever export (Ability_Tracking.blp).
    { id = "trails", label = "Trails", icon = { "ability_tracking", "Ability_Tracking" } },
    { id = "survival", label = "Survival", icon = { "ability_creature_cursed_02", "Ability_Creature_Cursed_02" }, toggle = true },
}

local SIZE = 42
local GAP = 3
local COLS = #SLOTS -- one single row
local ROWS = 1
local INNER_PAD = 5   -- space between the buttons and the shell's edge

local function HasAtlas(name)
    return name and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end

local function SpellTexture(spellID)
    if not spellID then return nil end
    return C_Spell.GetSpellTexture(spellID)
end

local function PaintIcon(tex, names, spellID)
    if not tex then return end
    tex:SetTexCoord(0, 1, 0, 1)
    if tex.SetAtlas then
        pcall(function() tex:SetAtlas(nil) end)
    end
    tex:SetTexture(nil)
    if type(names) == "string" then names = { names } end
    names = names or {}
    for i = 1, #names do
        local n = names[i]
        if HasAtlas(n) then
            tex:SetAtlas(n, false)
            return
        end
    end
    local file = SpellTexture(spellID)
    if file then
        tex:SetTexture(file)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        return
    end
    if names[1] then
        tex:SetTexture("Interface\\Icons\\" .. names[1])
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
end

local function PlayClick()
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.PlayUISound then
        Blackacre.UI.Theme.PlayUISound("toolClick")
    end
end

local function EmitOn()
    local p = Blackacre.Lifecycle and Blackacre.Lifecycle.EnsurePresenceDB and Blackacre.Lifecycle.EnsurePresenceDB()
    if not p then return false end
    return p.emitEnabled and true or false
end

local function SeekingOn()
    local p = Blackacre.Lifecycle and Blackacre.Lifecycle.EnsurePresenceDB and Blackacre.Lifecycle.EnsurePresenceDB()
    if not p then return true end
    if p.seekingEnabled == false then return false end
    return true
end

local function SurvivalOn()
    local s = Blackacre.CharDB and Blackacre.CharDB.survival
    if s and s.enabled == false then return false end
    return true
end

local function SetPushed(btn, down)
    if btn.pushed then
        btn.pushed:SetShown(down and true or false)
    end
    if btn.icon then
        if down then
            btn.icon:SetPoint("CENTER", 1, -1)
        else
            btn.icon:SetPoint("CENTER", 0, 0)
        end
    end
end

local function PaintToggle(btn)
    if not btn.toggle then return end
    local on
    if btn.id == "emit" then
        on = EmitOn()
    elseif btn.id == "seeking" then
        on = SeekingOn()
    else
        on = SurvivalOn()
    end
    btn.isOn = on and true or false
    if btn.id == "emit" or btn.id == "seeking" then
        PaintIcon(btn.icon, on and btn.iconOn or btn.iconOff)
        btn.icon:SetDesaturated(false)
        btn.icon:SetVertexColor(1, 1, 1)
    elseif btn.icon then
        btn.icon:SetDesaturated(not on)
        btn.icon:SetVertexColor(on and 1 or 0.55, on and 1 or 0.55, on and 1 or 0.55)
    end
end

local function Run(id)
    if id == "journal" then
        if Blackacre.TomeHub and Blackacre.TomeHub.Toggle then
            Blackacre.TomeHub.Toggle()
        end
    elseif id == "trails" then
        if Blackacre.Trails and Blackacre.Trails.Toggle then
            Blackacre.Trails.Toggle()
        elseif Blackacre.Print then
            Blackacre.Print("Trails need the Presence package.")
        end
    elseif id == "beacon" then
        if Blackacre.PostEditor and Blackacre.PostEditor.ShowBeaconEditor then
            Blackacre.PostEditor.ShowBeaconEditor()
        elseif Blackacre.Print then
            Blackacre.Print("Beacons need the Presence package.")
        end
    elseif id == "bulletin" then
        if Blackacre.PostEditor and Blackacre.PostEditor.ShowBulletinEditor then
            Blackacre.PostEditor.ShowBulletinEditor()
        elseif Blackacre.Print then
            Blackacre.Print("Bulletins need the Presence package.")
        end
    elseif id == "emit" then
        local on = not EmitOn()
        local ok = true
        if Blackacre.Lifecycle and Blackacre.Lifecycle.SetEmitEnabled then
            ok = Blackacre.Lifecycle.SetEmitEnabled(on)
        end
        if ok ~= false and Blackacre.Print then
            Blackacre.Print(on and "Emit on" or "Emit Off")
        end
        if Blackacre.PostEditor and Blackacre.PostEditor.RefreshBeaconButtons then
            Blackacre.PostEditor.RefreshBeaconButtons() -- Update button follows Emit
        end
    elseif id == "seeking" then
        local on = not SeekingOn()
        if Blackacre.Lifecycle and Blackacre.Lifecycle.SetSeekingEnabled then
            Blackacre.Lifecycle.SetSeekingEnabled(on)
        else
            local p = Blackacre.Lifecycle and Blackacre.Lifecycle.EnsurePresenceDB and Blackacre.Lifecycle.EnsurePresenceDB()
            if p then p.seekingEnabled = on end
        end
        if Blackacre.Print then
            Blackacre.Print(on and "Seeking on" or "Seeking Off")
        end
    elseif id == "survival" then
        local on = not SurvivalOn()
        if Blackacre.Survival and Blackacre.Survival.Engine and Blackacre.Survival.Engine.SetEnabled then
            Blackacre.Survival.Engine.SetEnabled(on)
        else
            Blackacre.CharDB = Blackacre.CharDB or {}
            Blackacre.CharDB.survival = Blackacre.CharDB.survival or {}
            Blackacre.CharDB.survival.enabled = on
        end
        if Blackacre.Survival and Blackacre.Survival.UI and Blackacre.Survival.UI.Refresh then
            Blackacre.Survival.UI.Refresh()
        end
    end
    PlayClick()
    for _, b in ipairs(buttons) do
        PaintToggle(b)
    end
end

local function MakeSlot(parent, spec, col, row, originX, originY)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(SIZE, SIZE)
    local x = originX + (col - 1) * (SIZE + GAP)
    local y = originY - (row - 1) * (SIZE + GAP)
    btn:SetPoint("TOPLEFT", x, y)
    btn.id = spec.id
    btn.toggle = spec.toggle
    btn.baseLabel = spec.label
    btn.iconOn = spec.iconOn
    btn.iconOff = spec.iconOff
    btn.spellID = spec.spellID

    btn.slot = btn:CreateTexture(nil, "BACKGROUND")
    btn.slot:SetAllPoints()
    btn.slot:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    btn.slot:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn.icon = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    btn.icon:SetSize(34, 34)
    btn.icon:SetPoint("CENTER", 0, 0)
    PaintIcon(btn.icon, spec.icon or spec.iconOff, spec.spellID)

    -- Action-bar icon outline over the icon's edge.
    btn.frame = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    btn.frame:SetAllPoints()
    if HasAtlas("UI-HUD-ActionBar-IconFrame") then
        btn.frame:SetAtlas("UI-HUD-ActionBar-IconFrame", false)
    else
        btn.frame:Hide()
    end

    btn.pushed = btn:CreateTexture(nil, "ARTWORK", nil, 1)
    btn.pushed:SetAllPoints()
    btn.pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    btn.pushed:Hide()

    btn.glow = btn:CreateTexture(nil, "OVERLAY")
    btn.glow:SetSize(32, 32)
    btn.glow:SetPoint("CENTER", btn.icon, "CENTER", 0, 0)
    btn.glow:SetTexture("Interface\\Spellbook\\SpellbookElementsAutoCastMask")
    if btn.glow.SetBlendMode then btn.glow:SetBlendMode("ADD") end
    btn.glow:Hide()

    btn:SetScript("OnEnter", function(self)
        self.glow:Show()
        local tip = spec.label
        if self.toggle then
            tip = spec.label .. ((self.isOn and " On") or " Off")
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tip)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self.glow:Hide()
        SetPushed(self, false)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnMouseDown", function(self)
        SetPushed(self, true)
    end)
    btn:SetScript("OnMouseUp", function(self)
        SetPushed(self, false)
    end)
    btn:SetScript("OnClick", function()
        Run(spec.id)
    end)

    PaintToggle(btn)
    return btn
end

-- Diamond Metal frame pieces (Blizzard's CharacterCreateThickBorder layout).
-- "_" edges tile horizontally, "!" edges tile vertically.
local BG_ATLAS = "UI-CastingBar-TextBox"
local FRAME_PIECES = {
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}

-- The visible metal of the frame is only a few pixels thick; the atlas pieces
-- are taller than that (mostly transparent), so measuring them left far too
-- much room. INNER_PAD is the gap past this line.
local BORDER_THICKNESS = 8

local function SizeForShell()
    local gridW = COLS * SIZE + (COLS - 1) * GAP
    local gridH = ROWS * SIZE + (ROWS - 1) * GAP
    local inset = BORDER_THICKNESS + INNER_PAD
    return gridW + inset * 2, gridH + inset * 2, inset
end

-- Text-box background, kept proportional: it is scaled up to cover the box
-- and the overhang is cropped off with texture coordinates, so the texture is
-- exactly the box's size and can't draw outside it (a frame's SetClipsChildren
-- doesn't clip its own textures, which is why the earlier version bled).
local BG_INSET = 4 -- keeps the square texture inside the frame's rounded corners

local function PaintBackground(frame, fw, fh)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", BG_INSET, -BG_INSET)
    bg:SetPoint("BOTTOMRIGHT", -BG_INSET, BG_INSET)
    local info = HasAtlas(BG_ATLAS) and C_Texture.GetAtlasInfo(BG_ATLAS)
    if info and info.width and info.height and info.width > 0 and info.height > 0
        and info.leftTexCoord and info.rightTexCoord and info.topTexCoord and info.bottomTexCoord then
        bg:SetAtlas(BG_ATLAS, false)
        local w, h = fw - BG_INSET * 2, fh - BG_INSET * 2
        local k = math.max(w / info.width, h / info.height)
        local wf, hf = w / (info.width * k), h / (info.height * k) -- visible fraction of the art
        local l, r, t, b = info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
        local cu, cv = (l + r) / 2, (t + b) / 2
        local hu, hv = (r - l) * wf / 2, (b - t) * hf / 2
        bg:SetTexCoord(cu - hu, cu + hu, cv - hv, cv + hv)
    else
        bg:SetColorTexture(0.1, 0.09, 0.08, 0.95)
    end
end

local function PaintFrame(frame)
    local host = CreateFrame("Frame", nil, frame)
    host:SetAllPoints()
    host:EnableMouse(false)
    host.layoutTextureLayer = "OVERLAY"
    host.layoutTextureSubLevel = 7
    local layout = {
        TopLeftCorner = { atlas = "UI-Frame-DiamondMetal-CornerTopLeft", layer = "OVERLAY", subLevel = 7 },
        TopRightCorner = { atlas = "UI-Frame-DiamondMetal-CornerTopRight", layer = "OVERLAY", subLevel = 7 },
        BottomLeftCorner = { atlas = "UI-Frame-DiamondMetal-CornerBottomLeft", layer = "OVERLAY", subLevel = 7 },
        BottomRightCorner = { atlas = "UI-Frame-DiamondMetal-CornerBottomRight", layer = "OVERLAY", subLevel = 7 },
        TopEdge = { atlas = "_UI-Frame-DiamondMetal-EdgeTop", layer = "OVERLAY", subLevel = 7 },
        BottomEdge = { atlas = "_UI-Frame-DiamondMetal-EdgeBottom", layer = "OVERLAY", subLevel = 7 },
        LeftEdge = { atlas = "!UI-Frame-DiamondMetal-EdgeLeft", layer = "OVERLAY", subLevel = 7 },
        RightEdge = { atlas = "!UI-Frame-DiamondMetal-EdgeRight", layer = "OVERLAY", subLevel = 7 },
    }
    if NineSliceUtil and NineSliceUtil.ApplyLayout then
        NineSliceUtil.ApplyLayout(host, layout)
        -- ApplyLayout never calls Show() on its pieces.
        for i = 1, #FRAME_PIECES do
            local piece = host[FRAME_PIECES[i]]
            if piece then piece:Show() end
        end
    end
    return host
end

local function Build()
    local fw, fh, inset = SizeForShell()
    frame = CreateFrame("Frame", "BlackacreToolBox", UIParent)
    frame:SetSize(fw, fh)
    -- Whole toolbox (frame art, buttons, X) drawn 15% smaller.
    frame:SetScale(0.85)
    frame:SetPoint("CENTER", 0, 80)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    tinsert(UISpecialFrames, "BlackacreToolBox")
    Blackacre.UI.Focus.Register(frame)

    local base = frame:GetFrameLevel() or 1
    PaintBackground(frame, fw, fh)
    PaintFrame(frame):SetFrameLevel(base + 10)

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetAllPoints()
    frame.content:EnableMouse(false)
    frame.content:SetFrameLevel(base + 40)

    -- Esc or the Toolbox button also close it; the X is tucked inside the top-right corner.
    local close = CreateFrame("Button", nil, frame.content, "UIPanelCloseButton")
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -1, -1)
    close:SetFrameLevel(base + 50)
    close:SetScript("OnClick", function() frame:Hide() end)

    wipe(buttons)
    for i, spec in ipairs(SLOTS) do
        local btn = MakeSlot(frame.content, spec, i, 1, inset, -inset)
        btn:SetFrameLevel(base + 45)
        buttons[#buttons + 1] = btn
    end
end

function Blackacre.ToolBox.Toggle()
    if not frame then Build() end
    if frame:IsShown() then
        frame:Hide()
    else
        for _, b in ipairs(buttons) do PaintToggle(b) end
        frame:Show()
    end
end

function Blackacre.ToolBox.Show()
    if not frame then Build() end
    for _, b in ipairs(buttons) do PaintToggle(b) end
    frame:Show()
end
