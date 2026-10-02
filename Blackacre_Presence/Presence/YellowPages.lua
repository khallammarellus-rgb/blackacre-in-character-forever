-- In Character Forever: Beacons & Bulletins - Yellow Pages

Blackacre = Blackacre or {}
Blackacre.YellowPages = {}

local pairs, type, time, tonumber = pairs, type, time, tonumber
local strsplit, format, sort = strsplit, string.format, table.sort
local UnitGUID, UnitName, UnitFactionGroup = UnitGUID, UnitName, UnitFactionGroup
local C_GossipInfo, C_TooltipInfo, C_Reputation = C_GossipInfo, C_TooltipInfo, C_Reputation
local issecretvalue = issecretvalue

-- Gossip option icon for "Make this inn your home." Confirmed on Forever
-- with /dump C_GossipInfo.GetOptions() at an innkeeper (2026-09-26).
-- This is a data signature for detection, not art, so it lives here and not in Theme.
local BINDER_ICON = 132052

local currentNpcID -- innkeeper behind the open gossip window, nil otherwise
local window

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

-- True while the open gossip window belongs to an innkeeper.
function Blackacre.YellowPages.IsInnkeeperGossip()
    if not (C_GossipInfo and C_GossipInfo.GetOptions) then return false end
    local opts = C_GossipInfo.GetOptions()
    if type(opts) ~= "table" then return false end
    for i = 1, #opts do
        local icon = opts[i].icon
        if not IsSecret(icon) and icon == BINDER_ICON then
            return true
        end
    end
    return false
end

local function Store()
    BlackacreDB.innkeepers = BlackacreDB.innkeepers or {}
    return BlackacreDB.innkeepers
end

-- NPC id from a creature GUID ("Creature-0-realm-inst-zone-npcID-spawn").
local function NpcIdFromGUID(guid)
    if type(guid) ~= "string" or IsSecret(guid) then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= "Creature" then return nil end
    return tonumber(id)
end

-- Reputation factions this character can see in their reputation panel, by name.
-- Collapsed headers hide their children, so this can miss some; the tooltip's
-- position rule below still catches the name and the ID is resolved later.
local function KnownFactionIDsByName()
    local out = {}
    if not (C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex) then
        return out
    end
    for i = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and data.name and data.factionID and not data.isHeader then
            out[data.name] = data.factionID
        end
    end
    return out
end

local function IsLevelLine(line, text)
    local levelType = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.UnitLevel
    if levelType and line.type == levelType then return true end
    local word = LEVEL or "Level"
    return text:sub(1, #word) == word
end

-- The NPC's reputation faction, read from its tooltip. Forever shows it as the
-- line after "Level NN" (confirmed on Innkeeper Belm: name / Innkeeper /
-- Level 30 / Ironforge / PvP, 2026-09-26). Returns name, factionID-or-nil.
local function ReadNpcFaction()
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return nil end
    local data = C_TooltipInfo.GetUnit("npc")
    local lines = data and data.lines
    if type(lines) ~= "table" then return nil end
    local known = KnownFactionIDsByName()
    local skip = {
        [PVP or "PvP"] = true,
        [FACTION_ALLIANCE or "Alliance"] = true,
        [FACTION_HORDE or "Horde"] = true,
    }
    local afterLevel
    local sawLevel = false
    for i = 2, #lines do -- line 1 is the NPC's name
        local text = lines[i].leftText
        if type(text) == "string" and not IsSecret(text) and text ~= "" then
            if known[text] then
                return text, known[text] -- exact match with a faction the player knows
            end
            if IsLevelLine(lines[i], text) then
                sawLevel = true
            elseif sawLevel and not afterLevel and not skip[text] then
                afterLevel = text
            end
        end
    end
    return afterLevel, nil
end

-- Faction ID for a faction name, if the reputation panel shows it now.
function Blackacre.YellowPages.ResolveFactionID(name)
    if not name then return nil end
    return KnownFactionIDsByName()[name]
end

-- Factions whose innkeepers we know in a region (from the Yellow Pages).
-- Used so "Spread the word" notices show and toast in the right places.
function Blackacre.YellowPages.FactionsInZone(zoneName)
    local out = {}
    if not zoneName or zoneName == "" then return out end
    for _, row in pairs(Store()) do
        if row.repFactionName and row.zoneName == zoneName then
            out[row.repFactionName] = true
        end
    end
    return out
end

local EXALTED = 8 -- reputation standing index: 1 Hated ... 8 Exalted

-- Exalted with a faction? Returns true/false, or nil when the faction can't
-- be looked up right now (its header is collapsed in the reputation panel).
function Blackacre.YellowPages.IsExaltedWith(factionName, factionID)
    factionID = factionID or Blackacre.YellowPages.ResolveFactionID(factionName)
    if not factionID or not (C_Reputation and C_Reputation.GetFactionDataByID) then return nil, nil end
    local data = C_Reputation.GetFactionDataByID(factionID)
    if not data then return nil, factionID end
    return (data.reaction or 0) >= EXALTED, factionID
end

-- Record (or refresh) the innkeeper behind the open gossip window.
-- Returns the directory row, or nil if the NPC can't be identified.
function Blackacre.YellowPages.RecordCurrent()
    local npcID = NpcIdFromGUID(UnitGUID("npc"))
    currentNpcID = npcID
    if not npcID then return nil end
    local name = UnitName("npc")
    if IsSecret(name) then name = nil end
    local side = UnitFactionGroup("npc")
    if IsSecret(side) then side = nil end
    local ctx = Blackacre.GetZoneContext()
    local store = Store()
    local row = store[npcID]
    local now = time()
    if not row then
        row = { firstSeen = now }
        store[npcID] = row
        if Blackacre.Print then
            Blackacre.Print("Yellow Pages: noted " .. (name or "an innkeeper") .. ", " .. ((ctx.subzone ~= "" and ctx.subzone) or ctx.zoneName or "") .. ".")
        end
    end
    row.npcID = npcID
    row.name = name or row.name
    row.side = side or row.side          -- "Alliance" / "Horde" / "Neutral"
    row.zoneId = ctx.zoneId
    row.zoneName = ctx.zoneName
    row.subzone = ctx.subzone
    -- The player's spot while talking, i.e. within a few yards of the innkeeper.
    row.x = ctx.coords.x
    row.y = ctx.coords.y
    row.lastSeen = now
    -- Reputation faction for "Spread the word", read from the NPC's tooltip.
    local repName, repID = ReadNpcFaction()
    if repName then
        row.repFactionName = repName
        row.repFactionID = repID or row.repFactionID
    end
    return row
end

-- Innkeeper row for the open gossip window (nil when not at an innkeeper).
function Blackacre.YellowPages.Current()
    return currentNpcID and Store()[currentNpcID] or nil
end

function Blackacre.YellowPages.ClearCurrent()
    currentNpcID = nil
end

function Blackacre.YellowPages.GetAll()
    return Store()
end

-- Zebra stripe under each row, same colors as the Tome Quest Index's list.
local ZEBRA_DARK = { 0, 0, 0, 0.35 }
local ZEBRA_LIGHT = { 0.35, 0.35, 0.37, 0.22 }
local ROW_H = 18

local rows = {}     -- pooled row frames
local items = {}    -- flattened, rebuilt on refresh: {kind="header"/"line"/"empty", ...}
local filters = {}  -- zoneName -> false hides it; nil/true shows it

-- Every zone name seen across all recorded innkeepers, not just the ones
-- passing the current filter — so a hidden zone still offers its own checkbox.
local function DistinctZones()
    local seen, list = {}, {}
    for _, row in pairs(Store()) do
        local zone = row.zoneName or "Unknown"
        if not seen[zone] then
            seen[zone] = true
            list[#list + 1] = zone
        end
    end
    sort(list)
    return list
end

local function BuildItems()
    for i = #items, 1, -1 do items[i] = nil end
    local list = {}
    for _, row in pairs(Store()) do list[#list + 1] = row end
    sort(list, function(a, b)
        if (a.zoneName or "") ~= (b.zoneName or "") then
            return (a.zoneName or "") < (b.zoneName or "")
        end
        return (a.name or "") < (b.name or "")
    end)
    local lastZone
    for i = 1, #list do
        local r = list[i]
        local zone = r.zoneName or "Unknown"
        if filters[zone] ~= false then
            if zone ~= lastZone then
                lastZone = zone
                items[#items + 1] = { kind = "header", label = zone }
            end
            items[#items + 1] = { kind = "line", rec = r }
        end
    end
    if #items == 0 then
        items[#items + 1] = { kind = "empty",
            label = next(Store()) and "No innkeepers match your filters."
                or "No innkeepers yet. Speak with one and they'll be written in here." }
    end
end

local function MakeRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)
    row.zebra = row:CreateTexture(nil, "BACKGROUND", nil, -1)
    row.zebra:SetAllPoints()
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", 4, 0)
    row.label:SetPoint("RIGHT", -4, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    return row
end

local function PaintRow(row, it, i)
    local z = (i % 2 == 0) and ZEBRA_LIGHT or ZEBRA_DARK
    row.zebra:SetColorTexture(z[1], z[2], z[3], z[4])
    if it.kind == "header" then
        row.label:SetFontObject(GameFontNormal)
        row.label:SetText("|cffc9a227" .. it.label .. "|r")
    elseif it.kind == "empty" then
        row.label:SetFontObject(GameFontHighlightSmall)
        row.label:SetText(it.label)
    else
        local r = it.rec
        row.label:SetFontObject(GameFontHighlightSmall)
        row.label:SetText(format("  %s \226\128\148 |cffc9a227%s|r  (%.1f, %.1f)%s",
            r.name or "?", (r.subzone and r.subzone ~= "") and r.subzone or "?",
            (r.x or 0) * 100, (r.y or 0) * 100,
            r.repFactionName and ("  |cff9d9d9d" .. r.repFactionName .. "|r") or ""))
    end
end

local function RenderList()
    if not window then return end
    local content = window.child
    for i, it in ipairs(items) do
        local row = rows[i]
        if not row then
            row = MakeRow(content)
            rows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
        PaintRow(row, it, i)
        row:Show()
    end
    for i = #items + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(1, #items * ROW_H))
end

local filterMenu
local filterChecks = {}

local function EnsureFilterMenu()
    if filterMenu then return filterMenu end
    local m = CreateFrame("Frame", nil, window, "BackdropTemplate")
    Blackacre.UI.Theme.ApplyChromeMenuFrame(m)
    m:SetFrameStrata("DIALOG")
    m:SetWidth(180)
    m:Hide()
    filterMenu = m
    return m
end

local function RefreshFilterMenu()
    local m = EnsureFilterMenu()
    local zones = DistinctZones()
    for i, zone in ipairs(zones) do
        local cb = filterChecks[i]
        if not cb then
            cb = CreateFrame("CheckButton", nil, m, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            filterChecks[i] = cb
        end
        cb:ClearAllPoints()
        cb:SetPoint("TOPLEFT", 8, -10 - (i - 1) * 24)
        cb.label:SetText(zone)
        cb.zone = zone
        cb:SetChecked(filters[zone] ~= false)
        cb:SetScript("OnClick", function(self)
            filters[self.zone] = self:GetChecked() or false
            BuildItems()
            RenderList()
        end)
        cb:Show()
    end
    for i = #zones + 1, #filterChecks do filterChecks[i]:Hide() end
    m:SetHeight(math.max(40, #zones * 24 + 16))
end

local function ToggleFilterMenu(anchor)
    local m = EnsureFilterMenu()
    if m:IsShown() then
        m:Hide()
        return
    end
    RefreshFilterMenu()
    m:ClearAllPoints()
    m:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    m:Show()
end

local function EnsureWindow()
    if window then return window end
    local th = Blackacre.UI.Theme
    local f = CreateFrame("Frame", "BlackacreYellowPages", UIParent, "BackdropTemplate")
    f:SetSize(360, 420)
    f:SetPoint("CENTER", 220, 0)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "BlackacreYellowPages")
    Blackacre.UI.Focus.Register(f)
    th.ApplyHeavyBronzeBase(f)

    f.header = CreateFrame("Frame", nil, f)
    f.header:SetPoint("TOPLEFT", 6, -6)
    f.header:SetPoint("TOPRIGHT", -6, -6)
    f.header:SetHeight(30)

    f.title = f.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("CENTER", 0, 9)
    f.title:SetText("Yellow Pages")
    th.GoldTitle(f.title)

    local close = CreateFrame("Button", nil, f.header, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("RIGHT", 2, 8)
    close:SetScript("OnClick", function() f:Hide() end)

    f.filterBtn = CreateFrame("Button", nil, f.header, "UIPanelButtonTemplate")
    f.filterBtn:SetSize(70, 20)
    f.filterBtn:SetPoint("LEFT", 2, -14)
    f.filterBtn:SetText("Filter")
    f.filterBtn:SetScript("OnClick", function(self) ToggleFilterMenu(self) end)

    -- Same scroll list chrome as the Tome Quest Index's history panel
    -- (quest-log frame border over the Journeys background) — just the
    -- list panel, not Quest Index's parchment pop-out (no detail pane here).
    local listPanel = CreateFrame("Frame", nil, f)
    listPanel:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 2, -8)
    listPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    Blackacre.UI.Theme.ApplyQuestLogListPanel(listPanel)
    f.listPanel = listPanel

    local scroll = CreateFrame("ScrollFrame", nil, listPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(listPanel:GetWidth() - 38, 10)
    scroll:SetScrollChild(child)
    f.child = child

    window = f
    return f
end

function Blackacre.YellowPages.Show()
    local f = EnsureWindow()
    BuildItems()
    RenderList()
    f:Show()
end

function Blackacre.YellowPages.Toggle()
    if window and window:IsShown() then
        window:Hide()
    else
        Blackacre.YellowPages.Show()
    end
end
