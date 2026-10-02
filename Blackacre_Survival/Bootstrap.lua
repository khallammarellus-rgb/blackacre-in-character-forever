-- In Character Forever: Survival - Startup

Blackacre = Blackacre or {}

local function InitSurvival()
    if Blackacre.Survival then
        if Blackacre.Survival.Engine and Blackacre.Survival.Engine.Init then
            Blackacre.Survival.Engine.Init()
        end
        if Blackacre.Survival.UI and Blackacre.Survival.UI.Init then
            Blackacre.Survival.UI.Init()
        end
    end
end

if Blackacre.RegisterPackage then
    Blackacre.RegisterPackage("Survival", InitSurvival)
else
    InitSurvival()
end
