-- In Character Forever: Beacons & Bulletins - Inn Board

Blackacre = Blackacre or {}
Blackacre.InnBoard = {}

local seeBtn
local postBtn
local listFrame
local detailFrame
local rows = {}
local listed = {}

local ROW_H = 20
local LIST_TOP_PAD = 8 -- first row sits this far below the top of the scroll area
local ZEBRA_DARK = { 0, 0, 0, 0.35 }
local ZEBRA_LIGHT = { 0.35, 0.35, 0.37, 0.22 }
-- Size of the Bulletin editor's parchment preview; the board's paper area is
-- exactly this, so opening a posting swaps the list for the page in place.
-- (read lazily: the editor file may load after this one)
local function PaperSize()
    local pe = Blackacre.PostEditor
    return (pe and pe.PREVIEW_W) or 294, (pe and pe.PREVIEW_H) or 380
end
local BOARD_PAD_X, BOARD_PAD_TOP, BOARD_PAD_BOTTOM = 20, 36, 20

-- Innkeeper = a gossip option carrying the bind-home icon (see YellowPages.lua).
local function IsInnkeeperGossip()
    return Blackacre.YellowPages and Blackacre.YellowPages.IsInnkeeperGossip() or false
end

local SpreadGate -- defined above PostDraftHere
local ShowDetail -- defined below EnsureDetail, used by row clicks above it
local TOAST_TEXT = "See your inn keeper in the region for news around these parts."

local function FormatStamp(ts)
    if not ts then return "unknown" end
    return date("%Y-%m-%d %I:%M %p", ts)
end

-- Which notices this character has opened, so unread ones can sort first.
local function ReadSet()
    local s = Blackacre.CharDB and Blackacre.CharDB.settings
    if not s then return {} end
    s.readBulletins = s.readBulletins or {}
    return s.readBulletins
end

local function IsRead(id)
    return id ~= nil and ReadSet()[id] == true
end

local function MarkRead(id)
    if id then ReadSet()[id] = true end
end

-- inn: the Yellow Pages row of the innkeeper being asked (filters "Only this
-- inn" notices and matches that innkeeper's faction network), or nil for the
-- whole region (toasts), which matches any faction with a known inn here.
local function CachedBulletinsForHere(inn)
    local key, name = Blackacre.Boards.CurrentZoneKey()
    local out, seen = {}, {}
    local now = time()
    local muted = Blackacre.IsMuted
    local innNpcID = inn and inn.npcID
    local factions
    if inn then
        factions = inn.repFactionName and { [inn.repFactionName] = true } or nil
    else
        factions = Blackacre.YellowPages.FactionsInZone(Blackacre.GetZoneSnapshot().zoneName)
    end
    local function consider(b)
        if not b or not b.id or seen[b.id] then return end
        if b.expiresAt and b.expiresAt < now then return end
        if muted(b.authorName) or muted(b.ownerGUID) then return end
        if Blackacre.Boards.BulletinMatchesZone(b, key, name, innNpcID, factions) then
            seen[b.id] = true -- our own notice sits in two stores; list it once
            out[#out + 1] = b
        end
    end
    for _, b in pairs(BlackacreDB.bulletins or {}) do consider(b) end
    local cache = BlackacreDB.cache and (BlackacreDB.cache.bulletin or BlackacreDB.cache.notice)
    if cache then
        for _, wrapped in pairs(cache) do
            consider(wrapped.data)
        end
    end
    -- Unread first, then soonest-to-expire — a board is for what needs
    -- attention now, not a feed of what's newest.
    table.sort(out, function(a, b)
        local ra, rb = IsRead(a.id), IsRead(b.id)
        if ra ~= rb then return not ra end
        return (a.expiresAt or math.huge) < (b.expiresAt or math.huge)
    end)
    return out
end

local function ApplyStationery(tex, bulletin)
    if Blackacre.PostEditor and Blackacre.PostEditor.PaintStationery then
        Blackacre.PostEditor.PaintStationery(tex, bulletin and bulletin.stationary)
        return
    end
    if tex then tex:SetTexture("Interface\\QuestFrame\\QuestBackgroundParchment") end
end

local function ApplySeal(tex, bulletin)
    if Blackacre.PostEditor and Blackacre.PostEditor.PaintSeal then
        Blackacre.PostEditor.PaintSeal(tex, bulletin and bulletin.waxSeal)
        return
    end
    if tex then tex:Hide() end
end

StaticPopupDialogs["BLACKACRE_COPY_NAME"] = {
    text = "Copy poster name (Ctrl+C):",
    button1 = OKAY,
    hasEditBox = true,
    editBoxWidth = 240,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self, data)
        local box = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
        if box then
            box:SetText(data or "")
            box:HighlightText()
            box:SetFocus()
        end
    end,
}

-- Small right-click menu: Remove posting (only for the player's own) and
-- Copy poster name (always). Not a real OS clipboard — WoW add-ons can't
-- write to one — so "copy" means a pre-selected edit box for Ctrl+C, same
-- convention as Report.lua's evidence text.
local contextMenu

local function EnsureContextMenu()
    if contextMenu then return contextMenu end
    local m = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    Blackacre.UI.Theme.ApplyChromeMenuFrame(m)
    m:SetFrameStrata("DIALOG")
    m:SetSize(160, 60)
    m:Hide()
    -- Click anywhere outside the menu closes it (the click itself still goes through).
    m:SetScript("OnShow", function(self) self:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
    m:SetScript("OnHide", function(self) self:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
    m:SetScript("OnEvent", function(self)
        if not self:IsMouseOver() then self:Hide() end
    end)

    local function MakeBtn(i)
        local b = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
        b:SetSize(140, 20)
        b:SetPoint("TOP", 0, -6 - (i - 1) * 24)
        return b
    end
    m.removeBtn = MakeBtn(1)
    m.removeBtn:SetText("Remove posting")
    m.copyBtn = MakeBtn(2)
    m.copyBtn:SetText("Copy poster name")
    contextMenu = m
    return m
end

local function ShowContextMenu(b)
    local m = EnsureContextMenu()
    local mine = b.ownerGUID == UnitGUID("player")
    m.removeBtn:SetShown(mine)
    m.copyBtn:ClearAllPoints()
    m.copyBtn:SetPoint("TOP", 0, mine and -30 or -6)
    m:SetHeight(mine and 60 or 34)
    m.removeBtn:SetScript("OnClick", function()
        m:Hide()
        local dialog = StaticPopup_Show("BLACKACRE_WITHDRAW_NOTICE", b.title ~= "" and b.title or "this notice")
        if dialog then dialog.data = b.id end
    end)
    m.copyBtn:SetScript("OnClick", function()
        m:Hide()
        StaticPopup_Show("BLACKACRE_COPY_NAME", nil, nil, b.authorName or b.charName or "Unknown")
    end)
    m:ClearAllPoints()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    m:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    m:Show()
end

local function MakeRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.zebra = row:CreateTexture(nil, "BACKGROUND", nil, -1)
    row.zebra:SetAllPoints()
    row.hover = row:CreateTexture(nil, "HIGHLIGHT")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(1, 0.82, 0, 0.15)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", 6, 0)
    row.text:SetPoint("RIGHT", -6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row:SetScript("OnClick", function(self, button)
        if not self.bulletin then return end
        if button == "RightButton" then
            ShowContextMenu(self.bulletin)
        else
            ShowDetail(self.bulletin)
        end
    end)
    row:SetScript("OnEnter", function(self)
        if not self.bulletin then return end
        local b = self.bulletin
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(b.authorName or b.charName or "Unknown")
        GameTooltip:AddLine("Expires: " .. FormatStamp(b.expiresAt), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Posted: " .. FormatStamp(b.postedAt or b.createdAt), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click for options", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    return row
end

local function PaintRow(row, b, i)
    local z = (i % 2 == 0) and ZEBRA_LIGHT or ZEBRA_DARK
    row.zebra:SetColorTexture(z[1], z[2], z[3], z[4])
    row.bulletin = b
    local title = Blackacre.Languages.ForReader(b.title or "Bulletin", b.lang)
    -- Unread: gold. Read: plain white.
    if IsRead(b.id) then
        row.text:SetText(title)
    else
        row.text:SetText("|cffffd200" .. title .. "|r")
    end
end

local function EnsureList()
    if listFrame then return listFrame end
    local f = CreateFrame("Frame", "BlackacreInnPostings", UIParent)
    local pw, ph = PaperSize()
    f:SetSize(pw + BOARD_PAD_X * 2, ph + BOARD_PAD_TOP + BOARD_PAD_BOTTOM)
    f:SetPoint("CENTER", 80, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, "BlackacreInnPostings")
    Blackacre.UI.Focus.Register(f)
    f:SetScript("OnHide", function()
        if contextMenu then contextMenu:Hide() end
    end)

    -- Corkboard base, behind everything.
    f.board = f:CreateTexture(nil, "BACKGROUND")
    f.board:SetAllPoints()
    Blackacre.UI.Theme.TrySetAtlas(f.board, "warboard-background", false)

    -- Wooden outer frame around the board (Tavern skin's own nine-slice
    -- pieces, not whatever chrome skin the player has picked elsewhere) —
    -- makes the corkboard read as an actual board, not a flat texture.
    local border = Blackacre.UI.Theme.ApplyTavernFrameBorder(f)

    -- Signboard + heading sit above the wooden border (own frame, higher
    -- level than the border host), since the sign overlaps down onto the
    -- board's top edge where the border's own corner art also draws.
    f.signHost = CreateFrame("Frame", nil, f)
    f.signHost:SetAllPoints(f)
    f.signHost:EnableMouse(false)
    f.signHost:SetFrameLevel((border:GetFrameLevel() or 1) + 1)

    -- Wooden signboard hanging above the board's own top edge, like a shop
    -- sign, holding the heading.
    f.sign = f.signHost:CreateTexture(nil, "OVERLAY")
    f.sign:SetPoint("BOTTOM", f, "TOP", 0, -10)
    Blackacre.UI.Theme.TrySetAtlas(f.sign, "islands-queue-difficultyselector-backboard", true)
    -- 15% smaller than the atlas's native size.
    local signW, signH = f.sign:GetSize()
    if signW and signW > 0 then f.sign:SetSize(signW * 0.85, signH * 0.85) end
    f.title = f.signHost:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("CENTER", f.sign, "CENTER", 0, 6)
    f.title:SetText("Postings")
    Blackacre.UI.Theme.GoldTitle(f.title)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetFrameLevel((border:GetFrameLevel() or 1) + 2)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Parchment pop-out (this repo's reusable "content/detail panel that
    -- reads as a page or note inside the shell" template) pinned to the
    -- corkboard, holding the actual scrollable list.
    f.panel = CreateFrame("Frame", nil, f)
    f.panel:SetPoint("TOPLEFT", BOARD_PAD_X, -BOARD_PAD_TOP)
    f.panel:SetPoint("BOTTOMRIGHT", -BOARD_PAD_X, BOARD_PAD_BOTTOM)
    Blackacre.UI.Theme.ApplyParchmentPopupFill(f.panel)

    -- Own frame so the parchment's art layers can never draw over the text.
    f.emptyHost = CreateFrame("Frame", nil, f.panel)
    f.emptyHost:SetAllPoints()
    f.emptyHost:SetFrameLevel(f.panel:GetFrameLevel() + 3)
    f.empty = f.emptyHost:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.empty:SetPoint("CENTER")
    f.empty:SetTextColor(0, 0, 0)
    f.empty:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, f.panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -22)
    scroll:SetPoint("BOTTOMRIGHT", -28, 14)
    f.scroll = scroll
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    -- Rows anchor left+right to the child, so it needs the scroll's real width
    -- (a 1px child collapses every row to nothing).
    scroll:SetScript("OnSizeChanged", function(_, w) child:SetWidth(w) end)
    child:SetWidth(pw - 14 - 28)
    f.child = child

    listFrame = f
    return f
end

-- The opened posting is a child of the board's paper area, same size as the
-- Bulletin editor's preview, so it reads as the page sitting on the board.
local function EnsureDetail()
    if detailFrame then return detailFrame end
    local list = EnsureList()
    local f = CreateFrame("Frame", nil, list.panel)
    f:SetAllPoints(list.panel)
    f:SetFrameLevel(list.panel:GetFrameLevel() + 10)
    f:EnableMouse(true) -- don't let clicks fall through to the list underneath
    -- Same quest-log frame + backdrop the Bulletin editor's preview has, with
    -- the paper sitting inside it (applied after the level is set: it pins its
    -- clip host to the frame's level).
    Blackacre.UI.Theme.ApplyQuestLogListPanel(f)
    f:Hide()
    f.paper = f:CreateTexture(nil, "ARTWORK")
    f.seal = f:CreateTexture(nil, "OVERLAY")
    f.seal:SetSize(48, 48)
    f.seal:Hide()
    -- Body is BBCode ({quest}/{questTitle}/{b} etc, see PostEditor.lua's
    -- ParseBBCode/RenderBBCode) rendered as stacked FontStrings, same
    -- renderer the Bulletin editor uses for its live parchment preview, so
    -- what the author saw while composing is what a reader sees here.
    f.bodyHost = CreateFrame("Frame", nil, f)
    f.bodyPool = {}

    -- Back to the full list of postings.
    f.back = CreateFrame("Button", nil, f)
    f.back:SetSize(28, 28)
    f.back:SetPoint("BOTTOMLEFT", 12, 12)
    pcall(f.back.SetNormalAtlas, f.back, "128-RedButton-Refresh")
    pcall(f.back.SetPushedAtlas, f.back, "128-RedButton-Refresh-Pressed")
    f.back:SetScript("OnClick", function() Blackacre.InnBoard.HideDetail() end)

    f.journal = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.journal:SetSize(80, 22)
    f.journal:SetPoint("BOTTOM", 0, 15)
    f.journal:SetText("Journal")
    f.report = Blackacre.Report.MakeButton(f, function()
        Blackacre.Report.Bulletin(f.bulletin)
    end)
    f.report:SetPoint("BOTTOMRIGHT", -12, 15)
    detailFrame = f
    return f
end

-- Fit the stationery into the paper area (keeping its proportions, like the
-- editor's preview) and set the text area inside it.
local function LayoutPaper(f, bulletin)
    local pw, ph = PaperSize()
    local natW, natH = 299, 407
    if Blackacre.PostEditor and Blackacre.PostEditor.StationeryNativeSize then
        natW, natH = Blackacre.PostEditor.StationeryNativeSize(bulletin.stationary)
    end
    local scale = math.min((pw - 10) / natW, (ph - 10) / natH)
    local w, h = natW * scale, natH * scale
    f.paper:ClearAllPoints()
    f.paper:SetSize(w, h)
    f.paper:SetPoint("CENTER", f, "CENTER", 0, 0)
    local insetX = math.floor(w * 0.1)
    local insetTop = math.floor(h * 0.11)
    local insetBot = math.floor(h * 0.09)
    local bodyW = w - insetX * 2
    f.bodyHost:ClearAllPoints()
    f.bodyHost:SetPoint("TOPLEFT", f.paper, "TOPLEFT", insetX, -insetTop)
    f.bodyHost:SetSize(bodyW, h - insetTop - insetBot - 34)
    f.seal:ClearAllPoints()
    f.seal:SetPoint("BOTTOMRIGHT", f.paper, "BOTTOMRIGHT", -math.floor(w * 0.04), math.floor(h * 0.05) + 30)
end

-- Tome pages are always first person: frame the notice as something I read,
-- with the notice itself quoted underneath.
function Blackacre.InnBoard.JournalPage(bulletin)
    local zone = bulletin.zoneName
    if not zone or zone == "" then
        local _, name = Blackacre.Boards.CurrentZoneKey()
        zone = name
    end
    local where = (zone and zone ~= "") and ("the inn in " .. zone) or "the inn"
    local title = (zone and zone ~= "") and ("A notice in " .. zone) or "A notice at the inn"
    if not Blackacre.Languages.Knows(bulletin.lang) then
        return title, "I found a notice pinned up at " .. where .. ", written in " .. bulletin.lang
            .. ". I couldn't make out a word of it."
    end
    -- Quote the notice's name above it, unless the name is just its own
    -- first line (older notices), which would print that line twice.
    local name = bulletin.title or ""
    local heading = ""
    if name ~= "" and name ~= Blackacre.PostEditor.DeriveTitle(bulletin.bodyText or "") then
        heading = "\"" .. name .. "\"\n"
    end
    local body = "I read a notice pinned up at " .. where .. ". It read:\n\n"
        .. heading .. Blackacre.PostEditor.StripBBCode(bulletin.bodyText or "")
    return title, body
end

ShowDetail = function(bulletin)
    local f = EnsureDetail()
    f.bulletin = bulletin
    local wasUnread = bulletin.id and not IsRead(bulletin.id)
    MarkRead(bulletin.id)
    if wasUnread then Blackacre.InnBoard.RefreshIfOpen() end
    ApplyStationery(f.paper, bulletin)
    ApplySeal(f.seal, bulletin)
    LayoutPaper(f, bulletin)
    -- Just the letter, like the editor's preview: its title is only its own
    -- first line, so drawing a title above it showed that line twice.
    -- Written in a tongue we don't know? Then we only see gibberish.
    Blackacre.PostEditor.RenderBBCode(f.bodyHost, f.bodyPool,
        Blackacre.Languages.ForReader(bulletin.bodyText or "", bulletin.lang), bulletin.font)
    -- You can't report your own notice.
    f.report:SetShown(bulletin.ownerGUID ~= UnitGUID("player"))
    f.journal:SetScript("OnClick", function()
        if Blackacre.Chronicle and Blackacre.Chronicle.Capture and Blackacre.Chronicle.Capture.AddEntry then
            local pageTitle, pageBody = Blackacre.InnBoard.JournalPage(bulletin)
            Blackacre.Chronicle.Capture.AddEntry("BULLETIN", {
                title = pageTitle,
                promptTitle = pageTitle,
                promptBody = pageBody,
                playerChose = true,
            }, "manual")
            Blackacre.Print("Copied to your journal.")
        end
    end)
    listFrame.scroll:Hide()
    listFrame.emptyHost:Hide()
    f:Show()
end

-- Fill the open postings list from what this client holds right now.
local function RenderPostings()
    local f = EnsureList()
    local inn = Blackacre.YellowPages and Blackacre.YellowPages.Current()
    listed = CachedBulletinsForHere(inn)
    local key, name = Blackacre.Boards.CurrentZoneKey()
    f.title:SetText((name or "Inn") .. " Postings")

    for i, b in ipairs(listed) do
        local row = rows[i]
        if not row then
            row = MakeRow(f.child)
            rows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -LIST_TOP_PAD - (i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", 0, -LIST_TOP_PAD - (i - 1) * ROW_H)
        PaintRow(row, b, i)
        row:Show()
    end
    for i = #listed + 1, #rows do rows[i]:Hide() end
    f.child:SetHeight(math.max(1, LIST_TOP_PAD + #listed * ROW_H))

    if #listed == 0 then
        local asking = Blackacre.InnRelay and Blackacre.InnRelay.IsAsking(key)
        f.empty:SetText(asking and "Asking around the inn…" or "There are zero notices active")
        f.empty:Show()
    else
        f.empty:Hide()
    end
end

function Blackacre.InnBoard.ShowPostings()
    -- Ask other add-ons for this region's notices; copies arrive over a few seconds.
    if Blackacre.InnRelay then Blackacre.InnRelay.QueryHere() end
    RenderPostings()
    Blackacre.InnBoard.HideDetail()
    listFrame:Show()
    -- If nothing arrives, drop "Asking around…" once the wait is over.
    C_Timer.After(7, Blackacre.InnBoard.RefreshIfOpen)
end

function Blackacre.InnBoard.RefreshIfOpen()
    if listFrame and listFrame:IsShown() then
        RenderPostings()
    end
end

function Blackacre.InnBoard.OnBulletinDiscovered(bulletin)
    if not bulletin then return end
    local p = Blackacre.Lifecycle.EnsurePresenceDB()
    if p.seekingEnabled == false then return end
    local key, name = Blackacre.Boards.CurrentZoneKey()
    -- Snapshot, not GetZoneContext: this runs for every notice a reply brings in.
    local factions = Blackacre.YellowPages.FactionsInZone(Blackacre.GetZoneSnapshot().zoneName)
    if not Blackacre.Boards.BulletinMatchesZone(bulletin, key, name, nil, factions) then return end
    local today = date("%Y-%m-%d")
    p.innToastDay = p.innToastDay or {}
    if p.innToastDay[key] == today then return end
    p.innToastDay[key] = today
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast(TOAST_TEXT)
    else
        Blackacre.Print(TOAST_TEXT)
    end
end

-- Back to the list of postings.
function Blackacre.InnBoard.HideDetail()
    if detailFrame then detailFrame:Hide() end
    if listFrame then
        listFrame.scroll:Show()
        listFrame.emptyHost:Show()
    end
end

local function MaybeZoneToast()
    local p = Blackacre.Lifecycle and Blackacre.Lifecycle.EnsurePresenceDB and Blackacre.Lifecycle.EnsurePresenceDB()
    if not p or p.seekingEnabled == false then return end
    local list = CachedBulletinsForHere()
    if #list == 0 then return end
    local key = Blackacre.Boards.CurrentZoneKey()
    local today = date("%Y-%m-%d")
    p.innToastDay = p.innToastDay or {}
    if p.innToastDay[key] == today then return end
    p.innToastDay[key] = today
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast(TOAST_TEXT)
    end
end

local picker -- the Post a Notice window (below)

local function HideInnButtons()
    if postBtn then postBtn:Hide() end
    if seeBtn then seeBtn:Hide() end
    -- Walked away from the innkeeper: nothing can be posted now.
    if picker then picker:Hide() end
end

-- Owner rule (2026-10-01): one live notice per region (a notice already
-- shows at every innkeeper in its region) and at most three at once. A slot
-- frees up when its notice is withdrawn or its posted duration runs out.
local MAX_LIVE_NOTICES = 3

local function LiveNoticeCounts(zoneKey)
    local me, now = UnitGUID("player"), time()
    local total, here = 0, 0
    for _, b in pairs(BlackacreDB.bulletins or {}) do
        if b.ownerGUID == me and b.status == Blackacre.STATUS.ACTIVE
            and (not b.expiresAt or b.expiresAt > now) then
            total = total + 1
            local zones = b.postedZones
            if type(zones) == "table" then
                for i = 1, #zones do
                    if zones[i] == zoneKey then
                        here = here + 1
                        break
                    end
                end
            end
        end
    end
    return total, here
end

-- Why nothing can be posted here right now, or nil if it can.
local function PostBlockedReason()
    local key, zoneName = Blackacre.Boards.CurrentZoneKey()
    local total, here = LiveNoticeCounts(key)
    if here > 0 then
        return "You already have a notice up in " .. ((zoneName and zoneName ~= "") and zoneName or "this region")
            .. ". Take it down in My drafts, or wait for it to expire."
    end
    if total >= MAX_LIVE_NOTICES then
        return "You have three notices up already. Take one down in My drafts, or wait for one to expire."
    end
    return nil
end

-- Anything you could post: saved drafts, then past notices (to repost).
local function HasPostable()
    return #Blackacre.Lifecycle.GetSavedBulletins() > 0 or #Blackacre.History.GetDrafts("bulletin") > 0
end

local function RefreshPostButton()
    if not postBtn then return end
    postBtn:SetEnabled(HasPostable())
end

-- Owner's wording for anyone below Exalted.
local NOT_EXALTED = "You don't hold a high enough reputation with this faction to leverage their network yet."

-- Owner call: a soft toast, not red error text + chat.
local function PostError(text)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast(text)
    else
        Blackacre.Print(text)
    end
end

-- Spread the word: only through an innkeeper who belongs to a faction, and
-- only when Exalted with it. Returns faction name + ID, or nil after telling
-- the player why (their draft is kept).
SpreadGate = function(inn)
    local name = inn.repFactionName
    if not name then
        PostError((inn.name or "This innkeeper") .. " has no faction network to spread the word through.")
        return nil
    end
    local exalted, id = Blackacre.YellowPages.IsExaltedWith(name, inn.repFactionID)
    if exalted == nil then
        PostError("Open your Reputation panel so " .. name .. " is showing, then try again.")
        return nil
    end
    if not exalted then
        PostError(NOT_EXALTED)
        return nil
    end
    inn.repFactionID = id
    return name, id
end


-- Post the chosen draft (or past notice) at the innkeeper you're talking to.
local function DoPostDraftHere(draft)
    local inn = Blackacre.YellowPages.Current()
    if not inn then
        Blackacre.Print("Speak with an innkeeper to post your notice.")
        return
    end
    local key = Blackacre.Boards.CurrentZoneKey()
    local factionNet, factionNetID
    if draft.spread then
        factionNet, factionNetID = SpreadGate(inn)
        if not factionNet then return end -- told the player why; draft kept
    end
    local blocked = PostBlockedReason()
    if blocked then
        PostError(blocked)
        return -- draft kept
    end
    -- The board lists a notice under the name its author gave the draft.
    local title = (draft.draftName and draft.draftName ~= "") and draft.draftName or draft.title or ""
    local body = draft.bodyText or ""
    if Blackacre.Voice and Blackacre.Voice.MaybeApplyBulletin then
        body = Blackacre.Voice.MaybeApplyBulletin(body)
        title = Blackacre.Voice.MaybeApplyBulletin(title)
    end
    local bulletin = Blackacre.Lifecycle.CreateBulletin(title, body, "inn:" .. key, Blackacre.SCOPE.INDIVIDUAL, {
        postedZones = { key },
        innNpcID = (draft.innOnly and not factionNet) and inn.npcID or nil,
        factionNet = factionNet,
        factionNetID = factionNetID,
        lang = Blackacre.Languages.MyLanguage(),
        innName = inn.name,
        zoneName = inn.zoneName,
        stationary = draft.stationary,
        waxSeal = draft.waxSeal,
        font = draft.font,
        ttlSeconds = draft.ttlSeconds,
    })
    Blackacre.Lifecycle.PostBulletin(bulletin)
    -- Posted: it lives under Live Notices now, not Saved Drafts.
    if draft.savedId then Blackacre.Lifecycle.DeleteSavedBulletin(draft.savedId) end
    if picker then picker:Hide() end
    RefreshPostButton()
    -- Open windows were drawn before this post; redraw so the new notice shows.
    Blackacre.InnBoard.RefreshIfOpen()
    if Blackacre.MyPostings and Blackacre.MyPostings.Refresh then Blackacre.MyPostings.Refresh() end
    local where = draft.innOnly and ("with " .. (inn.name or "the innkeeper"))
        or ("at the inns of " .. ((inn.zoneName ~= "" and inn.zoneName) or "this region"))
    if factionNet then
        where = "with every innkeeper of " .. factionNet
    end
    PostError("Your notice is posted " .. where .. ".")
end

StaticPopupDialogs["BLACKACRE_CONFIRM_POST"] = {
    text = "Are you sure you want to post \"%s\"?",
    button1 = YES,
    button2 = NO,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(_, draft)
        DoPostDraftHere(draft)
    end,
}

---------------------------------------------------------------------------
-- Post a Notice: pick any saved draft (or a past notice to repost), how long
-- it stays up, and where, then post. Opened by the gossip window's Post
-- Notice button. Built on the Quest Index window template.
---------------------------------------------------------------------------
local PICK_ROW_H = 36
local PICK_HEAD_H = 20
local DURATIONS = {
    { label = "12 hours", secs = 12 * 60 * 60 },
    { label = "1 day", secs = 24 * 60 * 60 },
    { label = "3 days", secs = 3 * 24 * 60 * 60 },
    { label = "7 days", secs = 7 * 24 * 60 * 60 },
}
local DEFAULT_DURATION = 3

local pickItems = {} -- flattened list, rebuilt on refresh
local pickRows = {}  -- pooled rows

local function PickName(it)
    local rec = it.rec
    if it.kind == "saved" then return rec.draftName or "Untitled draft" end
    return (rec.title and rec.title ~= "") and rec.title or "Untitled notice"
end

local RefreshPicker -- defined below

local function PickRow_OnClick(self)
    picker.selected = self._baItem
    RefreshPicker()
end

local function MakePickRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", PickRow_OnClick)
    row.zebra = row:CreateTexture(nil, "BACKGROUND", nil, -1)
    row.zebra:SetAllPoints()
    row.hover = row:CreateTexture(nil, "HIGHLIGHT")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(1, 0.82, 0, 0.15)
    row.sel = row:CreateTexture(nil, "BACKGROUND")
    row.sel:SetAllPoints()
    row.sel:SetColorTexture(1, 0.82, 0, 0.3)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 4, -3)
    row.title:SetPoint("RIGHT", -4, 0)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(false)
    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.info:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
    row.info:SetPoint("RIGHT", -4, 0)
    row.info:SetJustifyH("LEFT")
    row.info:SetWordWrap(false)
    return row
end

local function Duration_OnClick(self)
    picker.duration = self._baIndex
    RefreshPicker()
end

local function InnOnly_OnClick(self)
    picker.innOnly = self:GetChecked() and true or false
    if picker.innOnly then picker.spread = false end
    RefreshPicker()
end

local function Spread_OnClick(self)
    picker.spread = self:GetChecked() and true or false
    if picker.spread then picker.innOnly = false end
    RefreshPicker()
end

local function Picker_OnPost()
    local it = picker.selected
    if not it then return end
    local rec = it.rec
    local draft = {
        draftName = PickName(it),
        title = rec.title,
        bodyText = rec.bodyText,
        stationary = rec.stationary,
        waxSeal = rec.waxSeal,
        font = rec.font,
        innOnly = picker.innOnly,
        spread = picker.spread,
        ttlSeconds = DURATIONS[picker.duration].secs,
        savedId = it.kind == "saved" and rec.id or nil,
    }
    local dialog = StaticPopup_Show("BLACKACRE_CONFIRM_POST", draft.draftName)
    if dialog then dialog.data = draft end
end

-- A labelled check box; the words click too.
local function MakeCheck(parent, text, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetScript("OnClick", onClick)
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.label:SetText(text)
    cb:SetHitRectInsets(0, -(cb.label:GetStringWidth() + 4), 0, 0)
    return cb
end

local function BuildPicker()
    local th = Blackacre.UI.Theme
    local f = CreateFrame("Frame", "BlackacrePostPicker", UIParent, "BackdropTemplate")
    f:SetSize(380, 500)
    f:SetPoint("CENTER", 220, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "BlackacrePostPicker")
    Blackacre.UI.Focus.Register(f)
    th.ApplyHeavyBronzeBase(f)

    f.header = CreateFrame("Frame", nil, f)
    f.header:SetPoint("TOPLEFT", 6, -6)
    f.header:SetPoint("TOPRIGHT", -6, -6)
    f.header:SetHeight(30)
    f.title = f.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("CENTER", 0, 9)
    f.title:SetText("Post a Notice")
    th.GoldTitle(f.title)
    local close = CreateFrame("Button", nil, f.header, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("RIGHT", -2, 6)
    close:SetScript("OnClick", function() f:Hide() end)

    f.listPanel = CreateFrame("Frame", nil, f)
    f.listPanel:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 2, -8)
    f.listPanel:SetPoint("BOTTOMRIGHT", -16, 168)
    th.ApplyQuestLogListPanel(f.listPanel)
    local scroll = CreateFrame("ScrollFrame", nil, f.listPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    f.child = CreateFrame("Frame", nil, scroll)
    f.child:SetSize(f.listPanel:GetWidth() - 38, 10)
    scroll:SetScrollChild(f.child)

    local stays = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stays:SetPoint("BOTTOMLEFT", 18, 138)
    stays:SetText("Stays up for:")
    f.durationBoxes = {}
    for i, d in ipairs(DURATIONS) do
        local cb = MakeCheck(f, d.label, Duration_OnClick)
        cb:SetPoint("BOTTOMLEFT", 14 + (i - 1) * 88, 110)
        cb._baIndex = i
        f.durationBoxes[i] = cb
    end

    f.innOnlyBox = MakeCheck(f, "Only this inn", InnOnly_OnClick)
    f.innOnlyBox:SetPoint("BOTTOMLEFT", 14, 82)
    f.spreadBox = MakeCheck(f, "Spread the word", Spread_OnClick)
    f.spreadBox:SetPoint("BOTTOMLEFT", 14, 58)

    f.reason = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.reason:SetPoint("BOTTOMLEFT", 18, 40)
    f.reason:SetPoint("BOTTOMRIGHT", -18, 40)
    f.reason:SetJustifyH("LEFT")
    f.reason:SetTextColor(1, 0.35, 0.35)

    f.post = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.post:SetSize(110, 24)
    f.post:SetPoint("BOTTOMRIGHT", -16, 12)
    f.post:SetText("Post")
    f.post:SetScript("OnClick", Picker_OnPost)

    f.duration = DEFAULT_DURATION
    f.innOnly, f.spread = false, false
    picker = f
end

local function BuildPickItems()
    for i = #pickItems, 1, -1 do pickItems[i] = nil end
    local saved = Blackacre.Lifecycle.GetSavedBulletins()
    if #saved > 0 then
        pickItems[#pickItems + 1] = { kind = "header", label = "Saved Drafts" }
        for _, d in ipairs(saved) do pickItems[#pickItems + 1] = { kind = "saved", rec = d } end
    end
    local past = Blackacre.History.GetDrafts("bulletin")
    if #past > 0 then
        pickItems[#pickItems + 1] = { kind = "header", label = "Past Notices" }
        for _, b in ipairs(past) do pickItems[#pickItems + 1] = { kind = "past", rec = b } end
    end
end

RefreshPicker = function()
    if not picker or not picker:IsShown() then return end
    BuildPickItems()
    -- Keep the selection only if that draft is still in the list.
    local sel, stillThere = picker.selected, false
    local y, stripe = 0, 0
    for i, it in ipairs(pickItems) do
        local row = pickRows[i]
        if not row then
            row = MakePickRow(picker.child)
            pickRows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", 0, -y)
        row._baItem = it
        row.info:SetText("")
        if it.kind == "header" then
            row:SetHeight(PICK_HEAD_H)
            row:EnableMouse(false)
            row.zebra:Hide()
            row.sel:Hide()
            row.title:SetText("|cffc9a227" .. it.label .. "|r")
            y = y + PICK_HEAD_H
        else
            stripe = stripe + 1
            row:SetHeight(PICK_ROW_H)
            row:EnableMouse(true)
            local z = (stripe % 2 == 0) and ZEBRA_LIGHT or ZEBRA_DARK
            row.zebra:SetColorTexture(z[1], z[2], z[3], z[4])
            row.zebra:Show()
            local isSel = sel ~= nil and sel.rec == it.rec
            if isSel then
                stillThere = true
                picker.selected = it -- same record, fresh item
            end
            row.sel:SetShown(isSel)
            row.title:SetText(PickName(it))
            local first = Blackacre.PostEditor.DeriveTitle(it.rec.bodyText or "")
            row.info:SetText(it.kind == "past" and ("Posted before. " .. first) or first)
            y = y + PICK_ROW_H
        end
        row:Show()
    end
    for i = #pickItems + 1, #pickRows do pickRows[i]:Hide() end
    picker.child:SetHeight(math.max(1, y))
    if not stillThere then picker.selected = nil end

    for i, cb in ipairs(picker.durationBoxes) do cb:SetChecked(i == picker.duration) end
    picker.innOnlyBox:SetChecked(picker.innOnly)
    picker.spreadBox:SetChecked(picker.spread)

    local blocked = PostBlockedReason()
    if blocked then
        picker.reason:SetText(blocked)
    elseif #pickItems == 0 then
        picker.reason:SetText("No drafts yet. Write one in the Bulletin editor and Save draft.")
    elseif not picker.selected then
        picker.reason:SetText("|cffffd200Pick a draft to post.|r")
    else
        picker.reason:SetText("")
    end
    picker.post:SetEnabled(picker.selected ~= nil and not blocked)
end

function Blackacre.InnBoard.PostDraftHere()
    if not Blackacre.YellowPages.Current() then
        Blackacre.Print("Speak with an innkeeper to post your notice.")
        return
    end
    if not picker then BuildPicker() end
    picker.selected = nil
    picker:Show()
    RefreshPicker()
end

-- Two plain buttons on the gossip window's bottom row, left of Goodbye.
-- Goodbye (Forever GossipFrame.xml) sits BOTTOMRIGHT -6, 4 at 78x22; match its row.
local BTN_W, BTN_H, BTN_GAP = 104, 22, 4

local function EnsureInnButtons(gossip)
    if postBtn then return end
    postBtn = CreateFrame("Button", "BlackacrePostNoticeButton", gossip, "UIPanelButtonTemplate")
    postBtn:SetSize(BTN_W, BTN_H)
    postBtn:SetText("Post Notice")
    postBtn:SetMotionScriptsWhileDisabled(true)
    postBtn:SetScript("OnClick", Blackacre.InnBoard.PostDraftHere)
    postBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if self:IsEnabled() then
            GameTooltip:SetText("Post a notice here")
            GameTooltip:AddLine("Choose one of your drafts, how long it stays up, and where.", 1, 1, 1, true)
        else
            GameTooltip:SetText("No notice drafted")
            GameTooltip:AddLine("Write one in the Bulletin editor (Tool Box) and Save draft.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    postBtn:SetScript("OnLeave", GameTooltip_Hide)

    seeBtn = CreateFrame("Button", "BlackacreSeePostingsButton", gossip, "UIPanelButtonTemplate")
    seeBtn:SetSize(BTN_W, BTN_H)
    seeBtn:SetText("See Postings")
    seeBtn:SetScript("OnClick", function()
        Blackacre.InnBoard.ShowPostings()
    end)
end

local function ShowInnButtons(gossip)
    EnsureInnButtons(gossip)
    local level = (gossip:GetFrameLevel() or 1) + 20
    postBtn:SetParent(gossip)
    postBtn:ClearAllPoints()
    postBtn:SetPoint("BOTTOMLEFT", gossip, "BOTTOMLEFT", 6, 4)
    postBtn:SetFrameLevel(level)
    seeBtn:SetParent(gossip)
    seeBtn:ClearAllPoints()
    seeBtn:SetPoint("LEFT", postBtn, "RIGHT", BTN_GAP, 0)
    seeBtn:SetFrameLevel(level)
    RefreshPostButton()
    postBtn:Show()
    seeBtn:Show()
end

-- Called after drafts or live notices change (save, delete, withdraw).
function Blackacre.InnBoard.RefreshPostButton()
    RefreshPostButton()
    RefreshPicker()
end

function Blackacre.InnBoard.Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("GOSSIP_SHOW")
    f:RegisterEvent("GOSSIP_CLOSED")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event)
        if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, MaybeZoneToast)
            -- Ask for this region's notices. At login the hidden channel joins a
            -- few seconds late, so wait longer then.
            if Blackacre.InnRelay then
                C_Timer.After(event == "PLAYER_ENTERING_WORLD" and 8 or 2, Blackacre.InnRelay.QueryHere)
            end
            return
        end
        if event == "GOSSIP_CLOSED" then
            Blackacre.YellowPages.ClearCurrent()
            HideInnButtons()
            return
        end
        if not IsInnkeeperGossip() then
            Blackacre.YellowPages.ClearCurrent()
            HideInnButtons()
            return
        end
        Blackacre.YellowPages.RecordCurrent()
        local gossip = GossipFrame or _G.GossipFrame
        if not gossip then return end
        ShowInnButtons(gossip)
    end)
end
