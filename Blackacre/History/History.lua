-- In Character Forever - Draft History

Blackacre = Blackacre or {}
Blackacre.History = {}

function Blackacre.History.Init()
    BlackacreDB.history = BlackacreDB.history or {}
    -- migrate notice drafts
    if BlackacreDB.history.notice and not BlackacreDB.history.bulletin then
        BlackacreDB.history.bulletin = BlackacreDB.history.notice
    end
    -- Old name only; keeping it would save the list to disk twice.
    BlackacreDB.history.notice = nil
end

function Blackacre.History.SaveDraft(kind, entry)
    if kind == "notice" then kind = "bulletin" end
    BlackacreDB.history[kind] = BlackacreDB.history[kind] or {}
    entry.status = Blackacre.STATUS.DRAFT
    table.insert(BlackacreDB.history[kind], 1, entry)
    while #BlackacreDB.history[kind] > 20 do
        table.remove(BlackacreDB.history[kind])
    end
end

function Blackacre.History.GetDrafts(kind)
    if kind == "notice" then kind = "bulletin" end
    return BlackacreDB.history[kind] or {}
end

-- Drop one entry (the exact record) from a history list.
function Blackacre.History.RemoveDraft(kind, entry)
    local list = Blackacre.History.GetDrafts(kind)
    for i = #list, 1, -1 do
        if list[i] == entry then table.remove(list, i) end
    end
end

function Blackacre.History.Show()
    local beaconCount = #(Blackacre.History.GetDrafts("beacon"))
    local bulletinCount = #(Blackacre.History.GetDrafts("bulletin"))
    Blackacre.Print(string.format("History: %d beacon draft(s), %d bulletin draft(s).", beaconCount, bulletinCount))
end
