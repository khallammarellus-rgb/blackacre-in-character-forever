-- In Character Forever - Boons

Blackacre = Blackacre or {}
Blackacre.Boons = {}

local pairs, ipairs, type = pairs, ipairs, type

local sources = {}      -- name -> function() returning array of effects (or nil)
local multCache = {}
local addCache = {}
local dirty = true

local function Settings()
    local c = Blackacre.CharDB
    if not c then return nil end
    c.boons = c.boons or { enabled = false }
    return c.boons
end

local function Rebuild()
    for k in pairs(multCache) do multCache[k] = nil end
    for k in pairs(addCache) do addCache[k] = nil end
    dirty = false
    local s = Settings()
    if not s or not s.enabled then return end
    for _, fn in pairs(sources) do
        local effects = fn()
        if effects then
            for _, e in ipairs(effects) do
                if e.key then
                    if e.mult then multCache[e.key] = (multCache[e.key] or 1) * e.mult end
                    if e.add then addCache[e.key] = (addCache[e.key] or 0) + e.add end
                end
            end
        end
    end
end

--- Register a source. fn returns an array of effects for this character.
function Blackacre.Boons.RegisterSource(name, fn)
    if type(name) ~= "string" or type(fn) ~= "function" then return end
    sources[name] = fn
    dirty = true
end

--- Call whenever a source's answer may have changed (sign picked, toggle, etc).
function Blackacre.Boons.Invalidate()
    dirty = true
end

--- Multiplier for key; 1 when off or nothing applies.
function Blackacre.Boons.Mult(key)
    if dirty then Rebuild() end
    return multCache[key] or 1
end

--- Additive offset for key; 0 when off or nothing applies.
function Blackacre.Boons.Add(key)
    if dirty then Rebuild() end
    return addCache[key] or 0
end

function Blackacre.Boons.IsEnabled()
    local s = Settings()
    return s and s.enabled or false
end

function Blackacre.Boons.SetEnabled(on)
    local s = Settings()
    if not s then return end
    s.enabled = on and true or false
    dirty = true
end
