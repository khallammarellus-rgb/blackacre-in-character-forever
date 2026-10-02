-- In Character Forever - Minimap Button

Blackacre = Blackacre or {}
Blackacre.MinimapButton = {}

local ldb = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

local unread = 0

function Blackacre.MinimapButton.Init()
    local dataObj = ldb:NewDataObject("Blackacre", {
        type = "launcher",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        OnClick = function(_, button)
            if button == "RightButton" then
                if IsShiftKeyDown() then
                    if Blackacre.BugReport and Blackacre.BugReport.Show then
                        Blackacre.BugReport.Show()
                    else
                        Blackacre.Print("Bug report window is not loaded.")
                    end
                else
                    if Blackacre.TomeHub and Blackacre.TomeHub.Toggle then
                        Blackacre.TomeHub.Toggle()
                    elseif Blackacre.Chronicle and Blackacre.Chronicle.UI then
                        Blackacre.Chronicle.UI.Toggle()
                    else
                        Blackacre.Print("Enable In Character Forever: Journal for the journal.")
                    end
                end
            else
                if Blackacre.ToolBox and Blackacre.ToolBox.Toggle then
                    Blackacre.ToolBox.Toggle()
                else
                    Blackacre.Print("Tool Box is not loaded.")
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Blackacre")
            tooltip:AddLine("Left-click: Tool Box", 1, 1, 1)
            tooltip:AddLine("Right-click: Journal", 1, 1, 1)
            tooltip:AddLine("Shift+Right-click: Bug / Feedback report", 0.8, 0.8, 0.8)
            if unread > 0 then
                tooltip:AddLine(unread .. " new nearby", 0.8, 0.7, 0.2)
            end
        end,
    })

    -- Ensure a valid LibDBIcon table (hide must be boolean false to show)
    local minimapDB
    local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    if settings then
        settings.minimap = settings.minimap or { hide = false }
        if settings.minimap.hide == nil then
            settings.minimap.hide = false
        end
        minimapDB = settings.minimap
    else
        BlackacreDB = BlackacreDB or {}
        BlackacreDB.minimap = BlackacreDB.minimap or { hide = false }
        if BlackacreDB.minimap.hide == nil then
            BlackacreDB.minimap.hide = false
        end
        minimapDB = BlackacreDB.minimap
    end
    -- Force visible on init unless user explicitly hid
    if minimapDB.hide ~= true then
        minimapDB.hide = false
    end
    -- Register/Refresh already show or hide by minimapDB.hide. An extra
    -- Show() here put a hidden button back on the minimap at every login.
    if not icon:IsRegistered("Blackacre") then
        icon:Register("Blackacre", dataObj, minimapDB)
    else
        icon:Refresh("Blackacre", minimapDB)
    end
end

function Blackacre.MinimapButton.Refresh()
    local settings = Blackacre.GetProfileSettings and Blackacre.GetProfileSettings()
    local minimapDB = (settings and settings.minimap) or (BlackacreDB and BlackacreDB.minimap)
    if not minimapDB then
        icon:Show("Blackacre")
        return
    end
    if minimapDB.hide then
        icon:Hide("Blackacre")
    else
        icon:Show("Blackacre")
    end
    icon:Refresh("Blackacre", minimapDB)
end

function Blackacre.MinimapButton.Notify()
    unread = unread + 1
end
