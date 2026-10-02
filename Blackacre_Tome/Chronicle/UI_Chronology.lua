-- In Character Forever: Journal - Journal Book

Blackacre = Blackacre or {}
Blackacre.Chronicle = Blackacre.Chronicle or {}
Blackacre.Chronicle.UI = {}

local type, ipairs, next, tostring, tonumber = type, ipairs, next, tostring, tonumber
local time, wipe = time, wipe
local GetTime, C_Timer = GetTime, C_Timer
local IsControlKeyDown, IsShiftKeyDown = IsControlKeyDown, IsShiftKeyDown
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
    QUEST_PAGE = "Quest",
    QUESTLINE = "Road",
    META_QUEST = "Meta quest",
    META_ACHIEVEMENT = "Meta feat",
    FOS = "Feat of Strength",
    REPUTATION = "Standing",
    ACHIEVEMENT = "Feat",
    TITLE = "Title",
    PROFESSION = "Craft",
    WEAPON_SKILL = "Mastery",
    MANUAL = "Note",
    DEATH = "Death",
    AFTERLIFE = "Afterlife",
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

--- Kinds shown as pages (background records like survival stay hidden).
local function IsAllowedChronicleKind(kind)
    return Blackacre.Chronicle.Store.IsBookKind(kind)
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

local function ByStoryOrder(a, b)
    local st = Blackacre.Chronicle.Store.StoryTime
    local sa, sb = st(a.entry), st(b.entry)
    if sa ~= sb then return sa < sb end
    return (a.entry.createdAt or 0) < (b.entry.createdAt or 0)
end

--- Bookmarked slots: one "Bookmarked" heading, entries in story order
--- (not reshuffled when bookmarked), then a divider before the
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
    table.sort(bookmarked, ByStoryOrder)
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

-- Everything a leaf draws is pooled by kind (kid._baPool) and handed back in
-- ClearLeaf, so turning pages reuses the same frames. WoW never frees a
-- frame, so making new ones per render grew memory with every page turn.
local kidPools = { title = {}, bodyScroll = {} }
local titleEditPool = kidPools.title
local bodyScrollPool = kidPools.bodyScroll
local RetireSticky -- defined with the sticky cards below

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
    local kids = leaf._baKids
    for i = 1, #kids do
        local k = kids[i]
        local kind = k._baPool
        if kind == "title" then
            RetirePageEdit(k)
        elseif kind == "bodyScroll" then
            RetirePageEdit(k._baEdit)
        elseif kind == "sticky" then
            RetireSticky(k)
        end
        -- FontStrings and Textures have no scripts or mouse.
        local otype = k:GetObjectType()
        if otype ~= "FontString" and otype ~= "Texture" then
            k:SetScript("OnUpdate", nil)
            if not kind then
                k:SetScript("OnDragStart", nil)
                k:SetScript("OnDragStop", nil)
                k:EnableMouse(false)
            end
        end
        k:Hide()
        k:ClearAllPoints()
        k:SetParent(scrap)
        k:SetAlpha(0)
        local pool = kind and kidPools[kind]
        if pool then pool[#pool + 1] = k end
    end
    wipe(kids)
end

local function AddKid(leaf, kid)
    leaf._baKids = leaf._baKids or {}
    leaf._baKids[#leaf._baKids + 1] = kid
    return kid
end

-- Take a pooled piece of `kind` (or build one) and put it on `host`.
local function AcquireKid(kind, host, build)
    local pool = kidPools[kind]
    if not pool then
        pool = {}
        kidPools[kind] = pool
    end
    local k = table.remove(pool)
    if k then
        k:SetParent(host)
        k:SetAlpha(1)
        k:Show()
    else
        k = build(host)
        k._baPool = kind
    end
    return AddKid(host, k)
end

-- A pooled FontString comes back with whatever the last page set on it, so
-- reset everything a caller might have changed.
local function ResetFontString(fs, template)
    local font = _G[template] or GameFontHighlight
    fs:SetFontObject(font)
    fs:SetTextColor(font:GetTextColor())
    fs:SetDrawLayer("OVERLAY", 0)
    fs:ClearAllPoints()
    fs:SetWidth(0)
    fs:SetHeight(0)
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    fs:SetWordWrap(true)
    if fs.SetMaxLines then fs:SetMaxLines(0) end
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
    fs:SetAlpha(1)
    fs:Show()
end

local function NewFontString(host)
    return host:CreateFontString(nil, "OVERLAY")
end

local function AcquireFS(host, template)
    local fs = AcquireKid("fs", host, NewFontString)
    ResetFontString(fs, template)
    return fs
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
    if hub.pageJumpOf then
        hub.pageJumpOf:SetText("of " .. math.max(totalLeaves, rightN))
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

local function UnlockJournaling()
    local hub = Blackacre.TomeHub.GetFrame()
    if hub and hub.journalToggle and not hub.journalToggle._baOn then
        hub.journalToggle:Click()
    end
end

--- A blank page placed right after `entry` in the book's chronology.
local function InsertPageAfter(entry)
    local storyAt = Blackacre.Chronicle.Store.StoryTimeAfter(entry)
    Blackacre.Chronicle.Capture.AddManual(nil, nil, "MANUAL", storyAt, entry.yearKC)
    UnlockJournaling()
end

local function AddPageAtEnd()
    Blackacre.Chronicle.Capture.AddManual()
    UnlockJournaling()
end

--- TOC right-click: Edit title · Bookmark · New page after · Delete.
local function ShowTocEntryMenu(entry)
    if not entry then return end
    if not journal then return end
    if not journal.tocMenu then
        local m = CreateFrame("Frame", "BlackacreTocMenu", UIParent, "BackdropTemplate")
        m:SetSize(130, 122)
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
        m.insertBtn = Mk(-60, "New page after")
        m.delBtn = Mk(-86, "Delete page")
        journal.tocMenu = m
    end
    local m = journal.tocMenu
    m.pinBtn:SetText(entry.pinned and "Remove bookmark" or "Bookmark page")
    FitButtonWidth(m.pinBtn, 114)
    local widest = math.max(m.editBtn:GetWidth(), m.pinBtn:GetWidth(), m.insertBtn:GetWidth(), m.delBtn:GetWidth())
    m:SetWidth(widest + 16)
    m.editBtn:SetScript("OnClick", function()
        m:Hide()
        ShowTitleEditPopup(entry)
    end)
    m.insertBtn:SetScript("OnClick", function()
        m:Hide()
        InsertPageAfter(entry)
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
                    Blackacre.UI.Theme.Toast("Title updated.", "tome")
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

    local status = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
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

-- Save and detach before the card goes back to the pool.
RetireSticky = function(card)
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
    local host = (resolvedSide == "left") and journal.leftHost or journal.rightHost
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
    local parts = journal and journal._baBodyParts
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

local TOC_LEADERS = string.rep(".", 120)

--- TOC rows are pooled buttons. Each keeps its own FontStrings (row._fs) and
--- reuses them line by line; NextRowFS hands out the next one.
local function NextRowFS(btn)
    local n = btn._fsUsed + 1
    btn._fsUsed = n
    local fs = btn._fs[n]
    if not fs then
        fs = btn:CreateFontString(nil, "OVERLAY")
        btn._fs[n] = fs
    end
    ResetFontString(fs, "GameFontHighlight")
    return fs
end

--- One TOC text row: title left, leaders fill gap, page # flush to leaf edge.
--- Left leaf right-edge = gutter; right leaf right-edge = outer margin (same layout both sides).
local function PlaceTocLine(btn, ly, titleText, pageStr)
    local th = Theme()
    local applyFont = th and th.ApplyReadableBodyFont

    if not pageStr then
        local label = NextRowFS(btn)
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
    local pageFs = NextRowFS(btn)
    pageFs:SetJustifyH("RIGHT")
    pageFs:SetText(pageStr)
    Graphite(pageFs)
    if applyFont then applyFont(pageFs, 0) end
    local pageW = math.max(12, (pageFs:GetStringWidth() or 16) + 1)
    pageFs:SetWidth(pageW)
    pageFs:SetPoint("TOPRIGHT", -6, -ly)

    -- Title left; pin natural width so leader LEFT anchors at real text end
    local titleFs = NextRowFS(btn)
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
    local leaderFs = NextRowFS(btn)
    leaderFs:SetPoint("TOPLEFT", titleFs, "TOPRIGHT", 3, 0)
    leaderFs:SetPoint("TOPRIGHT", pageFs, "TOPLEFT", -3, 0)
    leaderFs:SetJustifyH("LEFT")
    leaderFs:SetWordWrap(false)
    if leaderFs.SetMaxLines then leaderFs:SetMaxLines(1) end
    leaderFs:SetText(TOC_LEADERS)
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

local function TocRow_OnClick(self, button)
    local e = self._baEntry
    if not e then return end
    if button == "RightButton" then
        ShowTocEntryMenu(e)
        return
    end
    if Theme() and Theme().PlayUISound then Theme().PlayUISound("pageTurn") end
    if not JumpToEntrySpread(e.id) and Blackacre.UI and Blackacre.UI.Theme then
        Blackacre.UI.Theme.Toast("Could not open that page.", "tome")
    end
end

local function BuildTocRow(host)
    local btn = CreateFrame("Button", nil, host)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 4)
    hl:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 4)
    if not TryAtlas(hl, "Garr_ListButton-Selection", false) then
        hl:SetColorTexture(0.90, 0.78, 0.35, 0.18)
    elseif hl.SetBlendMode then
        hl:SetBlendMode("ADD")
    end
    btn:SetHighlightTexture(hl)
    btn:SetScript("OnClick", TocRow_OnClick)
    btn._fs = {}
    btn._fsUsed = 0
    return btn
end

-- Heading: one Alliance ribbon, stretched to the phrase. No tile.
local function BuildTocTitle(host)
    local bar = CreateFrame("Frame", nil, host)
    -- Ribbon ends are decorative, so the bar is 25% past the old fit or the phrase sits on the points.
    bar:SetHeight(45)
    local ribbon = bar:CreateTexture(nil, "ARTWORK")
    ribbon:SetAllPoints(bar)
    if ribbon.SetHorizTile then ribbon:SetHorizTile(false) end
    if ribbon.SetVertTile then ribbon:SetVertTile(false) end
    if not TryAtlas(ribbon, "UI-Frame-Alliance-Ribbon", false) then
        TryAtlas(ribbon, "UI-Frame-Dragonflight-Ribbon", false)
    end
    bar.title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bar.title:SetPoint("CENTER", 0, 1)
    bar.title:SetTextColor(1, 0.92, 0.55, 1)
    bar.title:SetDrawLayer("OVERLAY", 1)
    return bar
end

-- Year subheading. Wings sit ~10px off the year text (not the leaf edge).
-- Right wing is a H-flip of the same atlas.
local function BuildTocYear(host)
    local bar = CreateFrame("Frame", nil, host)
    bar:SetHeight(20)
    local fs = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetTextColor(0.95, 0.88, 0.55, 1)
    bar.label = fs
    local wingL = bar:CreateTexture(nil, "ARTWORK")
    wingL:SetSize(46, 18)
    wingL:SetPoint("RIGHT", fs, "LEFT", -10, 0)
    ApplyAtlasMember(wingL, "PetJournal-PetBattleAchievementBG", false)
    local wingR = bar:CreateTexture(nil, "ARTWORK")
    wingR:SetSize(46, 18)
    wingR:SetPoint("LEFT", fs, "RIGHT", 10, 0)
    ApplyAtlasMember(wingR, "PetJournal-PetBattleAchievementBG", true)
    return bar
end

-- Plain rule, not an atlas guess -- swap for a themed divider once the owner
-- points TAV at a real one and we confirm the name.
local function BuildTocRule(host)
    local rule = host:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(0.55, 0.45, 0.25, 0.5)
    return rule
end

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

    local titleBar = AcquireKid("tocTitle", leaf, BuildTocTitle)
    titleBar:SetPoint("TOP", leaf, "TOP", 0, -6)
    titleBar.title:SetText(heading or "Table of Contents")
    local tw = math.ceil(titleBar.title:GetStringWidth() or 130)
    titleBar:SetWidth(math.max(math.ceil((tw + 48) * 1.25), 200))

    local y = -6 - 45 - 8
    for _, row in ipairs(items) do
        if row.kind == "divider" then
            local rule = AcquireKid("tocRule", leaf, BuildTocRule)
            rule:SetPoint("TOP", leaf, "TOP", 0, y - 4)
            rule:SetSize(w - 48, 2)
            y = y - 18
        elseif row.kind == "year" then
            local yearBar = AcquireKid("tocYear", leaf, BuildTocYear)
            yearBar:SetPoint("TOP", leaf, "TOP", 0, y)
            local fs = yearBar.label
            fs:SetWidth(0)
            fs:SetText(row.label or "Undated")
            local yw = math.max(24, fs:GetStringWidth() or 48)
            fs:SetWidth(yw + 2)
            yearBar:SetWidth(yw + 2 + 20 + 92)
            y = y - 26
        elseif row.kind == "entry" and row.entry then
            local e = row.entry
            local pageNum = e._baLeafLeft or e._baSpreadIndex or "?"
            local lines = BuildTocEntryLines(e, pageNum)

            local btn = AcquireKid("tocRow", leaf, BuildTocRow)
            btn:SetFrameLevel(baseLevel)
            btn:SetSize(w - 28, math.max(20, #lines * 16 + 2))
            btn:SetPoint("TOPLEFT", 14, y)
            btn:EnableMouse(true)
            btn._baEntry = e
            for i = 1, #btn._fs do btn._fs[i]:Hide() end
            btn._fsUsed = 0

            local ly = 0
            for _, ln in ipairs(lines) do
                PlaceTocLine(btn, ly, ln.title, ln.isLast and ln.page or nil)
                ly = ly + 15
            end
            y = y - (#lines * 16 + 8)
        end
    end

    if #items == 0 then
        local empty = AcquireFS(leaf, "GameFontHighlight")
        empty:SetPoint("TOPLEFT", 16, -80)
        empty:SetText("No pages yet, try adding a page.")
        Graphite(empty)
    end
end

local function RenderBlankLeaf(leaf)
    ClearLeaf(leaf)
end

--- Freeform page text like Send Mail: no InputBox chrome; black while editing, graphite when locked.
local function PageEdit_OnEscapePressed(self)
    self:ClearFocus()
end

-- Right-click on body/title field → same add-note menu as empty parchment.
-- Reads host/side from the box so a pooled box follows whichever leaf it is on.
local function PageEdit_OnMouseUp(self, button)
    if not self._baLeafSide then return end
    if button == "RightButton" then
        OnLeafRightClick(self._baLeafHost, self._baLeafSide, button)
    elseif button == "LeftButton" then
        RouteClickToSticky(self._baLeafHost, button, self)
    end
end

local PageEdit_OnKeyDown -- Ctrl+Z / Ctrl+Y; assigned with the undo history below

-- Last page the player typed in; toolbar buttons fall back to it.
local lastFocusEntry
local function PageEdit_OnFocusGained(self)
    if self._baEntry then lastFocusEntry = self._baEntry end
end

local function MakePageEditBox(parent, multi)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetMultiLine(multi and true or false)
    box:SetAutoFocus(false)
    box:SetTextInsets(4, 4, 4, 4)
    if box.SetBackdrop then box:SetBackdrop(nil) end
    box:SetScript("OnEscapePressed", PageEdit_OnEscapePressed)
    box:SetScript("OnKeyDown", PageEdit_OnKeyDown)
    box:SetScript("OnEditFocusGained", PageEdit_OnFocusGained)
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
    -- Reused editors keep their old level; pin them just above the leaf so
    -- sticky notes (leaf + 10) always stay on top of the page text.
    box:SetFrameLevel((host:GetFrameLevel() or 1) + 1)
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
    local level = (host:GetFrameLevel() or 1) + 1
    scroll:SetFrameLevel(level)
    scroll._baEdit:SetFrameLevel(level + 1)
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

-- Single write path for a page's text (typing autosave and undo/redo).
local function WriteEntryText(entry, titleText, bodyText)
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
    return updated
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

    local updated = WriteEntryText(entry, titleText, bodyText)
    if updated and showToast and Theme() and Theme().Toast then
        Blackacre.Print("Tome Saved") -- owner: system message, not a toast
    end
    return updated, updated ~= nil
end

------------------------------------------------------------------------
-- Undo / redo (handoff item 2)
-- WoW's EditBox has no undo of its own, so each page keeps a short history
-- of whole-page snapshots (title + full body, not per-leaf slices, so a long
-- entry split across leaves undoes correctly). A snapshot is taken once the
-- player pauses typing for UNDO_IDLE seconds -- not on every keystroke.
-- Undo writes the snapshot back to the store and redraws the spread.
-- History lives for the session only; /reload starts it fresh.
------------------------------------------------------------------------
local UNDO_MAX = 50
local UNDO_IDLE = 0.8
local undoStacks = {}        -- [entryId] = { pos = n, titles = {}, bodies = {} }
local undoPending            -- entry typed into since the last snapshot
local undoLastEdit = 0
local undoTimerArmed = false
local RefreshEditToolbar     -- assigned with the toolbar below

-- Called when a page is drawn editable: records the pre-edit state as the
-- bottom of that page's history.
local function UndoEnsure(entry)
    local s = undoStacks[entry.id]
    if not s then
        s = { pos = 1, titles = { entry.title or "" }, bodies = { entry.body or "" } }
        undoStacks[entry.id] = s
    end
    return s
end

local function UndoCommit(entry)
    local s = UndoEnsure(entry)
    local t, b = entry.title or "", entry.body or ""
    local titles, bodies = s.titles, s.bodies
    if titles[s.pos] == t and bodies[s.pos] == b then return end
    -- Typing after an undo drops the old redo branch, like any text editor.
    for i = #titles, s.pos + 1, -1 do
        titles[i] = nil
        bodies[i] = nil
    end
    s.pos = s.pos + 1
    titles[s.pos], bodies[s.pos] = t, b
    if s.pos > UNDO_MAX then
        table.remove(titles, 1)
        table.remove(bodies, 1)
        s.pos = s.pos - 1
    end
    if RefreshEditToolbar then RefreshEditToolbar() end
end

local function UndoFlush()
    local e = undoPending
    if e then
        undoPending = nil
        UndoCommit(e)
    end
end

-- One shared timer callback (no per-keystroke closure). If the player kept
-- typing since it was armed, it re-arms for the remaining idle time.
local function Undo_OnIdle()
    undoTimerArmed = false
    if not undoPending then return end
    local wait = UNDO_IDLE - (GetTime() - undoLastEdit)
    if wait > 0.05 then
        undoTimerArmed = true
        C_Timer.After(wait, Undo_OnIdle)
        return
    end
    UndoFlush()
end

local function UndoNoteEdit(entry)
    if undoPending and undoPending ~= entry then UndoFlush() end
    undoPending = entry
    undoLastEdit = GetTime()
    if not undoTimerArmed then
        undoTimerArmed = true
        C_Timer.After(UNDO_IDLE, Undo_OnIdle)
    end
end

-- The page the toolbar/hotkeys act on: the focused editor's page first,
-- else the page currently open on the spread.
-- The page the toolbar acts on: the one being typed in; else the one last
-- typed in, if it's still on the open spread; else the open page.
local function UndoTargetEntry()
    local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    if focus and focus._baEntry then return focus._baEntry end
    local last = lastFocusEntry
    local parts = journal and journal._baBodyParts
    if last and parts then
        for i = 1, #parts do
            if parts[i]._baEntry == last then return last end
        end
    end
    return journal and journal.currentEntry
end

local function UndoCanStep(entry, delta)
    local s = entry and undoStacks[entry.id]
    if not s then return false end
    if delta < 0 and undoPending == entry then return true end
    local target = s.pos + delta
    return target >= 1 and target <= #s.titles
end

-- After a redraw, put the cursor back in the page's first body box.
local function RefocusEntry(entry)
    local parts = journal and journal._baBodyParts
    if not entry or not parts then return end
    for i = 1, #parts do
        local box = parts[i]
        if box._baEntry == entry and box:IsEnabled() then
            box:SetFocus()
            box:SetCursorPosition(#(box:GetText() or ""))
            return
        end
    end
end

local function UndoStep(delta)
    if not journalMode or presentationMode then return end
    local entry = UndoTargetEntry()
    if not entry or not entry.id then return end
    local focused = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    if focused and focused._baEntry == entry then
        PersistEntryFromEditors(entry, false)
    end
    UndoFlush()
    local s = undoStacks[entry.id]
    local target = s and (s.pos + delta)
    if not target or target < 1 or target > #s.titles then return end
    s.pos = target
    WriteEntryText(entry, s.titles[target], s.bodies[target])
    Blackacre.Chronicle.UI.RenderSpread()
    RefocusEntry(entry)
end

PageEdit_OnKeyDown = function(self, key)
    if not IsControlKeyDown() then return end
    if key == "Z" then
        UndoStep(IsShiftKeyDown() and 1 or -1)
    elseif key == "Y" then
        UndoStep(1)
    end
end

-- Shared handlers (no per-render closures). A retired editor has no entry,
-- so PersistEntryFromEditors returns early for it.
local function PageEdit_Persist(self, userInput)
    local entry = self._baEntry
    PersistEntryFromEditors(entry, false)
    if userInput == true and entry and entry.id then
        UndoNoteEdit(entry)
    end
end

local function PageEdit_OnFocusLost(self)
    PersistEntryFromEditors(self._baEntry, false)
    UndoFlush()
end

------------------------------------------------------------------------
-- Journaling toolbar (handoff item 2) -- Pass B: owner-named art via Theme.
-- Shown only while Journaling is On. Undo / Redo / A- / A+ / Font.
-- Draggable; its spot is remembered relative to the book.
------------------------------------------------------------------------
local editToolbar

local function ToolbarSettings()
    return Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
end

local function Toolbar_OnDragStop(self)
    self:StopMovingOrSizing()
    local book = self:GetParent()
    local l, t = self:GetLeft(), self:GetTop()
    local bl, bt = book:GetLeft(), book:GetTop()
    if not (l and t and bl and bt) then return end
    local x, y = l - bl, t - bt
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", book, "TOPLEFT", x, y)
    local settings = ToolbarSettings()
    if settings then
        settings.tomeToolbarPos = settings.tomeToolbarPos or {}
        settings.tomeToolbarPos.x, settings.tomeToolbarPos.y = x, y
    end
end

local function Toolbar_OnUndo() UndoStep(-1) end
local function Toolbar_OnRedo() UndoStep(1) end

-- Size and font are PER PAGE (owner call: the toolbar never changes
-- Tome-wide settings; those stay in Options). Stored on the entry as
-- fontSizeOffset / fontKey; nil means "use the Tome-wide default".
-- A WoW EditBox holds one font for all its text, so this can't be per
-- word/selection -- the page is the smallest unit.
local PAGE_SIZE_MIN, PAGE_SIZE_MAX = -4, 8

local function SetPageFont(entry, fontKey, sizeOffset)
    if not entry or not entry.id then return end
    PersistEntryFromEditors(entry, false) -- redraw below re-reads the store
    entry.fontKey = fontKey
    entry.fontSizeOffset = (sizeOffset and sizeOffset ~= 0) and sizeOffset or nil
    Blackacre.Chronicle.Store.Touch()
    Blackacre.Chronicle.UI.RenderSpread()
    RefocusEntry(entry)
end

local function Toolbar_Resize(delta)
    local entry = UndoTargetEntry()
    if not entry then return end
    local n = (entry.fontSizeOffset or 0) + delta
    if n < PAGE_SIZE_MIN then n = PAGE_SIZE_MIN end
    if n > PAGE_SIZE_MAX then n = PAGE_SIZE_MAX end
    SetPageFont(entry, entry.fontKey, n)
end
local function Toolbar_OnSmaller() Toolbar_Resize(-1) end
local function Toolbar_OnBigger() Toolbar_Resize(1) end

local function FontRow_OnClick(self)
    local list = editToolbar.fontList
    local entry = list._baEntry
    list:Hide()
    if entry then SetPageFont(entry, self._baKey, entry.fontSizeOffset) end
end

-- Font picker: a fixed-size shell (owner art) holding a scrolling child
-- list, instead of one list as tall as the whole catalog.
local FONT_LIST_W = 240          -- shell width; height follows the border art's aspect
local FONT_LIST_MIN_H, FONT_LIST_MAX_H = 200, 360
local FONT_ROW_H = 22

local function BuildFontList(bar)
    local list = CreateFrame("Frame", nil, bar)
    list:SetFrameStrata("DIALOG")
    list:EnableMouse(true)
    local th = Theme()
    -- Plain if/then: "a and f()" would keep only f's FIRST return value.
    local bw, bh
    if th and th.ApplyFontListShell then bw, bh = th.ApplyFontListShell(list) end
    local h = (bw and bh) and math.floor(FONT_LIST_W * bh / bw + 0.5) or 280
    if h < FONT_LIST_MIN_H then h = FONT_LIST_MIN_H end
    if h > FONT_LIST_MAX_H then h = FONT_LIST_MAX_H end
    list:SetSize(FONT_LIST_W, h)
    list:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -2)

    -- Insets keep rows inside the QuestLog-frame border; right side leaves
    -- room for the scroll bar.
    local scroll = CreateFrame("ScrollFrame", nil, list, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -18)
    scroll:SetPoint("BOTTOMRIGHT", -36, 18)
    local child = CreateFrame("Frame", nil, scroll)
    local rowW = FONT_LIST_W - 18 - 36
    child:SetWidth(rowW)
    scroll:SetScrollChild(child)

    list.rows = {}
    local catalog = th and th.GetBodyFontCatalog and th.GetBodyFontCatalog() or {}
    for i, row in ipairs(catalog) do
        local b = CreateFrame("Button", nil, child, "UIPanelButtonTemplate")
        b:SetSize(rowW, FONT_ROW_H - 2)
        b:SetPoint("TOPLEFT", 0, -(i - 1) * FONT_ROW_H)
        b._baKey = row.key
        b:SetText(row.name or row.key)
        b:SetScript("OnClick", FontRow_OnClick)
        list.rows[i] = b
    end
    child:SetHeight(math.max(1, #catalog * FONT_ROW_H))
    list:Hide()
    return list
end

local function Toolbar_OnFont()
    local list = editToolbar.fontList
    if not list then
        list = BuildFontList(editToolbar)
        editToolbar.fontList = list
    end
    if list:IsShown() then list:Hide() return end
    local entry = UndoTargetEntry()
    if not entry then return end
    list._baEntry = entry
    local th = Theme()
    -- This page's own font, else the Tome-wide one it's currently showing.
    local active = entry.fontKey or (th and th.Fonts and th.Fonts.activeKey) or "default"
    for _, b in ipairs(list.rows) do
        -- The active font's button is greyed out (disabled): that IS the marker.
        b:SetEnabled(b._baKey ~= active)
    end
    list:Show()
end

local TOOLBAR_BUTTONS = {
    { key = "undo", text = "Undo", w = 54, fn = Toolbar_OnUndo },
    { key = "redo", text = "Redo", w = 54, fn = Toolbar_OnRedo },
    { key = "smaller", text = "A-", w = 34, fn = Toolbar_OnSmaller },
    { key = "bigger", text = "A+", w = 34, fn = Toolbar_OnBigger },
    { key = "font", text = "Font", w = 54, fn = Toolbar_OnFont },
}

local function BuildEditToolbar()
    local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
    local book = hub and hub.bookOpen
    if not book then return nil end
    local bar = CreateFrame("Frame", nil, book, "BackdropTemplate")
    bar:SetFrameLevel(book:GetFrameLevel() + 30)
    local th = Theme()
    -- Owner art (TopHUD 3-slice); plain panel only if that art is missing.
    local barH, capL, capR
    if th and th.ApplyToolbarStrip then barH, capL, capR = th.ApplyToolbarStrip(bar, 40) end
    if not barH and th and th.ApplyFilledPanel then th.ApplyFilledPanel(bar, 0.92, "page") end
    barH = math.max(barH or 32, 28)
    bar:EnableMouse(true)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", Toolbar_OnDragStop)

    -- Buttons start just inside the left cap so they sit on the middle strip.
    local pad = math.max(8, math.floor((capL or 0) * 0.5))
    local x = pad
    bar.buttons = {}
    for _, def in ipairs(TOOLBAR_BUTTONS) do
        local b = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
        b:SetSize(def.w, 22)
        b:SetPoint("LEFT", bar, "LEFT", x, 0)
        b:SetText(def.text)
        b:SetScript("OnClick", def.fn)
        bar.buttons[def.key] = b
        x = x + def.w + 4
    end
    -- Never narrower than the two caps, or the middle strip would invert.
    bar:SetSize(math.max(x - 4 + pad, (capL or 0) + (capR or 0) + 8), barH)

    local settings = ToolbarSettings()
    local pos = settings and settings.tomeToolbarPos
    if pos and pos.x and pos.y then
        bar:SetPoint("TOPLEFT", book, "TOPLEFT", pos.x, pos.y)
    else
        -- Default: sitting just above the book's top edge, centered.
        bar:SetPoint("BOTTOM", book, "TOP", 0, 4)
    end
    bar:Hide()
    return bar
end

RefreshEditToolbar = function()
    local want = journalMode and not presentationMode
    if not want then
        if editToolbar then editToolbar:Hide() end
        return
    end
    if not editToolbar then
        editToolbar = BuildEditToolbar()
        if not editToolbar then return end
    end
    local entry = UndoTargetEntry()
    local btn = editToolbar.buttons
    btn.undo:SetEnabled(UndoCanStep(entry, -1))
    btn.redo:SetEnabled(UndoCanStep(entry, 1))
    -- Size/font act on one page; nothing to act on from the contents pages.
    local hasPage = entry ~= nil
    btn.smaller:SetEnabled(hasPage)
    btn.bigger:SetEnabled(hasPage)
    btn.font:SetEnabled(hasPage)
    if not hasPage and editToolbar.fontList then editToolbar.fontList:Hide() end
    editToolbar:Show()
end

local function BodyScroll_OnMouseUp(self, button)
    local edit = self._baEdit
    if button == "LeftButton" and edit and RouteClickToSticky(edit._baLeafHost, button, edit) then
        return
    end
    if button == "LeftButton" and edit and edit:IsEnabled() and not edit:HasFocus() then
        edit:SetFocus()
        edit:SetCursorPosition(#(edit:GetText() or ""))
    elseif button == "RightButton" and edit and edit._baLeafSide then
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
    if editing and entry.id then UndoEnsure(entry) end

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
        titleEdit:SetScript("OnEditFocusLost", PageEdit_OnFocusLost)
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
        local meta = AcquireFS(host, "GameFontHighlight")
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
        yTop = yTop - 36
    elseif leafData.isContinuation then
        local cont = AcquireFS(host, "GameFontDisableSmall")
        cont:SetPoint("TOPLEFT", padLeft, yTop)
        cont:SetText("(continued)")
        Graphite(cont)
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
    -- Per-page size/font from the Journaling toolbar (nil = Tome-wide defaults).
    Blackacre.UI.Theme.ApplyReadableBodyFont(bodyEdit, 2 + (entry.fontSizeOffset or 0), entry.fontKey)
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
    bodyEdit:SetScript("OnEditFocusLost", PageEdit_OnFocusLost)

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

---@param skipRebuild boolean|nil true = use current spreads (caller already rebuilt)
function Blackacre.Chronicle.UI.RenderSpread(skipRebuild)
    if not journal then return end
    HideStickyMenu()
    HideAddNoteMenu()
    if journal.tocMenu then journal.tocMenu:Hide() end
    if journal.addMenu then journal.addMenu:Hide() end
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
    RefreshEditToolbar()
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
        Blackacre.Print("Tome Saved") -- owner: system message, not a toast
    end
    Blackacre.Chronicle.UI.RenderSpread()
end

--- Header "Add page": at the end of the book, or right after the page that
--- is open. On the contents pages there is no "this page", so it just adds.
function Blackacre.Chronicle.UI.OnAddPageClicked(anchor)
    Blackacre.Chronicle.UI.EnsureBuilt()
    local current = GetSpreadEntry(spreads[spreadIndex])
    if not current then
        AddPageAtEnd()
        return
    end
    local m = journal.addMenu
    if not m then
        m = CreateFrame("Frame", "BlackacreAddPageMenu", UIParent, "BackdropTemplate")
        m:SetFrameStrata("FULLSCREEN_DIALOG")
        if Theme() and Theme().ApplyChromeMenuFrame then Theme().ApplyChromeMenuFrame(m) end
        m:EnableMouse(true)
        m:Hide()
        local function Mk(y, label)
            local b = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
            b:SetHeight(22)
            b:SetPoint("TOP", 0, y)
            b:SetText(label)
            return b
        end
        m.afterBtn = Mk(-8, "New page after this one")
        m.endBtn = Mk(-34, "New page at the end")
        journal.addMenu = m
    end
    FitButtonWidth(m.afterBtn, 180)
    FitButtonWidth(m.endBtn, 180)
    local w = math.max(m.afterBtn:GetWidth(), m.endBtn:GetWidth())
    m.afterBtn:SetWidth(w)
    m.endBtn:SetWidth(w)
    m:SetSize(w + 16, 64)
    m.afterBtn:SetScript("OnClick", function()
        m:Hide()
        InsertPageAfter(current)
    end)
    m.endBtn:SetScript("OnClick", function()
        m:Hide()
        AddPageAtEnd()
    end)
    m:ClearAllPoints()
    m:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
    m:Show()
end

-- Footer no longer mounts Save/Add/Pin/Delete text tools (icon + TOC menus instead).
-- The one footer tool: the Quest Index, the player's quest history.
local function MountToolsOnParentFooter()
    local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
    if not hub or not hub.toolStrip or hub.toolStrip._baBuilt then return end
    hub.toolStrip._baBuilt = true
    local b = CreateFrame("Button", nil, hub.toolStrip, "UIPanelButtonTemplate")
    b:SetHeight(26)
    b:SetPoint("LEFT", 0, 0)
    b:SetText("Quest Index")
    FitButtonWidth(b, 110)
    b:SetScript("OnClick", function()
        if Theme() and Theme().PlayUISound then Theme().PlayUISound("toolClick") end
        Blackacre.QuestIndex.Toggle()
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Quest Index")
        GameTooltip:AddLine("Every quest you've taken up and finished, in their own words.", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
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

-- Put each leaf's layered pieces back in order (page text under its notes).
-- The window-focus code calls this after raising the book.
local function RelevelLeaf(host)
    local kids = host and host._baKids
    if not kids then return end
    local base = host:GetFrameLevel() or 1
    for i = 1, #kids do
        local k = kids[i]
        local kind = k._baPool
        if kind == "sticky" then
            SetStickyLevels(k, host)
        elseif kind == "bodyScroll" then
            k:SetFrameLevel(base + 1)
            k._baEdit:SetFrameLevel(base + 2)
        elseif kind == "title" then
            k:SetFrameLevel(base + 1)
        end
    end
end

function Blackacre.Chronicle.UI.Relevel()
    if not journal then return end
    local left, right = journal.leftHost, journal.rightHost
    if not left or not right then return end
    local want = (left:GetParent() and left:GetParent():GetFrameLevel() or 1) + 10
    if (left:GetFrameLevel() or 0) < want then left:SetFrameLevel(want) end
    if (right:GetFrameLevel() or 0) < want then right:SetFrameLevel(want) end
    RelevelLeaf(left)
    RelevelLeaf(right)
end

function Blackacre.Chronicle.UI.EnsureBuilt()
    if not journal then
        BuildUI()
        local hub = Blackacre.TomeHub and Blackacre.TomeHub.GetFrame and Blackacre.TomeHub.GetFrame()
        if hub then hub._baOnRaised = Blackacre.Chronicle.UI.Relevel end
    end
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
