-- In Character Forever: Journal - Journal Window

Blackacre = Blackacre or {}
Blackacre.TomeHub = {}

local pcall, tostring = pcall, tostring
local CreateFrame = CreateFrame

local hub
local chronicleHost
local setupHost
local setupMode = false
local escGate -- Esc: closes the book; a sidecar keeps its own X
local suppressEscGate = false
local sidecar -- { IsTab(id), Show(id), Hide(), Toggle(id), IsShown() } from Backstory

--- Remove a global frame name from UISpecialFrames (Esc closes all entries at once).
local function RemoveFromUISpecialFrames(name)
    if not name or not UISpecialFrames then return end
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == name then
            tremove(UISpecialFrames, i)
        end
    end
end

local function EnsureEscGate()
    if escGate then return escGate end
    escGate = CreateFrame("Frame", "BlackacreTomeEscGate")
    escGate:Hide()
    tinsert(UISpecialFrames, "BlackacreTomeEscGate")
    escGate:SetScript("OnHide", function()
        if suppressEscGate then return end
        -- Esc closes the journal only. A sidecar stays until its own X.
        if hub and hub:IsShown() then
            hub:Hide()
        end
    end)
    return escGate
end

local function SyncEscGate()
    EnsureEscGate()
    suppressEscGate = true
    if hub and hub:IsShown() then
        if not escGate:IsShown() then escGate:Show() end
    elseif escGate:IsShown() then
        escGate:Hide()
    end
    suppressEscGate = false
end

local function Print(msg)
    if Blackacre.Print then Blackacre.Print(msg) else print(msg) end
end

local function ShowBookAsChronicle()
    if not hub then return end
    hub.leftPage:Show()
    hub.rightPage:Show()
    hub.pageHost:Hide()
    hub.prevPageBtn:Show()
    hub.nextPageBtn:Show()
    if hub.leftPageNum then hub.leftPageNum:Show() end
    if hub.rightPageNum then hub.rightPageNum:Show() end
    if hub.chronicleBookmark then hub.chronicleBookmark:Show() end
    if hub.toolStrip then hub.toolStrip:Show() end
end

local function OpenChronicle()
    ShowBookAsChronicle()
    if chronicleHost then chronicleHost:Show() end
    if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.OnHubShow then
        pcall(Blackacre.Chronicle.UI.OnHubShow)
    end
end

-- The footer Backstory button only exists for players who installed it.
-- The page-jump row is chained off its left edge, so re-anchor that chain
-- to the footer's right edge when the button is hidden.
local function RefreshBackstoryButton()
    if not hub or not hub.backstoryBtn then return end
    local has = sidecar ~= nil
    hub.backstoryBtn:SetShown(has)
    if hub.pageJumpBtn then
        hub.pageJumpBtn:ClearAllPoints()
        if has then
            hub.pageJumpBtn:SetPoint("RIGHT", hub.backstoryBtn, "LEFT", -6, 0)
        else
            hub.pageJumpBtn:SetPoint("RIGHT", hub.footer, "RIGHT", -10, 0)
        end
    end
end

local function Build()
    local ok, err = pcall(function()
        if not Blackacre.UI or not Blackacre.UI.Theme or not Blackacre.UI.Theme.CreateBookShell then
            error("Theme.CreateBookShell missing — core UI failed to load")
        end
        local title = Blackacre.GetJournalTitle and Blackacre.GetJournalTitle() or "Journal"
        hub = Blackacre.UI.Theme.CreateBookShell("BlackacreTomeHub", title)
        -- Esc goes through BlackacreTomeEscGate so a sidecar is not closed with the book.
        RemoveFromUISpecialFrames("BlackacreTomeHub")
        EnsureEscGate()
        hub:HookScript("OnShow", function()
            SyncEscGate()
            if Blackacre.UI.Theme.PlayUISound then
                Blackacre.UI.Theme.PlayUISound("bookOpen")
            end
        end)
        hub:HookScript("OnHide", function()
            -- Commit any active editor before the book disappears. Text is
            -- also persisted as it changes; this covers a final paste or a
            -- focus change right before closing.
            if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.SaveSelected then
                pcall(Blackacre.Chronicle.UI.SaveSelected)
            end
            SyncEscGate()
            if Blackacre.UI.Theme.PlayUISound then
                Blackacre.UI.Theme.PlayUISound("bookClose")
            end
        end)

        -- In-character book only: chronicle hosts, no feature tabs on the book.
        chronicleHost = CreateFrame("Frame", nil, hub.bookOpen)
        chronicleHost:SetSize(1, 1)
        chronicleHost:SetPoint("TOPLEFT", hub.bookOpen, "TOPLEFT", 0, 0)
        chronicleHost:EnableMouse(false)
        chronicleHost:Hide()
        chronicleHost.tocHost = hub.leftPage
        chronicleHost.pageHost = hub.rightPage
        hub.chronicleHost = chronicleHost

        -- Full-page host for the Backstory setup wizard.
        setupHost = CreateFrame("Frame", nil, hub.pageHost)
        setupHost:SetAllPoints(hub.pageHost)
        setupHost:Hide()

        hub._built = true
        RefreshBackstoryButton()
        if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.EnsureBuilt then
            Blackacre.Chronicle.UI.EnsureBuilt()
        end
        OpenChronicle()
    end)
    if not ok then
        hub = nil
        Print("|cffff6666Journal failed to build:|r " .. tostring(err))
    end
end

local building = false
local function EnsureHub()
    -- Guard re-entry: the chronicle asks for its page hosts mid-build.
    if (not hub or not hub._built) and not building then
        building = true
        Build()
        building = false
    end
    return hub
end

--- Backstory (or another OOC add-on) attaches its menu here.
function Blackacre.TomeHub.RegisterSidecar(api)
    sidecar = api
    RefreshBackstoryButton()
end

function Blackacre.TomeHub.RefreshTitle()
    if hub and hub.title and Blackacre.GetJournalTitle then
        hub.title:SetText(Blackacre.GetJournalTitle())
    end
end

function Blackacre.TomeHub.GetChronicleTocParent()
    EnsureHub()
    return hub and hub.leftPage
end

function Blackacre.TomeHub.GetChroniclePageParent()
    EnsureHub()
    return hub and hub.rightPage
end

function Blackacre.TomeHub.Init()
end

--- The footer Backstory button and /ba backstory land here.
function Blackacre.TomeHub.ToggleBackstoryMenu(tabId)
    if sidecar then sidecar.Toggle(tabId) end
end

function Blackacre.TomeHub.Show(tabId)
    if not EnsureHub() then
        Print("The journal is not available; see system messages for errors to diagnose.")
        return
    end
    local ok, err = pcall(function()
        if Blackacre.SetupWizard and Blackacre.SetupWizard.PAUSED then
            setupMode = false
        end
        if setupMode or tabId == "setup" then
            hub:Show()
            return
        end
        if sidecar and tabId and sidecar.IsTab(tabId) then
            sidecar.Show(tabId)
            return
        end
        OpenChronicle()
        hub:Show()
    end)
    if not ok then
        Print("|cffff6666Journal open failed:|r " .. tostring(err))
    end
end

function Blackacre.TomeHub.Hide()
    if hub then hub:Hide() end
end

function Blackacre.TomeHub.Toggle(tabId)
    if not EnsureHub() then
        Print("The journal is not available; see system messages for errors to diagnose.")
        return
    end
    if sidecar and tabId and sidecar.IsTab(tabId) then
        sidecar.Toggle(tabId)
        return
    end
    if hub:IsShown() and not setupMode then
        Blackacre.TomeHub.Hide()
    else
        Blackacre.TomeHub.Show(tabId)
    end
end

function Blackacre.TomeHub.IsShown()
    return hub and hub:IsShown()
end

function Blackacre.TomeHub.GetFrame()
    EnsureHub()
    return hub
end

function Blackacre.TomeHub.OnJournalToggle(on)
    local msg = on and "Journaling On" or "Journaling is Off"
    if Blackacre.UI and Blackacre.UI.Theme and Blackacre.UI.Theme.Toast then
        Blackacre.UI.Theme.Toast(msg, "tome")
    else
        Print(msg)
    end
    if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.SetJournalMode then
        Blackacre.Chronicle.UI.SetJournalMode(on)
    end
end

function Blackacre.TomeHub.TurnPage(delta)
    if Blackacre.Chronicle and Blackacre.Chronicle.UI and Blackacre.Chronicle.UI.TurnPage then
        Blackacre.Chronicle.UI.TurnPage(delta)
    end
end
