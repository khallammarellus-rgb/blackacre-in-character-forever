-- In Character Forever - Tour

Blackacre = Blackacre or {}
Blackacre.Tour = Blackacre.Tour or {}

local Tour = Blackacre.Tour

local CreateFrame, UIParent, C_Timer = CreateFrame, UIParent, C_Timer
local ipairs, wipe, max, min, floor, format = ipairs, wipe, math.max, math.min, math.floor, string.format

local ROOT_STRATA = "FULLSCREEN_DIALOG"
local DIM_ALPHA = 0.72
local HOLE_PAD = 6      -- the clear area sits this far outside the target
local CALLOUT_W = 340
local GAP = 14          -- callout to target when there is no art (plain box)
local ARROW_GAP = 4     -- arrow tip to the edge of the clear area
local SLOT_MAX = 64     -- a target no bigger than this (both ways) gets the slot glow, else the card
local SLOT_PAD = 3      -- slot glow: the clear area sits this far outside the target (the glow's white frame lands on its edge)
local SLOT_CLEAR = 8    -- slot glow: the callout stays this far from that frame
local GOLD = { 1, 0.82, 0 }
local GREY = { 0.62, 0.62, 0.62 }

local root, dim, ring, callout
local queue = {}        -- the steps of the running tour, in order
local index = 0         -- 0 = no tour running
local layoutToken = 0   -- ignores a delayed layout from a step we already left
local BuildGlow         -- defined with the glow code below
local calloutArt        -- Theme.TourArt.callout when this client has it, else nil (plain box)
local inset = 14        -- callout edge to the border line

--- Sections are registered by Data\TourSteps.lua: { key, label, steps = {...} }.
Tour.sections = Tour.sections or {}

function Tour.RegisterSection(key, label, steps)
    Tour.sections[#Tour.sections + 1] = { key = key, label = label, steps = steps }
end

local function StepAvailable(step)
    return not step.available or step.available()
end

--- True when at least one step of the section can run right now (its add-on is loaded).
function Tour.IsAvailable(section)
    for _, step in ipairs(section.steps) do
        if StepAvailable(step) then return true end
    end
    return false
end

local function Print(msg)
    if Blackacre.Print then Blackacre.Print(msg) end
end

local function Theme()
    return Blackacre.UI and Blackacre.UI.Theme
end

-- ---------------------------------------------------------------- nine-slice

-- One atlas cut into nine pieces: corners keep their size, edges and the middle
-- stretch. The grid comes from the art row (cols/rows, or `margin` for an even frame).
local function NewNine(parent, layer)
    local n = {}
    for i = 1, 9 do n[i] = parent:CreateTexture(nil, layer) end
    n.parent = parent
    return n
end

local function HideNine(n)
    for i = 1, 9 do n[i]:Hide() end
end

--- maxW/maxH shrink the corners when the frame is smaller than two of them.
--- Returns true when drawn, nil when this client lacks the art.
local function ApplyNine(n, kind, maxW, maxH)
    local theme = Theme()
    if not theme then HideNine(n); return nil end
    local art, info = theme.GetTourArt(kind)
    local file = info and (info.filename or info.file)
    if not file then HideNine(n); return nil end
    local dw, dh = art.w or info.width or 0, art.h or info.height or 0
    if dw <= 0 or dh <= 0 then HideNine(n); return nil end
    local cols = art.cols or { 0, art.margin, dw - art.margin, dw }
    local rows = art.rows or { 0, art.margin, dh - art.margin, dh }
    local s = art.scale or 1
    local tl = info.leftTexCoord or info.left or 0
    local tr = info.rightTexCoord or info.right or 1
    local tt = info.topTexCoord or info.top or 0
    local tb = info.bottomTexCoord or info.bottom or 1
    local us = {}
    local vs = {}
    for i = 1, 4 do
        us[i] = tl + (tr - tl) * cols[i] / dw
        vs[i] = tt + (tb - tt) * rows[i] / dh
    end
    local wl, wr = (cols[2] - cols[1]) * s, (cols[4] - cols[3]) * s
    local ht, hb = (rows[2] - rows[1]) * s, (rows[4] - rows[3]) * s
    if maxW and wl + wr > maxW then
        local f = maxW / (wl + wr)
        wl, wr = wl * f, wr * f
    end
    if maxH and ht + hb > maxH then
        local f = maxH / (ht + hb)
        ht, hb = ht * f, hb * f
    end
    for row = 1, 3 do
        for col = 1, 3 do
            local t = n[(row - 1) * 3 + col]
            t:SetTexture(file)
            t:SetTexCoord(us[col], us[col + 1], vs[row], vs[row + 1])
            t:ClearAllPoints()
            t:Show()
        end
    end
    local p = n.parent
    n[1]:SetPoint("TOPLEFT", p, "TOPLEFT");         n[1]:SetSize(wl, ht)
    n[3]:SetPoint("TOPRIGHT", p, "TOPRIGHT");       n[3]:SetSize(wr, ht)
    n[7]:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT");   n[7]:SetSize(wl, hb)
    n[9]:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT"); n[9]:SetSize(wr, hb)
    n[2]:SetPoint("TOPLEFT", n[1], "TOPRIGHT");     n[2]:SetPoint("BOTTOMRIGHT", n[3], "BOTTOMLEFT")
    n[8]:SetPoint("TOPLEFT", n[7], "TOPRIGHT");     n[8]:SetPoint("BOTTOMRIGHT", n[9], "BOTTOMLEFT")
    n[4]:SetPoint("TOPLEFT", n[1], "BOTTOMLEFT");   n[4]:SetPoint("BOTTOMRIGHT", n[7], "TOPRIGHT")
    n[6]:SetPoint("TOPLEFT", n[3], "BOTTOMLEFT");   n[6]:SetPoint("BOTTOMRIGHT", n[9], "TOPRIGHT")
    n[5]:SetPoint("TOPLEFT", n[1], "BOTTOMRIGHT");  n[5]:SetPoint("BOTTOMRIGHT", n[9], "TOPLEFT")
    if art.noCenter then n[5]:Hide() end
    -- The bottom edge is sampled from a slab left of the arrow, so no piece of the
    -- baked-in arrow rides along when the edge stretches.
    if art.edgeX then
        n[8]:SetTexCoord(tl + (tr - tl) * art.edgeX[1] / dw, tl + (tr - tl) * art.edgeX[2] / dw, vs[3], vs[4])
    end
    return true
end

-- ---------------------------------------------------------------- glow

-- The ring of eight glow pieces around the callout, like Blizzard's tutorial boxes
-- (which draw it additively). The glow's bright core line is laid on the box's border
-- line, so the halo wraps the box. It runs unbroken behind the arrow.
--
-- The art never fades fully out: its last few pixels sit at 8-16% opacity and end in a
-- hard step. So each piece is drawn as up to nine slices, and the slices on its OUTER
-- sides carry an alpha gradient from full to nothing. Inner slices are untouched, so
-- the bright core and the main fade look exactly as drawn.
local GLOW_CORNERS = { -- anchor point, then which way "outside" is in x and y
    TL = { "TOPLEFT", -1, 1 }, TR = { "TOPRIGHT", 1, 1 },
    BL = { "BOTTOMLEFT", -1, -1 }, BR = { "BOTTOMRIGHT", 1, -1 },
}

local GLOW_OUTER = { -- which sides of each piece face away from the callout
    TL = { left = true, top = true }, TR = { right = true, top = true },
    BL = { left = true, bottom = true }, BR = { right = true, bottom = true },
    top = { top = true }, bottom = { bottom = true },
    left = { left = true }, right = { right = true },
}

--- Multiply a texture's alpha by a gradient (alphaMin at the left, or the bottom for a
--- vertical gradient, to alphaMax at the right, or the top). Blizzard's own fades use
--- the same call; vertical gradients run bottom (first) to top (second).
local function AlphaGradient(tex, orientation, alphaMin, alphaMax)
    if tex.SetGradient and CreateColor then
        tex:SetGradient(orientation, CreateColor(1, 1, 1, alphaMin), CreateColor(1, 1, 1, alphaMax))
    elseif tex.SetGradientAlpha then
        tex:SetGradientAlpha(orientation, 1, 1, 1, alphaMin, 1, 1, 1, alphaMax)
    end
end

--- One glow atlas as slices. `rect` is an invisible texture standing for the piece's
--- place; slices are anchored inside it. Fixed-size directions use pw/ph; a stretched
--- direction (an edge's length) always has its slices run the whole way.
local function GlowPiece(parent, rect, info, g, sides, pw, ph)
    local file = info.file
    local fx = min(0.9, g.fade / info.w)
    local fy = min(0.9, g.fade / info.h)
    local xs = { 0, sides.left and fx or 0, sides.right and (1 - fx) or 1, 1 }
    local ys = { 0, sides.top and fy or 0, sides.bottom and (1 - fy) or 1, 1 }
    for row = 1, 3 do
        for col = 1, 3 do
            local x0, x1, y0, y1 = xs[col], xs[col + 1], ys[row], ys[row + 1]
            if x1 > x0 and y1 > y0 then
                local tex = parent:CreateTexture(nil, "BORDER")
                tex:SetTexture(file)
                tex:SetTexCoord(
                    info.l + (info.r - info.l) * x0, info.l + (info.r - info.l) * x1,
                    info.t + (info.b - info.t) * y0, info.t + (info.b - info.t) * y1)
                tex:SetBlendMode(g.blend)
                tex:SetPoint("TOPLEFT", rect, "TOPLEFT", x0 * pw, -y0 * ph)
                tex:SetPoint("BOTTOMRIGHT", rect, "BOTTOMRIGHT", -(1 - x1) * pw, (1 - y1) * ph)
                if col == 1 then
                    AlphaGradient(tex, "HORIZONTAL", 0, 1)
                elseif col == 3 then
                    AlphaGradient(tex, "HORIZONTAL", 1, 0)
                elseif row == 1 then
                    AlphaGradient(tex, "VERTICAL", 1, 0) -- bottom full, top nothing
                elseif row == 3 then
                    AlphaGradient(tex, "VERTICAL", 0, 1)
                end
            end
        end
    end
end

--- `borderInset` is the border's distance from the frame edge (0 when the box art is
--- cut at its border).
BuildGlow = function(parent, borderInset)
    local theme = Theme()
    local g = theme and theme.GetTourGlow()
    if not g then return end
    local out = g.d - borderInset -- how far the glow's outer edge sits outside the frame edge
    local rect = {}
    for _, key in ipairs({ "TL", "TR", "BL", "BR", "top", "bottom", "left", "right" }) do
        local r = parent:CreateTexture(nil, "BORDER")
        r:SetColorTexture(0, 0, 0, 0) -- invisible: only here to be anchored to
        r:SetSize(g[key].w * g.scale, g[key].h * g.scale)
        rect[key] = r
    end
    -- Some corner tiles have their line a pixel off from the matching edge piece in
    -- Blizzard's art, so a corner can be nudged (g.nudge, art pixels) to put its line
    -- on the edge's. Edges are placed from the parent, ending where the nudged corner
    -- begins, so nothing overlaps or leaves a gap.
    local s = g.scale
    local function nx(k) local n = g.nudge[k]; return n and (n.x or 0) * s or 0 end
    local function ny(k) local n = g.nudge[k]; return n and (n.y or 0) * s or 0 end
    local function cw(k) return g[k].w * s end
    local function ch(k) return g[k].h * s end
    for key, c in pairs(GLOW_CORNERS) do
        rect[key]:SetPoint(c[1], parent, c[1], c[2] * out + nx(key), c[3] * out + ny(key))
    end
    rect.top:SetPoint("TOPLEFT", parent, "TOPLEFT", -out + nx("TL") + cw("TL"), out)
    rect.top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", out + nx("TR") - cw("TR"), out)
    rect.bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -out + nx("BL") + cw("BL"), -out)
    rect.bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", out + nx("BR") - cw("BR"), -out)
    rect.left:SetPoint("TOPLEFT", parent, "TOPLEFT", -out, out + ny("TL") - ch("TL"))
    rect.left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", -out, -out + ny("BL") + ch("BL"))
    rect.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", out, out + ny("TR") - ch("TR"))
    rect.right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", out, -out + ny("BR") + ch("BR"))
    for key, info in pairs({ TL = g.TL, TR = g.TR, BL = g.BL, BR = g.BR,
            top = g.top, bottom = g.bottom, left = g.left, right = g.right }) do
        GlowPiece(parent, rect[key], info, g, GLOW_OUTER[key], info.w * g.scale, info.h * g.scale)
    end
    parent.glowRect = rect
end

-- ---------------------------------------------------------------- arrow

-- The arrow is cut out of the callout art and drawn on its own, so it can sit on any
-- edge. `side` is where the callout sits relative to the target; the arrow points
-- back at the target. The art's own arrow points down, so the other three are the
-- same strip turned (texcoords UL, LL, UR, LR).
local function ArrowCoords(side, u0, u1, v0, v1)
    if side == "TOP" then       -- callout above the target: points down
        return u0, v0, u0, v1, u1, v0, u1, v1
    elseif side == "BOTTOM" then -- below: points up
        return u0, v1, u0, v0, u1, v1, u1, v0
    elseif side == "LEFT" then   -- callout to the left: points right
        return u1, v0, u0, v0, u1, v1, u0, v1
    end                          -- "RIGHT": points left
    return u0, v1, u1, v1, u0, v0, u1, v0
end

--- Arrow size, how far it reaches inside the box edge, and how far past it. The arrow
--- has its own scale (it is drawn smaller than the box); its border row is lined up
--- with the box's border line.
local function ArrowMetrics(art)
    local a = art.arrow
    local sa = a.scale or art.scale
    local length, depth = (a.x1 - a.x0) * sa, (a.y1 - a.y0) * sa
    local overlap = (art.rows[4] - a.borderY) * art.scale + (a.borderY - a.y0) * sa
    return length, depth, overlap, depth - overlap
end

--- (x, y) is the callout's bottom-left; (cx, cy) the centre of what it points at.
local function PlaceArrow(side, x, y, cx, cy)
    local art = calloutArt
    local arrow = callout.arrow
    local s = art.scale
    local a = art.arrow
    local length, depth, overlap = ArrowMetrics(art)
    local vertical = (side == "LEFT" or side == "RIGHT")
    local span = vertical and callout:GetHeight() or callout:GetWidth()
    local along = vertical and (cy - y) or (cx - x)
    local lo = (art.cols[2] - art.cols[1]) * s + length / 2
    along = (span - lo >= lo) and max(lo, min(along, span - lo)) or span / 2

    local theme = Theme()
    local _, info = theme.GetTourArt("callout")
    arrow:SetTexture(info.filename or info.file)
    local tl = info.leftTexCoord or info.left or 0
    local tr = info.rightTexCoord or info.right or 1
    local tt = info.topTexCoord or info.top or 0
    local tb = info.bottomTexCoord or info.bottom or 1
    local u0, u1 = tl + (tr - tl) * a.x0 / art.w, tl + (tr - tl) * a.x1 / art.w
    local v0, v1 = tt + (tb - tt) * a.y0 / art.h, tt + (tb - tt) * a.y1 / art.h
    arrow:SetTexCoord(ArrowCoords(side, u0, u1, v0, v1))

    arrow:ClearAllPoints()
    if side == "TOP" then
        arrow:SetSize(length, depth)
        arrow:SetPoint("TOP", callout, "BOTTOMLEFT", along, overlap)
    elseif side == "BOTTOM" then
        arrow:SetSize(length, depth)
        arrow:SetPoint("BOTTOM", callout, "TOPLEFT", along, -overlap)
    elseif side == "LEFT" then
        arrow:SetSize(depth, length)
        arrow:SetPoint("LEFT", callout, "BOTTOMRIGHT", -overlap, along)
    else
        arrow:SetSize(depth, length)
        arrow:SetPoint("RIGHT", callout, "BOTTOMLEFT", overlap, along)
    end
    arrow:Show()
end

-- ---------------------------------------------------------------- frames

local function Edge(parent, name)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetColorTexture(0, 0, 0, DIM_ALPHA)
    dim[name] = t
    return t
end

--- A quiet text button: coloured text, white under the mouse.
local function MakeLink(parent, color)
    local btn = CreateFrame("Button", nil, parent)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.color = color
    btn.text:SetTextColor(color[1], color[2], color[3])
    btn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
    btn:SetScript("OnLeave", function(self)
        local c = self.color
        self.text:SetTextColor(c[1], c[2], c[3])
    end)
    return btn
end

local function SetLink(btn, label)
    btn.text:SetText(label)
    btn:SetSize(btn.text:GetStringWidth() + 10, 16)
end

local function BuildRoot()
    root = CreateFrame("Frame", "BlackacreTourRoot", UIParent)
    root:SetAllPoints(UIParent)
    root:SetFrameStrata(ROOT_STRATA)
    root:SetFrameLevel(100)
    root:EnableMouse(true) -- swallows clicks so the UI under the dim can't be poked mid-tour
    root:EnableKeyboard(true)
    root:Hide()

    dim = {}
    Edge(root, "top"); Edge(root, "bottom"); Edge(root, "left"); Edge(root, "right")

    -- Spotlight ring: the slot glow (small things) or the card frame (large bodies);
    -- four gold lines are the fallback for a client that lacks the atlases.
    ring = CreateFrame("Frame", nil, root)
    ring:SetFrameLevel(root:GetFrameLevel() + 2)
    ring.slot = ring:CreateTexture(nil, "OVERLAY")
    ring.slot:SetAllPoints()
    ring.card = NewNine(ring, "OVERLAY")
    ring.line = {}
    for i = 1, 4 do
        local t = ring:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(0.85, 0.7, 0.25, 1)
        ring.line[i] = t
    end

    callout = CreateFrame("Frame", "BlackacreTourCallout", root, "BackdropTemplate")
    callout:SetFrameLevel(root:GetFrameLevel() + 10)
    callout:SetWidth(CALLOUT_W)
    callout:EnableMouse(true)
    callout.nine = NewNine(callout, "BACKGROUND") -- the text box art, under the text
    callout.arrow = callout:CreateTexture(nil, "ARTWORK") -- above the glow
    callout.arrow:SetBlendMode("ADD") -- its black shadow adds nothing, so only the gold chevron shows
    callout.arrow:Hide()

    callout.title = callout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    callout.title:SetJustifyH("LEFT")
    callout.body = callout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    callout.body:SetJustifyH("LEFT")
    callout.body:SetSpacing(2)

    callout.count = callout:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    callout.count:SetTextColor(GREY[1], GREY[2], GREY[3])

    callout.next = MakeLink(callout, GOLD)
    callout.next:SetScript("OnClick", function() Tour.Next() end)
    callout.back = MakeLink(callout, GREY)
    callout.back:SetScript("OnClick", function() Tour.Back() end)
    SetLink(callout.back, "\194\171 Back")
    callout.skip = MakeLink(callout, GREY)
    callout.skip:SetScript("OnClick", function() Tour.Stop() end)
    SetLink(callout.skip, "Skip tour")

    -- With the art, everything is inset from the border line, not the glow.
    local theme = Theme()
    calloutArt = theme and theme.GetTourArt("callout") or nil
    if calloutArt and ApplyNine(callout.nine, "callout") then
        callout:SetBackdrop(nil)
        inset = floor(calloutArt.inset * calloutArt.scale)
        BuildGlow(callout, 0) -- the box is now cut at its border, so the border is the frame edge
    else
        calloutArt = nil
        callout:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        callout:SetBackdropColor(0.04, 0.03, 0.01, 0.95)
        callout:SetBackdropBorderColor(0.85, 0.7, 0.25, 1)
        inset = 0
    end
    local padX, padTop, padBottom = inset + 12, inset + 10, inset + 6
    callout.skip:SetPoint("TOPRIGHT", -(inset + 6), -(inset + 6))
    callout.title:SetPoint("TOPLEFT", padX, -padTop)
    callout.title:SetWidth(CALLOUT_W - 2 * padX - callout.skip:GetWidth())
    callout.body:SetPoint("TOPLEFT", callout.title, "BOTTOMLEFT", 0, -8)
    callout.body:SetWidth(CALLOUT_W - 2 * padX)
    callout.count:SetPoint("BOTTOMLEFT", inset + 8, padBottom)
    callout.next:SetPoint("BOTTOMRIGHT", -(inset + 6), padBottom - 3)
    callout.back:SetPoint("RIGHT", callout.next, "LEFT", -6, 0)
    callout.padTop, callout.padBottom = padTop, padBottom

    root:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            Tour.Stop()
        elseif key == "RIGHT" or key == "ENTER" or key == "SPACE" then
            Tour.Next()
        elseif key == "LEFT" then
            Tour.Back()
        end
        self:SetPropagateKeyboardInput(false)
    end)
    root:SetScript("OnEvent", function()
        if index > 0 then Tour.Layout() end -- screen size or UI scale changed
    end)
end

-- ---------------------------------------------------------------- layout

--- Where `frame` sits in UIParent units (left, bottom, right, top), or nil when it
--- can't be measured (not built, hidden, or zero-sized).
local function RectOf(frame)
    if not frame or not frame.GetRect or not frame:IsVisible() then return nil end
    local l, b, w, h = frame:GetRect()
    if not l or not w or w < 1 or h < 1 then return nil end
    local s = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return l * s, b * s, (l + w) * s, (b + h) * s
end

--- (l, b, r, t) is the clear area. The ring (slot glow or card frame) is drawn `ox`/`oy`
--- wider than it: the card frame sits right on the edge, the slot glow reaches out.
local function PlaceDim(l, b, r, t, W, H, style, ox, oy)
    l, r = max(0, min(l, W)), max(0, min(r, W))
    b, t = max(0, min(b, H)), max(0, min(t, H))
    dim.top:ClearAllPoints()
    dim.top:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, t)
    dim.top:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    dim.bottom:ClearAllPoints()
    dim.bottom:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
    dim.bottom:SetPoint("TOPRIGHT", root, "BOTTOMRIGHT", 0, b)
    dim.left:ClearAllPoints()
    dim.left:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, b)
    dim.left:SetPoint("TOPRIGHT", root, "BOTTOMLEFT", l, t)
    dim.right:ClearAllPoints()
    dim.right:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", r, b)
    dim.right:SetPoint("TOPRIGHT", root, "BOTTOMLEFT", W, t)

    ring:ClearAllPoints()
    ring:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", l - ox, b - oy)
    ring:SetPoint("TOPRIGHT", root, "BOTTOMLEFT", r + ox, t + oy)
    local haveArt = false
    ring.slot:Hide(); HideNine(ring.card)
    for i = 1, 4 do ring.line[i]:Hide() end
    if style == "slot" then
        local theme = Theme()
        local art = theme and theme.GetTourArt("slot")
        if art and theme.TrySetAtlas(ring.slot, art.atlas, false) then
            ring.slot:SetBlendMode(art.blend or "BLEND")
            ring.slot:Show()
            haveArt = true
        end
    else
        haveArt = ApplyNine(ring.card, "card", r - l, t - b) ~= nil
    end
    if not haveArt then
        local L1, L2, L3, L4 = ring.line[1], ring.line[2], ring.line[3], ring.line[4]
        L1:ClearAllPoints(); L1:SetPoint("TOPLEFT"); L1:SetPoint("TOPRIGHT"); L1:SetHeight(2); L1:Show()
        L2:ClearAllPoints(); L2:SetPoint("BOTTOMLEFT"); L2:SetPoint("BOTTOMRIGHT"); L2:SetHeight(2); L2:Show()
        L3:ClearAllPoints(); L3:SetPoint("TOPLEFT"); L3:SetPoint("BOTTOMLEFT"); L3:SetWidth(2); L3:Show()
        L4:ClearAllPoints(); L4:SetPoint("TOPRIGHT"); L4:SetPoint("BOTTOMRIGHT"); L4:SetWidth(2); L4:Show()
    end
    ring:Show()
end

local function PlaceFullDim()
    dim.top:ClearAllPoints()
    dim.top:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
    dim.top:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    dim.bottom:ClearAllPoints(); dim.bottom:SetSize(1, 1)
    dim.bottom:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
    dim.left:ClearAllPoints(); dim.left:SetSize(1, 1)
    dim.left:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
    dim.right:ClearAllPoints(); dim.right:SetSize(1, 1)
    dim.right:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
    ring:Hide()
end

local function FillCallout(step, note)
    callout.title:SetText(step.title or "")
    callout.body:SetText((step.text or "") .. (note and ("\n\n|cffaaaaaa" .. note .. "|r") or ""))
    callout.count:SetText(format("%d / %d", index, #queue))
    callout.back:SetShown(index > 1)
    SetLink(callout.next, index >= #queue and "Done" or "Next \194\187")
    -- top inset + title + gap + body + gap + footer row + bottom inset
    callout:SetHeight(callout.padTop + callout.title:GetStringHeight() + 8
        + callout.body:GetStringHeight() + 12 + 14 + callout.padBottom)
end

--- Callout goes on the roomiest side of the spotlight (or `preferred` when it fits),
--- its arrow pointing at the target. When no side has room (the target fills the
--- screen) it sits over the middle of the target with no arrow.
local function PlaceCallout(l, b, r, t, W, H, preferred)
    local cw, ch = callout:GetWidth(), callout:GetHeight()
    local reach = 0
    if calloutArt then
        local _, _, _, past = ArrowMetrics(calloutArt)
        reach = past
    end
    local lead = (calloutArt and (reach + ARROW_GAP)) or GAP -- target edge to the callout's frame
    local room = { RIGHT = W - r, LEFT = l, TOP = H - t, BOTTOM = b }
    local need = { RIGHT = cw + lead, LEFT = cw + lead, TOP = ch + lead, BOTTOM = ch + lead }
    local side = preferred
    if not side or room[side] < need[side] then
        side = nil
        local best = -1
        for _, s in ipairs({ "RIGHT", "LEFT", "BOTTOM", "TOP" }) do
            if room[s] - need[s] > best then best, side = room[s] - need[s], s end
        end
    end
    local cx, cy = (l + r) / 2, (b + t) / 2
    local x, y
    if side == "RIGHT" then
        x, y = r + lead, cy - ch / 2
    elseif side == "LEFT" then
        x, y = l - lead - cw, cy - ch / 2
    elseif side == "TOP" then
        x, y = cx - cw / 2, t + lead
    elseif side == "BOTTOM" then
        x, y = cx - cw / 2, b - lead - ch
    else
        x, y = cx - cw / 2, cy - ch / 2
    end
    x = max(8, min(x, W - cw - 8))
    y = max(8, min(y, H - ch - 8))
    callout:ClearAllPoints()
    callout:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", x, y)
    if calloutArt and side then
        PlaceArrow(side, x, y, cx, cy)
    else
        callout.arrow:Hide()
    end
end

function Tour.Layout()
    local step = queue[index]
    if not step then return end
    local W, H = root:GetWidth(), root:GetHeight()
    local target = step.target and step.target()
    local l, b, r, t = RectOf(target)
    if l then
        FillCallout(step)
        local style = step.style or ((r - l <= SLOT_MAX and t - b <= SLOT_MAX) and "slot" or "card")
        local pad = (style == "slot") and SLOT_PAD or HOLE_PAD
        local hl, hb, hr, ht = l - pad, b - pad, r + pad, t + pad -- the clear area
        local ox, oy, clear = 0, 0, 0
        if style == "slot" then
            -- The glow art has a white frame `k` of the way in from its edge. Sizing the
            -- glow so that frame lands on the clear area's edge puts the spotlight's hard
            -- edge under the frame, not out in the soft green glow.
            local theme = Theme()
            local art = theme and theme.GetTourArt("slot")
            local k = (art and art.outline) or 0.238
            local f = k / (1 - 2 * k)
            ox, oy, clear = (hr - hl) * f, (ht - hb) * f, SLOT_CLEAR
        end
        PlaceDim(hl, hb, hr, ht, W, H, style, ox, oy)
        PlaceCallout(hl - clear, hb - clear, hr + clear, ht + clear, W, H, step.side)
    else
        -- Nothing to point at (a window that isn't open, a meter that's switched off).
        FillCallout(step, step.missing or "(This part isn't on screen right now.)")
        PlaceFullDim()
        callout.arrow:Hide()
        callout:ClearAllPoints()
        callout:SetPoint("CENTER", root, "CENTER", 0, 0)
    end
end

-- ---------------------------------------------------------------- flow

local function NextAvailable(from, dir)
    local i = from + dir
    while queue[i] do
        if StepAvailable(queue[i]) then return i end
        i = i + dir
    end
    return nil
end

local function ShowStep(i)
    index = i
    local step = queue[i]
    if step.onEnter then step.onEnter() end
    -- Give a window that was just opened one beat to lay itself out before measuring.
    layoutToken = layoutToken + 1
    local token = layoutToken
    callout:Hide()
    C_Timer.After(0.12, function()
        if token ~= layoutToken or index == 0 then return end
        Tour.Layout()
        callout:Show()
    end)
end

function Tour.IsRunning()
    return index > 0
end

--- Start a section ("tome", "survival", ...) or the whole tour ("all").
function Tour.Start(key)
    if InCombatLockdown and InCombatLockdown() then
        Print("The tour can't start while you're in combat.")
        return
    end
    if not root then BuildRoot() end
    wipe(queue)
    for _, section in ipairs(Tour.sections) do
        if key == "all" or key == section.key then
            for _, step in ipairs(section.steps) do
                if StepAvailable(step) then queue[#queue + 1] = step end
            end
        end
    end
    if #queue == 0 then
        Print("Nothing to show for that tour. Its add-on may not be installed.")
        return
    end
    root:RegisterEvent("DISPLAY_SIZE_CHANGED")
    root:RegisterEvent("UI_SCALE_CHANGED")
    root:SetPropagateKeyboardInput(false)
    root:Show()
    ShowStep(1)
end

function Tour.Next()
    if index == 0 then return end
    local nxt = NextAvailable(index, 1)
    if nxt then ShowStep(nxt) else Tour.Stop(true) end
end

function Tour.Back()
    if index == 0 then return end
    local prev = NextAvailable(index, -1)
    if prev then ShowStep(prev) end
end

function Tour.Stop(finished)
    if index == 0 then return end
    index = 0
    layoutToken = layoutToken + 1
    wipe(queue)
    root:UnregisterAllEvents()
    callout:Hide()
    root:Hide()
    if Tour.onStop then Tour.onStop() end -- close the windows the tour opened
    if Blackacre.CharDB then
        Blackacre.CharDB.tour = Blackacre.CharDB.tour or {}
        Blackacre.CharDB.tour.seen = true
    end
    if finished then Print("Tour finished. Run it again any time: /ba helper") end
end

--- Settings and /ba helper both come through here: close Settings so it isn't in the way.
function Tour.StartFromSettings(key)
    local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
    if dialog then dialog:Close("Blackacre") end
    C_Timer.After(0.2, function() Tour.Start(key) end)
end

--- /ba tourart: what this client says about the three atlases, to check the sizes
--- in Theme.TourArt still match the art.
function Tour.DebugArt()
    local theme = Theme()
    for _, kind in ipairs({ "slot", "card", "callout" }) do
        local art, info = theme.GetTourArt(kind)
        if info then
            Print(format("%s: %s  %dx%d  (Theme expects %s)", kind, art.atlas, info.width or 0, info.height or 0,
                art.w and (art.w .. "x" .. art.h) or "any size"))
        else
            Print(kind .. ": atlas not found in this client")
        end
    end
    local g = theme.GetTourGlow()
    if not g then
        Print("glow: one or more of the eight glow atlases is missing in this client")
        return
    end
    for _, key in ipairs({ "TL", "TR", "BL", "BR", "top", "bottom", "left", "right" }) do
        local p = g[key]
        Print(format("glow %s: %s  %dx%d", key, p.atlas, p.w, p.h))
    end
end

-- ---------------------------------------------------------------- first run

StaticPopupDialogs["BLACKACRE_TOUR_OFFER"] = {
    text = "Welcome to In Character Forever.\n\nTake a short tour of what's here?",
    button1 = "Take the tour",
    button2 = "Maybe later",
    OnAccept = function() Tour.Start("all") end,
    OnCancel = function()
        Print("You can take the tour any time: /ba helper")
    end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
}

local function OfferTour()
    local db = Blackacre.CharDB
    if not db or (db.tour and db.tour.seen) then return end
    if InCombatLockdown and InCombatLockdown() then return end
    db.tour = db.tour or {}
    db.tour.seen = true -- asked once; any answer counts
    StaticPopup_Show("BLACKACRE_TOUR_OFFER")
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:SetScript("OnEvent", function(self, _, isInitialLogin)
    if not isInitialLogin then return end
    self:UnregisterAllEvents()
    C_Timer.After(8, OfferTour)
end)
