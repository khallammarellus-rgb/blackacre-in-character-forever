-- Traveler's Chronicle UI (flip-book TOC + entry leaves).
-- DBM hygiene: file-local helpers, Theme-owned paths, no tick OnUpdate except sticky resize.
Blackacre = Blackacre or {}
Blackacre.Chronicle = Blackacre.Chronicle or {}
Blackacre.Chronicle.UI = {}

-- Hot-path upvalues (DBM-Core style): direct register reads, not global lookups.
local type, ipairs, next, tostring, tonumber = type, ipairs, next, tostring, tonumber
local time, wipe = time, wipe
local CreateFrame, UIParent = CreateFrame, UIParent

local journal
local oldestFirst = true
local filterKind = nil
local searchText = ""
local presentationMode = false
local journalMode = false

local spreads = {}
local spreadIndex = 1
local totalLeaves = 0
local TOC_LINES_PER_PAGE = 10
local CHARS_PER_ENTRY_PAGE = 780
local TOC_TITLE_LINE_MAX = 23

local KIND_LABELS = {
    QUEST = "Prompt",
    QUESTLINE = "Road",
    META_QUEST = "Meta quest",
    META_ACHIEVEMENT = "Meta feat",
    FOS = "Feat of Strength",
    REPUTATION = "Standing",
    RENOWN = "Renown",
    ACHIEVEMENT = "Feat",
    TITLE = "Title",
    PROFESSION = "Craft",
    MANUAL = "Note",
    DEATH = "Death",
    AFTERLIFE = "Afterlife",
    ROADMAP = "Road",
    PVP = "Field",
    STICKY = "Sticky",
}

local function Theme()
    return Blackacre.UI and Blackacre.UI.Theme
end

local function KindLabel(kind)
    return KIND_LABELS[kind] or kind or "?"
end

--- Graphite pencil-lead body text (Theme.Colors.ink).
local function Graphite(fs)
    if not fs or not fs.SetTextColor then return end
    local th = Theme()
    local c = th and th.Colors and th.Colors.ink
    if c then
        fs:SetTextColor(c[1], c[2], c[3], 1)
    else
        fs:SetTextColor(0.20, 0.21, 0.23, 1)
    end
end

--- UIPanelButtonTemplate does not auto-fit its label -- a caption longer than
--- the fixed width you gave the button spills text past the button's own
--- cap/middle textures. Call after SetText so the button always grows to fit.
local function FitButtonWidth(btn, minW)
    minW = minW or 114
    local fs = btn.GetFontString and btn:GetFontString()
    local textW = fs and fs.GetStringWidth and fs:GetStringWidth() or 0
    btn:SetWidth(math.max(minW, math.ceil(textW) + 24))
end

local function TryAtlas(tex, name, useSize)
    if not tex or not name then return false end
    local th = Theme()
    if th and th.TrySetAtlas then
        return th.TrySetAtlas(tex, name, useSize and true or false)
    end
    if tex.SetAtlas then
        local ok = pcall(function() tex:SetAtlas(name, useSize and true or false) end)
        return ok and true or false
    end
    return false
end

local function TitleCapAtlases()
    local skin = Theme() and Theme().GetActiveSkin and Theme().GetActiveSkin()
    if skin and skin.tocTitleLeft then
        return skin.tocTitleLeft, skin.tocTitleMid, skin.tocTitleRight
    end
    return "AllianceFrame_Title-End-2", "_AllianceFrame_Title-Tile", "AllianceFrame_Title-End"
end

--- Set atlas by file + member UVs so a horizontal flip does not sample the whole sheet.
local function ApplyAtlasMember(tex, name, flipH)
    if not tex or not name then return false end
    local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
    local file = info and (info.filename or info.file)
    if file then
        tex:SetTexture(file)
        local l = info.leftTexCoord or info.left or 0
        local r = info.rightTexCoord or info.right or 1
        local t = info.topTexCoord or info.top or 0
        local b = info.bottomTexCoord or info.bottom or 1
        if flipH then
            tex:SetTexCoord(r, l, t, b)
        else
            tex:SetTexCoord(l, r, t, b)
        end
        return true
    end
    return false
end

local function FormatEntryYear(entry)
    local y = entry and (entry.yearKC or entry.yearADP)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.FormatFactionYear then
        return Blackacre.UI.Theme.FormatFactionYear(y)
    end
    return tostring(y or "")
end

--- Stable sort key + display label for TOC year sections (Alliance K.C. / Horde ADP).
local function EntryYearSection(entry)
    local raw = entry and (entry.yearKC or entry.yearADP)
    local n = tonumber(raw)
    if not n then
        return "undated", "Undated"
    end
    -- Stored values may be ADP or KC; normalize to ADP for sorting when possible
    local adp = n
    if n > 200 and Blackacre.YearCalendar and Blackacre.YearCalendar.FromKC then
        adp = Blackacre.YearCalendar.FromKC(n) or n
    end
    local label = FormatEntryYear(entry)
    if not label or label == "" or label == "?" then
        label = "Undated"
    end
    return tostring(adp), label, adp
end

--- Kinds allowed in the chronicle (no survival / encumbrance / skill spam / every-quest).
local function IsAllowedChronicleKind(kind)
    if kind == "SURVIVAL" or kind == "HC_MOUNT" or kind == "HC_FLY"
        or kind == "HC_ENCUMBRANCE" or kind == "PROFESSION" or kind == "QUEST" then
        return false
    end
    return true
end

local function GetEntryList()
    local raw = Blackacre.Chronicle.Store.List({
        kind = filterKind,
        search = searchText,
        oldestFirst = oldestFirst,
    })
    local list = {}
    for i = 1, #raw do
        if IsAllowedChronicleKind(raw[i].kind) then
            list[#list + 1] = raw[i]
        end
    end
    return list
end

local function ByCreatedAt(a, b)
    return (a.entry.createdAt or 0) < (b.entry.createdAt or 0)
end

--- Bookmarked slots: one "Bookmarked" heading, entries in the order they were
--- created (not reshuffled when bookmarked), then a divider before the
--- standard year-grouped TOC. Bookmarked entries still appear again in their
--- own year section below -- this is a quick-jump list, not a second inbox.
local function BuildBookmarkedSlots(list)
    local bookmarked = {}
    for j = 1, #list do
        if list[j].pinned then
            bookmarked[#bookmarked + 1] = { kind = "entry", entry = list[j], listIndex = j }
        end
    end
    if #bookmarked == 0 then
        return nil
    end
    table.sort(bookmarked, ByCreatedAt)
    local slots = { { kind = "year", label = "Bookmarked", yearKey = "__bookmarked__" } }
    for _, row in ipairs(bookmarked) do
        slots[#slots + 1] = row
    end
    slots[#slots + 1] = { kind = "divider" }
    return slots
end

--- TOC slots: year subheading then entries that share that year (sorted by year).
local function BuildTocSlots(list)
    local byKey = {}
    local order = {}
    for j = 1, #list do
        local e = list[j]
        local key, label, sortVal = EntryYearSection(e)
        if not byKey[key] then
            byKey[key] = {
                key = key,
                label = label,
                sortVal = sortVal or 999999,
                entries = {},
            }
            order[#order + 1] = byKey[key]
        end
        byKey[key].entries[#byKey[key].entries + 1] = { kind = "entry", entry = e, listIndex = j }
    end
    table.sort(order, function(a, b)
        if a.sortVal == b.sortVal then
            return tostring(a.key) < tostring(b.key)
        end
        if oldestFirst then
            return a.sortVal < b.sortVal
        end
        return a.sortVal > b.sortVal
    end)
    local slots = BuildBookmarkedSlots(list) or {}
    for _, g in ipairs(order) do
        slots[#slots + 1] = { kind = "year", label = g.label, yearKey = g.key }
        for _, row in ipairs(g.entries) do
            slots[#slots + 1] = row
        end
    end
    return slots
end

--- Open-book model: leaf = physical page; spread = left+right; flip = one spread.
--- Entry: title+meta+body on same leaf; long entries continue onto as many leaves as needed.

--- Fills `out` with the byte range of each leaf's slice of `body` as
--- start1, end1, start2, end2, ...  No leaf limit: long-form entries run
--- onto as many leaves as they need.  Editors save by splicing their slice
--- back into the full body at these offsets, so a leaf never overwrites
--- text it is not showing.  Whitespace between slices stays in the body.
local function SplitBodyForPages(body, out)
    wipe(out)
    local len = #body
    local start = 1
    while true do
        if len - start + 1 <= CHARS_PER_ENTRY_PAGE then
            out[#out + 1] = start
            out[#out + 1] = len
            return out
        end
        local cut = start + CHARS_PER_ENTRY_PAGE - 1
        -- Prefer break at whitespace so words stay whole
        local space = body:sub(start, cut):match(".*()%s")
        if space and space > CHARS_PER_ENTRY_PAGE * 0.5 then
            cut = start + space - 2
        end
        local lastInk = body:sub(start, cut):match("^.*()%S")
        out[#out + 1] = start
        out[#out + 1] = lastInk and (start + lastInk - 1) or (start - 1)
        local nextStart = body:find("%S", cut + 1)
        if not nextStart then
            return out
        end
        start = nextStart
    end
end

local splitScratch = {}

local BuildSpreads

-- Page turns and jumps reuse the laid-out book unless something it depends
-- on changed.  Rebuilding re-sorts, re-splits, and re-allocates every entry,
-- which used to happen on every single page turn.  Full refreshes
-- (RenderSpread without skipRebuild) pass force, so settings that change
-- labels, like the calendar, still show immediately.
local builtVersion, builtEntries, builtOldestFirst, builtFilter, builtSearch

local function RebuildSpreads(force)
    local store = Blackacre.Chronicle.Store
    local ver = store.Version and store.Version() or 0
    local entries = store.GetAll()
    if not force and spreads[1]
        and ver == builtVersion and entries == builtEntries
        and oldestFirst == builtOldestFirst and filterKind == builtFilter
        and searchText == builtSearch then
        return
    end
    builtVersion, builtEntries = ver, entries
    builtOldestFirst, builtFilter, builtSearch = oldestFirst, filterKind, searchText
    BuildSpreads()
end

function BuildSpreads()
    spreads = {}
    local list = GetEntryList()
    local leafSeq = {} -- ordered physical leaves
    local leafNum = 1

    -- --- TOC leaves (year sections + entry lines) ---
    local slots = BuildTocSlots(list)
    if #slots == 0 then
        leafSeq[#leafSeq + 1] = { kind = "toc", items = {}, heading = "Table of Contents", leafNum = leafNum }
        leafNum = leafNum + 1
    else
        local i = 1
        local tocIndex = 0
        while i <= #slots do
            local chunk = {}
            for j = i, math.min(i + TOC_LINES_PER_PAGE - 1, #slots) do
                chunk[#chunk + 1] = slots[j]
            end
            -- Avoid orphan year header as last line of a leaf (pull next entry if possible)
            if #chunk > 1 and chunk[#chunk].kind == "year" and (i + #chunk) <= #slots then
                -- leave header for next leaf
                chunk[#chunk] = nil
            end
            if #chunk == 0 then
                chunk[1] = slots[i]
            end
            tocIndex = tocIndex + 1
            leafSeq[#leafSeq + 1] = {
                kind = "toc",
                items = chunk,
                heading = (tocIndex == 1) and "Table of Contents" or "Contents (continued)",
                leafNum = leafNum,
            }
            leafNum = leafNum + 1
            i = i + #chunk
        end
    end

    -- --- Entry leaves: one per slice; pack sequentially ---
    for j = 1, #list do
        local e = list[j]
        local body = e.body or ""
        local ranges = SplitBodyForPages(body, splitScratch)
        local startLeaf = leafNum
        for r = 1, #ranges, 2 do
            local first = (r == 1)
            leafSeq[#leafSeq + 1] = {
                kind = "entry",
                entry = e,
                showTitle = first,
                showMeta = first,
                bodyPart = body:sub(ranges[r], ranges[r + 1]),
                sourceBody = body,
                segStart = ranges[r],
                segEnd = ranges[r + 1],
                isContinuation = not first,
                leafNum = leafNum,
            }
            leafNum = leafNum + 1
        end
        e._baLeafLeft = startLeaf
        e._baLeafRight = leafNum - 1
        e._baPageLabel = (startLeaf == leafNum - 1) and tostring(startLeaf)
            or string.format("%d–%d", startLeaf, leafNum - 1)
    end

    totalLeaves = math.max(0, leafNum - 1)

    -- Pair leaves into open-book spreads
    local li = 1
    while li <= #leafSeq do
        local left = leafSeq[li]
        local right = leafSeq[li + 1] or { kind = "blank", leafNum = (left.leafNum or li) + 1 }
        local L = left.leafNum or li
        local R = right.leafNum or (L + 1)
        local primary = nil
        if left.kind == "entry" and left.entry then
            primary = left.entry
        elseif right.kind == "entry" and right.entry then
            primary = right.entry
        end
        spreads[#spreads + 1] = {
            type = "open",
            left = left,
            right = right,
            leftNum = L,
            rightNum = R,
            entry = primary,
        }
        -- Mark start spread for every entry leaf that shows the title (left or right)
        if left.kind == "entry" and left.showTitle and left.entry then
            left.entry._baSpreadIndex = #spreads
        end
        if right.kind == "entry" and right.showTitle and right.entry then
            right.entry._baSpreadIndex = #spreads
        end
        li = li + 2
    end

    if #spreads == 0 then
        spreads[1] = {
            type = "open",
            left = { kind = "toc", items = {}, heading = "Table of Contents", leafNum = 1 },
            right = { kind = "blank", leafNum = 2 },
            leftNum = 1,
            rightNum = 2,
        }
        totalLeaves = 2
    end
end

--- Prefer titled entry on either leaf (open book can start an entry on the right page).
local function GetSpreadEntry(s)
    if not s then return nil end
    if s.left and s.left.kind == "entry" and s.left.entry and s.left.showTitle then
        return s.left.entry
    end
    if s.right and s.right.kind == "entry" and s.right.entry and s.right.showTitle then
        return s.right.entry
    end
    if s.entry then return s.entry end
    if s.left and s.left.kind == "entry" and s.left.entry then return s.left.entry end
    if s.right and s.right.kind == "entry" and s.right.entry then return s.right.entry end
    return nil
end

local function SpreadContainsEntryId(s, entryId)
    if not s or not entryId then return false, false end
    local isStart = false
    local found = false
    if s.left and s.left.kind == "entry" and s.left.entry and s.left.entry.id == entryId then
        found = true
        if s.left.showTitle then isStart = true end
    end
    if s.right and s.right.kind == "entry" and s.right.entry and s.right.entry.id == entryId then
        found = true
        if s.right.showTitle then isStart = true end
    end
    return found, isStart
end

--- Hidden scrap so discarded leaf kids never float on UIParent (was causing ghost stickies).
local function GetScrap()
    if not journal then return nil end
    if not journal._scrap then
        journal._scrap = CreateFrame("Frame", "BlackacreLeafScrap")
        journal._scrap:Hide()
    end
    return journal._scrap
end

-- Page editors are pooled: a spread re-render used to create a fresh EditBox
-- and ScrollFrame per leaf and strand the old ones on the scrap frame forever.
local titleEditPool = {}
local bodyScrollPool = {}

-- Detach a page editor from its entry before it is hidden.  Hiding a focused
-- EditBox fires OnEditFocusLost; with the entry still attached, a retired
-- continuation box could save only the half of the page that had already
-- been redrawn, truncating the rest.
local function RetirePageEdit(box)
    if not box then return end
    box._baEntry = nil
    box._baSource = nil
    box:SetScript("OnTextChanged", nil)
    box:SetScript("OnEditFocusLost", nil)
    box:ClearFocus()
end

local function ClearLeaf(leaf)
    if not leaf or not leaf._baKids then return end
    local scrap = GetScrap()
    for _, k in ipairs(leaf._baKids) do
        if k then
            if k._baPool == "title" then
                RetirePageEdit(k)
            elseif k._baPool == "bodyScroll" then
                RetirePageEdit(k._baEdit)
            end
            if k.isResizing then k.isResizing = false end
            -- FontStrings do not support SetScript (OnUpdate etc.) — only frames/buttons.
            local otype = k.GetObjectType and k:GetObjectType() or ""
            if otype ~= "FontString" and otype ~= "Texture" and k.SetScript then
                k:SetScript("OnUpdate", nil)
                k:SetScript("OnDragStart", nil)
                k:SetScript("OnDragStop", nil)
            end
            if otype ~= "FontString" and otype ~= "Texture" and k.EnableMouse then
                k:EnableMouse(false)
            end
            if k.Hide then k:Hide() end
            if k.ClearAllPoints then k:ClearAllPoints() end
            if k.SetParent then k:SetParent(scrap or nil) end
            if k.SetAlpha then k:SetAlpha(0) end
            if k._baPool == "title" then
                titleEditPool[#titleEditPool + 1] = k
            elseif k._baPool == "bodyScroll" then
                bodyScrollPool[#bodyScrollPool + 1] = k
            end
        end
    end
    wipe(leaf._baKids)
end

local function AddKid(leaf, kid)
    leaf._baKids = leaf._baKids or {}
    leaf._baKids[#leaf._baKids + 1] = kid
    return kid
end

local function SetPageChrome()
    local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
    if not hub then return end
    if spreadIndex < 1 then spreadIndex = 1 end
    if spreadIndex > #spreads then spreadIndex = math.max(1, #spreads) end
    local s = spreads[spreadIndex]
    local leftN = s and s.leftNum or 1
    local rightN = s and s.rightNum or 2
    -- Per-leaf numbers: right of < and left of >
    if hub.leftPageNum then
        hub.leftPageNum:SetText(tostring(leftN))
        Graphite(hub.leftPageNum)
    end
    if hub.rightPageNum then
        hub.rightPageNum:SetText(tostring(rightN))
        Graphite(hub.rightPageNum)
    end
    -- Footer jump field shows current left leaf (not drawn on the book)
    if hub.pageJump then
        hub.pageJump:SetText(tostring(leftN))
    end
end

local function JumpToEntrySpread(entryId)
    if not entryId then return false end
    RebuildSpreads()
    -- Prefer the spread where this entry's title leaf starts (may be left OR right page)
    for i = 1, #spreads do
        local found, isStart = SpreadContainsEntryId(spreads[i], entryId)
        if found and isStart then
            spreadIndex = i
            Blackacre.Chronicle.UI.RenderSpread(true)
            return true
        end
    end
    for i = 1, #spreads do
        local found = SpreadContainsEntryId(spreads[i], entryId)
        if found then
            spreadIndex = i
            Blackacre.Chronicle.UI.RenderSpread(true)
            return true
        end
    end
    return false
end

--- Open the spread that contains physical leaf number n.
local function JumpToLeaf(n)
    n = tonumber(n) or 1
    RebuildSpreads()
    if n < 1 then n = 1 end
    if totalLeaves > 0 and n > totalLeaves then n = totalLeaves end
    for i = 1, #spreads do
        local s = spreads[i]
        if s.leftNum and s.rightNum and n >= s.leftNum and n <= s.rightNum then
            spreadIndex = i
            Blackacre.Chronicle.UI.RenderSpread(true)
            return
        end
    end
    spreadIndex = 1
    Blackacre.Chronicle.UI.RenderSpread(true)
end

local ShowTitleEditPopup -- forward decl for TOC menu

--- TOC right-click: Edit title · Pin page · Delete (replaces footer Pin/Delete).
local function ShowTocEntryMenu(entry)
    if not entry then return end
    if not journal then return end
    if not journal.tocMenu then
        local m = CreateFrame("Frame", "BlackacreTocMenu", UIParent, "BackdropTemplate")
        m:SetSize(130, 96)
        m:SetFrameStrata("FULLSCREEN_DIALOG")
        if Theme() and Theme().ApplyChromeMenuFrame then Theme().ApplyChromeMenuFrame(m) end
        m:EnableMouse(true)
        m:Hide()
        local function Mk(y, label)
            local b = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
            b:SetHeight(22)
            b:SetPoint("TOP", 0, y)
            b:SetText(label)
            FitButtonWidth(b, 114)
            return b
        end
        m.editBtn = Mk(-8, "Edit title")
        m.pinBtn = Mk(-34, "Bookmark page")
        m.delBtn = Mk(-60, "Delete page")
        journal.tocMenu = m
    end
    local m = journal.tocMenu
    m.pinBtn:SetText(entry.pinned and "Remove bookmark" or "Bookmark page")
    FitButtonWidth(m.pinBtn, 114)
    local widest = math.max(m.editBtn:GetWidth(), m.pinBtn:GetWidth(), m.delBtn:GetWidth())
    m:SetWidth(widest + 16)
    m.editBtn:SetScript("OnClick", function()
        m:Hide()
        ShowTitleEditPopup(entry)
    end)
    m.pinBtn:SetScript("OnClick", function()
        entry.pinned = not entry.pinned
        Blackacre.Chronicle.Store.Update(entry.id, { pinned = entry.pinned })
        if Theme() and Theme().PlayUISound then Theme().PlayUISound("pinSoft") end
        if Blackacre.Print then
            Blackacre.Print(entry.pinned and "Page bookmarked" or "Bookmark removed")
        end
        m:Hide()
        Blackacre.Chronicle.UI.RenderSpread()
    end)
    m.delBtn:SetScript("OnClick", function()
        m:Hide()
        StaticPopup_Show("Blackacre_DELETE_ENTRY", nil, nil, entry.id)
    end)
    local scale = UIParent:GetEffectiveScale() or 1
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    m:ClearAllPoints()
    m:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 4, y - 4)
    m:Show()
end

ShowTitleEditPopup = function(entry)
    if not entry then return end
    if not StaticPopupDialogs["Blackacre_EDIT_TITLE"] then
        StaticPopupDialogs["Blackacre_EDIT_TITLE"] = {
            text = "Edit page title:",
            button1 = "Save",
            button2 = "Cancel",
            hasEditBox = true,
            maxLetters = 120,
            OnShow = function(self, data)
                local box = self.editBox or self:GetEditBox()
                if box and data then
                    box:SetText(data.title or "")
                    box:HighlightText()
                    box:SetFocus()
                end
            end,
            OnAccept = function(self, data)
                if not data or not data.id then return end
                local box = self.editBox or self:GetEditBox()
                local t = box and box:GetText() or data.title
                Blackacre.Chronicle.Store.Update(data.id, { title = t })
                if Blackacre.UI and Blackacre.UI.Theme then
                    Blackacre.UI.Theme.Toast("Title updated.")
                end
                Blackacre.Chronicle.UI.RenderSpread()
            end,
            EditBoxOnEnterPressed = function(self)
                local parent = self:GetParent()
                if parent and parent.button1 then
                    parent.button1:Click()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show("Blackacre_EDIT_TITLE", nil, nil, entry)
end

local function EnsureStickyNotes(entry)
    entry.stickyNotes = entry.stickyNotes or {}
    return entry.stickyNotes
end

local function PersistStickies(entry)
    if not entry or not entry.id then return end
    Blackacre.Chronicle.Store.Update(entry.id, { stickyNotes = EnsureStickyNotes(entry) })
end

local function HideStickyMenu()
    if journal and journal.stickyMenu then
        journal.stickyMenu:Hide()
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
    if journal and journal.stickyMenu then
        journal.stickyMenu:Hide()
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
local function CreateStickyCard(parent, entry, note, index)
    note.w = tonumber(note.w) or 150
    note.h = tonumber(note.h) or 90
    note.x = tonumber(note.x) or (16 + ((index - 1) % 2) * 18)
    note.y = tonumber(note.y) or (-70 - (index - 1) * 22)
    if note.pinned == nil then note.pinned = true end

    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(note.w, note.h)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", note.x, note.y)
    card:SetFrameLevel((parent:GetFrameLevel() or 1) + 10)
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
    card._note = note
    card._entry = entry
    card._baIsSticky = true
    card._baEditOpen = false

    local function BeginCardDrag()
        HideStickyMenu()
        card:StartMoving()
    end
    local function EndCardDrag()
        card:StopMovingOrSizing()
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
    card:SetScript("OnDragStart", BeginCardDrag)
    card:SetScript("OnDragStop", EndCardDrag)

    local header = CreateFrame("Button", nil, card)
    header:SetPoint("TOPLEFT", 3, -3)
    header:SetPoint("TOPRIGHT", -32, -3)
    header:SetHeight(22)
    header:RegisterForClicks("RightButtonUp")
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", BeginCardDrag)
    header:SetScript("OnDragStop", EndCardDrag)
    header:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ToggleStickyRightClick(card, entry, note)
        end
    end)
    card.header = header

    local actLevel = (card:GetFrameLevel() or 1) + 8
    local deleteBtn = CreateFrame("Button", nil, card)
    deleteBtn:SetSize(28, 28)
    deleteBtn:SetPoint("TOPRIGHT", -1, -1)
    deleteBtn:SetFrameLevel(actLevel)
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
    deleteBtn:SetScript("OnClick", function()
        DeleteStickyNote(entry, note)
    end)
    card.deleteBtn = deleteBtn
    card.settingsBtn = nil
    card.lockBtn = nil
    card.menuBtn = nil

    local status = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    status:SetPoint("LEFT", 4, 0)
    status:SetPoint("RIGHT", -4, 0)
    status:SetJustifyH("LEFT")
    status:SetText("")
    card.status = status

    local box = CreateFrame("EditBox", nil, card)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetPoint("TOPLEFT", 8, -30)
    box:SetPoint("BOTTOMRIGHT", -28, 26)
    box:SetTextInsets(2, 2, 2, 2)
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
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self)
        note.text = self:GetText() or ""
        PersistStickies(entry)
    end)
    box:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            ToggleStickyRightClick(card, entry, note)
        end
    end)
    card.box = box
    deleteBtn:SetFrameLevel(actLevel)

    -- Resize: grey unable cursor idle, gold size cursor while dragging. Always shown.
    local grip = CreateFrame("Button", nil, card)
    grip:SetSize(24, 24)
    grip:SetPoint("BOTTOMRIGHT", 0, 0)
    grip:SetFrameLevel(actLevel)
    grip:EnableMouse(true)
    grip:Show()
    grip.icon = grip:CreateTexture(nil, "ARTWORK")
    grip.icon:SetAllPoints()
    SetResizeGripLook(grip, false)
    grip:SetScript("OnEnter", function() SetResizeGripLook(grip, true) end)
    grip:SetScript("OnLeave", function()
        if card.isResizing or card._baGripHeld then return end
        SetResizeGripLook(grip, false)
    end)
    grip:SetScript("OnMouseDown", function()
        card._baGripHeld = true
        SetResizeGripLook(grip, true)
    end)
    grip:SetScript("OnMouseUp", function()
        card._baGripHeld = false
        if not (grip.IsMouseOver and grip:IsMouseOver()) then
            SetResizeGripLook(grip, false)
        end
    end)
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", function()
        HideStickyMenu()
        card.isResizing = true
        SetResizeGripLook(grip, true)
        card:SetScript("OnUpdate", function(self)
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
            note.w, note.h = nw, nh
        end)
    end)
    grip:SetScript("OnDragStop", function()
        card._baGripHeld = false
        StopStickyResize(card)
        if grip.IsMouseOver and grip:IsMouseOver() then
            SetResizeGripLook(grip, true)
        end
        SaveStickyGeometry(card)
        PersistStickies(entry)
    end)
    card.resizeGrip = grip

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
            local card = CreateStickyCard(pageLeaf, entry, note, n)
            AddKid(pageLeaf, card)
        end
    end
end

local function EntryOnLeafSide(side)
    local s = spreads[spreadIndex]
    if not s or (side ~= "left" and side ~= "right") then return nil, nil end
    local leaf = (side == "left") and s.left or s.right
    if leaf and leaf.kind == "entry" and leaf.entry then
        return leaf.entry, side
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
    notes[#notes + 1] = {
        id = (Blackacre.NewID and Blackacre.NewID()) or (tostring(time()) .. "-" .. math.random(1000, 9999)),
        text = "",
        x = x or (20 + (#notes % 3) * 12),
        y = y or (-50 - #notes * 16),
        w = w,
        h = h,
        pinned = true,
        createdAt = time(),
        leafSide = resolvedSide,
    }
    PersistStickies(entry)
    if Theme() and Theme().PlayUISound then Theme().PlayUISound("pinSoft") end
    Blackacre.Chronicle.UI.RenderSpread()
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
            local left = journal and journal.leftHost
            local right = journal and journal.rightHost
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
    if journal and journal.addNoteMenu then
        journal.addNoteMenu:Hide()
    end
end

--- Cursor popup: Add scrap note? / Bookmark (un)bookmark this page / Cancel.
local function ShowAddNoteMenuAtCursor(side)
    local entry = EntryOnLeafSide(side)
    if not entry then return end -- TOC / blank: do nothing, no toast

    if not journal.addNoteMenu then
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
        journal.addNoteMenu = m
    end

    local m = journal.addNoteMenu
    m._baSide = side
    m.addBtn:SetScript("OnClick", function()
        AddStickyToLeaf(m._baSide)
        m:Hide()
    end)

    m.bookmarkBtn:SetText(entry.pinned and "Remove bookmark" or "Bookmark page")
    FitButtonWidth(m.bookmarkBtn, 130)
    m.bookmarkBtn:SetScript("OnClick", function()
        entry.pinned = not entry.pinned
        Blackacre.Chronicle.Store.Update(entry.id, { pinned = entry.pinned })
        if Theme() and Theme().PlayUISound then Theme().PlayUISound("pinSoft") end
        if Blackacre.Print then
            Blackacre.Print(entry.pinned and "Page bookmarked" or "Bookmark removed")
        end
        m:Hide()
        Blackacre.Chronicle.UI.RenderSpread()
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

local function IsUnderSticky(focus, host)
    local f = focus
    for _ = 1, 16 do
        if not f or f == host then return false end
        if f._baIsSticky then return true end
        f = f.GetParent and f:GetParent() or nil
    end
    return false
end

local function OnLeafRightClick(host, side, button)
    if button ~= "RightButton" then return end
    HideAddNoteMenu()
    local focus = GetMouseFocus and GetMouseFocus()
    if IsUnderSticky(focus, host) then return end
    ShowAddNoteMenuAtCursor(side)
end

local function AddStickyToCurrentPage()
    -- Footer button: pick right entry, else left (still uses confirm menu)
    local s = spreads[spreadIndex]
    if not s then return end
    if s.right and s.right.kind == "entry" then
        ShowAddNoteMenuAtCursor("right")
    elseif s.left and s.left.kind == "entry" then
        ShowAddNoteMenuAtCursor("left")
    end
end

--- Wire leaf + its children so right page (covered by EditBox) still gets right-click.
local function WireLeafRightClickAddNote(host, side)
    if not host then return end
    host._baLeafSide = side
    host:EnableMouse(true)
    host:SetScript("OnMouseUp", function(self, button)
        OnLeafRightClick(self, side, button)
    end)
end

--- Wrap title into lines of max 23 chars; never break mid-word (long words keep whole).
local function WrapTitleWords(title, maxLen)
    maxLen = maxLen or TOC_TITLE_LINE_MAX
    title = title or "Untitled"
    local lines, cur = {}, ""
    for word in string.gmatch(title, "%S+") do
        if cur == "" then
            cur = word
        elseif (#cur + 1 + #word) <= maxLen then
            cur = cur .. " " .. word
        else
            lines[#lines + 1] = cur
            cur = word
        end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    if #lines == 0 then lines[1] = "Untitled" end
    return lines
end

--- Build TOC block lines: wrap title only (year lives in section subheading); last line gets page #.
local function BuildTocEntryLines(entry, pageNum)
    local titleLines = WrapTitleWords(entry.title or "Untitled", TOC_TITLE_LINE_MAX)
    local pageStr = tostring(pageNum or entry._baLeafLeft or "?")
    local out = {}
    for i = 1, #titleLines do
        local line = titleLines[i]
        if i == #titleLines then
            out[#out + 1] = {
                title = line,
                page = pageStr,
                isLast = true,
            }
        else
            out[#out + 1] = { title = line, page = nil, isLast = false }
        end
    end
    return out
end

--- One TOC text row: title left, leaders fill gap, page # flush to leaf edge.
--- Left leaf right-edge = gutter; right leaf right-edge = outer margin (same layout both sides).
local function PlaceTocLine(btn, ly, titleText, pageStr)
    local th = Theme()
    local applyFont = th and th.ApplyReadableBodyFont

    if not pageStr then
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", 4, -ly)
        label:SetPoint("TOPRIGHT", -6, -ly)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        if label.SetMaxLines then label:SetMaxLines(1) end
        label:SetText(titleText or "")
        Graphite(label)
        if applyFont then applyFont(label, 0) end
        return
    end

    -- Page number flush right (gutter on left leaf / outer edge on right leaf)
    local pageFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pageFs:SetJustifyH("RIGHT")
    pageFs:SetText(pageStr)
    Graphite(pageFs)
    if applyFont then applyFont(pageFs, 0) end
    local pageW = math.max(12, (pageFs:GetStringWidth() or 16) + 1)
    pageFs:SetWidth(pageW)
    pageFs:SetPoint("TOPRIGHT", -6, -ly)

    -- Title left; pin natural width so leader LEFT anchors at real text end
    local titleFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleFs:SetJustifyH("LEFT")
    titleFs:SetWordWrap(false)
    if titleFs.SetMaxLines then titleFs:SetMaxLines(1) end
    titleFs:SetText(titleText or "")
    Graphite(titleFs)
    if applyFont then applyFont(titleFs, 0) end

    local btnW = btn:GetWidth() or 280
    local titleW = math.max(8, (titleFs:GetStringWidth() or 40) + 1)
    local maxTitle = btnW - 4 - 6 - pageW - 24 -- pad + min leader gap
    if maxTitle < 40 then maxTitle = 40 end
    if titleW > maxTitle then titleW = maxTitle end
    titleFs:SetWidth(titleW)
    titleFs:SetPoint("TOPLEFT", 4, -ly)

    -- Leaders fill title → page (pixel-anchored, not monospaced char count)
    local leaderFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    leaderFs:SetPoint("TOPLEFT", titleFs, "TOPRIGHT", 3, 0)
    leaderFs:SetPoint("TOPRIGHT", pageFs, "TOPLEFT", -3, 0)
    leaderFs:SetJustifyH("LEFT")
    leaderFs:SetWordWrap(false)
    if leaderFs.SetMaxLines then leaderFs:SetMaxLines(1) end
    if leaderFs.SetNonSpaceWrap then leaderFs:SetNonSpaceWrap(false) end
    leaderFs:SetText(string.rep(".", 120))
    if applyFont then applyFont(leaderFs, 0) end
    -- Slightly softer than body ink so leaders read as rule, not text
    local c = th and th.Colors and th.Colors.ink
    if c then
        leaderFs:SetTextColor(c[1], c[2], c[3], 0.55)
    else
        leaderFs:SetTextColor(0.35, 0.32, 0.28, 0.55)
    end
end

local HideBookmarkTab -- forward decl; page bookmark tab defined near RenderEntryLeaf

local function RenderTocLeaf(leaf, items, heading, leafSide)
    ClearLeaf(leaf)
    HideBookmarkTab(leafSide)
    -- Must receive mouse so top TOC rows are clickable (siblings like TOC bookmark can steal hits)
    leaf:EnableMouse(false) -- clicks go to children only
    local w = leaf:GetWidth()
    if not w or w < 50 then w = 320 end
    local baseLevel = (leaf:GetFrameLevel() or 1) + 30
    -- leafSide kept for callers; page # always flush to this leaf's right edge
    leaf._baLeafSide = leafSide

    -- TOC heading: one Alliance ribbon, stretched to the phrase. No tile.
    local headingText = heading or "Table of Contents"
    local titleBar = CreateFrame("Frame", nil, leaf)
    -- Ribbon ends are decorative, so the bar is 25% past the old fit or the phrase sits on the points.
    titleBar:SetHeight(45)
    titleBar:SetPoint("TOP", leaf, "TOP", 0, -6)
    AddKid(leaf, titleBar)
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", 0, 1)
    title:SetText(headingText)
    title:SetTextColor(1, 0.92, 0.55, 1)
    local tw = math.ceil((title.GetStringWidth and title:GetStringWidth()) or 130)
    titleBar:SetWidth(math.max(math.ceil((tw + 48) * 1.25), 200))
    local ribbon = titleBar:CreateTexture(nil, "ARTWORK")
    ribbon:SetAllPoints(titleBar)
    if ribbon.SetHorizTile then ribbon:SetHorizTile(false) end
    if ribbon.SetVertTile then ribbon:SetVertTile(false) end
    if not TryAtlas(ribbon, "UI-Frame-Alliance-Ribbon", false) then
        TryAtlas(ribbon, "UI-Frame-Dragonflight-Ribbon", false)
    end
    title:SetDrawLayer("OVERLAY", 1)
    AddKid(leaf, title)

    local y = -6 - (titleBar:GetHeight() or 45) - 8
    for _, row in ipairs(items) do
        if row.kind == "divider" then
            -- Plain rule, not an atlas guess -- swap for a themed divider once
            -- the owner points TAV at a real one and we confirm the name.
            local rule = leaf:CreateTexture(nil, "ARTWORK")
            rule:SetPoint("TOP", leaf, "TOP", 0, y - 4)
            rule:SetSize(w - 48, 2)
            rule:SetColorTexture(0.55, 0.45, 0.25, 0.5)
            AddKid(leaf, rule)
            y = y - 18
        elseif row.kind == "year" then
            -- Wings sit ~10px off the year text (not the leaf edge). Right wing is a H-flip of the same atlas.
            local yearBar = CreateFrame("Frame", nil, leaf)
            yearBar:SetPoint("TOP", leaf, "TOP", 0, y)
            yearBar:SetHeight(20)
            AddKid(leaf, yearBar)
            local yearFs = yearBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            yearFs:SetPoint("CENTER", 0, 0)
            yearFs:SetText(row.label or "Undated")
            yearFs:SetTextColor(0.95, 0.88, 0.55, 1)
            local tw = math.max(24, (yearFs.GetStringWidth and yearFs:GetStringWidth()) or 48)
            yearFs:SetWidth(tw + 2)
            yearBar:SetWidth(tw + 2 + 20 + 92)
            local wingL = yearBar:CreateTexture(nil, "ARTWORK")
            wingL:SetSize(46, 18)
            wingL:SetPoint("RIGHT", yearFs, "LEFT", -10, 0)
            ApplyAtlasMember(wingL, "PetJournal-PetBattleAchievementBG", false)
            local wingR = yearBar:CreateTexture(nil, "ARTWORK")
            wingR:SetSize(46, 18)
            wingR:SetPoint("LEFT", yearFs, "RIGHT", 10, 0)
            ApplyAtlasMember(wingR, "PetJournal-PetBattleAchievementBG", true)
            AddKid(leaf, yearFs)
            y = y - 26
        elseif row.kind == "entry" and row.entry then
            local e = row.entry
            local pageNum = e._baLeafLeft or e._baSpreadIndex or "?"
            local lines = BuildTocEntryLines(e, pageNum)
            local blockH = #lines * 16 + 8
            local entryId = e.id

            local btn = CreateFrame("Button", nil, leaf)
            btn:SetFrameLevel(baseLevel)
            btn:SetSize(w - 28, math.max(20, #lines * 16 + 2))
            btn:SetPoint("TOPLEFT", 14, y)
            btn:EnableMouse(true)
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:ClearAllPoints()
            hl:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 4)
            hl:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 4)
            if not TryAtlas(hl, "Garr_ListButton-Selection", false) then
                hl:SetColorTexture(0.90, 0.78, 0.35, 0.18)
            elseif hl.SetBlendMode then
                hl:SetBlendMode("ADD")
            end
            btn:SetHighlightTexture(hl)

            local ly = 0
            for _, ln in ipairs(lines) do
                PlaceTocLine(btn, ly, ln.title, ln.isLast and ln.page or nil)
                ly = ly + 15
            end

            btn:SetScript("OnClick", function(_, button)
                if button == "RightButton" then
                    ShowTocEntryMenu(e)
                else
                    if Theme() and Theme().PlayUISound then Theme().PlayUISound("pageTurn") end
                    if not JumpToEntrySpread(entryId) and Blackacre.UI and Blackacre.UI.Theme then
                        Blackacre.UI.Theme.Toast("Could not open that page.")
                    end
                end
            end)
            AddKid(leaf, btn)
            y = y - blockH
        end
    end

    if #items == 0 then
        local empty = leaf:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        empty:SetPoint("TOPLEFT", 16, -80)
        empty:SetText("No pages yet, try adding a page.")
        Graphite(empty)
        AddKid(leaf, empty)
    end
end

local function RenderBlankLeaf(leaf)
    ClearLeaf(leaf)
    local fs = leaf:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText("")
    AddKid(leaf, fs)
end

--- Freeform page text like Send Mail: no InputBox chrome; black while editing, graphite when locked.
local function PageEdit_OnEscapePressed(self)
    self:ClearFocus()
end

-- Right-click on body/title field → same add-note menu as empty parchment.
-- Reads host/side from the box so a pooled box follows whichever leaf it is on.
local function PageEdit_OnMouseUp(self, button)
    if button == "RightButton" and self._baLeafSide then
        OnLeafRightClick(self._baLeafHost, self._baLeafSide, button)
    end
end

local function MakePageEditBox(parent, multi)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetMultiLine(multi and true or false)
    box:SetAutoFocus(false)
    box:SetTextInsets(4, 4, 4, 4)
    if box.SetBackdrop then box:SetBackdrop(nil) end
    box:SetScript("OnEscapePressed", PageEdit_OnEscapePressed)
    box:HookScript("OnMouseUp", PageEdit_OnMouseUp)
    return box
end

local function ReviveKid(kid, parent)
    kid:SetParent(parent)
    kid:SetAlpha(1)
    kid:EnableMouse(true)
    kid:Show()
end

local function AcquireTitleEdit(host, leafSide)
    local box = table.remove(titleEditPool)
    if box then
        ReviveKid(box, host)
    else
        box = MakePageEditBox(host, false)
        box._baPool = "title"
    end
    box._baLeafHost = host
    box._baLeafSide = leafSide
    return box
end

local function AcquireBodyScroll(host, leafSide)
    local scroll = table.remove(bodyScrollPool)
    if scroll then
        ReviveKid(scroll, host)
        ReviveKid(scroll._baEdit, scroll)
        scroll:SetVerticalScroll(0)
    else
        scroll = CreateFrame("ScrollFrame", nil, host)
        scroll._baPool = "bodyScroll"
        scroll._baEdit = MakePageEditBox(scroll, true)
        scroll:EnableMouse(true)
    end
    scroll._baEdit._baLeafHost = host
    scroll._baEdit._baLeafSide = leafSide
    return scroll, scroll._baEdit
end

local function StyleEditLocked(box, locked)
    if not box then return end
    if locked then
        Graphite(box)
        box:Disable()
        box:ClearFocus()
        if box.SetCursorPosition then box:SetCursorPosition(0) end
    else
        box:SetTextColor(0.05, 0.05, 0.06, 1)
        box:Enable()
    end
end

-- Persist the rendered editors directly.  The old implementation only read
-- the controls when the Journal toggle changed from On to Locked, so text
-- could still exist only in an EditBox when the player reloaded the UI.
local persistBoxes = {}
local persistOut = {}
local function BySegStart(a, b)
    return a._baSegStart < b._baSegStart
end

local function PersistEntryFromEditors(entry, showToast)
    if not journal or not entry or not entry.id then return nil, false end

    local titleText = entry.title or ""
    local foundTitle = false
    for _, box in ipairs(journal._baTitleParts or {}) do
        if box._baEntry and box._baEntry.id == entry.id and box.GetText then
            titleText = box:GetText() or ""
            foundTitle = true
            break
        end
    end
    if not foundTitle and journal.titleEdit and journal.titleEdit._baEntry
        and journal.titleEdit._baEntry.id == entry.id and journal.titleEdit.GetText then
        titleText = journal.titleEdit:GetText() or ""
    end

    -- Each body editor shows one slice (segStart..segEnd) of the body as it
    -- was when the spread was drawn.  Rebuild the full body from that source,
    -- replacing only the visible slices.  Joining just the visible boxes used
    -- to save a continuation leaf as the whole entry, dropping page one.
    -- Runs on every keystroke: scratch tables are reused, not allocated.
    local boxes = persistBoxes
    wipe(boxes)
    local bodyParts = journal._baBodyParts
    if bodyParts then
        for i = 1, #bodyParts do
            local box = bodyParts[i]
            if box._baEntry and box._baEntry.id == entry.id and box._baSource then
                boxes[#boxes + 1] = box
            end
        end
    end
    local bodyText = entry.body or ""
    local count = #boxes
    if count == 1 then
        -- Common case: one leaf of this entry is on screen.
        local box, source = boxes[1], boxes[1]._baSource
        bodyText = source:sub(1, box._baSegStart - 1) .. (box:GetText() or "")
            .. source:sub(box._baSegEnd + 1)
    elseif count > 1 then
        table.sort(boxes, BySegStart)
        local source = boxes[1]._baSource
        local out = persistOut
        wipe(out)
        out[1] = source:sub(1, boxes[1]._baSegStart - 1)
        for i = 1, count do
            local box, nextBox = boxes[i], boxes[i + 1]
            out[#out + 1] = box:GetText() or ""
            out[#out + 1] = source:sub(box._baSegEnd + 1,
                nextBox and (nextBox._baSegStart - 1) or #source)
        end
        bodyText = table.concat(out)
        wipe(out)
    end
    wipe(boxes)
    if titleText == (entry.title or "") and bodyText == (entry.body or "") then
        return entry, false
    end

    local updated = Blackacre.Chronicle.Store.Update(entry.id, {
        title = titleText,
        body = bodyText,
    })
    if updated and updated.kind == "MANUAL" then
        updated.facts = updated.facts or {}
        updated.facts.title = titleText
        updated.facts.manualTitle = titleText
        updated.facts.body = bodyText
        updated.facts.manualBody = bodyText
    end
    if updated and showToast and Theme() and Theme().Toast then
        Theme().Toast("Page saved.")
    end
    return updated, updated ~= nil
end

-- Shared handlers (no per-render closures). A retired editor has no entry,
-- so PersistEntryFromEditors returns early for it.
local function PageEdit_Persist(self)
    PersistEntryFromEditors(self._baEntry, false)
end

local function BodyScroll_OnMouseUp(self, button)
    local edit = self._baEdit
    if button == "RightButton" and edit and edit._baLeafSide then
        OnLeafRightClick(edit._baLeafHost, edit._baLeafSide, button)
    end
end

--- One physical leaf of an entry: title+meta lead body on the SAME page (or continuation body).
-- Page bookmark tabs live OUTSIDE the leaf frames (hub.leftPage/rightPage, per
-- Theme.lua:956,963, hard-clip any child at their own rect via SetClipsChildren
-- -- no draw-layer/sublevel trick escapes that). Parented instead to
-- hub.bookOpen (unclipped, same as the TOC bookmark / region 8), with a
-- FrameLevel above the leaf's own so it still draws over the page art, and
-- positioned by anchors to the leaf's edge, so it reads the same height as
-- the TOC bookmark tab instead of being boxed into the leaf's rectangle.
local function EnsureBookmarkTab(side)
    journal.bookmarkTabs = journal.bookmarkTabs or {}
    local t = journal.bookmarkTabs[side]
    if t then return t end
    local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
    local parent = (hub and hub.bookOpen) or journal
    t = CreateFrame("Frame", nil, parent)
    t.tex = t:CreateTexture(nil, "ARTWORK")
    t.tex:SetAllPoints(t)
    -- Fades the gutter-facing edge into the spine's own dark color instead of
    -- showing a hard rectangular cutoff -- the tab reads as draping into
    -- shadow rather than being clipped.
    t.shadow = t:CreateTexture(nil, "OVERLAY")
    t:Hide()
    journal.bookmarkTabs[side] = t
    return t
end

HideBookmarkTab = function(side)
    local t = journal and journal.bookmarkTabs and journal.bookmarkTabs[side]
    if t then t:Hide() end
end

-- Owner call: the gutter is where a real sticky page-tab would be USELESS
-- (hidden in the spine fold) -- real tabs live on the fore-edge, the outer
-- side you thumb through to find a marked page. Moved there: left page's tab
-- on its own LEFT (outer) edge, right page's on its own RIGHT (outer) edge,
-- mirrored versions of each other. No spine to fake falling into, so the
-- whole gutter-shadow/bleed mechanism from the gutter-placement attempt is
-- gone -- nothing left to blend into.
--
-- The book's existing TOC-jump tab (hub.chronicleBookmark, region 8, per
-- Theme.lua:919) already lives on the LEFT outer edge. Owner wants them
-- stacked as ONE combined tab, not two separate ones: this tab drawn on top,
-- starting at the same height as chronicleBookmark (which Theme.lua now
-- makes reliably taller than this one), so the TOC tab's tail still peeks
-- out below as a clickable tongue. Both anchor to bookOpen's own top (the
-- same reference chronicleBookmark uses), not the leaf's, so they align
-- pixel-for-pixel instead of the leaf's own ~20px inset throwing them off.
local function ShowBookmarkTab(host, leafSide)
    local tabFrame = journal and EnsureBookmarkTab(leafSide)
    if not tabFrame then return end
    if tabFrame.shadow then tabFrame.shadow:Hide() end -- unused on the outer edge; nothing to fade into
    local leafH = host:GetHeight()
    if not leafH or leafH < 50 then leafH = 480 end
    -- Owner: scaled to 40% then reduced another 25% (net 30% of the leaf
    -- height), aspect ratio kept throughout.
    local targetH = leafH * 0.3
    local flipH = leafSide == "right" -- mirrored so the cut edge faces the page's own outer edge, not inward
    local tabWidth, tabHeight
    local th = Theme()
    if th and th.ApplyBookmarkTab then
        tabWidth, tabHeight = th.ApplyBookmarkTab(tabFrame.tex, targetH, flipH)
    end
    if not tabWidth then
        -- Atlas didn't resolve (not yet confirmed for this skin/flavor) --
        -- flat-color placeholder so a bookmarked page is still visibly marked.
        tabFrame.tex:SetColorTexture(0.55, 0.5, 0.42, 0.85)
        tabWidth, tabHeight = 28, targetH
    end
    tabFrame:SetSize(tabWidth, tabHeight)
    tabFrame:ClearAllPoints()

    local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
    local tocTab = hub and hub.chronicleBookmark
    -- Draw above the TOC tab so this one reads as the top layer of the stack.
    tabFrame:SetFrameLevel(((tocTab and tocTab:GetFrameLevel()) or (host:GetFrameLevel() or 1)) + 1)

    if leafSide == "right" then
        -- Right page's outer edge is its own right edge. Pulled in from the
        -- window's outer border (it was touching the shell at +4) -- the TOC
        -- tab on the left isn't touched, it just happens to clear the border
        -- already at its own -4.
        if hub and hub.bookOpen then
            tabFrame:SetPoint("TOPRIGHT", hub.bookOpen, "TOPRIGHT", -2, 0)
        else
            tabFrame:SetPoint("TOPRIGHT", host, "TOPRIGHT", 8, 0)
        end
    else
        -- Left page's outer edge is its own left edge -- same top as the TOC tab.
        if hub and hub.bookOpen then
            tabFrame:SetPoint("TOPLEFT", hub.bookOpen, "TOPLEFT", 4, 0)
        else
            tabFrame:SetPoint("TOPLEFT", host, "TOPLEFT", 8, 0)
        end
    end
    tabFrame:Show()
end

local function RenderEntryLeaf(host, leafData, leafSide)
    ClearLeaf(host)
    host._baLeafSide = leafSide
    if not leafData or not leafData.entry then
        HideBookmarkTab(leafSide)
        RenderBlankLeaf(host)
        return
    end
    local entry = leafData.entry
    local editing = journalMode and not presentationMode
    local w = host:GetWidth()
    if not w or w < 50 then w = 320 end
    local yTop = -14

    -- The bookmark tab now lives on hub.bookOpen, outside the leaf's own
    -- rect, so it no longer needs the leaf's text pushed over to clear it.
    if entry.pinned then
        ShowBookmarkTab(host, leafSide)
    else
        HideBookmarkTab(leafSide)
    end
    local padLeft = 12
    local padRight = 12

    if leafData.showTitle then
        local titleEdit = AcquireTitleEdit(host, leafSide)
        titleEdit:SetPoint("TOPLEFT", padLeft, yTop)
        titleEdit:SetPoint("TOPRIGHT", -padRight, yTop)
        titleEdit:SetHeight(26)
        titleEdit:SetFontObject(GameFontNormalLarge)
        titleEdit:SetText(entry.title or "Untitled")
        titleEdit:SetJustifyH("LEFT")
        titleEdit._baEntry = entry
        titleEdit._baIsTitle = true
        titleEdit:SetScript("OnTextChanged", PageEdit_Persist)
        titleEdit:SetScript("OnEditFocusLost", PageEdit_Persist)
        if editing then
            titleEdit:SetTextColor(0.05, 0.05, 0.06, 1)
            titleEdit:Enable()
        else
            titleEdit:SetTextColor(1, 0.92, 0.55, 1)
            titleEdit:Disable()
        end
        AddKid(host, titleEdit)
        journal._baTitleParts = journal._baTitleParts or {}
        journal._baTitleParts[#journal._baTitleParts + 1] = titleEdit
        -- Prefer first title box on the open spread for Save
        if not journal.titleEdit then
            journal.titleEdit = titleEdit
            journal.displayTitle = titleEdit
        end
        yTop = yTop - 30
    end

    if leafData.showMeta then
        local meta = host:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        meta:SetPoint("TOPLEFT", padLeft, yTop)
        meta:SetPoint("TOPRIGHT", -padRight, yTop)
        meta:SetJustifyH("LEFT")
        local metaText = string.format("%s | %s | %s",
            KindLabel(entry.kind),
            entry.zoneName or "Unknown lands",
            FormatEntryYear(entry))
        if Blackacre.UI.Theme.SanitizeBodyText then
            metaText = Blackacre.UI.Theme.SanitizeBodyText(metaText)
        end
        meta:SetText(metaText)
        Graphite(meta)
        Blackacre.UI.Theme.ApplyReadableBodyFont(meta, -1)
        AddKid(host, meta)
        yTop = yTop - 36
    elseif leafData.isContinuation then
        local cont = host:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cont:SetPoint("TOPLEFT", padLeft, yTop)
        cont:SetText("(continued)")
        Graphite(cont)
        AddKid(host, cont)
        yTop = yTop - 18
    end

    local bodyScroll, bodyEdit = AcquireBodyScroll(host, leafSide)
    bodyScroll:SetPoint("TOPLEFT", 10, yTop)
    bodyScroll:SetPoint("BOTTOMRIGHT", -14, 44)
    bodyScroll:SetScript("OnMouseUp", BodyScroll_OnMouseUp)
    AddKid(host, bodyScroll)

    local bodyText = leafData.bodyPart or entry.body or ""
    if Blackacre.UI.Theme.SanitizeBodyText then
        bodyText = Blackacre.UI.Theme.SanitizeBodyText(bodyText)
    end
    bodyEdit:SetText(bodyText)
    Blackacre.UI.Theme.ApplyReadableBodyFont(bodyEdit, 2)
    StyleEditLocked(bodyEdit, not editing)
    bodyScroll:SetScrollChild(bodyEdit)
    bodyEdit:SetWidth(math.max(180, w - 28))
    bodyEdit:SetHeight(math.max(360, (host:GetHeight() or 400) - 80))
    bodyEdit._baEntry = entry
    bodyEdit._baIsContinuation = leafData.isContinuation and true or false
    local source = leafData.sourceBody or entry.body or ""
    bodyEdit._baSource = source
    bodyEdit._baSegStart = leafData.segStart or 1
    bodyEdit._baSegEnd = leafData.segEnd or #source
    bodyEdit:SetScript("OnTextChanged", PageEdit_Persist)
    bodyEdit:SetScript("OnEditFocusLost", PageEdit_Persist)

    -- Save uses primary body box (page 1); continuations still edit-able but Save merges carefully
    if not journal.bodyEdit or leafData.showTitle then
        journal.bodyEdit = bodyEdit
    end
    journal.currentEntry = entry
    journal._baBodyParts = journal._baBodyParts or {}
    journal._baBodyParts[#journal._baBodyParts + 1] = bodyEdit
    -- Stickies placed after both leaves are drawn (so right-page entries get notes too)
end

local function RenderOpenLeaf(host, leaf, leafSide)
    if not host then return end
    host._baLeafSide = leafSide
    if not leaf or leaf.kind == "blank" then
        RenderBlankLeaf(host)
        return
    end
    if leaf.kind == "toc" then
        RenderTocLeaf(host, leaf.items or {}, leaf.heading or "Table of Contents", leafSide)
        return
    end
    if leaf.kind == "entry" then
        RenderEntryLeaf(host, leaf, leafSide)
        return
    end
    RenderBlankLeaf(host)
end

--- Draw stickies on left and right entry leaves (by note.leafSide).
local function PlaceStickiesOnSpread(s, leftHost, rightHost)
    if s.left and s.left.kind == "entry" and s.left.entry then
        RenderStickyNotes(leftHost, s.left.entry, "left")
    end
    if s.right and s.right.kind == "entry" and s.right.entry then
        RenderStickyNotes(rightHost, s.right.entry, "right")
    end
    WireLeafRightClickAddNote(leftHost, "left")
    WireLeafRightClickAddNote(rightHost, "right")
end

--- @param skipRebuild if true, use current spreads (caller already rebuilt)
function Blackacre.Chronicle.UI.RenderSpread(skipRebuild)
    if not journal then return end
    HideStickyMenu()
    HideAddNoteMenu()
    if journal.tocMenu then journal.tocMenu:Hide() end
    EndPinMode()
    if not skipRebuild then
        RebuildSpreads(true)
    end
    if spreadIndex < 1 then spreadIndex = 1 end
    if spreadIndex > #spreads then spreadIndex = math.max(1, #spreads) end
    local s = spreads[spreadIndex] or {
        type = "open",
        left = { kind = "blank" },
        right = { kind = "blank" },
        leftNum = 1,
        rightNum = 2,
    }

    local left = journal.leftHost
    local right = journal.rightHost
    if not left or not right then return end
    left:Show()
    right:Show()

    -- Raise leaves above bookmark once (avoid thrash if already high enough)
    local want = (left:GetParent() and left:GetParent():GetFrameLevel() or 1) + 10
    if (left:GetFrameLevel() or 0) < want then left:SetFrameLevel(want) end
    if (right:GetFrameLevel() or 0) < want then right:SetFrameLevel(want) end

    journal.bodyEdit = nil
    journal.titleEdit = nil
    journal.currentEntry = nil
    journal._baBodyParts = {}
    journal._baTitleParts = {}

    RenderOpenLeaf(left, s.left or { kind = "blank" }, "left")
    RenderOpenLeaf(right, s.right or { kind = "blank" }, "right")
    PlaceStickiesOnSpread(s, left, right)
    SetPageChrome()
end

function Blackacre.Chronicle.UI.SaveSelected()
    if not journal then return end
    local s = spreads[spreadIndex]
    local entry = GetSpreadEntry(s)
    if not entry then
        -- Silent when leaving edit mode on TOC
        return
    end
    if journal.bodyEdit then journal.bodyEdit:ClearFocus() end
    if journal.titleEdit then journal.titleEdit:ClearFocus() end
    local updated = PersistEntryFromEditors(entry, false)
    if updated then
        if Theme() and Theme().PlayUISound then Theme().PlayUISound("writeQuill") end
        if Theme() and Theme().Toast then Theme().Toast("Page saved.") end
    end
    Blackacre.Chronicle.UI.RenderSpread()
end

-- Footer no longer mounts Save/Add/Pin/Delete text tools (icon + TOC menus instead).
local function MountToolsOnParentFooter()
    local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
    if not hub or not hub.toolStrip then return end
    hub.toolStrip._baBuilt = true
end

local function BuildUI()
    local tocParent = Blackacre.TomeHub and Blackacre.TomeHub.GetChronicleTocParent and Blackacre.TomeHub.GetChronicleTocParent()
    local pageParent = Blackacre.TomeHub and Blackacre.TomeHub.GetChroniclePageParent and Blackacre.TomeHub.GetChroniclePageParent()

    journal = {
        leftHost = tocParent,
        rightHost = pageParent,
        _baJournalMode = false,
    }

    if not journal.leftHost or not journal.rightHost then
        local f = CreateFrame("Frame", "BlackacreJournalFallback", UIParent, "BackdropTemplate")
        f:SetSize(900, 520)
        f:SetPoint("CENTER")
        f:Hide()
        journal.leftHost = CreateFrame("Frame", nil, f)
        journal.leftHost:SetPoint("TOPLEFT", 10, -10)
        journal.leftHost:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -8, 10)
        journal.rightHost = CreateFrame("Frame", nil, f)
        journal.rightHost:SetPoint("TOPLEFT", f, "TOP", 8, -10)
        journal.rightHost:SetPoint("BOTTOMRIGHT", -10, 10)
    end

    BuildStickyMenu()
    MountToolsOnParentFooter()

    StaticPopupDialogs["Blackacre_DELETE_ENTRY"] = {
        text = "You cannot recover a page torn from your journal.",
        button1 = "Tear out",
        button2 = "Keep",
        OnAccept = function(_, id)
            Blackacre.Chronicle.Store.Delete(id)
            Blackacre.Chronicle.UI.GoToToc()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function Blackacre.Chronicle.UI.EnsureBuilt()
    if not journal then BuildUI() end
    return journal
end

function Blackacre.Chronicle.UI.Init()
end

function Blackacre.Chronicle.UI.OnHubShow()
    Blackacre.Chronicle.UI.EnsureBuilt()
    -- Refresh hosts in case shell rebuilt
    if Blackacre.TomeHub then
        if Blackacre.TomeHub.GetChronicleTocParent then
            journal.leftHost = Blackacre.TomeHub.GetChronicleTocParent()
        end
        if Blackacre.TomeHub.GetChroniclePageParent then
            journal.rightHost = Blackacre.TomeHub.GetChroniclePageParent()
        end
    end
    if not journal.leftHost or not journal.rightHost then
        if Blackacre.Print then
            Blackacre.Print("Chronicle pages missing (left/right leaf).")
        end
        return
    end
    MountToolsOnParentFooter()
    RebuildSpreads()
    if spreadIndex < 1 or spreadIndex > #spreads then spreadIndex = 1 end
    Blackacre.Chronicle.UI.RenderSpread()
end

function Blackacre.Chronicle.UI.Refresh()
    if journal then Blackacre.Chronicle.UI.RenderSpread() end
end

function Blackacre.Chronicle.UI.GoToToc()
    Blackacre.Chronicle.UI.EnsureBuilt()
    RebuildSpreads()
    spreadIndex = 1
    Blackacre.Chronicle.UI.RenderSpread(true)
end

function Blackacre.Chronicle.UI.GoToPage(n)
    Blackacre.Chronicle.UI.EnsureBuilt()
    JumpToLeaf(n)
end

function Blackacre.Chronicle.UI.TurnPage(delta)
    Blackacre.Chronicle.UI.EnsureBuilt()
    RebuildSpreads()
    local prev = spreadIndex
    spreadIndex = spreadIndex + (delta or 1)
    if spreadIndex < 1 then spreadIndex = 1 end
    if spreadIndex > #spreads then spreadIndex = #spreads end
    if spreadIndex ~= prev and Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.PlayUISound then
        Blackacre.UI.Theme.PlayUISound("pageTurn") -- local SFX only (Wowhead igAbilityPageTurn / 836)
    end
    Blackacre.Chronicle.UI.RenderSpread(true)
end

function Blackacre.Chronicle.UI.SetJournalMode(on)
    journalMode = on and true or false
    if journal then
        journal._baJournalMode = journalMode
        Blackacre.Chronicle.UI.RenderSpread()
    end
end

function Blackacre.Chronicle.UI.Toggle()
    if Blackacre.TomeHub and Blackacre.TomeHub.Toggle then
        Blackacre.TomeHub.Toggle("chronicle")
    end
end

function Blackacre.Chronicle.UI.Show()
    if Blackacre.TomeHub and Blackacre.TomeHub.Show then
        Blackacre.TomeHub.Show("chronicle")
    end
end

function Blackacre.Chronicle.UI.OnNewEntry(entry)
    if entry and not IsAllowedChronicleKind(entry.kind) then
        return
    end
    if entry then
        JumpToEntrySpread(entry.id)
    elseif journal then
        Blackacre.Chronicle.UI.RenderSpread()
    end
end
