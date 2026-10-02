-- In Character Forever: Journal - Page Store

Blackacre = Blackacre or {}
Blackacre.Chronicle = Blackacre.Chronicle or {}
Blackacre.Chronicle.Store = {}

local ipairs, pairs, type, time, table_insert, table_remove, table_sort =
    ipairs, pairs, type, time, table.insert, table.remove, table.sort

-- Kinds older builds stored but never showed (survival and mount notes,
-- automatic every-quest notes, hidden profession notes). Nothing writes
-- them any more; they are deleted once per profile on first load.
local LEGACY_HIDDEN = {
    SURVIVAL = true,
    HC_MOUNT = true,
    HC_FLY = true,
    HC_ENCUMBRANCE = true,
    PROFESSION = true,
    QUEST = true,
}

-- Bumped on every change to any entry. The book UI caches its page layout
-- and only rebuilds when this moves, instead of on every page turn.
local version = 0

function Blackacre.Chronicle.Store.Touch()
    version = version + 1
end

function Blackacre.Chronicle.Store.Version()
    return version
end

--- Every stored entry is a page now (legacy hidden records are purged on
--- load); kept as the one place the book asks.
function Blackacre.Chronicle.Store.IsBookKind()
    return true
end

local function EnsureDB()
    -- The active AceDB profile owns the feature data. BlackacreCharDB remains
    -- a compatibility mirror for older installs and the profile pointer.
    local owner = Blackacre.CharDB or BlackacreCharDB or {}
    Blackacre.CharDB = owner
    owner.chronicle = owner.chronicle or { entries = {}, nextNotify = true }
    owner.chronicle.entries = owner.chronicle.entries or {}
    if type(BlackacreCharDB) == "table" and BlackacreCharDB ~= owner then
        BlackacreCharDB.chronicle = owner.chronicle
    end
    return owner.chronicle
end

-- One-time cleanup: delete the hidden records older builds kept. Profession
-- milestones written after this are real pages, so the flag stops it
-- from ever running again on this profile.
local function PurgeLegacyHidden(db)
    if db.purgedHidden then return end
    local entries = db.entries
    for i = #entries, 1, -1 do
        if LEGACY_HIDDEN[entries[i].kind] then table_remove(entries, i) end
    end
    db.purgedHidden = true
    version = version + 1
end

function Blackacre.Chronicle.Store.Init()
    PurgeLegacyHidden(EnsureDB())
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

function Blackacre.Chronicle.Store.StoryTime(entry)
    return entry.storyAt or entry.createdAt or 0
end
local StoryTime = Blackacre.Chronicle.Store.StoryTime

local function StoryBefore(a, b)
    local sa, sb = StoryTime(a), StoryTime(b)
    if sa ~= sb then return sa < sb end
    local ca, cb = a.createdAt or 0, b.createdAt or 0
    if ca ~= cb then return ca < cb end
    return (a.id or "") < (b.id or "")
end

function Blackacre.Chronicle.Store.Add(entry)
    local db = EnsureDB()
    local now = time()
    entry.id = entry.id or Blackacre.NewID()
    entry.createdAt = entry.createdAt or now
    entry.storyAt = entry.storyAt or entry.createdAt
    entry.editedAt = entry.editedAt or entry.createdAt
    entry.pinned = entry.pinned or false
    entry.tags = entry.tags or {}
    -- No page limit: pages are only ever removed by the player.
    table_insert(db.entries, 1, entry)
    version = version + 1
    return entry
end

--- A story time that sorts right after `entry` and before whatever page
--- follows it in the book, so a new page lands exactly there.
function Blackacre.Chronicle.Store.StoryTimeAfter(entry)
    local here = StoryTime(entry)
    local nextAt
    for _, e in ipairs(EnsureDB().entries) do
        local t = StoryTime(e)
        if e ~= entry and Blackacre.Chronicle.Store.IsBookKind(e.kind) and t > here
            and (not nextAt or t < nextAt) then
            nextAt = t
        end
    end
    if nextAt then
        return here + (nextAt - here) / 2
    end
    return here + 1
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
            table_remove(db.entries, i)
            version = version + 1
            return true
        end
    end
    return false
end

local function PinnedThenNewest(a, b)
    if a.pinned ~= b.pinned then
        return a.pinned
    end
    return StoryBefore(b, a)
end

function Blackacre.Chronicle.Store.List(opts)
    opts = opts or {}
    local list = {}
    local q = opts.search and opts.search ~= "" and opts.search:lower() or nil
    for _, entry in ipairs(EnsureDB().entries) do
        if not (opts.kind and entry.kind ~= opts.kind) then
            if q then
                local hay = ((entry.title or "") .. " " .. (entry.body or "") .. " " .. (entry.zoneName or "")):lower()
                if hay:find(q, 1, true) then
                    list[#list + 1] = entry
                end
            else
                list[#list + 1] = entry
            end
        end
    end
    table_sort(list, opts.oldestFirst and StoryBefore or PinnedThenNewest)
    return list
end
