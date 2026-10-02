-- In Character Forever: Beacons & Bulletins - Trails

Blackacre = Blackacre or {}
Blackacre.Trails = {}

local pairs, time, sort = pairs, time, table.sort

local MAX_FOLLOW = 3
local MAX_ROWS = 8
local RUMOR_TOAST_EVERY = 60 * 60 -- one "rumors are going around" toast per region per hour

local following = {}     -- emitter (sender name) -> true; survives their beacon updates
local toastedAt = {}     -- region map id -> time()
local frame
local rows = {}

local function Key(beacon)
    return beacon and (beacon.senderName or beacon.ownerGUID)
end

function Blackacre.Trails.IsFollowing(beacon)
    local k = Key(beacon)
    return k ~= nil and following[k] == true
end

local function FollowCount()
    local n = 0
    for _ in pairs(following) do n = n + 1 end
    return n
end

local function Toast(text)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast(text)
    else
        Blackacre.Print(text)
    end
end

function Blackacre.Trails.Follow(beacon)
    local k = Key(beacon)
    if not k or following[k] then return end
    if FollowCount() >= MAX_FOLLOW then
        Toast("You can follow three trails at once. Let one go first.")
        return
    end
    following[k] = true
    -- Now fetch their Lead and Found, and let the ladder run for this trail.
    if Blackacre.Comms.RequestTrail then Blackacre.Comms.RequestTrail(beacon) end
    if Blackacre.BeaconHead and Blackacre.BeaconHead.OnCacheChanged then
        Blackacre.BeaconHead.OnCacheChanged(beacon)
    end
    Blackacre.Trails.Refresh()
end

function Blackacre.Trails.Unfollow(beacon)
    local k = Key(beacon)
    if not k or not following[k] then return end
    following[k] = nil
    if Blackacre.BeaconHead and Blackacre.BeaconHead.StopFollowing then
        Blackacre.BeaconHead.StopFollowing(beacon)
    end
    Blackacre.Trails.Refresh()
end

-- A Rumor reached us (BeaconHead). One soft toast per region per hour.
function Blackacre.Trails.OnRumorHeard(beacon)
    local zone = beacon and beacon.zoneId
    local now = time()
    if zone and (not toastedAt[zone] or now - toastedAt[zone] > RUMOR_TOAST_EVERY) then
        toastedAt[zone] = now
        Toast("Rumors are going around these parts.")
    end
    Blackacre.Trails.Refresh()
end

local function InMyRegion(ctx, b)
    if ctx.zoneId and ctx.zoneId ~= 0 and ctx.zoneId == b.zoneId then return true end
    local a, z = ctx.zoneName or "", b.zoneName or ""
    return a ~= "" and a:lower() == z:lower()
end

-- Heard beacons in this region that we have the Rumor for; followed first.
local function ListHere()
    local ctx = Blackacre.GetZoneContext()
    local now = time()
    local list = {}
    for _, b in pairs(Blackacre.Lifecycle.HeardBeacons()) do
        if (not b.expiresAt or b.expiresAt >= now) and b.textLogged and InMyRegion(ctx, b)
            and not Blackacre.IsMuted(b.senderName) and not Blackacre.IsMuted(b.ownerGUID) then
            list[#list + 1] = b
        end
    end
    sort(list, function(a, b)
        local fa, fb = Blackacre.Trails.IsFollowing(a), Blackacre.Trails.IsFollowing(b)
        if fa ~= fb then return fa end
        return (a.receivedAt or 0) > (b.receivedAt or 0)
    end)
    return list
end

-- The latest crumb we have for a trail: Found, else Lead, else Rumor.
local function LatestCrumb(b)
    local rec = Blackacre.BeaconHead and Blackacre.BeaconHead.Record and Blackacre.BeaconHead.Record(b)
    if rec and rec.found and b.found and b.found ~= "" then return "Found: " .. b.found end
    if rec and rec.lead and b.lead and b.lead ~= "" then return "Lead: " .. b.lead end
    if b.rumor and b.rumor ~= "" then return b.rumor end
    return ""
end

local function Build()
    local f = CreateFrame("Frame", "BlackacreTrails", UIParent, "BackdropTemplate")
    f:SetSize(500, 96 + MAX_ROWS * 56)
    f:SetPoint("CENTER", 200, 40)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.ApplyParchmentBackdrop then
        Blackacre.UI.Theme.ApplyParchmentBackdrop(f, 0.97)
    end
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -14)
    f.title:SetText("Trails")
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.GoldTitle then
        Blackacre.UI.Theme.GoldTitle(f.title)
    end
    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.hint:SetPoint("TOP", 0, -36)
    f.hint:SetWidth(460)
    f.hint:SetText("Talk heard around these parts. Follow up to three trails to hear more.")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    f.empty = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.empty:SetPoint("TOP", 0, -80)
    f.empty:SetText("No talk of anyone around here.")
    f.more = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.more:SetPoint("BOTTOM", 0, 12)

    for i = 1, MAX_ROWS do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(460, 52)
        row:SetPoint("TOPLEFT", 20, -58 - (i - 1) * 56)
        row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.status:SetPoint("TOPLEFT", 0, 0)
        row.status:SetWidth(300)
        row.status:SetJustifyH("LEFT")
        row.crumb = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.crumb:SetPoint("TOPLEFT", row.status, "BOTTOMLEFT", 0, -3)
        row.crumb:SetWidth(300)
        row.crumb:SetHeight(30)
        row.crumb:SetJustifyH("LEFT")
        row.crumb:SetJustifyV("TOP")
        row.follow = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.follow:SetSize(76, 22)
        row.follow:SetPoint("TOPRIGHT", -84, 0)
        row.follow:SetScript("OnClick", function()
            local b = row.beacon
            if not b then return end
            if Blackacre.Trails.IsFollowing(b) then
                Blackacre.Trails.Unfollow(b)
            else
                Blackacre.Trails.Follow(b)
            end
        end)
        row.report = Blackacre.Report.MakeButton(row, function()
            if row.beacon then Blackacre.Report.Beacon(row.beacon) end
        end)
        row.report:SetPoint("TOPRIGHT", 0, 0)
        row.follow:ClearAllPoints()
        row.follow:SetPoint("RIGHT", row.report, "LEFT", -6, 0)
        rows[i] = row
    end
    f:Hide()
    tinsert(UISpecialFrames, "BlackacreTrails")
    Blackacre.UI.Focus.Register(f)
    frame = f

    -- /ba skin labels (R = tRails).
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.RegisterSkinRegion then
        local Tag = Blackacre.UI.Theme.RegisterSkinRegion
        Tag(f, "R1", "S", 0, 60)
        Tag(f.title, "R2", "F")
        Tag(f.hint, "R3", "F")
        Tag(close, "R4", "F")
        Tag(f.empty, "R5", "F")
        Tag(f.more, "R6", "F")
        Tag(rows[1], "R7", "F", -60, 0)
    end
end

function Blackacre.Trails.Refresh()
    if not frame or not frame:IsShown() then return end
    local list = ListHere()
    for i = 1, MAX_ROWS do
        local row, b = rows[i], list[i]
        row.beacon = b
        if b then
            local followed = Blackacre.Trails.IsFollowing(b)
            row.status:SetText((followed and "|cff66cc66• |r" or "") .. ((b.shortText and b.shortText ~= "") and b.shortText or "Someone is about."))
            row.crumb:SetText(LatestCrumb(b))
            row.follow:SetText(followed and "Let go" or "Follow")
            row:Show()
        else
            row:Hide()
        end
    end
    frame.empty:SetShown(#list == 0)
    if #list > MAX_ROWS then
        frame.more:SetText("+" .. (#list - MAX_ROWS) .. " more around here")
        frame.more:Show()
    else
        frame.more:Hide()
    end
end

function Blackacre.Trails.Toggle()
    if not frame then Build() end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        Blackacre.Trails.Refresh()
    end
end
