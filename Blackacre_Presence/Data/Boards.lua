-- In Character Forever: Beacons & Bulletins - Boards

Blackacre = Blackacre or {}
Blackacre.Boards = {}

local boards = {
    -- Eastern Kingdoms / Kalimdor capitals
    {
        id = "sw_heroes_call",
        zoneId = 84,
        coords = { x = 0.62, y = 0.72 },
        displayName = "Stormwind Hero's Call Bulletin Board",
        proximityRadius = 0.04,
        region = "Stormwind",
    },
    {
        id = "sw_trade_board",
        zoneId = 84,
        coords = { x = 0.61, y = 0.74 },
        displayName = "Stormwind Trade District Bulletin Board",
        proximityRadius = 0.03,
        region = "Stormwind",
    },
    {
        id = "if_board",
        zoneId = 87,
        coords = { x = 0.55, y = 0.47 },
        displayName = "Ironforge Military Ward Board",
        proximityRadius = 0.04,
        region = "Ironforge",
    },
    {
        id = "darn_board",
        zoneId = 89,
        coords = { x = 0.55, y = 0.52 },
        displayName = "Darnassus Craftsmen's Terrace Board",
        proximityRadius = 0.04,
        region = "Darnassus",
    },
    {
        id = "org_warchief",
        zoneId = 85,
        coords = { x = 0.49, y = 0.76 },
        displayName = "Orgrimmar Warchief's Command Bulletin Board",
        proximityRadius = 0.04,
        region = "Orgrimmar",
    },
    {
        id = "org_valley_board",
        zoneId = 85,
        coords = { x = 0.52, y = 0.88 },
        displayName = "Valley of Strength Bulletin Board",
        proximityRadius = 0.03,
        region = "Orgrimmar",
    },
    {
        id = "tb_board",
        zoneId = 88,
        coords = { x = 0.47, y = 0.50 },
        displayName = "Thunder Bluff Central Rise Board",
        proximityRadius = 0.04,
        region = "Thunder Bluff",
    },
    {
        id = "sm_board",
        zoneId = 110,
        coords = { x = 0.54, y = 0.50 },
        displayName = "Silvermoon Court of the Sun Board",
        proximityRadius = 0.04,
        region = "Silvermoon",
    },
    -- Outland / Northrend / Broken Isles
    {
        id = "shattrath_board",
        zoneId = 111,
        coords = { x = 0.53, y = 0.50 },
        displayName = "Shattrath Terrace of Light Board",
        proximityRadius = 0.04,
        region = "Shattrath",
    },
    {
        id = "dalaran_board",
        zoneId = 627,
        coords = { x = 0.48, y = 0.42 },
        displayName = "Dalaran Commission Bulletin Board",
        proximityRadius = 0.04,
        region = "Dalaran",
    },
    {
        id = "dalaran_northrend",
        zoneId = 125,
        coords = { x = 0.48, y = 0.42 },
        displayName = "Dalaran (Northrend) Notice Board",
        proximityRadius = 0.04,
        region = "Dalaran",
    },
    -- BfA capitals
    {
        id = "boralus_board",
        zoneId = 1161,
        coords = { x = 0.48, y = 0.62 },
        displayName = "Boralus Harbor Commission Board",
        proximityRadius = 0.04,
        region = "Boralus",
    },
    {
        id = "dazaralor_board",
        zoneId = 1165,
        coords = { x = 0.50, y = 0.45 },
        displayName = "Dazar'alor Great Seal Board",
        proximityRadius = 0.04,
        region = "Dazar'alor",
    },
    -- Shadowlands / Dragonflight / TWW
    {
        id = "oribos_board",
        zoneId = 1670,
        coords = { x = 0.50, y = 0.52 },
        displayName = "Oribos Ring of Fates Board",
        proximityRadius = 0.04,
        region = "Oribos",
    },
    {
        id = "valdrakken_board",
        zoneId = 2112,
        coords = { x = 0.48, y = 0.58 },
        displayName = "Valdrakken Seat of the Aspects Board",
        proximityRadius = 0.04,
        region = "Valdrakken",
    },
    {
        id = "dornogal_board",
        zoneId = 2339,
        coords = { x = 0.48, y = 0.52 },
        displayName = "Dornogal Foundation Hall Board",
        proximityRadius = 0.04,
        region = "Dornogal",
    },
}

local boardsByZone = {}
for i = 1, #boards do
    local board = boards[i]
    local list = boardsByZone[board.zoneId]
    if not list then
        list = {}
        boardsByZone[board.zoneId] = list
    end
    list[#list + 1] = board
end

function Blackacre.Boards.GetAll()
    return boards
end

function Blackacre.Boards.GetById(boardId)
    for _, board in ipairs(boards) do
        if board.id == boardId then
            return board
        end
    end
    return nil
end

-- Major overworld zones + capitals for bulletin Posted Location.
local MAJOR_ZONES = {
    { id = "elwynn", name = "Elwynn Forest" },
    { id = "westfall", name = "Westfall" },
    { id = "redridge", name = "Redridge Mountains" },
    { id = "duskwood", name = "Duskwood" },
    { id = "stranglethorn", name = "Stranglethorn Vale" },
    { id = "dun_morogh", name = "Dun Morogh" },
    { id = "loch_modan", name = "Loch Modan" },
    { id = "wetlands", name = "Wetlands" },
    { id = "teldrassil", name = "Teldrassil" },
    { id = "darkshore", name = "Darkshore" },
    { id = "ashenvale", name = "Ashenvale" },
    { id = "durotar", name = "Durotar" },
    { id = "barrens", name = "The Barrens" },
    { id = "mulgore", name = "Mulgore" },
    { id = "stonetalon", name = "Stonetalon Mountains" },
    { id = "desolace", name = "Desolace" },
    { id = "feralas", name = "Feralas" },
    { id = "dustwallow", name = "Dustwallow Marsh" },
    { id = "thousand_needles", name = "Thousand Needles" },
    { id = "tanaris", name = "Tanaris" },
    { id = "ungoro", name = "Un'goro Crater" },
    { id = "felwood", name = "Felwood" },
    { id = "winterspring", name = "Winterspring" },
    { id = "azshara", name = "Azshara" },
    { id = "tirisfal", name = "Tirisfal Glades" },
    { id = "silverpine", name = "Silverpine Forest" },
    { id = "hillsbrad", name = "Hillsbrad Foothills" },
    { id = "alterac", name = "Alterac Mountains" },
    { id = "arathi", name = "Arathi Highlands" },
    { id = "hinterlands", name = "The Hinterlands" },
    { id = "badlands", name = "Badlands" },
    { id = "searing_gorge", name = "Searing Gorge" },
    { id = "burning_steppes", name = "Burning Steppes" },
    { id = "swamp_of_sorrows", name = "Swamp of Sorrows" },
    { id = "blasted_lands", name = "Blasted Lands" },
    { id = "deadwind", name = "Deadwind Pass" },
    { id = "wpl", name = "Western Plaguelands" },
    { id = "epl", name = "Eastern Plaguelands" },
    { id = "silithus", name = "Silithus" },
    { id = "stormwind", name = "Stormwind City", capital = true },
    { id = "ironforge", name = "Ironforge", capital = true },
    { id = "darnassus", name = "Darnassus", capital = true },
    { id = "orgrimmar", name = "Orgrimmar", capital = true },
    { id = "thunder_bluff", name = "Thunder Bluff", capital = true },
    { id = "undercity", name = "Undercity", capital = true },
}

for i = 1, #MAJOR_ZONES do
    MAJOR_ZONES[i].nameLower = MAJOR_ZONES[i].name:lower()
end

-- Region key + display name for a zone name (the key notices are posted under).
function Blackacre.Boards.ZoneKeyForName(zoneName)
    local name = (zoneName or ""):lower()
    for i = 1, #MAJOR_ZONES do
        if name:find(MAJOR_ZONES[i].nameLower, 1, true) then
            return MAJOR_ZONES[i].id, MAJOR_ZONES[i].name
        end
    end
    if name ~= "" then
        return (name:gsub("%s+", "_")), zoneName
    end
    return "unknown", zoneName or "Unknown"
end

function Blackacre.Boards.CurrentZoneKey()
    return Blackacre.Boards.ZoneKeyForName(Blackacre.GetZoneSnapshot().zoneName)
end

-- innNpcID: the innkeeper the reader is talking to. "Only this inn" notices
-- show only there; pass nil for region-level checks (toasts).
-- factions: set of faction names with innkeepers here (the innkeeper being
-- asked, or every known innkeeper in the region). A notice spread through a
-- faction network ("Spread the word") matches wherever that faction keeps an inn.
function Blackacre.Boards.BulletinMatchesZone(bulletin, zoneKey, zoneName, innNpcID, factions)
    if not bulletin then return false end
    if innNpcID and bulletin.innNpcID and bulletin.innNpcID ~= innNpcID then
        return false
    end
    if bulletin.factionNet and factions and factions[bulletin.factionNet] then
        return true
    end
    -- Built once per call, not once per posted zone: boards check every held
    -- notice in a row.
    local innKey = "inn:" .. (zoneKey or "")
    local zones = bulletin.postedZones
    if type(zones) ~= "table" then
        return bulletin.boardId == zoneKey or bulletin.boardId == innKey
    end
    local nameLower = zoneName and zoneName:lower()
    for i = 1, #zones do
        local z = zones[i]
        if z == zoneKey or z == zoneName or z == innKey then
            return true
        end
        if nameLower and type(z) == "string" and z:lower() == nameLower then
            return true
        end
    end
    return false
end
