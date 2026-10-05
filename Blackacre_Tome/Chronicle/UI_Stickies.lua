-- In Character Forever: Journal - Sticky Notes

local Book = Blackacre.Chronicle.Book

-- Hot-path upvalues (DBM-Core style).
local tonumber, tostring, time = tonumber, tostring, time
local CreateFrame, UIParent = CreateFrame, UIParent

-- Shared with UI_Chronology.lua (defined there, which loads first).
local Theme, TryAtlas, ApplyAtlasMember = Book.Theme, Book.TryAtlas, Book.ApplyAtlasMember
local FitButtonWidth, GetScrap, AcquireKid = Book.FitButtonWidth, Book.GetScrap, Book.AcquireKid

local function EnsureStickyNotes(entry)
    entry.stickyNotes = entry.stickyNotes or {}
    return entry.stickyNotes
end

local function PersistStickies(entry)
    if not entry or not entry.id then return end
    Blackacre.Chronicle.Store.Update(entry.id, { stickyNotes = EnsureStickyNotes(entry) })
end

local function HideStickyMenu()
    if Book.journal and Book.journal.stickyMenu then
        Book.journal.stickyMenu:Hide()
    end
end

local function SaveStickyGeometry(card)
    local note = card and card._note
    local parent = card and card:GetParent()
    if not note or not parent or parent == GetScrap() then return end
    local pl, pt = parent:GetLeft(), parent:GetTop()
    local cl, ct = card:GetLeft(), card:GetTop()
    if pl and pt and cl and ct then
        note.x = cl - pl
        note.y = ct - pt
    end
    note.w = card:GetWidth() or note.w or 150
    note.h = card:GetHeight() or note.h or 90
end

local function SetTextureFromList(tex, atlases, files)
    if not tex then return false end
    if atlases then
        for i = 1, #atlases do
            if ApplyAtlasMember(tex, atlases[i], false) then
                return true
            end
        end
    end
    if files then
        for i = 1, #files do
            tex:SetTexture(files[i])
            if tex.GetTexture and tex:GetTexture() then
                return true
            end
        end
    end
    return false
end

local function SetResizeGripLook(grip, active)
    if not grip then return end
    local tex = grip.icon
    if not tex then return end
    tex:Show()
    if active then
        if not SetTextureFromList(tex, {
            "Cursor_UI-Cursor-Size_32",
            "Cursor_UI-Cursor-Size32",
        }, {
            "Interface\\Cursor\\UIResizeCursor2x",
            "Interface\\Cursor\\UI-Cursor-Size",
        }) then
            tex:SetTexture("Interface\\Cursor\\UI-Cursor-Size")
        end
    else
        if not SetTextureFromList(tex, {
            "Cursor_UnableUI-Cursor_size_48",
            "Cursor_UnableUI-Cursor-Size_48",
            "Cursor_UnableUI-Cursor-Size48",
        }, {
            "Interface\\Cursor\\UIResizeCursor2x",
            "Interface\\Cursor\\UI-Cursor-Size",
        }) then
            tex:SetTexture("Interface\\Cursor\\UI-Cursor-Size")
        end
    end
    tex:SetAlpha(1)
end

local function StopStickyResize(card)
    if not card then return end
    card.isResizing = false
    card:SetScript("OnUpdate", nil)
    local grip = card.resizeGrip
    if grip and not (grip.IsMouseOver and grip:IsMouseOver()) then
        SetResizeGripLook(grip, false)
    end
end

--- Right-click still toggles edit/lock. Delete is always on the note.
local function ShowStickyActionRow(card, showActions)
    if not card then return end
    card._baActionsOpen = showActions and true or false
    if card.deleteBtn then card.deleteBtn:Show() end
end

local function ApplyStickyLocked(card, locked)
    local note = card._note
    if not note then return end
    note.pinned = locked and true or false
    card._baEditOpen = not locked
    StopStickyResize(card)
    card:SetMovable(true)
    if card.header then
        card.header:RegisterForDrag("LeftButton")
        card.header:EnableMouse(true)
    end
    if card.resizeGrip then
        card.resizeGrip:Show()
        card.resizeGrip:EnableMouse(true)
        card.resizeGrip:RegisterForDrag("LeftButton")
        SetResizeGripLook(card.resizeGrip, false)
    end
    if card.deleteBtn then card.deleteBtn:Show() end
    if locked then
        if card.status then card.status:SetText("") end
        if card.box then
            card.box:Disable()
            card.box:ClearFocus()
            card.box:SetTextColor(0.12, 0.1, 0.05, 1)
        end
    else
        if card.status then card.status:SetText("") end
        if card.box then
            card.box:Enable()
            card.box:SetTextColor(0.05, 0.05, 0.06, 1)
        end
    end
end

local function DeleteStickyNote(entry, note)
    local notes = EnsureStickyNotes(entry)
    for i = #notes, 1, -1 do
        if notes[i] == note or (note.id and notes[i].id == note.id) then
            table.remove(notes, i)
            break
        end
    end
    PersistStickies(entry)
    HideStickyMenu()
    if Theme() and Theme().PlayUISound then Theme().PlayUISound("paperTear") end
    Blackacre.Chronicle.UI.RenderSpread()
end

local function BuildStickyMenu()
    -- Pop-out menu removed (E0): lock/delete live on the scrap itself.
    if Book.journal and Book.journal.stickyMenu then
        Book.journal.stickyMenu:Hide()
    end
end

local function ToggleStickyRightClick(card, entry, note)
    -- Right-click still toggles lock without a floating menu
    if card._baEditOpen then
        if card.box then note.text = card.box:GetText() or note.text end
        SaveStickyGeometry(card)
        ApplyStickyLocked(card, true)
        PersistStickies(entry)
        ShowStickyActionRow(card, false)
        if Theme() and Theme().PlayUISound then Theme().PlayUISound("pinSoft") end
        return
    end
    ApplyStickyLocked(card, false)
    ShowStickyActionRow(card, true)
    if card.box then card.box:SetFocus() end
end

--- Freeform sticky scrap (Spellbook page fill); menu icon TR; resize offline icon BR.
--- Cards are pooled: built once, then re-bound to a note each render. Every
--- handler reads card._entry / card._note so a reused card follows its note.
local function StickyBeginDrag(self)
    local card = self._baCard or self
    HideStickyMenu()
    card:StartMoving()
end

local function StickyEndDrag(self)
    local card = self._baCard or self
    card:StopMovingOrSizing()
    local note, entry = card._note, card._entry
    if not note then return end
    local p = card:GetParent()
    if p and p ~= GetScrap() then
        local pl, pt = p:GetLeft(), p:GetTop()
        local cl, ct = card:GetLeft(), card:GetTop()
        if pl and pt and cl and ct then
            note.x = cl - pl
            note.y = ct - pt
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", p, "TOPLEFT", note.x, note.y)
        end
    end
    SaveStickyGeometry(card)
    PersistStickies(entry)
end

local function StickyHeader_OnClick(self, button)
    local card = self._baCard
    if button == "RightButton" and card._note then
        ToggleStickyRightClick(card, card._entry, card._note)
    end
end

local function StickyDelete_OnClick(self)
    local card = self._baCard
    if card._note then DeleteStickyNote(card._entry, card._note) end
end

local function StickyBox_OnEscape(self)
    self:ClearFocus()
end

local function StickyBox_OnFocusLost(self)
    local card = self._baCard
    if not card._note then return end
    card._note.text = self:GetText() or ""
    PersistStickies(card._entry)
end

local function StickyBox_OnMouseUp(self, button)
    local card = self._baCard
    if button == "RightButton" and card._note then
        ToggleStickyRightClick(card, card._entry, card._note)
    end
end

-- Resize: grey unable cursor idle, gold size cursor while dragging. Always shown.
local function StickyResize_OnUpdate(self)
    if not self.isResizing then
        StopStickyResize(self)
        return
    end
    local scale = self:GetEffectiveScale() or 1
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    local left, top = self:GetLeft(), self:GetTop()
    if not left or not top then return end
    local nw = math.max(100, math.min(280, cx - left))
    local nh = math.max(60, math.min(220, top - cy))
    self:SetSize(nw, nh)
    if self._note then self._note.w, self._note.h = nw, nh end
end

local function Grip_OnEnter(self) SetResizeGripLook(self, true) end

local function Grip_OnLeave(self)
    local card = self._baCard
    if card.isResizing or card._baGripHeld then return end
    SetResizeGripLook(self, false)
end

local function Grip_OnMouseDown(self)
    self._baCard._baGripHeld = true
    SetResizeGripLook(self, true)
end

local function Grip_OnMouseUp(self)
    self._baCard._baGripHeld = false
    if not self:IsMouseOver() then SetResizeGripLook(self, false) end
end

local function Grip_OnDragStart(self)
    local card = self._baCard
    HideStickyMenu()
    card.isResizing = true
    SetResizeGripLook(self, true)
    card:SetScript("OnUpdate", StickyResize_OnUpdate)
end

local function Grip_OnDragStop(self)
    local card = self._baCard
    card._baGripHeld = false
    StopStickyResize(card)
    if self:IsMouseOver() then SetResizeGripLook(self, true) end
    SaveStickyGeometry(card)
    PersistStickies(card._entry)
end

local function BuildStickyCard(parent)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetClampedToScreen(false)
    -- adventureguide-pane-small; keep default 150×90, still resizable.
    if card.SetBackdrop then card:SetBackdrop(nil) end
    local pane = card:CreateTexture(nil, "BACKGROUND")
    pane:SetAllPoints(card)
    if not TryAtlas(pane, "adventureguide-pane-small", false) then
        pane:SetColorTexture(0.97, 0.93, 0.82, 0.95)
    end
    card.pane = pane
    card:EnableMouse(true)
    card:SetMovable(true)
    card:RegisterForDrag("LeftButton")
    card._baIsSticky = true
    card:SetScript("OnDragStart", StickyBeginDrag)
    card:SetScript("OnDragStop", StickyEndDrag)

    local header = CreateFrame("Button", nil, card)
    header._baCard = card
    header:SetPoint("TOPLEFT", 3, -3)
    header:SetPoint("TOPRIGHT", -32, -3)
    header:SetHeight(22)
    header:RegisterForClicks("RightButtonUp")
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", StickyBeginDrag)
    header:SetScript("OnDragStop", StickyEndDrag)
    header:SetScript("OnClick", StickyHeader_OnClick)
    card.header = header

    local deleteBtn = CreateFrame("Button", nil, card)
    deleteBtn._baCard = card
    deleteBtn:SetSize(28, 28)
    deleteBtn:SetPoint("TOPRIGHT", -1, -1)
    deleteBtn:EnableMouse(true)
    deleteBtn:RegisterForClicks("LeftButtonUp")
    if deleteBtn.SetNormalAtlas then
        pcall(deleteBtn.SetNormalAtlas, deleteBtn, "128-RedButton-Delete")
        if deleteBtn.SetPushedAtlas then
            pcall(deleteBtn.SetPushedAtlas, deleteBtn, "128-RedButton-Delete-Pressed")
        end
        if deleteBtn.SetHighlightAtlas then
            pcall(deleteBtn.SetHighlightAtlas, deleteBtn, "128-RedButton-Delete-Highlight")
        end
    else
        local n = deleteBtn:CreateTexture(nil, "ARTWORK")
        n:SetAllPoints()
        TryAtlas(n, "128-RedButton-Delete", false)
        deleteBtn:SetNormalTexture(n)
        local p = deleteBtn:CreateTexture(nil, "ARTWORK")
        p:SetAllPoints()
        TryAtlas(p, "128-RedButton-Delete-Pressed", false)
        deleteBtn:SetPushedTexture(p)
        local h = deleteBtn:CreateTexture(nil, "HIGHLIGHT")
        h:SetAllPoints()
        TryAtlas(h, "128-RedButton-Delete-Highlight", false)
        deleteBtn:SetHighlightTexture(h)
    end
    deleteBtn:SetScript("OnClick", StickyDelete_OnClick)
    card.deleteBtn = deleteBtn

    local status = header:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontDisableSmall")
    status:SetPoint("LEFT", 4, 0)
    status:SetPoint("RIGHT", -4, 0)
    status:SetJustifyH("LEFT")
    status:SetText("")
    card.status = status

    local box = CreateFrame("EditBox", nil, card)
    box._baCard = card
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetPoint("TOPLEFT", 8, -30)
    box:SetPoint("BOTTOMRIGHT", -28, 26)
    box:SetTextInsets(2, 2, 2, 2)
    box:SetScript("OnEscapePressed", StickyBox_OnEscape)
    box:SetScript("OnEditFocusLost", StickyBox_OnFocusLost)
    box:SetScript("OnMouseUp", StickyBox_OnMouseUp)
    card.box = box

    local grip = CreateFrame("Button", nil, card)
    grip._baCard = card
    grip:SetSize(24, 24)
    grip:SetPoint("BOTTOMRIGHT", 0, 0)
    grip:EnableMouse(true)
    grip.icon = grip:CreateTexture(nil, "ARTWORK")
    grip.icon:SetAllPoints()
    grip:SetScript("OnEnter", Grip_OnEnter)
    grip:SetScript("OnLeave", Grip_OnLeave)
    grip:SetScript("OnMouseDown", Grip_OnMouseDown)
    grip:SetScript("OnMouseUp", Grip_OnMouseUp)
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", Grip_OnDragStart)
    grip:SetScript("OnDragStop", Grip_OnDragStop)
    card.resizeGrip = grip
    return card
end

-- Save and detach before the card goes back to the pool (ClearLeaf calls it).
local function RetireSticky(card)
    if card.box:HasFocus() then card.box:ClearFocus() end -- saves via OnEditFocusLost
    StopStickyResize(card)
    card._baGripHeld = false
end

-- A note sits 10 levels above its leaf, so the page's text (leaf + 1..2)
-- stays under it.
local function SetStickyLevels(card, parent)
    local level = (parent:GetFrameLevel() or 1) + 10
    card:SetFrameLevel(level)
    card.header:SetFrameLevel(level + 1)
    card.box:SetFrameLevel(level + 1)
    card.deleteBtn:SetFrameLevel(level + 8)
    card.resizeGrip:SetFrameLevel(level + 8)
end

local function BindStickyCard(card, parent, entry, note, index)
    note.w = tonumber(note.w) or 150
    note.h = tonumber(note.h) or 90
    note.x = tonumber(note.x) or (16 + ((index - 1) % 2) * 18)
    note.y = tonumber(note.y) or (-70 - (index - 1) * 22)
    if note.pinned == nil then note.pinned = true end

    card._note = note
    card._entry = entry
    card._baEditOpen = false
    card._baActionsOpen = false
    card:SetSize(note.w, note.h)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", note.x, note.y)
    -- Levels are set every time, not just at build: a reused card must sit
    -- above this leaf's page text, or the page's text box takes its clicks.
    SetStickyLevels(card, parent)
    card.resizeGrip:Show()
    SetResizeGripLook(card.resizeGrip, false)

    local box = card.box
    local noteText = note.text or ""
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.SanitizeBodyText then
        noteText = Blackacre.UI.Theme.SanitizeBodyText(noteText)
    end
    box:SetText(noteText)
    box:SetTextColor(0.12, 0.1, 0.05, 1)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.ApplyReadableBodyFont then
        Blackacre.UI.Theme.ApplyReadableBodyFont(box, 0)
    else
        box:SetFontObject(GameFontHighlightSmall)
    end

    ApplyStickyLocked(card, note.pinned == true)
    return card
end

--- Stickies for this entry on this leaf (filter by note.leafSide when set).
local function RenderStickyNotes(pageLeaf, entry, side)
    HideStickyMenu()
    if not pageLeaf or not entry then return end
    local notes = EnsureStickyNotes(entry)
    local n = 0
    for i = 1, #notes do
        local note = notes[i]
        -- Legacy notes without leafSide default to left leaf
        local noteSide = note.leafSide or "left"
        if noteSide == side then
            n = n + 1
            local card = AcquireKid("sticky", pageLeaf, BuildStickyCard)
            BindStickyCard(card, pageLeaf, entry, note, n)
        end
    end
end

local function EntryOnLeafSide(side)
    local s = Book.CurrentSpread()
    if not s or (side ~= "left" and side ~= "right") then return nil, nil end
    local leaf = (side == "left") and s.left or s.right
    if leaf and leaf.kind == "entry" and leaf.entry then
        return leaf.entry, side, leaf
    end
    return nil, side
end

local pinModeActive = false
local pinModeFrame

local function EndPinMode()
    pinModeActive = false
    if pinModeFrame then pinModeFrame:Hide() end
    if ResetCursor then ResetCursor() end
end

--- Place scrap on leaf; if relX/relY given, top-right of scrap anchors there (parent TOPLEFT space).
local function AddStickyToLeaf(side, relX, relY)
    local entry, resolvedSide = EntryOnLeafSide(side)
    if not entry then return false end
    local notes = EnsureStickyNotes(entry)
    local w, h = 150, 90
    local x, y
    if relX and relY then
        -- TOPRIGHT of note at click: TOPLEFT = clickX - w, clickY
        x = relX - w
        y = relY
    end
    local note = {
        id = (Blackacre.NewID and Blackacre.NewID()) or (tostring(time()) .. "-" .. math.random(1000, 9999)),
        text = "",
        x = x or (20 + (#notes % 3) * 12),
        y = y or (-50 - #notes * 16),
        w = w,
        h = h,
        pinned = false, -- a new note opens ready to write in; right-click locks it
        createdAt = time(),
        leafSide = resolvedSide,
    }
    notes[#notes + 1] = note
    PersistStickies(entry)
    if Theme() and Theme().PlayUISound then Theme().PlayUISound("pinSoft") end
    Blackacre.Chronicle.UI.RenderSpread()
    local host = (resolvedSide == "left") and Book.journal.leftHost or Book.journal.rightHost
    local kids = host and host._baKids
    if kids then
        for i = 1, #kids do
            if kids[i]._note == note then
                kids[i].box:SetFocus()
                break
            end
        end
    end
    return true
end

function Blackacre.Chronicle.UI.BeginPinMode()
    Blackacre.Chronicle.UI.EnsureBuilt()
    pinModeActive = true
    if not pinModeFrame then
        pinModeFrame = CreateFrame("Frame", "BlackacrePinModeOverlay", UIParent)
        pinModeFrame:SetAllPoints(UIParent)
        pinModeFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        pinModeFrame:EnableMouse(true)
        local pinCursor = (Theme() and Theme().Textures and (Theme().Textures.mapPinCursor or Theme().Textures.mapPinCursorCross))
            or "Interface\\Cursor\\MapPinCursor"
        -- The client resets the cursor every frame while this overlay is shown. No pcall on that path.
        pinModeFrame:SetScript("OnUpdate", function()
            if pinModeActive and SetCursor then
                SetCursor(pinCursor)
            end
        end)
        pinModeFrame:SetScript("OnMouseUp", function(_, button)
            if button == "RightButton" then
                EndPinMode()
                return
            end
            if button ~= "LeftButton" then return end
            -- Hit-test leaves under cursor
            local left = Book.journal and Book.journal.leftHost
            local right = Book.journal and Book.journal.rightHost
            local scale = UIParent:GetEffectiveScale() or 1
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            local function tryHost(host, side)
                if not host or not host:IsVisible() then return false end
                local l, r, t, b = host:GetLeft(), host:GetRight(), host:GetTop(), host:GetBottom()
                if not l or not r or not t or not b then return false end
                if cx >= l and cx <= r and cy >= b and cy <= t then
                    local relX = cx - l
                    local relY = cy - t -- negative below top
                    if AddStickyToLeaf(side, relX, relY) then
                        EndPinMode()
                        return true
                    end
                end
                return false
            end
            if not tryHost(left, "left") then
                tryHost(right, "right")
            end
            EndPinMode()
        end)
        pinModeFrame:EnableKeyboard(true)
        pinModeFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                EndPinMode()
                if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
            elseif self.SetPropagateKeyboardInput then
                self:SetPropagateKeyboardInput(true)
            end
        end)
    end
    pinModeFrame:Show()
end

local function HideAddNoteMenu()
    if Book.journal and Book.journal.addNoteMenu then
        Book.journal.addNoteMenu:Hide()
    end
end

--- Cursor popup: Add scrap note? / Bookmark (un)bookmark this page / Cancel.
local function ShowAddNoteMenuAtCursor(side)
    local entry, _, leaf = EntryOnLeafSide(side)
    if not entry or not leaf then return end -- TOC / blank: do nothing, no toast

    if not Book.journal.addNoteMenu then
        local m = CreateFrame("Frame", "BlackacreAddNoteMenu", UIParent, "BackdropTemplate")
        m:SetSize(150, 90)
        m:SetFrameStrata("FULLSCREEN_DIALOG")
        if Theme() and Theme().ApplyChromeMenuFrame then
            Theme().ApplyChromeMenuFrame(m)
        end
        m:EnableMouse(true)
        m:Hide()
        local addBtn = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
        addBtn:SetHeight(22)
        addBtn:SetPoint("TOP", 0, -8)
        addBtn:SetText("Add scrap note")
        FitButtonWidth(addBtn, 130)
        m.addBtn = addBtn
        local bookmarkBtn = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
        bookmarkBtn:SetHeight(22)
        bookmarkBtn:SetPoint("TOP", addBtn, "BOTTOM", 0, -6)
        m.bookmarkBtn = bookmarkBtn
        local cancelBtn = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
        cancelBtn:SetHeight(22)
        cancelBtn:SetPoint("TOP", bookmarkBtn, "BOTTOM", 0, -6)
        cancelBtn:SetText("Cancel")
        FitButtonWidth(cancelBtn, 130)
        cancelBtn:SetScript("OnClick", function() m:Hide() end)
        m.cancelBtn = cancelBtn
        Book.journal.addNoteMenu = m
    end

    local m = Book.journal.addNoteMenu
    m._baSide = side
    m.addBtn:SetScript("OnClick", function()
        AddStickyToLeaf(m._baSide)
        m:Hide()
    end)

    -- Bookmarks this page (this leaf), not the whole entry.
    m.bookmarkBtn:SetText(Book.IsPageBookmarked(entry, leaf.part, leaf.lastPart) and "Remove bookmark" or "Bookmark page")
    FitButtonWidth(m.bookmarkBtn, 130)
    m.bookmarkBtn:SetScript("OnClick", function()
        m:Hide()
        Book.ToggleBookmark(entry, leaf.part, leaf.lastPart)
    end)

    local widest = math.max(m.addBtn:GetWidth(), m.bookmarkBtn:GetWidth(), m.cancelBtn:GetWidth())
    m:SetWidth(widest + 20)

    local scale = UIParent:GetEffectiveScale() or 1
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    m:ClearAllPoints()
    m:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 4, y - 4)
    m:Show()
end

-- The sticky note under the cursor on this leaf, found by position rather
-- than by which frame the client says is on top. If the page's text box ever
-- ends up above a note, clicks on the note still reach the note.
local function StickyUnderCursor(host)
    local kids = host and host._baKids
    if not kids then return nil end
    for i = #kids, 1, -1 do
        local k = kids[i]
        if k._baPool == "sticky" and k:IsShown() and k:IsMouseOver() then return k end
    end
    return nil
end

-- A click that landed on a sticky note, whichever page frame received it.
-- Right: lock/unlock the note. Left: write in it (when unlocked).
-- Returns true when the click was the note's.
local function RouteClickToSticky(host, button, receiver)
    local card = StickyUnderCursor(host)
    if not card or not card._note then return false end
    if button == "RightButton" then
        ToggleStickyRightClick(card, card._entry, card._note)
    elseif card._baEditOpen then
        card.box:SetFocus()
    elseif receiver and receiver.ClearFocus then
        receiver:ClearFocus() -- clicked a locked note: don't start typing on the page
    end
    return true
end

local function OnLeafRightClick(host, side, button)
    if button ~= "RightButton" then return end
    HideAddNoteMenu()
    if RouteClickToSticky(host, button) then return end
    ShowAddNoteMenuAtCursor(side)
end

-- Item 5: left-clicking anywhere on an editable page (margins, below the
-- text, the title gap) puts the cursor in that page's body, at the end.
local function FocusLeafBody(host)
    local parts = Book.journal and Book.journal._baBodyParts
    if not parts then return end
    for i = 1, #parts do
        local box = parts[i]
        if box._baLeafHost == host and box:IsEnabled() then
            box:SetFocus()
            box:SetCursorPosition(#(box:GetText() or ""))
            return
        end
    end
end

-- Shared handler (no per-render closure); side is read off the leaf.
local function Leaf_OnMouseUp(self, button)
    if button == "LeftButton" then
        if not RouteClickToSticky(self, button) then FocusLeafBody(self) end
    else
        OnLeafRightClick(self, self._baLeafSide, button)
    end
end

--- Wire leaf + its children so right page (covered by EditBox) still gets right-click.
local function WireLeafRightClickAddNote(host, side)
    if not host then return end
    host._baLeafSide = side
    host:EnableMouse(true)
    host:SetScript("OnMouseUp", Leaf_OnMouseUp)
end

-- What UI_Chronology.lua calls back into.
Book.RetireSticky = RetireSticky
Book.HideStickyMenu = HideStickyMenu
Book.BuildStickyMenu = BuildStickyMenu
Book.SetStickyLevels = SetStickyLevels
Book.RenderStickyNotes = RenderStickyNotes
Book.EndPinMode = EndPinMode
Book.HideAddNoteMenu = HideAddNoteMenu
Book.RouteClickToSticky = RouteClickToSticky
Book.OnLeafRightClick = OnLeafRightClick
Book.WireLeafRightClickAddNote = WireLeafRightClickAddNote
