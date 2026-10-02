-- In Character Forever: Beacons & Bulletins - Report and Mute

Blackacre = Blackacre or {}
Blackacre.Report = {}

local date, pairs, type = date, pairs, type
local concat = table.concat

local window
local current -- { name, guid, base = evidence text, text = what's shown, reason }

-- The parts of Blizzard's Code of Conduct a notice or beacon can break.
-- blizz = what to pick in Blizzard's own report window.
local REASONS = {
    { key = "harass", label = "Harassment or threats", blizz = "Inappropriate Communication" },
    { key = "hate", label = "Hate speech or slurs", blizz = "Inappropriate Communication" },
    { key = "obscene", label = "Sexual or obscene content", blizz = "Inappropriate Communication" },
    { key = "spam", label = "Spam, advertising or scams", blizz = "Inappropriate Communication, then Spam" },
    { key = "private", label = "Someone's real-life details", blizz = "Inappropriate Communication" },
    { key = "other", label = "Something else against the Code", blizz = "the closest match" },
}

local CONDUCT_TEXT = "Blizzard's Code of Conduct forbids harassment, hate speech, obscene "
    .. "content, spam and sharing someone's real-life details. Report words that break "
    .. "it, not roleplay you simply don't like."

local function FormatUTC(ts)
    if not ts then return "unknown time" end
    return date("!%Y-%m-%d %H:%M UTC", ts)
end

local function OneLine(t)
    return ((t or ""):gsub("\n", " / "))
end

local function BulletinReportText(b)
    local lines = {
        "Blackacre add-on: inn notice (bulletin). Sent as a logged addon message, prefix BA_RP.",
        "Author: " .. (b.authorName or b.charName or "unknown"),
        "Sent: " .. FormatUTC(b.postedAt) .. ((b.zoneName and b.zoneName ~= "") and (", " .. b.zoneName) or ""),
        "Notice ID: " .. (b.id or "?"),
        "Title: " .. OneLine(b.title),
        "Text: " .. OneLine(b.bodyText),
    }
    return concat(lines, "\n")
end

local function BeaconReportText(bc)
    local lines = {
        "Blackacre add-on: beacon (location hint text). Addon prefix BA_RP.",
        "Sender: " .. (bc.senderName or "unknown"),
        "Received: " .. FormatUTC(bc.receivedAt) .. ((bc.zoneName and bc.zoneName ~= "") and (", " .. bc.zoneName) or ""),
        "Beacon ID: " .. (bc.id or "?"),
    }
    if bc.rumor and bc.rumor ~= "" then lines[#lines + 1] = "Rumor: " .. OneLine(bc.rumor) end
    if bc.lead and bc.lead ~= "" then lines[#lines + 1] = "Lead: " .. OneLine(bc.lead) end
    if bc.found and bc.found ~= "" then lines[#lines + 1] = "Found: " .. OneLine(bc.found) end
    return concat(lines, "\n")
end

local function BaseName(n)
    return n and n:match("^[^-]+") or nil
end

-- Blizzard's window needs the player's in-game identity. Only trust the GUID
-- carried in the message if the game agrees it belongs to the named author.
local function PlayerLocationFor(name, guid)
    if not (guid and PlayerLocation and PlayerLocation.CreateFromGUID) then return nil end
    if GetPlayerInfoByGUID then
        local _, _, _, _, _, gName = GetPlayerInfoByGUID(guid)
        if gName and name and BaseName(gName) ~= BaseName(name) then
            return nil
        end
    end
    local loc = PlayerLocation:CreateFromGUID(guid)
    if C_ReportSystem and C_ReportSystem.CanReportPlayer and not C_ReportSystem.CanReportPlayer(loc) then
        return nil
    end
    return loc
end

local function OpenBlizzardReport()
    if not current then return end
    local loc = PlayerLocationFor(current.name, current.guid)
    if not loc or not (ReportFrame and ReportInfo and Enum and Enum.ReportType) then
        Blackacre.Print("Blizzard's report window can't reach " .. (current.name or "this player")
            .. " right now. Keep this text and report them from the Help menu (Customer Support), pasting it into your ticket.")
        return
    end
    local info = ReportInfo:CreateReportInfoFromType(Enum.ReportType.InWorld)
    ReportFrame:InitiateReport(info, current.name, loc)
end

-- Drop anything we already hold from muted players, then refresh the views.
local function PurgeMuted()
    local muted = Blackacre.IsMuted
    local function isMutedEntry(e)
        return e and (muted(e.authorName) or muted(e.senderName) or muted(e.ownerGUID))
    end
    local heard = Blackacre.Lifecycle.HeardBeacons()
    for id, b in pairs(heard) do
        if isMutedEntry(b) then heard[id] = nil end
    end
    for _, bucket in pairs(BlackacreDB.cache or {}) do
        for id, wrapped in pairs(bucket) do
            if isMutedEntry(wrapped.data) then bucket[id] = nil end
        end
    end
    if Blackacre.BeaconHint and Blackacre.BeaconHint.Refresh then Blackacre.BeaconHint.Refresh() end
    if Blackacre.InnBoard and Blackacre.InnBoard.RefreshIfOpen then Blackacre.InnBoard.RefreshIfOpen() end
end

local function MuteCurrent()
    if not current then return end
    Blackacre.Mute(current.name, current.guid)
    PurgeMuted()
    Blackacre.Print("Muted. You won't see notices or beacons from them any more. (/ba mutes clear to undo all mutes)")
    if window then window:Hide() end
    if Blackacre.InnBoard and Blackacre.InnBoard.HideDetail then Blackacre.InnBoard.HideDetail() end
end

-- Evidence shown in the box: the chosen reason on top, then the facts.
local function ComposeText()
    if not current then return "" end
    local r = current.reason
    if not r then return current.base end
    return "Reason (Code of Conduct): " .. r.label .. "\n" .. current.base
end

local function SetSteps(f)
    local r = current and current.reason
    if r then
        f.steps:SetText("1. The text below is selected: press Ctrl+C to copy it.\n"
            .. "2. Click Open report, choose |cffffd200" .. r.blizz .. "|r, paste into the comment box, and submit.")
    else
        f.steps:SetText("Pick what it breaks first. Blizzard checks your report against their own record of what was sent.")
    end
end

local function SelectReason(f, reason)
    current.reason = reason
    for i = 1, #f.reasonBoxes do
        local cb = f.reasonBoxes[i]
        cb:SetChecked(cb._baReason == reason)
    end
    current.text = ComposeText()
    f.edit:SetText(current.text)
    f.edit:SetFocus()
    f.edit:HighlightText()
    f.open:SetEnabled(true)
    SetSteps(f)
end

local function Reason_OnClick(self)
    SelectReason(window, self._baReason)
end

-- Pass A (plain) window. Real chrome waits for Phase 10.
local function EnsureWindow()
    if window then return window end
    local f = CreateFrame("Frame", "BlackacreReportWindow", UIParent, "BackdropTemplate")
    f:SetSize(480, 470)
    f:SetPoint("CENTER", 0, 40)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.ApplyParchmentBackdrop then
        Blackacre.UI.Theme.ApplyParchmentBackdrop(f, 0.98)
    end
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -14)
    f.title:SetText("|cffff4040Report to Blizzard|r")
    f.conduct = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.conduct:SetPoint("TOPLEFT", 18, -40)
    f.conduct:SetWidth(444)
    f.conduct:SetJustifyH("LEFT")
    f.conduct:SetText(CONDUCT_TEXT)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local ask = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ask:SetPoint("TOPLEFT", 18, -86)
    ask:SetText("What does it break?")
    f.reasonBoxes = {}
    for i, reason in ipairs(REASONS) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", 14 + col * 228, -104 - row * 26)
        cb._baReason = reason
        cb:SetScript("OnClick", Reason_OnClick)
        local label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        label:SetText(reason.label)
        -- The words are clickable too, not just the box.
        cb:SetHitRectInsets(0, -(label:GetStringWidth() + 4), 0, 0)
        f.reasonBoxes[i] = cb
    end

    f.steps = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.steps:SetPoint("TOPLEFT", 18, -190)
    f.steps:SetWidth(444)
    f.steps:SetJustifyH("LEFT")

    local holder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    holder:SetPoint("TOPLEFT", 16, -232)
    holder:SetPoint("BOTTOMRIGHT", -16, 48)
    holder:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    holder:SetBackdropColor(0, 0, 0, 0.45)
    local scroll = CreateFrame("ScrollFrame", nil, holder, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(400)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    -- Keep the text exactly as generated; any typing snaps back to it.
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and current then
            self:SetText(current.text)
            self:HighlightText()
        end
    end)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    scroll:SetScrollChild(edit)
    f.edit = edit

    local open = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    open:SetSize(130, 24)
    open:SetPoint("BOTTOMRIGHT", -16, 14)
    open:SetText("|cffff4040Open report|r")
    open:SetScript("OnClick", OpenBlizzardReport)
    f.open = open

    local mute = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mute:SetSize(110, 24)
    mute:SetPoint("RIGHT", open, "LEFT", -8, 0)
    mute:SetText("Mute them")
    mute:SetScript("OnClick", MuteCurrent)
    mute:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Mute them")
        GameTooltip:AddLine("Hide every notice and beacon from this player, for you only. Doesn't report them.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    mute:SetScript("OnLeave", GameTooltip_Hide)

    f:Hide()
    tinsert(UISpecialFrames, "BlackacreReportWindow")
    Blackacre.UI.Focus.Register(f)
    window = f
    return f
end

local function Show(name, guid, text)
    current = { name = name, guid = guid, base = text, text = text }
    local f = EnsureWindow()
    for i = 1, #f.reasonBoxes do f.reasonBoxes[i]:SetChecked(false) end
    f.open:SetEnabled(false) -- a reason first, so every report says what was broken
    SetSteps(f)
    f.edit:SetText(text)
    f:Show()
end

function Blackacre.Report.Bulletin(b)
    if not b then return end
    Show(b.authorName or b.charName, b.ownerGUID, BulletinReportText(b))
end

function Blackacre.Report.Beacon(bc)
    if not bc then return end
    Show(bc.senderName, bc.ownerGUID, BeaconReportText(bc))
end

-- Report button for any window that shows someone's words: Blizzard's GM
-- icon at its own proportions, 22 px tall.
local BUTTON_H = 22

local function ReportButton_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Report to Blizzard", 1, 0.25, 0.25)
    GameTooltip:AddLine("Words that break Blizzard's Code of Conduct? Report them, or mute this player.", 1, 1, 1, true)
    GameTooltip:Show()
end

function Blackacre.Report.MakeButton(parent, onClick)
    local btn = CreateFrame("Button", nil, parent)
    local theme = Blackacre.UI and Blackacre.UI.Theme
    local atlas = theme and theme.Textures and theme.Textures.reportIconAtlas
    local info = atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    if info then
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetAtlas(atlas, false)
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetAtlas(atlas, false)
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.5)
        local w = BUTTON_H
        if info.width and info.height and info.height > 0 then
            w = BUTTON_H * info.width / info.height
        end
        btn:SetSize(w, BUTTON_H)
    else
        -- Atlas missing on this client: a plain red word, never a guessed crop.
        btn:SetNormalFontObject(GameFontNormalSmall)
        btn:SetText("|cffff4040Report|r")
        btn:SetSize(52, BUTTON_H)
    end
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", ReportButton_OnEnter)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    return btn
end
