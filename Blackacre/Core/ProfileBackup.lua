-- In Character Forever - Profile Backup

Blackacre = Blackacre or {}

local pairs, type, time, format = pairs, type, time, string.format

local box

local function CloneTable(source)
    if type(source) ~= "table" then return source end
    local copy = {}
    for key, value in pairs(source) do copy[CloneTable(key)] = CloneTable(value) end
    return copy
end

local function BuildBox()
    local f = CreateFrame("Frame", "BlackacreProfileExportFrame", UIParent, "BackdropTemplate")
    f:SetSize(520, 340)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    Blackacre.UI.Theme.ApplyParchmentBackdrop(f, 0.98)
    tinsert(UISpecialFrames, "BlackacreProfileExportFrame")
    Blackacre.UI.Focus.Register(f)
    local title = f:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Full Profile Backup")
    Blackacre.UI.Theme.GoldTitle(title)
    local hint = f:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 16, -36)
    hint:SetText("Select all, copy, and save as a .lua file somewhere safe.")
    Blackacre.UI.Theme.InkFont(hint)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -56)
    scroll:SetPoint("BOTTOMRIGHT", -36, 16)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetWidth(460)
    edit:SetAutoFocus(true)
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(edit)
    f.edit = edit
    return f
end

function Blackacre.ExportProfileBackup()
    local db = Blackacre.db
    local profile = db and db.profile
    if not profile then Blackacre.Print("Profile storage is not ready."); return end
    local profileName = db:GetCurrentProfile()
    local settings = CloneTable(profile)
    settings.characterData = nil
    local bundle = {
        format = "BlackacreProfileBackup",
        version = 1,
        profileID = profileName,
        profileName = profileName,
        exportedAt = time(),
        settings = settings,
        characterData = CloneTable(profile.characterData),
    }
    local serialized = LibStub("AceSerializer-3.0"):Serialize(bundle)
    local deflate = LibStub("LibDeflate")
    local payload = "BLACKACRE_PROFILE_V1:" .. deflate:EncodeForPrint(deflate:CompressDeflate(serialized))
    -- The copied text is a valid Lua file, so it can be saved directly as a
    -- backup outside WoW. The compressed payload stays opaque and compact.
    local text = "-- Blackacre full profile backup\nBlackacreProfileBackup = " .. format("%q", payload) .. "\n"

    box = box or BuildBox()
    box.edit:SetText(text)
    box.edit:HighlightText()
    box:Show()
    box.edit:SetFocus()
    if Blackacre.UI and Blackacre.UI.Theme then Blackacre.UI.Theme.Toast("Full profile backup ready to copy.") end
end
