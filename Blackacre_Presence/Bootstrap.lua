-- In Character Forever: Beacons & Bulletins - Startup

Blackacre = Blackacre or {}

local function InitPresence()
    if Blackacre.BeaconEmitter and Blackacre.BeaconEmitter.Init then
        Blackacre.BeaconEmitter.Init()
    end
    if Blackacre.BeaconHead and Blackacre.BeaconHead.Init then
        Blackacre.BeaconHead.Init()
    end
    if Blackacre.BeaconHint and Blackacre.BeaconHint.Init then
        Blackacre.BeaconHint.Init()
    end
    if Blackacre.PostEditor and Blackacre.PostEditor.Init then
        Blackacre.PostEditor.Init()
    end
    if Blackacre.InnBoard and Blackacre.InnBoard.Init then
        Blackacre.InnBoard.Init()
    end
end

if Blackacre.RegisterPackage then
    Blackacre.RegisterPackage("Presence", InitPresence)
else
    InitPresence()
end
