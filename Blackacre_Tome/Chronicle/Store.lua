Blackacre = Blackacre or {}
Blackacre.Chronicle = Blackacre.Chronicle or {}
Blackacre.Chronicle.Store = {}

local MAX_ENTRIES = 500

-- Bumped on every change to any entry.  The book UI caches its page layout
-- and only rebuilds when this moves, instead of on every page turn.
local version = 0

function Blackacre.Chronicle.Store.Touch()
    version = version + 1
end

function Blackacre.Chronicle.Store.Version()
    return version
end

local function EnsureDB()
    -- The active AceDB profile owns the feature data. BlackacreCharDB remains
    -- a compatibility mirror for older installs and the profile pointer.
    local owner = Blackacre.CharDB or BlackacreCharDB or {}
    Blackacre.CharDB = owner
    owner.chronicle = owner.chronicle or {
        entries = {},
        nextNotify = true,
    }
    owner.chronicle.entries = owner.chronicle.entries or {}
    if type(BlackacreCharDB) == "table" and BlackacreCharDB ~= owner then
        BlackacreCharDB.chronicle = owner.chronicle
    end
    return owner.chronicle
end

function Blackacre.Chronicle.Store.Init()
    EnsureDB()
end

function Blackacre.Chronicle.Store.GetAll()
    return EnsureDB().entries
end

function Blackacre.Chronicle.Store.GetById(id)
    for _, entry in ipairs(EnsureDB().entries) do
        if entry.id == id then
            return entry
        end
    end
    return nil
end

function Blackacre.Chronicle.Store.Add(entry)
    local db = EnsureDB()
    entry.id = entry.id or Blackacre.NewID()
    entry.createdAt = entry.createdAt or time()
    entry.editedAt = entry.editedAt or entry.createdAt
    entry.pinned = entry.pinned or false
    entry.tags = entry.tags or {}
    table.insert(db.entries, 1, entry)
    while #db.entries > MAX_ENTRIES do
        -- Prefer dropping unpinned oldest auto entries
        local removed = false
        for i = #db.entries, 1, -1 do
            local e = db.entries[i]
            if not e.pinned then
                table.remove(db.entries, i)
                removed = true
                break
            end
        end
        if not removed then
            table.remove(db.entries)
        end
    end
    version = version + 1
    return entry
end

function Blackacre.Chronicle.Store.Update(id, fields)
    local entry = Blackacre.Chronicle.Store.GetById(id)
    if not entry then return nil end
    for k, v in pairs(fields) do
        entry[k] = v
    end
    entry.editedAt = time()
    version = version + 1
    return entry
end

function Blackacre.Chronicle.Store.Delete(id)
    local db = EnsureDB()
    for i, entry in ipairs(db.entries) do
        if entry.id == id then
            table.remove(db.entries, i)
            version = version + 1
            return true
        end
    end
    return false
end

function Blackacre.Chronicle.Store.List(opts)
    opts = opts or {}
    local list = {}
    for _, entry in ipairs(EnsureDB().entries) do
        if opts.kind and entry.kind ~= opts.kind then
            -- skip
        elseif opts.search and opts.search ~= "" then
            local q = opts.search:lower()
            local hay = ((entry.title or "") .. " " .. (entry.body or "") .. " " .. (entry.zoneName or "")):lower()
            if hay:find(q, 1, true) then
                list[#list + 1] = entry
            end
        else
            list[#list + 1] = entry
        end
    end
    if opts.oldestFirst then
        table.sort(list, function(a, b)
            return (a.createdAt or 0) < (b.createdAt or 0)
        end)
    else
        table.sort(list, function(a, b)
            if a.pinned ~= b.pinned then
                return a.pinned
            end
            return (a.createdAt or 0) > (b.createdAt or 0)
        end)
    end
    return list
end
