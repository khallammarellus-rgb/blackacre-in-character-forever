-- In Character Forever: Beacons & Bulletins - My Postings

Blackacre = Blackacre or {}
Blackacre.MyPostings = {}

local pairs, time, sort = pairs, time, table.sort

local HEADER_ROW_H = 20
local LIVE_ROW_H = 40
local PAST_ROW_H = 26

-- Same zebra colors as the Tome Quest Index's list / Yellow Pages.
local ZEBRA_DARK = { 0, 0, 0, 0.35 }
local ZEBRA_LIGHT = { 0.35, 0.35, 0.37, 0.22 }

local frame
local rows = {}   -- pooled row frames, one per flattened item
local items = {}  -- flattened, rebuilt on refresh
local RenderList  -- defined below, called by row click handlers above it

local function MyLiveNotices()
    local me = UnitGUID("player")
    local now = time()
    local list = {}
    for _, b in pairs(BlackacreDB.bulletins or {}) do
        if b.ownerGUID == me and b.status == Blackacre.STATUS.ACTIVE
            and (not b.expiresAt or b.expiresAt > now) then
            list[#list + 1] = b
        end
    end
    sort(list, function(a, b) return (a.createdAt or 0) > (b.createdAt or 0) end)
    return list
end

local function Describe(b)
    local where = b.innNpcID and ("with " .. (b.innName or "one innkeeper"))
        or ("at the inns of " .. ((b.zoneName and b.zoneName ~= "") and b.zoneName or "a region"))
    if b.factionNet then where = where .. ", spread through " .. b.factionNet end
    local left = (b.expiresAt or 0) - time()
    local hours = math.max(0, math.floor(left / 3600))
    local until_ = hours >= 24 and (math.floor(hours / 24) .. "d " .. (hours % 24) .. "h") or (hours .. "h")
    return (b.title and b.title ~= "" and b.title or "Untitled notice"), where .. " · " .. until_ .. " left"
end

StaticPopupDialogs["BLACKACRE_WITHDRAW_NOTICE"] = {
    text = "Take down \"%s\"? It disappears from every inn.",
    button1 = YES,
    button2 = NO,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(_, id)
        Blackacre.Lifecycle.DeleteOwned("bulletin", id)
        Blackacre.Print("Notice withdrawn.")
        Blackacre.MyPostings.Refresh()
        if Blackacre.InnBoard and Blackacre.InnBoard.RefreshIfOpen then Blackacre.InnBoard.RefreshIfOpen() end
        -- Taking one down may free a slot at the innkeeper you're talking to.
        if Blackacre.InnBoard and Blackacre.InnBoard.RefreshPostButton then Blackacre.InnBoard.RefreshPostButton() end
    end,
}

local function BuildItems()
    for i = #items, 1, -1 do items[i] = nil end
    local saved = Blackacre.Lifecycle.GetSavedBulletins()
    if #saved > 0 then
        items[#items + 1] = { kind = "header", label = "Saved Drafts" }
        for _, d in ipairs(saved) do
            items[#items + 1] = { kind = "saved", rec = d }
        end
    end
    local live = MyLiveNotices()
    if #live > 0 then
        items[#items + 1] = { kind = "header", label = "Live Notices" }
        for _, b in ipairs(live) do
            items[#items + 1] = { kind = "live", rec = b }
        end
    end
    local past = Blackacre.History.GetDrafts("bulletin")
    if #past > 0 then
        items[#items + 1] = { kind = "header", label = "Past Notices" }
        for _, b in ipairs(past) do
            items[#items + 1] = { kind = "past", rec = b }
        end
    end
    if #items == 0 then
        items[#items + 1] = { kind = "empty", label = "No drafts or notices yet. Write one and Save draft." }
    end
end

local function ItemHeight(it)
    if it.kind == "header" then return HEADER_ROW_H end
    if it.kind == "past" then return PAST_ROW_H end
    if it.kind == "empty" then return 40 end
    if it.kind == "saved" then return LIVE_ROW_H end
    return LIVE_ROW_H
end

-- Right-click a saved draft or a past notice: a one-line menu to get rid of
-- it, then a confirm. Same small chrome menu as the inn board's, closed by
-- any click outside it.
local rowMenu

local function RefreshAfterChange()
    if Blackacre.InnBoard and Blackacre.InnBoard.RefreshPostButton then
        Blackacre.InnBoard.RefreshPostButton()
    end
    RenderList()
end

StaticPopupDialogs["BLACKACRE_DELETE_DRAFT"] = {
    text = "Delete the draft \"%s\"? This can't be undone.",
    button1 = DELETE,
    button2 = CANCEL,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(_, id)
        Blackacre.Lifecycle.DeleteSavedBulletin(id)
        RefreshAfterChange()
    end,
}

StaticPopupDialogs["BLACKACRE_REMOVE_PAST_NOTICE"] = {
    text = "Remove \"%s\" from your past notices?",
    button1 = "Remove",
    button2 = CANCEL,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(_, rec)
        Blackacre.History.RemoveDraft("bulletin", rec)
        RefreshAfterChange()
    end,
}

local function EnsureRowMenu()
    if rowMenu then return rowMenu end
    local m = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    Blackacre.UI.Theme.ApplyChromeMenuFrame(m)
    m:SetFrameStrata("DIALOG")
    m:SetSize(160, 34)
    m:Hide()
    m:SetScript("OnShow", function(self) self:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
    m:SetScript("OnHide", function(self) self:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
    m:SetScript("OnEvent", function(self)
        if not self:IsMouseOver() then self:Hide() end
    end)
    m.btn = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
    m.btn:SetSize(140, 20)
    m.btn:SetPoint("TOP", 0, -6)
    m.btn:SetScript("OnClick", function()
        m:Hide()
        local it = m.item
        if not it then return end
        local rec = it.rec
        if it.kind == "saved" then
            local dialog = StaticPopup_Show("BLACKACRE_DELETE_DRAFT", rec.draftName or "this draft")
            if dialog then dialog.data = rec.id end
        else
            local dialog = StaticPopup_Show("BLACKACRE_REMOVE_PAST_NOTICE",
                (rec.title and rec.title ~= "") and rec.title or "this notice")
            if dialog then dialog.data = rec end
        end
    end)
    rowMenu = m
    return m
end

local function Row_OnClick(self, button)
    local it = self._baItem
    if not it then return end
    if button == "LeftButton" then
        -- Click a saved draft to open it in the Bulletin editor.
        if it.kind == "saved" and Blackacre.PostEditor and Blackacre.PostEditor.EditDraft then
            Blackacre.PostEditor.EditDraft(it.rec)
        end
        return
    end
    local m = EnsureRowMenu()
    m.item = it
    m.btn:SetText(it.kind == "saved" and "Delete draft" or "Remove from list")
    m:ClearAllPoints()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    m:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    m:Show()
end

local function Row_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    if self._baItem.kind == "saved" then
        GameTooltip:SetText("Click to edit. Right-click to delete.", 1, 1, 1)
        GameTooltip:AddLine("Post it at any innkeeper: Post Notice.", 0.8, 0.8, 0.8, true)
    else
        GameTooltip:SetText("Right-click to remove this from the list", 1, 1, 1)
        GameTooltip:AddLine("Repost it at any innkeeper: Post Notice.", 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
end

local function MakeRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", Row_OnClick)
    row:SetScript("OnEnter", Row_OnEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row.zebra = row:CreateTexture(nil, "BACKGROUND", nil, -1)
    row.zebra:SetAllPoints()
    row.hover = row:CreateTexture(nil, "HIGHLIGHT")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(1, 0.82, 0, 0.15)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 4, -2)
    row.title:SetWidth(280)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)
    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.info:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
    row.info:SetWidth(280)
    row.info:SetJustifyH("LEFT")
    row.info:SetWordWrap(false)
    -- Withdraw: takes a live notice down for good (network-wide retraction).
    row.withdraw = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.withdraw:SetSize(90, 22)
    row.withdraw:SetPoint("RIGHT", -4, 0)
    row.withdraw:SetText("Deactivate")
    row.withdraw:SetScript("OnClick", function()
        local b = row.bulletin
        if not b then return end
        local dialog = StaticPopup_Show("BLACKACRE_WITHDRAW_NOTICE", b.title ~= "" and b.title or "this notice")
        if dialog then dialog.data = b.id end
    end)
    return row
end

local function PaintRow(row, it, i)
    row.bulletin = it.rec
    row._baItem = it
    -- Only saved drafts and past notices have a right-click menu.
    row:EnableMouse(it.kind == "saved" or it.kind == "past")
    row.zebra:Show()
    row.withdraw:Hide()
    row.info:SetText("")
    if it.kind == "header" then
        row.zebra:Hide()
        row.title:SetFontObject(GameFontNormal)
        row.title:SetPoint("TOPLEFT", 4, -2)
        row.title:SetText("|cffc9a227" .. it.label .. "|r")
    elseif it.kind == "empty" then
        row.zebra:Hide()
        row.title:SetFontObject(GameFontHighlight)
        row.title:SetPoint("TOPLEFT", 4, -2)
        row.title:SetText(it.label)
    else
        local z = (i % 2 == 0) and ZEBRA_LIGHT or ZEBRA_DARK
        row.zebra:SetColorTexture(z[1], z[2], z[3], z[4])
        row.title:SetFontObject(GameFontNormal)
        row.title:SetPoint("TOPLEFT", 4, -2)
        if it.kind == "live" then
            local title, info = Describe(it.rec)
            row.title:SetText(title)
            row.info:SetText(info)
            row.withdraw:Show()
        elseif it.kind == "saved" then
            row.title:SetText(it.rec.draftName or "Untitled draft")
            row.info:SetText((it.rec.title and it.rec.title ~= "") and it.rec.title or "")
        else -- "past"
            row.title:SetText((it.rec.title and it.rec.title ~= "") and it.rec.title or "Untitled notice")
        end
    end
end

RenderList = function()
    if not frame or not frame:IsShown() then return end
    BuildItems()
    local content = frame.child
    local y = 0
    for i, it in ipairs(items) do
        local row = rows[i]
        if not row then
            row = MakeRow(content)
            rows[i] = row
        end
        local h = ItemHeight(it)
        row:SetHeight(h)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", 0, -y)
        PaintRow(row, it, i)
        row:Show()
        y = y + h
    end
    for i = #items + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(1, y))
end

local function Build()
    local th = Blackacre.UI.Theme
    local f = CreateFrame("Frame", "BlackacreMyPostings", UIParent, "BackdropTemplate")
    f:SetSize(440, 460)
    f:SetPoint("CENTER", -200, 0)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "BlackacreMyPostings")
    Blackacre.UI.Focus.Register(f)
    th.ApplyHeavyBronzeBase(f)

    f.header = CreateFrame("Frame", nil, f)
    f.header:SetPoint("TOPLEFT", 6, -6)
    f.header:SetPoint("TOPRIGHT", -6, -6)
    f.header:SetHeight(30)

    f.title = f.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("CENTER", 0, 9)
    f.title:SetText("My Postings")
    th.GoldTitle(f.title)

    local close = CreateFrame("Button", nil, f.header, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("RIGHT", -2, 6)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Same scroll list chrome as the Tome Quest Index's history panel /
    -- Yellow Pages (quest-log frame border over the Journeys background).
    f.listPanel = CreateFrame("Frame", nil, f)
    f.listPanel:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 2, -8)
    f.listPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    th.ApplyQuestLogListPanel(f.listPanel)

    local scroll = CreateFrame("ScrollFrame", nil, f.listPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(f.listPanel:GetWidth() - 38, 10)
    scroll:SetScrollChild(child)
    f.child = child

    frame = f
end

function Blackacre.MyPostings.Refresh()
    RenderList()
end

function Blackacre.MyPostings.Toggle()
    if not frame then Build() end
    if frame:IsShown() then
        frame:Hide()
        return
    end
    frame:Show()
    RenderList()
end
