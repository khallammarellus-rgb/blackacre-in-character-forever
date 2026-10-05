-- In Character Forever: Journal - Quest Index

Blackacre = Blackacre or {}
Blackacre.QuestIndex = {}

local ipairs, pairs, format = ipairs, pairs, string.format
local CreateFrame, GameTooltip = CreateFrame, GameTooltip

local ROW_H = 18
local LIST_W = 290
local INDENT = 22      -- child rows
local LINE_X = 11      -- tree line column (center of the +/- box)
local HEADER_H = 30     -- clean top bar
local TOOLBAR_H = 24    -- Filter + collapse-arrow row above the list
local FOOTER_H = 30     -- Import row (left) / page tools row (right)
local PAGE_PAD_X = 26   -- keeps parchment text off the corner/edge art
local PAGE_PAD_TOP = 24
local PAGE_PAD_BOTTOM = 16
local PAGER_ROW_H = 30  -- reserved strip at the parchment's own bottom for Q10F

local frame, list, detail
local rows = {}        -- pooled row buttons
local items = {}       -- flattened visible rows, rebuilt on refresh
local itemPool = {}    -- reused row descriptors
local expanded = {}    -- chain key -> true while open (this session)
local selectedId
local pageIndex = 1
local pages = {}       -- heading, text, heading, text ...
local underway = {}
local chainMembers, chainLast = {}, {}
local firstShow = true

local function Color(name)
    return Blackacre.UI.Theme.Colors[name]
end

local function Ink(fs, small)
    fs:SetFontObject(small and BlackacreFont_GameFontHighlightSmall or BlackacreFont_GameFontHighlight)
    local c = Color("ink")
    fs:SetTextColor(c[1], c[2], c[3])
end

local function Wipe(t)
    for k in pairs(t) do t[k] = nil end
end

---------------------------------------------------------------------------
-- Filters (Completed / In Progress / Imported), persisted per character
---------------------------------------------------------------------------

local function GetFilters()
    local s = Blackacre.CharDB.settings
    if not s then return {} end
    s.questIndexFilters = s.questIndexFilters or {}
    return s.questIndexFilters
end

-- Absent/nil means on; only an explicit false turns a category off.
local function FilterOn(filters, key)
    return filters[key] ~= false
end

---------------------------------------------------------------------------
-- Build the visible list
---------------------------------------------------------------------------

local function AddItem(kind, rec, extra)
    local n = #items + 1
    local it = itemPool[n]
    if not it then it = {}; itemPool[n] = it end
    items[n] = it
    it.kind, it.rec, it.chain, it.count, it.last, it.label = kind, rec, nil, nil, nil, nil
    if extra then
        for k, v in pairs(extra) do it[k] = v end
    end
    return it
end

local function BuildItems()
    for i = #items, 1, -1 do items[i] = nil end
    local order = Blackacre.QuestLog.CompletedOrder()
    local filters = GetFilters()

    -- Chains: collect completed members in completion order.
    for _, m in pairs(chainMembers) do Wipe(m) end
    Wipe(chainLast)
    for i, id in ipairs(order) do
        local rec = Blackacre.QuestLog.Get(id)
        if rec and rec.chain then
            local m = chainMembers[rec.chain]
            if not m then m = {}; chainMembers[rec.chain] = m end
            m[#m + 1] = rec
            chainLast[rec.chain] = i
        end
    end

    AddItem("section", nil, { label = "Completed" })
    local any = false
    local wantCompleted, wantImported = FilterOn(filters, "completed"), FilterOn(filters, "imported")
    for i, id in ipairs(order) do
        local rec = Blackacre.QuestLog.Get(id)
        if rec and ((rec.imported and wantImported) or (not rec.imported and wantCompleted)) then
            local m = rec.chain and chainMembers[rec.chain]
            if m and #m > 1 then
                -- The chain appears once, where its final quest was finished.
                if chainLast[rec.chain] == i then
                    any = true
                    AddItem("header", rec, { chain = rec.chain, count = #m })
                    if expanded[rec.chain] then
                        for j = 1, #m - 1 do
                            AddItem("child", m[j], { last = (j == #m - 1) })
                        end
                    end
                end
            else
                any = true
                AddItem("leaf", rec)
            end
        end
    end
    if not any then
        AddItem("empty", nil, { label = "No quests match your filters." })
    end

    if FilterOn(filters, "inProgress") then
        Blackacre.QuestLog.Underway(underway)
        if #underway > 0 then
            AddItem("section", nil, { label = "In Progress" })
            for _, rec in ipairs(underway) do
                AddItem("leaf", rec)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Rows
---------------------------------------------------------------------------

local Refresh
local SelectQuest

local function RowClick(self)
    local it = self.item
    if it and it.rec then SelectQuest(it.rec.id) end
end

local function ToggleClick(self)
    local row = self:GetParent()
    local it = row.item
    if it and it.chain then
        expanded[it.chain] = not expanded[it.chain]
        Refresh()
    end
end

local function RowEnter(self)
    local it = self.item
    if not (it and it.rec) then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(it.rec.title)
    if it.rec.imported then
        GameTooltip:AddLine("Finished before this journal", 0.8, 0.8, 0.8)
    elseif it.rec.completedAt then
        GameTooltip:AddLine("Completed " .. Blackacre.QuestLog.StampText(it.rec.stamp), 0.8, 0.8, 0.8)
    else
        GameTooltip:AddLine("In Progress", 0.8, 0.8, 0.8)
    end
    if it.kind == "header" then
        GameTooltip:AddLine((it.count - 1) .. " earlier quest(s) in this chain", 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
end

-- TAV-style zebra stripe: alternating black/grey bands under the rows,
-- sitting behind row.hl (sublevel -1) so the gold selection highlight stays on top.
local ZEBRA_DARK = { 0, 0, 0, 0.35 }
local ZEBRA_LIGHT = { 0.35, 0.35, 0.37, 0.22 }

local function MakeRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    local ink = Color("ink")

    row.zebra = row:CreateTexture(nil, "BACKGROUND", nil, -1)
    row.zebra:SetAllPoints()

    row.hl = row:CreateTexture(nil, "BACKGROUND")
    row.hl:SetAllPoints()
    local g = Color("highlight")
    row.hl:SetColorTexture(g[1], g[2], g[3], 0.18)
    row.hl:Hide()

    -- Tree lines (child rows and open headers).
    row.vLine = row:CreateTexture(nil, "ARTWORK")
    row.vLine:SetColorTexture(ink[1], ink[2], ink[3], 0.45)
    row.vLine:SetWidth(1)
    row.hLine = row:CreateTexture(nil, "ARTWORK")
    row.hLine:SetColorTexture(ink[1], ink[2], ink[3], 0.45)
    row.hLine:SetHeight(1)

    -- The +/- box for chain headers.
    row.toggle = CreateFrame("Button", nil, row)
    row.toggle:SetSize(14, 14)
    row.toggle:SetPoint("CENTER", row, "LEFT", LINE_X, 0)
    local box = row.toggle:CreateTexture(nil, "BACKGROUND")
    box:SetAllPoints()
    box:SetColorTexture(ink[1], ink[2], ink[3], 0.55)
    local inner = row.toggle:CreateTexture(nil, "BORDER")
    inner:SetPoint("TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", -1, 1)
    local p = Color("parchment")
    inner:SetColorTexture(p[1], p[2], p[3], 1)
    row.toggle.sign = row.toggle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.toggle.sign:SetPoint("CENTER", 0, 1)
    row.toggle.sign:SetTextColor(ink[1], ink[2], ink[3])
    row.toggle:SetScript("OnClick", ToggleClick)

    row.label = row:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontHighlightSmall")
    row.label:SetPoint("RIGHT", -4, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)

    row:SetScript("OnClick", RowClick)
    row:SetScript("OnEnter", RowEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
    return row
end

local function PaintRow(row, it)
    row.item = it
    row.vLine:Hide()
    row.hLine:Hide()
    row.toggle:Hide()
    row.label:ClearAllPoints()
    row.label:SetPoint("RIGHT", -4, 0)

    if it.kind == "section" then
        row.label:SetPoint("LEFT", 4, 0)
        row.label:SetFontObject(BlackacreFont_GameFontNormal)
        local g = Color("edge")
        row.label:SetTextColor(g[1], g[2], g[3])
        row.label:SetText(it.label)
        row:EnableMouse(false)
    elseif it.kind == "empty" then
        row.label:SetPoint("LEFT", INDENT, 0)
        Ink(row.label, true)
        row.label:SetText(it.label)
        row:EnableMouse(false)
    else
        row:EnableMouse(true)
        row.label:SetFontObject(BlackacreFont_GameFontHighlightSmall)
        row.label:SetTextColor(1, 1, 1)
        if it.kind == "header" then
            row.toggle:Show()
            row.toggle.sign:SetText(expanded[it.chain] and "-" or "+")
            row.label:SetPoint("LEFT", INDENT, 0)
            row.label:SetText(format("%s  |cff8a7a60(%d)|r", it.rec.title, it.count))
            if expanded[it.chain] then
                -- Line runs from under the box to the row's bottom edge.
                row.vLine:ClearAllPoints()
                row.vLine:SetPoint("TOP", row, "TOPLEFT", LINE_X, -(ROW_H / 2 + 7))
                row.vLine:SetPoint("BOTTOM", row, "BOTTOMLEFT", LINE_X, 0)
                row.vLine:Show()
            end
        elseif it.kind == "child" then
            -- │ through the row (└ on the last child), then a stub to the label.
            row.vLine:ClearAllPoints()
            row.vLine:SetPoint("TOP", row, "TOPLEFT", LINE_X, 0)
            row.vLine:SetPoint("BOTTOM", row, "BOTTOMLEFT", LINE_X, it.last and (ROW_H / 2) or 0)
            row.vLine:Show()
            row.hLine:ClearAllPoints()
            row.hLine:SetPoint("LEFT", row, "LEFT", LINE_X, 0)
            row.hLine:SetWidth(INDENT + 6 - LINE_X)
            row.hLine:Show()
            row.label:SetPoint("LEFT", INDENT + 10, 0)
            row.label:SetText(it.rec.title)
        else
            row.label:SetPoint("LEFT", INDENT, 0)
            row.label:SetText(it.rec.title)
        end
        if not it.rec.completedAt then
            row.label:SetTextColor(1, 1, 1, 0.6)
        end
    end
    if it.rec and it.rec.id == selectedId then row.hl:Show() else row.hl:Hide() end
end

local function RenderList()
    local content = list.content
    for i, it in ipairs(items) do
        local row = rows[i]
        if not row then
            row = MakeRow(content)
            rows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
        local z = (i % 2 == 0) and ZEBRA_LIGHT or ZEBRA_DARK
        row.zebra:SetColorTexture(z[1], z[2], z[3], z[4])
        PaintRow(row, it)
        row:Show()
    end
    for i = #items + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(1, #items * ROW_H))
    Blackacre.UI.Theme.UpdateProportionalScrollThumb(list.scroll, content, 20)
end

---------------------------------------------------------------------------
-- Detail (original text, paged)
---------------------------------------------------------------------------

-- Title/meta/heading/body all live inside the scroll child now (so the
-- scrollbar spans the parchment from its real top to its real bottom,
-- instead of starting partway down below a fixed header). Height is the
-- span from the top of the content to the bottom of the body text.
local function ResizeTextHost()
    local host = detail.textHost
    local top, bottom = host:GetTop(), detail.body:GetBottom()
    if top and bottom then
        host:SetHeight(math.max(1, top - bottom + 10))
    end
end

local function RenderDetail()
    local rec = selectedId and Blackacre.QuestLog.Get(selectedId)
    if not rec then
        detail.title:SetText("Quest Index")
        detail.meta:SetText("Choose a quest from your history.")
        detail.heading:SetText("")
        detail.body:SetText("")
        detail.pager:Hide()
        detail.logBtn:Hide()
        detail.openBtn:Hide()
        ResizeTextHost()
        return
    end

    detail.title:SetText(rec.title)
    local meta
    if rec.imported then
        meta = "Finished before this journal (placed by level" .. (rec.level and (", level " .. rec.level) or "") .. ")"
    else
        meta = rec.completedAt and ("Completed " .. Blackacre.QuestLog.StampText(rec.stamp)) or "In Progress"
    end
    if rec.zone and rec.zone ~= "" then meta = meta .. "  ·  " .. rec.zone end
    local giver = rec.giverEnd or rec.giver
    if giver then meta = meta .. "  ·  " .. giver end
    if rec.timesDone then meta = meta .. "  ·  done " .. rec.timesDone .. " times" end
    detail.meta:SetText(meta)

    Blackacre.QuestLog.Pages(rec, pages)
    local count = #pages / 2
    if count == 0 then
        detail.heading:SetText("")
        detail.body:SetText("No words were recorded for this quest. It was taken up before the Quest Index was keeping them.")
        detail.pager:Hide()
    else
        if pageIndex > count then pageIndex = count end
        if pageIndex < 1 then pageIndex = 1 end
        detail.heading:SetText(pages[pageIndex * 2 - 1])
        detail.body:SetText(pages[pageIndex * 2])
        detail.pageText:SetText(format("Page %d of %d", pageIndex, count))
        detail.prevBtn:SetEnabled(pageIndex > 1)
        detail.nextBtn:SetEnabled(pageIndex < count)
        detail.pager:Show()
    end
    ResizeTextHost()
    detail.scroll:SetVerticalScroll(0)

    local entry = Blackacre.QuestLog.GetEntry(rec.id)
    detail.logBtn:SetShown(rec.completedAt ~= nil and entry == nil and not rec.imported)
    detail.openBtn:SetShown(entry ~= nil)
end

function SelectQuest(questID)
    if selectedId ~= questID then pageIndex = 1 end
    selectedId = questID
    RenderList()
    RenderDetail()
end

function Refresh()
    if not (frame and frame:IsShown()) then return end
    BuildItems()
    RenderList()
    RenderDetail()
end

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------

local function SetListCollapsed(collapsed)
    local s = Blackacre.CharDB.settings
    if s then s.questIndexListHidden = collapsed or nil end
    list:SetShown(not collapsed)
    -- Filtering only matters while the list is visible; hiding it also
    -- clears the corner the arrow moves into when collapsed.
    frame.filterBtn:SetShown(not collapsed)
    detail:ClearAllPoints()
    -- Expanded: hang off the toolbar's corner (same X as the list's right
    -- edge, same Y as the top of the list column, above the toolbar row).
    detail:SetPoint("TOPLEFT", collapsed and frame.inset or frame.listToolbar,
        collapsed and "TOPLEFT" or "TOPRIGHT", collapsed and 0 or 10, 0)
    detail:SetPoint("BOTTOMRIGHT", frame.inset, "BOTTOMRIGHT", 0, 0)
    -- The arrow travels with the list: sits above the scrollbar when shown,
    -- slides to the far left edge (where the list went) when hidden, and
    -- points toward the action each time (right = "click to send it away",
    -- left = "click to bring it back").
    frame.collapseBtn:ClearAllPoints()
    if collapsed then
        frame.collapseBtn:SetPoint("TOPLEFT", frame.inset, "TOPLEFT", 4, -2)
    else
        frame.collapseBtn:SetPoint("TOPRIGHT", frame.listToolbar, "TOPRIGHT", -4, 0)
    end
    frame.collapseBtn.arrow:SetRotation(collapsed and math.pi or 0)
end

---------------------------------------------------------------------------
-- Filter popout (Completed / In Progress / Imported)
---------------------------------------------------------------------------

local filterMenu

local function BuildFilterMenu()
    if filterMenu then return filterMenu end
    local th = Blackacre.UI.Theme
    local m = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    m:SetSize(150, 100)
    th.ApplyChromeMenuFrame(m)
    m:SetFrameStrata("DIALOG")
    m:Hide()

    local function MakeCheck(label, key, y)
        local cb = CreateFrame("CheckButton", nil, m, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", 8, y)
        local text = cb:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontHighlightSmall")
        text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        text:SetText(label)
        -- GameFontHighlightSmall's own light color already reads on this
        -- popout's dark fill (ApplyChromeMenuFrame) — don't override to "ink".
        cb:SetScript("OnClick", function(self)
            local filters = GetFilters()
            if self:GetChecked() then
                filters[key] = nil
            else
                filters[key] = false
            end
            Refresh()
        end)
        return cb
    end

    m.completed = MakeCheck("Completed", "completed", -10)
    m.inProgress = MakeCheck("In Progress", "inProgress", -34)
    m.imported = MakeCheck("Imported", "imported", -58)
    filterMenu = m
    return m
end

local function ToggleFilterMenu(anchor)
    local m = BuildFilterMenu()
    if m:IsShown() then m:Hide(); return end
    local filters = GetFilters()
    m.completed:SetChecked(FilterOn(filters, "completed"))
    m.inProgress:SetChecked(FilterOn(filters, "inProgress"))
    m.imported:SetChecked(FilterOn(filters, "imported"))
    m:ClearAllPoints()
    m:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    m:Show()
end

local function Button(parent, text, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 22)
    b:SetText(text)
    return b
end

local function Build()
    local th = Blackacre.UI.Theme
    frame = CreateFrame("Frame", "BlackacreQuestIndex", UIParent, "BackdropTemplate")
    frame:SetSize(786, 600)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    tinsert(UISpecialFrames, "BlackacreQuestIndex")
    Blackacre.UI.Focus.Register(frame)
    th.ApplyHeavyBronzeBase(frame)

    -- Clean top bar (TAV-style): a distinct strip instead of the title
    -- floating directly on the bronze base. Dragging still works anywhere
    -- over it since it's the whole `frame` that's EnableMouse+draggable.
    -- No boxed backdrop here — TAV's own title floats directly on the shell
    -- (its TitleContainer is a plain FontString host, no background/border);
    -- the metal border's own top edge is the header band.
    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetPoint("TOPLEFT", 6, -6)
    frame.header:SetPoint("TOPRIGHT", -6, -6)
    frame.header:SetHeight(HEADER_H)

    frame.title = frame.header:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalLarge")
    frame.title:SetPoint("CENTER", 0, 9)
    frame.title:SetText("Quest Index")
    th.GoldTitle(frame.title)
    do
        local path, size, flags = frame.title:GetFont()
        if path and size then
            frame.title:SetFont(path, math.max(8, size - 3), flags)
        end
    end

    -- UIPanelCloseButton's default OnClick hides self:GetParent() — since this
    -- button is parented to frame.header (for anchoring only), that hid the
    -- header strip, not the window. Explicit handler hides the real window.
    local close = CreateFrame("Button", nil, frame.header, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("RIGHT", -2, 6)
    close:SetScript("OnClick", function() frame:Hide() end)

    frame.inset = CreateFrame("Frame", nil, frame)
    frame.inset:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 8, -3)
    frame.inset:SetPoint("TOPRIGHT", frame.header, "BOTTOMRIGHT", -8, -3)

    -- Bottom band: Import (under the list) and the page/log tools (under the
    -- parchment) both sit here, below frame.inset, so the parchment gets its
    -- own clear bottom edge instead of buttons overlapping its art.
    frame.footer = CreateFrame("Frame", nil, frame)
    frame.footer:SetPoint("BOTTOMLEFT", 14, 14)
    frame.footer:SetPoint("BOTTOMRIGHT", -14, 14)
    frame.footer:SetHeight(FOOTER_H)
    frame.inset:SetPoint("BOTTOMLEFT", frame.footer, "TOPLEFT", 0, 6)
    frame.inset:SetPoint("BOTTOMRIGHT", frame.footer, "TOPRIGHT", 0, 6)

    -- List toolbar: Filter (left) and the collapse arrow (right, right above
    -- where the list's scrollbar starts).
    frame.listToolbar = CreateFrame("Frame", nil, frame.inset)
    frame.listToolbar:SetPoint("TOPLEFT", frame.inset, "TOPLEFT", 0, 0)
    frame.listToolbar:SetWidth(LIST_W)
    frame.listToolbar:SetHeight(TOOLBAR_H)

    frame.filterBtn = Button(frame.listToolbar, "Filter", 90)
    frame.filterBtn:SetPoint("LEFT", 0, 0)
    frame.filterBtn:SetScript("OnClick", function(self) ToggleFilterMenu(self) end)

    -- Simple red arrow toggle. Parented to frame.inset (not the toolbar) so
    -- it can travel: sits above the list when shown, slides to the far left
    -- (where the list went) when hidden, and travels back on re-expand.
    -- Tooltip carries the actual state ("Show Index" / "Hide Index").
    frame.collapseBtn = CreateFrame("Button", nil, frame.inset)
    frame.collapseBtn:SetSize(20, 20)
    frame.collapseBtn.arrow = frame.collapseBtn:CreateTexture(nil, "ARTWORK")
    frame.collapseBtn.arrow:SetAllPoints()
    th.TrySetAtlas(frame.collapseBtn.arrow, "bag-arrow", true)
    frame.collapseBtn.arrow:SetVertexColor(0.78, 0.14, 0.14)
    frame.collapseBtn:SetScript("OnClick", function()
        SetListCollapsed(list:IsShown())
    end)
    frame.collapseBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(list:IsShown() and "Hide Index" or "Show Index")
        GameTooltip:Show()
    end)
    frame.collapseBtn:SetScript("OnLeave", GameTooltip_Hide)

    -- History panel (left) — Quest Log frame chrome over the Journeys
    -- background, rotated tall (see ApplyQuestLogListPanel).
    list = CreateFrame("Frame", nil, frame.inset)
    list:SetPoint("TOPLEFT", frame.listToolbar, "BOTTOMLEFT", 0, -4)
    list:SetPoint("BOTTOMLEFT", frame.inset, "BOTTOMLEFT")
    list:SetWidth(LIST_W)
    th.ApplyQuestLogListPanel(list)
    list.scroll = CreateFrame("ScrollFrame", "BlackacreQuestIndexList", list, "UIPanelScrollFrameTemplate")
    list.scroll:SetPoint("TOPLEFT", 8, -8)
    list.scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    list.content = CreateFrame("Frame", nil, list.scroll)
    list.content:SetSize(LIST_W - 30, 1)
    list.scroll:SetScrollChild(list.content)

    -- Import earlier quests — below the list, in the bottom band.
    frame.importBtn = Button(frame.footer, "Import Quests", 160)
    frame.importBtn:SetPoint("LEFT", frame.footer, "LEFT", 0, 0)
    frame.importBtn:SetScript("OnClick", function(self)
        self:Disable()
        Blackacre.QuestLog.ImportCompleted(function() self:Enable() end)
    end)
    frame.importBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Import Quests")
        GameTooltip:AddLine("Import quests your character has completed before this add on was downloaded. It will add the name of the quest to your index but will not be able to log the quest text.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.importBtn:SetScript("OnLeave", GameTooltip_Hide)

    -- Quest text (right) — the Backstory parchment pop-out fill (applied once
    -- this panel has real anchors, at the end of Build; the fill math needs
    -- GetWidth()/GetHeight() to be the real panel size, not 0).
    detail = CreateFrame("Frame", nil, frame.inset)

    -- Title/meta/heading/body all live inside the scroll child so the
    -- scrollbar always spans from the parchment's real top to its real
    -- bottom (see ResizeTextHost), instead of starting partway down below
    -- a fixed header.
    detail.scroll = CreateFrame("ScrollFrame", "BlackacreQuestIndexText", detail, "UIPanelScrollFrameTemplate")
    detail.scroll:SetPoint("TOPLEFT", PAGE_PAD_X, -PAGE_PAD_TOP)
    detail.scroll:SetPoint("BOTTOMRIGHT", -(PAGE_PAD_X + 24), PAGE_PAD_BOTTOM + PAGER_ROW_H)
    local textHost = CreateFrame("Frame", nil, detail.scroll)
    textHost:SetSize(400, 1)
    detail.scroll:SetScrollChild(textHost)
    detail.textHost = textHost

    -- Blizzard's own Quest Log fonts: QuestTitleFont for headers, QuestFont
    -- for body text (Blizzard_UIPanels_Game QuestInfo.xml), all recolored
    -- black per the owner's request rather than each font's own default.
    detail.title = textHost:CreateFontString(nil, "OVERLAY")
    detail.title:SetPoint("TOPLEFT")
    detail.title:SetPoint("TOPRIGHT")
    detail.title:SetJustifyH("LEFT")
    detail.title:SetFontObject(BlackacreFont_QuestTitleFont)
    detail.title:SetTextColor(0, 0, 0)

    detail.meta = textHost:CreateFontString(nil, "OVERLAY")
    detail.meta:SetPoint("TOPLEFT", detail.title, "BOTTOMLEFT", 0, -6)
    detail.meta:SetPoint("TOPRIGHT", detail.title, "BOTTOMRIGHT", 0, -6)
    detail.meta:SetJustifyH("LEFT")
    detail.meta:SetFontObject(BlackacreFont_QuestFontNormalSmall)
    detail.meta:SetTextColor(0, 0, 0)

    detail.heading = textHost:CreateFontString(nil, "OVERLAY")
    detail.heading:SetPoint("TOPLEFT", detail.meta, "BOTTOMLEFT", 0, -14)
    detail.heading:SetPoint("TOPRIGHT", detail.meta, "BOTTOMRIGHT", 0, -14)
    detail.heading:SetJustifyH("LEFT")
    detail.heading:SetFontObject(BlackacreFont_QuestTitleFont)
    detail.heading:SetTextColor(0, 0, 0)

    detail.body = textHost:CreateFontString(nil, "OVERLAY")
    detail.body:SetPoint("TOPLEFT", detail.heading, "BOTTOMLEFT", 0, -10)
    detail.body:SetJustifyH("LEFT")
    detail.body:SetJustifyV("TOP")
    detail.body:SetSpacing(3)
    detail.body:SetFontObject(BlackacreFont_QuestFont)
    detail.body:SetTextColor(0, 0, 0)

    detail.scroll:SetScript("OnSizeChanged", function(_, w)
        textHost:SetWidth(w)
        detail.body:SetWidth(w - 4)
        ResizeTextHost()
    end)

    -- Page nav (Q10F) — centered at the parchment's own bottom, inside it,
    -- in the strip detail.scroll's bottom margin reserves above.
    detail.pager = CreateFrame("Frame", nil, detail)
    detail.pager:SetPoint("BOTTOM", 0, PAGE_PAD_BOTTOM)
    detail.pager:SetSize(260, 24)
    detail.prevBtn = Button(detail.pager, "< Prev", 70)
    detail.prevBtn:SetPoint("LEFT")
    detail.prevBtn:SetScript("OnClick", function() pageIndex = pageIndex - 1; RenderDetail() end)
    detail.pageText = detail.pager:CreateFontString(nil, "OVERLAY")
    detail.pageText:SetPoint("LEFT", detail.prevBtn, "RIGHT", 10, 0)
    detail.pageText:SetFontObject(BlackacreFont_QuestFontNormalSmall)
    detail.nextBtn = Button(detail.pager, "Next >", 70)
    detail.nextBtn:SetPoint("LEFT", detail.prevBtn, "RIGHT", 100, 0)
    detail.nextBtn:SetScript("OnClick", function() pageIndex = pageIndex + 1; RenderDetail() end)

    -- Log/chain tools — below the parchment, aligned under the detail column
    -- (its left edge tracks the list's right edge, same as `detail` itself).
    frame.footerRight = CreateFrame("Frame", nil, frame.footer)
    frame.footerRight:SetPoint("TOP", frame.footer, "TOP", 0, 0)
    frame.footerRight:SetPoint("BOTTOM", frame.footer, "BOTTOM", 0, 0)
    frame.footerRight:SetPoint("RIGHT", frame.footer, "RIGHT", 0, 0)
    frame.footerRight:SetPoint("LEFT", list, "RIGHT", 10, 0)

    detail.logBtn = Button(frame.footerRight, "Journal Quest", 130)
    detail.logBtn:SetPoint("RIGHT", 0, 0)
    detail.logBtn:SetScript("OnClick", function()
        if selectedId and Blackacre.QuestLog.LogToJournal(selectedId) then
            RenderDetail()
        end
    end)

    detail.openBtn = Button(frame.footerRight, "Open in journal", 130)
    detail.openBtn:SetPoint("RIGHT", 0, 0)
    detail.openBtn:SetScript("OnClick", function()
        local entry = selectedId and Blackacre.QuestLog.GetEntry(selectedId)
        if entry then
            Blackacre.TomeHub.Show()
            Blackacre.Chronicle.UI.OnNewEntry(entry)
        end
    end)

    frame:SetScript("OnShow", function()
        Refresh()
        if firstShow then
            firstShow = false
            -- Open on the most recent quest, at the bottom of the history.
            local order = Blackacre.QuestLog.CompletedOrder()
            if order[#order] then SelectQuest(order[#order]) end
            list.scroll:SetVerticalScroll(list.scroll:GetVerticalScrollRange())
        end
    end)

    local s = Blackacre.CharDB.settings
    SetListCollapsed(s and s.questIndexListHidden or false)
    th.ApplyParchmentPopupFill(detail)

    -- /ba skin labels (Q = Quest Index).
    local Tag = th.RegisterSkinRegion
    Tag(frame, "Q1", "S", 0, 200)
    Tag(frame.title, "Q2", "F")
    Tag(frame.importBtn, "Q3", "F")
    Tag(frame.collapseBtn, "Q4", "F")
    Tag(list, "Q5", "F")
    Tag(detail.title, "Q6", "F")
    Tag(detail.meta, "Q7", "F")
    Tag(detail.heading, "Q8", "F", 40, 0)
    Tag(detail.scroll, "Q9", "F")
    Tag(detail.pager, "Q10", "F")
    Tag(detail.logBtn, "Q11", "F")
    Tag(frame.filterBtn, "Q13", "F")
end

function Blackacre.QuestIndex.Show()
    if not frame then Build() end
    frame:Show()
end

function Blackacre.QuestIndex.Toggle()
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end

function Blackacre.QuestIndex.Refresh()
    Refresh()
end
