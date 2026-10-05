-- In Character Forever - Bug Report

Blackacre = Blackacre or {}
Blackacre.BugReport = {}

local ISSUES_URL = "github.com/khallammarellus-rgb/blackacre-in-character-forever/issues"
local MAX_ERRORS = 5

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded

local window
local errorLog = {}

-- Chain onto whatever error handler is already installed (BugSack, etc.) so
-- we only add a record, never swallow or replace anyone else's handling.
local previousHandler = geterrorhandler()
local function CaptureError(msg)
    table.insert(errorLog, 1, date("%H:%M:%S") .. "  " .. tostring(msg))
    while #errorLog > MAX_ERRORS do
        table.remove(errorLog)
    end
    if previousHandler then
        return previousHandler(msg)
    end
end
seterrorhandler(CaptureError)

local function LoadedPackages()
    local names = {
        { "Blackacre_Tome", "Tome" },
        { "Blackacre_Survival", "Survival" },
        { "Blackacre_Presence", "Presence" },
    }
    local loaded = {}
    for _, entry in ipairs(names) do
        if IsAddOnLoaded and IsAddOnLoaded(entry[1]) then
            table.insert(loaded, entry[2])
        end
    end
    if #loaded == 0 then
        return "(core only)"
    end
    return table.concat(loaded, ", ")
end

local function BuildTemplate()
    local version, build, buildDate = GetBuildInfo()
    local race = UnitRace("player") or "?"
    local class = UnitClass("player") or "?"
    local level = UnitLevel("player") or "?"
    local zone = GetZoneText() or "?"
    local subZone = GetSubZoneText()
    if subZone and subZone ~= "" and subZone ~= zone then
        zone = zone .. " (" .. subZone .. ")"
    end

    local errorBlock = "(none this session)"
    if #errorLog > 0 then
        errorBlock = table.concat(errorLog, "\n")
    end

    local lines = {
        "(Describe the problem here — what you did, what you expected, what happened instead)",
        "",
        "--- Auto-filled, leave as-is ---",
        ("Blackacre %s (build %d)"):format(Blackacre.VERSION or "?", Blackacre.BUILD or 0),
        ("Client: %s build %s (%s)"):format(version, build, buildDate),
        ("Realm: %s"):format(GetRealmName() or "?"),
        ("Character: %s %s, level %s"):format(race, class, tostring(level)),
        ("Zone: %s"):format(zone),
        ("Packages loaded: %s"):format(LoadedPackages()),
        "Recent Lua errors:",
        errorBlock,
        ("Time (UTC): %s"):format(date("!%Y-%m-%d %H:%M:%S")),
    }
    return table.concat(lines, "\n")
end

local function EnsureWindow()
    if window then return window end
    local f = CreateFrame("Frame", "BlackacreBugReportFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(460, 380)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f.TitleText:SetText("Blackacre Bug / Feedback Report")

    local hint = f:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 16, -30)
    hint:SetWidth(428)
    hint:SetJustifyH("LEFT")
    hint:SetText("Fill in the description, then click into the box and press Ctrl+A, Ctrl+C to copy it all. "
        .. "Paste it into a new issue at:\n|cffc9a227" .. ISSUES_URL .. "|r")

    -- Starts below the hint's three lines (two of text, one for the address).
    local holder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    holder:SetPoint("TOPLEFT", 16, -80)
    holder:SetPoint("BOTTOMRIGHT", -16, 40)
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
    scroll:SetScrollChild(edit)
    f.edit = edit

    local copyHint = f:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontDisableSmall")
    copyHint:SetPoint("BOTTOMLEFT", 16, 14)
    copyHint:SetText("Nothing is sent automatically — copy and paste it yourself.")

    f:SetScript("OnHide", function()
        if f.edit then f.edit:ClearFocus() end
    end)

    f:Hide()
    tinsert(UISpecialFrames, "BlackacreBugReportFrame")
    Blackacre.UI.Focus.Register(f)
    window = f
    return f
end

function Blackacre.BugReport.Show()
    local f = EnsureWindow()
    f.edit:SetText(BuildTemplate())
    f:Show()
    f.edit:SetFocus()
    f.edit:HighlightText()
end

function Blackacre.BugReport.Toggle()
    if window and window:IsShown() then
        window:Hide()
    else
        Blackacre.BugReport.Show()
    end
end
