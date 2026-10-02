-- In Character Forever - Client Compatibility

Blackacre = Blackacre or {}
Blackacre.Compat = {}

local GetBuildInfo, tonumber, pcall = GetBuildInfo, tonumber, pcall

local cached

local function Detect()
    if cached then return cached end
    local version, _, _, interface = GetBuildInfo()
    cached = {
        version = version or "",
        interface = tonumber(interface) or 0,
    }
    return cached
end

--- Build facts for diagnostics (/ba storage, /ba packages).
function Blackacre.Compat.GetFlavor()
    return Detect()
end

function Blackacre.Compat.FlavorLabel()
    local f = Detect()
    return string.format("WoW Forever (%s / %d)", f.version, f.interface)
end

-- Forever presents rulesets instead of a realm picker. AceDB still builds its
-- own internal character key from GetRealmName(), so Blackacre's default
-- profile name uses the stable game-mode record when the client exposes it.
-- This is only a namespace for our profile name; it does not replace AceDB's
-- mapping or the explicit per-character pointer.
function Blackacre.Compat.GetProfileScope()
    if C_GameRules and C_GameRules.GetCurrentGameModeRecordID then
        local ok, recordID = pcall(C_GameRules.GetCurrentGameModeRecordID)
        if ok and type(recordID) == "number" and recordID > 0 then
            return "Forever ruleset " .. tostring(recordID)
        end
    end
    -- Must stay exactly "Forever": existing profiles are named with it.
    return "Forever"
end

--- Present year: Age of Adventure, 25 years after the Dark Portal.
Blackacre.Compat.PRESENT_ADP = 25
