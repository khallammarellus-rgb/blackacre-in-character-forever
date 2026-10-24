-- In Character Forever - Profile Backup

Blackacre = Blackacre or {}
Blackacre.Backup = Blackacre.Backup or {}

local pairs, ipairs, type, time, format, tostring, tinsert = pairs, ipairs, type, time, string.format, tostring, table.insert
local C_Timer, date = C_Timer, date

local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

local MAX_SNAPSHOTS = 4              -- newest first; a restore adds one more
local ROUTINE_SECONDS = 24 * 60 * 60 -- at most one routine snapshot a day
local CHUNK_BYTES = 64 * 1024        -- one compressed stream per slice
local CHUNK_LEVEL = 3                -- background slices: balance size and speed
local NOW_LEVEL = 1                  -- when the player is waiting: fastest
local SLICE_DELAY = 0.1              -- seconds between slices
local FIRST_DELAY = 10               -- let the world finish loading first
local COMBAT_DELAY = 5
local PAYLOAD_PREFIX = "BLACKACRE_PROFILE_V1:"
local MAX_IMPORT_BYTES = 40 * 1024 * 1024

local box, window

-- What each export carries. "full" is the whole profile; the others carry only
-- their own parts of the character data, and importing one replaces only those
-- parts. Backstory's lives in core's saved data like everything else, so it can
-- be exported even if the Backstory add-on is turned off.
local KINDS = {
    full = { format = "BlackacreProfileBackup", title = "Full Profile Backup",
        what = "journal, Quest Index and character data" },
    tome = { format = "BlackacreTomeBackup", title = "Tome Backup",
        keys = { "chronicle", "chronicleStory", "questLog" },
        what = "journal and Quest Index" },
    backstory = { format = "BlackacreBackstoryBackup", title = "Backstory Backup",
        keys = { "family", "identity" },
        what = "family tree, birthsign and birth details" },
}
local KIND_BY_FORMAT = {}
for key, kind in pairs(KINDS) do KIND_BY_FORMAT[kind.format] = key end

---------------------------------------------------------------------------
-- Storage
---------------------------------------------------------------------------

local function Store()
    BlackacreSafetyDB = BlackacreSafetyDB or {}
    BlackacreSafetyDB.snapshots = BlackacreSafetyDB.snapshots or {}
    return BlackacreSafetyDB
end

--- Pages and quests in a character-data table.
local function Count(cd)
    local pages, quests = 0, 0
    local chronicle = type(cd.chronicle) == "table" and cd.chronicle.entries
    if type(chronicle) == "table" then pages = #chronicle end
    local q = type(cd.questLog) == "table" and cd.questLog.quests
    if type(q) == "table" then
        for _ in pairs(q) do quests = quests + 1 end
    end
    return pages, quests
end

local function TextLen(s)
    return type(s) == "string" and #s or 0
end

--- A cheap fingerprint of the journal and the Quest Index (no serializing), so an
--- unchanged day costs nothing. Any edit changes a time, a text length or a count.
local function Fingerprint(cd)
    local sum = 0
    local entries = type(cd.chronicle) == "table" and cd.chronicle.entries
    if type(entries) == "table" then
        for i = 1, #entries do
            local e = entries[i]
            if type(e) == "table" then
                sum = sum + ((e.editedAt or 0) % 1000003) + TextLen(e.body) + TextLen(e.title)
                if type(e.stickyNotes) == "table" then
                    for j = 1, #e.stickyNotes do
                        local s = e.stickyNotes[j]
                        sum = sum + 7 + (type(s) == "table" and TextLen(s.text) or 0)
                    end
                end
                if type(e.bookmarks) == "table" then sum = sum + 3 * #e.bookmarks end
            end
        end
    end
    local q = type(cd.questLog) == "table" and cd.questLog.quests
    if type(q) == "table" then
        for _, rec in pairs(q) do
            if type(rec) == "table" then
                sum = sum + ((rec.completedAt or 0) % 1000003) + TextLen(rec.startText)
                    + TextLen(rec.endText) + TextLen(rec.progressText) + (rec.entryId and 5 or 0)
            end
        end
    end
    local pages, quests = Count(cd)
    -- %.0f, not %d: times between two pages are fractions (Insert Page, imported quests).
    return format("%d:%d:%.0f", pages, quests, sum % 2147483647), pages, quests
end

local function CompressChunk(chunk, level)
    return LibDeflate:EncodeForPrint(LibDeflate:CompressDeflate(chunk, { level = level }))
end

local function Unpack(chunks)
    if type(chunks) ~= "table" or #chunks == 0 then return nil end
    local parts = {}
    for i = 1, #chunks do
        local compressed = LibDeflate:DecodeForPrint(chunks[i])
        local raw = compressed and LibDeflate:DecompressDeflate(compressed)
        if not raw then return nil end
        parts[i] = raw
    end
    return table.concat(parts)
end

local function Deserialize(serialized)
    if type(serialized) ~= "string" then return nil end
    local ok, data = AceSerializer:Deserialize(serialized)
    if ok and type(data) == "table" then return data end
    return nil
end

--- A usable character-data table has a journal; everything else is optional.
local function Valid(data)
    if type(data) ~= "table" then return false end
    local chronicle = data.chronicle
    if type(chronicle) ~= "table" or type(chronicle.entries) ~= "table" then return false end
    for i = 1, #chronicle.entries do
        if type(chronicle.entries[i]) ~= "table" then return false end
    end
    if data.questLog ~= nil and type(data.questLog) ~= "table" then return false end
    return true
end

local function Fail(err)
    Store().lastError = { at = time(), message = tostring(err):sub(1, 240) }
end

local function AddSnapshot(rec)
    local store = Store()
    tinsert(store.snapshots, 1, rec)
    for i = #store.snapshots, MAX_SNAPSHOTS + 1, -1 do store.snapshots[i] = nil end
    store.lastError = nil
end

local function ProfileName()
    return Blackacre.db and Blackacre.db:GetCurrentProfile() or "?"
end

local function NewRecord(reason, fp, pages, quests)
    return {
        at = time(), reason = reason, fp = fp, pages = pages, quests = quests,
        profile = ProfileName(), version = Blackacre.VERSION, build = Blackacre.BUILD,
    }
end

---------------------------------------------------------------------------
-- Automatic snapshots
---------------------------------------------------------------------------

local job -- the snapshot being written, one at a time

local function Step(j)
    if job ~= j then return end -- replaced or cancelled
    if UnitAffectingCombat and UnitAffectingCombat("player") then
        C_Timer.After(COMBAT_DELAY, function() Step(j) end)
        return
    end
    local ok, err = pcall(function()
        local from = j.pos
        j.chunks[#j.chunks + 1] = CompressChunk(j.frozen:sub(from, from + CHUNK_BYTES - 1), CHUNK_LEVEL)
        j.pos = from + CHUNK_BYTES
    end)
    if not ok then
        job = nil
        Fail(err)
        return
    end
    if j.pos > #j.frozen then
        j.rec.chunks, j.rec.bytes = j.chunks, #j.frozen
        job = nil
        AddSnapshot(j.rec)
    else
        C_Timer.After(SLICE_DELAY, function() Step(j) end)
    end
end

--- Called once at login, after the character's data is bound and before the other
--- packages start up, so the copy is the data exactly as the last session saved it.
function Blackacre.Backup.OnLogin()
    local ok, err = pcall(function()
        local cd = Blackacre.CharDB
        if type(cd) ~= "table" then return end
        local profile = ProfileName()
        local last
        local list = Store().snapshots
        for i = 1, #list do
            if list[i].profile == profile then last = list[i] break end
        end
        local fp, pages, quests = Fingerprint(cd)
        local reason
        if not last then
            reason = "First backup"
        elseif fp ~= last.fp then
            if last.version ~= Blackacre.VERSION or last.build ~= Blackacre.BUILD then
                reason = "Before update to " .. tostring(Blackacre.VERSION)
            elseif time() - (last.at or 0) >= ROUTINE_SECONDS then
                reason = "Daily"
            end
        end
        if not reason then return end
        -- Freeze it now. Compressing happens later, a slice at a time.
        local frozen = AceSerializer:Serialize(cd)
        local j = { frozen = frozen, pos = 1, chunks = {}, rec = NewRecord(reason, fp, pages, quests) }
        job = j
        C_Timer.After(FIRST_DELAY, function() Step(j) end)
    end)
    if not ok then Fail(err) end
end

--- A snapshot made right now (the player is waiting), for "before restoring".
local function TakeNow(reason)
    local cd = Blackacre.CharDB
    local fp, pages, quests = Fingerprint(cd)
    local frozen = AceSerializer:Serialize(cd)
    local rec = NewRecord(reason, fp, pages, quests)
    rec.chunks, rec.bytes = {}, #frozen
    for pos = 1, #frozen, CHUNK_BYTES do
        rec.chunks[#rec.chunks + 1] = CompressChunk(frozen:sub(pos, pos + CHUNK_BYTES - 1), NOW_LEVEL)
    end
    AddSnapshot(rec)
end

--- A snapshot made right now, before a one-time data repair changes anything.
--- Returns false (and records why) if it couldn't be made; the caller must then
--- leave the data alone.
function Blackacre.Backup.SnapshotNow(reason)
    local ok, err = pcall(TakeNow, reason)
    if not ok then Fail(err) end
    return ok
end

function Blackacre.Backup.List()
    return Store().snapshots
end

function Blackacre.Backup.IsWriting()
    return job ~= nil
end

function Blackacre.Backup.LastError()
    return Store().lastError
end

---------------------------------------------------------------------------
-- Restore and import
---------------------------------------------------------------------------

--- Replace the live character data with `data`, keeping the same tables. The journal's
--- table is also referenced from a second saved-variable root, so it must stay the same
--- table or the two copies stop being one.
local function Apply(data)
    local cd = Blackacre.CharDB
    local chronicle = cd.chronicle
    for k in pairs(cd) do cd[k] = nil end
    for k, v in pairs(data) do cd[k] = v end
    if type(chronicle) == "table" and type(data.chronicle) == "table" then
        for k in pairs(chronicle) do chronicle[k] = nil end
        for k, v in pairs(data.chronicle) do chronicle[k] = v end
        cd.chronicle = chronicle
    end
end

--- Replace only one kind's parts of the live character data (Tome or Backstory).
--- The journal keeps its table, as in Apply.
local function ApplyPart(keys, data)
    local cd = Blackacre.CharDB
    for _, key in ipairs(keys) do
        local old, new = cd[key], data[key]
        if key == "chronicle" and type(old) == "table" and type(new) == "table" then
            for k in pairs(old) do old[k] = nil end
            for k, v in pairs(new) do old[k] = v end
        else
            cd[key] = new
        end
    end
end

--- Add every key `dst` doesn't have yet, all the way down. Nothing in `dst` changes.
local function FillMissing(dst, src)
    for k, v in pairs(src) do
        local have = dst[k]
        if have == nil then
            dst[k] = v
        elseif type(have) == "table" and type(v) == "table" then
            FillMissing(have, v)
        end
    end
end

local QUEST_TEXT_FIELDS = { "startText", "objective", "progressText", "endText", "giver", "giverEnd", "zone" }

--- Merge a Tome backup into the live journal and Quest Index (owner, 2026-10-23:
--- merge, never replace). Nothing is ever doubled:
---   pages: matched by id. A page only in the backup is added; a page in both keeps
---     whichever copy was edited last.
---   quests: matched by quest id. A quest only in the backup is added in its place by
---     completion time; a quest in both keeps this character's record and only gains
---     words or a journal link it was missing. Repeats folded away stay folded.
---   milestones (chronicleStory): only steps this character hasn't recorded are added.
--- Returns pages added, pages updated, quests added.
local function MergeTome(data)
    local cd = Blackacre.CharDB
    local added, updated, questsAdded = 0, 0, 0

    cd.chronicle = cd.chronicle or { entries = {} }
    cd.chronicle.entries = cd.chronicle.entries or {}
    local entries = cd.chronicle.entries
    local byId = {}
    for i, e in ipairs(entries) do
        if type(e) == "table" and e.id then byId[e.id] = i end
    end
    local incoming = type(data.chronicle) == "table" and data.chronicle.entries
    if type(incoming) == "table" then
        for _, e in ipairs(incoming) do
            if type(e) == "table" and e.id then
                local i = byId[e.id]
                if not i then
                    entries[#entries + 1] = e
                    byId[e.id] = #entries
                    added = added + 1
                elseif (e.editedAt or 0) > (entries[i].editedAt or 0) then
                    entries[i] = e
                    updated = updated + 1
                end
            end
        end
    end

    local theirs = type(data.questLog) == "table" and data.questLog
    if theirs and type(theirs.quests) == "table" then
        cd.questLog = cd.questLog or { quests = {}, order = {} }
        local q = cd.questLog
        q.quests, q.order, q.folded = q.quests or {}, q.order or {}, q.folded or {}
        if type(theirs.folded) == "table" then FillMissing(q.folded, theirs.folded) end
        for id, rec in pairs(theirs.quests) do
            if type(rec) == "table" and not q.folded[id] then
                local mine = q.quests[id]
                if not mine then
                    q.quests[id] = rec
                    if rec.completedAt then questsAdded = questsAdded + 1 end
                else
                    for _, field in ipairs(QUEST_TEXT_FIELDS) do
                        if mine[field] == nil then mine[field] = rec[field] end
                    end
                    if mine.entryId == nil then mine.entryId = rec.entryId end
                end
            end
        end
        -- Completion order again, oldest first, so added quests sit in their place.
        local order = {}
        for id, rec in pairs(q.quests) do
            if rec.completedAt then order[#order + 1] = id end
        end
        table.sort(order, function(a, b)
            local ta, tb = q.quests[a].completedAt, q.quests[b].completedAt
            if ta ~= tb then return ta < tb end
            return a < b
        end)
        q.order = order
    end

    if type(data.chronicleStory) == "table" then
        cd.chronicleStory = cd.chronicleStory or {}
        FillMissing(cd.chronicleStory, data.chronicleStory)
    end
    return added, updated, questsAdded
end
Blackacre.Backup.MergeTome = MergeTome -- for the tests

--- Quest words from a Tome backup go into the account's shared store, filling
--- only quests it has no words for. Nothing already there is replaced.
local function MergeQuestText(locale, words)
    if type(words) ~= "table" or type(locale) ~= "string" or not BlackacreDB then return end
    BlackacreDB.questText = BlackacreDB.questText or {}
    local store = BlackacreDB.questText[locale] or {}
    BlackacreDB.questText[locale] = store
    for id, saved in pairs(words) do
        if type(id) == "number" and type(saved) == "table" and store[id] == nil then
            store[id] = saved
        end
    end
end

local function ApplyAndReload(data, label, apply)
    job = nil
    -- Keep today's data too, so this can be undone. If that fails, change nothing.
    local ok, err = pcall(TakeNow, "Before restoring " .. label)
    if not ok then
        Fail(err)
        Blackacre.Print("Couldn't save a copy of your current data first, so nothing was changed.")
        return false
    end
    if apply then apply() else Apply(data) end
    Blackacre.Print("Backup restored. Reloading to save it...")
    ReloadUI()
    return true
end

local function Describe(rec)
    return format("%s - %d pages, %d quests - %s", date("%d %b %Y %H:%M", rec.at or 0),
        rec.pages or 0, rec.quests or 0, rec.reason or "Backup")
end

local function Confirm(message, onAccept)
    if StaticPopup_Show then
        StaticPopup_Show("BLACKACRE_RESTORE_BACKUP", message, nil, { onAccept = onAccept })
    end
end

StaticPopupDialogs["BLACKACRE_RESTORE_BACKUP"] = {
    text = "%s",
    button1 = "Restore",
    button2 = "Cancel",
    OnAccept = function(self)
        local data = self.data
        if data and data.onAccept then data.onAccept() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function Warning(rec)
    return "Replace this character's journal, Quest Index and character data with the backup from "
        .. Describe(rec) .. "?\n\nYour current data is saved first as a backup you can restore. The game will reload."
end

--- Ask, then restore snapshot number `index` of the list.
function Blackacre.Backup.RestoreSnapshot(index)
    local rec = Store().snapshots[index]
    local data = rec and Deserialize(Unpack(rec.chunks))
    if not Valid(data) then
        Blackacre.Print("That backup can't be read, so nothing was changed.")
        return false
    end
    Confirm(Warning(rec), function() ApplyAndReload(data, "a backup") end)
    return true
end

--- Read backup text made by Export. Returns the bundle, or nil and a reason.
function Blackacre.Backup.ParseExport(text)
    if type(text) ~= "string" or text == "" then return nil, "Paste the backup text first." end
    if #text > MAX_IMPORT_BYTES then return nil, "That text is too large to be a backup." end
    local payload = text:match(PAYLOAD_PREFIX .. "([%w%(%)%s]+)")
    if not payload then return nil, "That doesn't look like a backup made by this add-on." end
    payload = payload:gsub("%s+", "")
    local compressed = LibDeflate:DecodeForPrint(payload)
    local raw = compressed and LibDeflate:DecompressDeflate(compressed)
    local bundle = Deserialize(raw)
    local kind = bundle and bundle.version == 1 and KIND_BY_FORMAT[bundle.format]
    local damaged = "That backup is damaged or incomplete, so nothing was changed."
    if not kind then return nil, damaged end
    if kind == "full" and not Valid(bundle.characterData) then return nil, damaged end
    if kind == "tome" and not Valid(bundle.data) then return nil, damaged end
    if kind == "backstory" then
        local d = bundle.data
        if type(d) ~= "table" or (d.family ~= nil and type(d.family) ~= "table")
            or (d.identity ~= nil and type(d.identity) ~= "table") or not (d.family or d.identity) then
            return nil, damaged
        end
    end
    return bundle, nil, kind
end

local function FamilyCount(data)
    local n = 0
    local people = type(data.family) == "table" and data.family.people
    if type(people) == "table" then
        for _ in pairs(people) do n = n + 1 end
    end
    return n
end

--- Ask, then import a Tome or Backstory backup. A Tome backup is merged into the
--- journal and Quest Index; a Backstory backup replaces the family tree and birth
--- details. Nothing else is changed either way.
local function ImportPart(bundle, kindKey)
    local kind = KINDS[kindKey]
    local from = format("the %s from %s (profile %s)", kind.title,
        date("%d %b %Y %H:%M", bundle.exportedAt or 0), tostring(bundle.profileName or "?"))
    local message
    if kindKey == "tome" then
        local pages, quests = Count(bundle.data)
        message = format("Add to this character's journal and Quest Index from %s: %d pages, %d quests?\n\n"
            .. "Only what's missing is added; nothing is doubled and nothing you have is removed. "
            .. "Your current data is saved first as a backup you can restore. The game will reload.",
            from, pages, quests)
    else
        message = format("Replace this character's %s with %s: %d people in the family tree?\n\n"
            .. "Nothing else is changed. Your current data is saved first as a backup you can restore. The game will reload.",
            kind.what, from, FamilyCount(bundle.data))
    end
    Confirm(message, function()
        ApplyAndReload(bundle.data, "an imported " .. kind.title, function()
            if kindKey == "tome" then
                local added, updated, questsAdded = MergeTome(bundle.data)
                MergeQuestText(bundle.questTextLocale, bundle.questText)
                Blackacre.Print(format("Tome backup merged: %d pages added, %d pages updated, %d quests added.",
                    added, updated, questsAdded))
            else
                ApplyPart(kind.keys, bundle.data)
            end
        end)
    end)
    return true
end

--- Ask, then import backup text.
function Blackacre.Backup.ImportText(text)
    local bundle, err, kindKey = Blackacre.Backup.ParseExport(text)
    if not bundle then
        Blackacre.Print(err)
        return false
    end
    if kindKey ~= "full" then return ImportPart(bundle, kindKey) end
    local pages, quests = Count(bundle.characterData)
    local rec = { at = bundle.exportedAt, pages = pages, quests = quests,
        reason = "Exported text from the profile " .. tostring(bundle.profileName or "?") }
    Confirm(Warning(rec), function() ApplyAndReload(bundle.characterData, "an imported backup") end)
    return true
end

---------------------------------------------------------------------------
-- Export
---------------------------------------------------------------------------

local function Encode(bundle, comment)
    local serialized = AceSerializer:Serialize(bundle)
    local payload = PAYLOAD_PREFIX .. LibDeflate:EncodeForPrint(LibDeflate:CompressDeflate(serialized, { level = CHUNK_LEVEL }))
    -- The text is a valid Lua file, so it can be saved as one outside the game.
    return "-- " .. comment .. "\nBlackacreProfileBackup = " .. format("%q", payload) .. "\n"
end

--- A Tome or Backstory backup: only that kind's parts of the character data. A Tome
--- backup also carries the account's shared quest words in this game language.
local function BuildPartText(kindKey)
    local db = Blackacre.db
    local cd = Blackacre.CharDB
    if not (db and type(cd) == "table") then return nil end
    local kind = KINDS[kindKey]
    local data = {}
    for _, key in ipairs(kind.keys) do data[key] = cd[key] end
    local bundle = {
        format = kind.format,
        version = 1,
        profileName = db:GetCurrentProfile(),
        exportedAt = time(),
        data = data,
    }
    if kindKey == "tome" then
        local locale = GetLocale()
        bundle.questTextLocale = locale
        bundle.questText = BlackacreDB and BlackacreDB.questText and BlackacreDB.questText[locale]
    end
    return Encode(bundle, "Blackacre " .. kind.title:lower())
end

--- The backup as text that is also a valid .lua file. Returns the text and the counts.
--- kindKey: "full" (default), "tome" or "backstory".
function Blackacre.Backup.BuildExportText(kindKey)
    if kindKey == "tome" or kindKey == "backstory" then
        local text = BuildPartText(kindKey)
        if not text then return nil end
        if kindKey == "tome" then return text, Count(Blackacre.CharDB) end
        return text, FamilyCount(Blackacre.CharDB)
    end
    local db = Blackacre.db
    local profile = db and db.profile
    if not profile then return nil end
    local profileName = db:GetCurrentProfile()
    local settings = {}
    for k, v in pairs(profile) do
        if k ~= "characterData" then settings[k] = v end
    end
    local bundle = {
        format = "BlackacreProfileBackup",
        version = 1,
        profileID = profileName,
        profileName = profileName,
        exportedAt = time(),
        settings = settings,
        characterData = profile.characterData,
    }
    return Encode(bundle, "Blackacre full profile backup"), Count(profile.characterData)
end

local function BuildBox()
    local f = CreateFrame("Frame", "BlackacreProfileExportFrame", UIParent, "BackdropTemplate")
    f:SetSize(520, 340)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    Blackacre.UI.Theme.ApplyParchmentBackdrop(f, 0.98)
    tinsert(UISpecialFrames, "BlackacreProfileExportFrame")
    Blackacre.UI.Focus.Register(f)
    local title = f:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    Blackacre.UI.Theme.GoldTitle(title)
    f.title = title
    f.hint = f:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontHighlightSmall")
    f.hint:SetPoint("TOPLEFT", 16, -36)
    Blackacre.UI.Theme.InkFont(f.hint)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -56)
    scroll:SetPoint("BOTTOMRIGHT", -36, 16)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetWidth(460)
    edit:SetAutoFocus(true)
    edit:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(edit)
    f.edit = edit
    return f
end

--- kindKey: "full" (default), "tome" or "backstory".
function Blackacre.ExportProfileBackup(kindKey)
    kindKey = KINDS[kindKey] and kindKey or "full"
    local text, a, b = Blackacre.Backup.BuildExportText(kindKey)
    if not text then Blackacre.Print("Profile storage is not ready."); return end
    local kind = KINDS[kindKey]
    local counts
    if kindKey == "backstory" then
        counts = format("%d people in the family tree", a or 0)
    else
        counts = format("%d pages, %d quests", a or 0, b or 0)
    end
    box = box or BuildBox()
    box.title:SetText(kind.title)
    box.hint:SetText(format("%s, %d KB. Select all, copy, and save it as a .lua file somewhere safe.",
        counts, math.ceil(#text / 1024)))
    box.edit:SetText(text)
    box.edit:HighlightText()
    box:Show()
    box.edit:SetFocus()
    if Blackacre.UI and Blackacre.UI.Theme then Blackacre.UI.Theme.Toast(kind.title .. " ready to copy.") end
end

---------------------------------------------------------------------------
-- Window: automatic backups to restore from, and a box to import text
---------------------------------------------------------------------------

local ROW_H = 30
local HEADER_H, FOOTER_H = 30, 30

local function RefreshWindow()
    if not window then return end
    local list = Store().snapshots
    for i = 1, MAX_SNAPSHOTS do
        local row, rec = window.rows[i], list[i]
        if rec then
            row.text:SetText(Describe(rec) .. (rec.profile ~= ProfileName() and ("  (profile " .. tostring(rec.profile) .. ")") or ""))
            row:Show()
        else
            row:Hide()
        end
    end
    local err = Store().lastError
    local note
    if #list == 0 and job then
        note = "The first backup is being written. It appears here in a few seconds."
    elseif #list == 0 then
        note = "No automatic backup yet. One is made at the next login."
    elseif err then
        note = "The last automatic backup failed: " .. err.message
    elseif job then
        note = "A new backup is being written..."
    end
    window.note:SetText(note or "")
end

-- Built on the Quest Index template (see LESSONS-LEARNED): bronze shell, header strip,
-- Quest Log list panel for the backups, Quest Log panel for the import box too.
local function BuildWindow()
    local th = Blackacre.UI.Theme
    local f = CreateFrame("Frame", "BlackacreBackupFrame", UIParent, "BackdropTemplate")
    f:SetSize(600, 560)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "BlackacreBackupFrame")
    Blackacre.UI.Focus.Register(f)
    th.ApplyHeavyBronzeBase(f)
    f:SetScript("OnShow", RefreshWindow)

    f.header = CreateFrame("Frame", nil, f)
    f.header:SetPoint("TOPLEFT", 6, -6)
    f.header:SetPoint("TOPRIGHT", -6, -6)
    f.header:SetHeight(HEADER_H)
    f.title = f.header:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalLarge")
    f.title:SetPoint("CENTER", 0, 9)
    f.title:SetText("Backups")
    th.GoldTitle(f.title)
    local close = CreateFrame("Button", nil, f.header, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("RIGHT", -2, 6)
    close:SetScript("OnClick", function() f:Hide() end) -- parent is the header, not the window

    f.footer = CreateFrame("Frame", nil, f)
    f.footer:SetPoint("BOTTOMLEFT", 14, 14)
    f.footer:SetPoint("BOTTOMRIGHT", -14, 14)
    f.footer:SetHeight(FOOTER_H)
    f.inset = CreateFrame("Frame", nil, f)
    f.inset:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 8, -3)
    f.inset:SetPoint("TOPRIGHT", f.header, "BOTTOMRIGHT", -8, -3)
    f.inset:SetPoint("BOTTOMLEFT", f.footer, "TOPLEFT", 0, 6)
    f.inset:SetPoint("BOTTOMRIGHT", f.footer, "TOPRIGHT", 0, 6)

    local intro = f.inset:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 0, -2)
    intro:SetPoint("TOPRIGHT", 0, -2)
    intro:SetJustifyH("LEFT")
    intro:SetJustifyV("TOP")
    intro:SetHeight(58)
    intro:SetText("Your journal, Quest Index and character data are copied automatically at login (the first time, after an update, and once a day when something changed). Restoring replaces today's data, and a copy of it is kept first so you can undo.")

    -- Backups list (Quest Log panel, light text on the dark art)
    local list = CreateFrame("Frame", nil, f.inset)
    list:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -4)
    list:SetPoint("TOPRIGHT", intro, "BOTTOMRIGHT", 0, -4)
    list:SetHeight(MAX_SNAPSHOTS * ROW_H + 16)
    th.ApplyQuestLogListPanel(list)
    f.rows = {}
    for i = 1, MAX_SNAPSHOTS do
        local row = CreateFrame("Frame", nil, list)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT", 10, -8 - (i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", -10, -8 - (i - 1) * ROW_H)
        row.button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.button:SetSize(80, 22)
        row.button:SetPoint("RIGHT", 0, 0)
        row.button:SetText("Restore")
        row.button:SetScript("OnClick", function() Blackacre.Backup.RestoreSnapshot(i) end)
        row.text = row:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 0, 0)
        row.text:SetPoint("RIGHT", row.button, "LEFT", -8, 0)
        row.text:SetJustifyH("LEFT")
        f.rows[i] = row
    end

    f.note = f.inset:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontHighlightSmall")
    f.note:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 0, -6)
    f.note:SetPoint("TOPRIGHT", list, "BOTTOMRIGHT", 0, -6)
    f.note:SetJustifyH("LEFT")

    local exportBtn = CreateFrame("Button", nil, f.inset, "UIPanelButtonTemplate")
    exportBtn:SetSize(150, 22)
    exportBtn:SetPoint("TOPLEFT", f.note, "BOTTOMLEFT", 0, -10)
    exportBtn:SetText("Export everything")
    exportBtn:SetScript("OnClick", function() Blackacre.ExportProfileBackup("full") end)
    local tomeBtn = CreateFrame("Button", nil, f.inset, "UIPanelButtonTemplate")
    tomeBtn:SetSize(150, 22)
    tomeBtn:SetPoint("LEFT", exportBtn, "RIGHT", 6, 0)
    tomeBtn:SetText("Export Tome")
    tomeBtn:SetScript("OnClick", function() Blackacre.ExportProfileBackup("tome") end)
    -- Only with Backstory installed: the public build never points at an add-on
    -- the player doesn't have.
    if Blackacre.Backstory then
        local backstoryBtn = CreateFrame("Button", nil, f.inset, "UIPanelButtonTemplate")
        backstoryBtn:SetSize(150, 22)
        backstoryBtn:SetPoint("LEFT", tomeBtn, "RIGHT", 6, 0)
        backstoryBtn:SetText("Export Backstory")
        backstoryBtn:SetScript("OnClick", function() Blackacre.ExportProfileBackup("backstory") end)
    end

    local importLabel = f.inset:CreateFontString(nil, "OVERLAY", "BlackacreFont_GameFontNormalSmall")
    importLabel:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -10)
    importLabel:SetText("Import: paste backup text below, then press Import.")

    -- Import box on the Quest Log panel (grey, light text)
    local page = CreateFrame("Frame", nil, f.inset)
    page:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -4)
    page:SetPoint("BOTTOMRIGHT", f.inset, "BOTTOMRIGHT", 0, 0)
    th.ApplyQuestLogListPanel(page)
    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetTextColor(1, 1, 1, 1)
    edit:SetWidth(520)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(0) -- backups are long
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    f.edit = edit

    local importBtn = CreateFrame("Button", nil, f.footer, "UIPanelButtonTemplate")
    importBtn:SetSize(100, 22)
    importBtn:SetPoint("RIGHT", 0, 0)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function() Blackacre.Backup.ImportText(edit:GetText()) end)
    return f
end

function Blackacre.Backup.ShowWindow()
    window = window or BuildWindow()
    RefreshWindow()
    window:Show()
end
