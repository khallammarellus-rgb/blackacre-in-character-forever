-- In Character Forever - Tour Steps

local Tour = Blackacre.Tour

local function ToolBoxButton(id)
    return function()
        local tb = Blackacre.ToolBox
        return tb and tb.GetButton and tb.GetButton(id)
    end
end

local function TomeHubFrame()
    local hub = Blackacre.TomeHub
    return hub and hub.GetFrame and hub.GetFrame()
end

-- Windows the tour opened itself, so it can put them back. The Tome and the Tool Box
-- sit on top of each other in the middle of the screen: whichever step needs one
-- puts the other away, otherwise the Tool Box ends up hidden behind the book.
local opened = {}

local function HideToolBox()
    local f = _G["BlackacreToolBox"]
    if f and f:IsShown() then f:Hide() end
    opened.toolbox = nil
end

local function HideTome()
    local hub = Blackacre.TomeHub
    if hub and hub.IsShown and hub.IsShown() then hub.Hide() end
    opened.tome = nil
end

local function OpenTome()
    local hub = Blackacre.TomeHub
    if not (hub and hub.Show) then return end
    HideToolBox()
    if not hub.IsShown() then
        hub.Show()
        opened.tome = true
    end
end

local function OpenToolBox()
    local tb = Blackacre.ToolBox
    if not (tb and tb.Show) then return end
    HideTome()
    local f = _G["BlackacreToolBox"]
    if not (f and f:IsShown()) then opened.toolbox = true end
    tb.Show()
end

function Tour.onStop()
    if opened.tome then HideTome() end
    if opened.toolbox then HideToolBox() end
end

local hasTome = function() return Blackacre.TomeHub ~= nil end
local hasPresence = function() return Blackacre.PostEditor ~= nil end
local hasSurvival = function() return Blackacre.Survival ~= nil end

Tour.RegisterSection("minimap", "Minimap Button", {
    {
        title = "The minimap button",
        text = "Left-click opens the Tool Box. Right-click opens your Tome. Shift + right-click sends a bug report or feedback.",
        target = function() return _G["LibDBIcon10_Blackacre"] end,
        missing = "The minimap button is hidden. You can show it again in Settings > General.",
    },
})

Tour.RegisterSection("toolbox", "Tool Box", {
    {
        title = "The Tool Box",
        text = "Your everyday switches in one place: the Tome, Trails, your Beacon and Bulletin, and the Emit, Seeking and Survival toggles. Drag it wherever you like.",
        target = function() return _G["BlackacreToolBox"] end,
        side = "TOP",
        onEnter = OpenToolBox,
    },
})

Tour.RegisterSection("tome", "Tome", {
    {
        title = "The Tome",
        text = "Your in-character journal. Everything in it is written as your character, in first person. Pages sit in story order, not the order you wrote them.",
        target = TomeHubFrame,
        onEnter = OpenTome,
        available = hasTome,
    },
    {
        title = "Quest Index",
        text = "Every quest you take up and finish is recorded here in its own words. A quest only becomes a journal page when you choose \"Log this quest\".",
        target = function()
            local hub = TomeHubFrame()
            return hub and hub.questIndexBtn
        end,
        side = "TOP",
        onEnter = OpenTome,
        available = hasTome,
    },
    {
        title = "Add a note",
        text = "Right-click anywhere on a page to stick a note to it. Notes can be locked in place or unlocked to edit.",
        target = function()
            local hub = Blackacre.TomeHub
            return hub and hub.GetChroniclePageParent and hub.GetChroniclePageParent()
        end,
        side = "LEFT",
        onEnter = OpenTome,
        available = hasTome,
    },
    {
        title = "Bookmarking",
        text = "Right-click an entry in the contents and choose \"Bookmark page\". Bookmarked pages gather at the top of the contents and show a tab on the page itself.",
        target = function()
            local hub = Blackacre.TomeHub
            return hub and hub.GetChronicleTocParent and hub.GetChronicleTocParent()
        end,
        side = "RIGHT",
        onEnter = OpenTome,
        available = hasTome,
    },
    {
        title = "Add a page",
        text = "This button adds a blank page right after the one you have open, at the end of the book, or at a page number you pick. It asks which year the page is set in.",
        target = function()
            local hub = TomeHubFrame()
            return hub and hub.addPageBtn
        end,
        side = "BOTTOM",
        onEnter = OpenTome,
        available = hasTome,
    },
})

Tour.RegisterSection("beacon", "Beacon", {
    {
        title = "Beacon",
        text = "A Beacon tells other players, passing nearby, what your character is doing and how to approach. Open the editor here. Emit must be on for others to see it.",
        target = ToolBoxButton("beacon"),
        side = "TOP",
        onEnter = OpenToolBox,
        available = hasPresence,
    },
})

Tour.RegisterSection("bulletin", "Bulletin", {
    {
        title = "Bulletin",
        text = "A Bulletin is a notice you post for others to find: a job, an event, a message. Open the editor here.",
        target = ToolBoxButton("bulletin"),
        side = "TOP",
        onEnter = OpenToolBox,
        available = hasPresence,
    },
})

local function SurvivalIcon(key)
    return function()
        local ui = Blackacre.Survival and Blackacre.Survival.UI
        return ui and ui.GetIcon and ui.GetIcon(key)
    end
end

local survivalOff = "Survival is switched off for this character. Turn it on from the Tool Box."

Tour.RegisterSection("survival", "Survival Pane", {
    {
        title = "Survival",
        text = "Three meters: Exposure, Thirst and Hunger. They carry no penalties. Drag the panel anywhere, and use the arrow to collapse it. The Tool Box turns it on and off.",
        target = function() return _G["BlackacreSurvivalMeters"] end,
        side = "LEFT",
        available = hasSurvival,
        missing = survivalOff,
    },
    {
        title = "Hunger",
        text = "Fills as you eat. The number is how many stacks you have, and a red border means it has run low.",
        target = SurvivalIcon("hunger"),
        side = "LEFT",
        available = hasSurvival,
        missing = survivalOff,
    },
    {
        title = "Thirst",
        text = "Fills as you drink. Same stacks, same red border when low.",
        target = SurvivalIcon("thirst"),
        side = "LEFT",
        available = hasSurvival,
        missing = survivalOff,
    },
    {
        title = "Exposure",
        text = "How well you're coping with the weather where you are. Hover it to see why.",
        target = SurvivalIcon("exposure"),
        side = "LEFT",
        available = hasSurvival,
        missing = survivalOff,
    },
    {
        title = "Prepared",
        text = "Appears while you carry food or water. It's your preparation keeping you sated.",
        target = SurvivalIcon("prepared"),
        side = "LEFT",
        available = hasSurvival,
        missing = "This icon only shows while you have food or water in your bags.",
    },
})
