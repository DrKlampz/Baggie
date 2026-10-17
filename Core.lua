-- Baggie: one bag window where you choose where items sit.
-- Core.lua holds settings, bag access, events and the slash command.
local ADDON_NAME, B = ...
B.name = ADDON_NAME
_G.Baggie = B

B.DEFAULTS = {
    enabled = true,      -- replace the default bag windows
    cols = 10,           -- cells per row
    scale = 1,
    borderMode = "quality", -- quality | custom | slots | none
    borderMinQuality = 2,   -- quality borders start at this quality (2 = uncommon)
    borderSize = 1,
    borderColor = { 1, 1, 1 },
    gap = 4,                -- space between slots
    padding = 12,           -- space between slots and the window edge
    iconInset = 2,          -- space between a slot's edge and its icon
    preset = "gold",
    followGreedUI = true,
    bgColor = { 0.05, 0.05, 0.07 },
    edgeColor = { 0.88, 0.69, 0.29 },
    titleColor = { 0.13, 0.11, 0.07 },
    slotColor = { 0.13, 0.13, 0.16 },
    counterMode = "used",   -- used | free | freeonly | none
    goldMode = "icons",     -- icons | text | gold | none
    footerSize = 11,
    junkDim = true,      -- dim grey items
    -- appearance
    bgStyle = "solid",      -- solid | dark | parchment | marble | rock | tooltip | leather | stone | linen | carbon | brushed | gradient | custom
    bgCustom = "",          -- texture path (or a SharedMedia background name) used when bgStyle is custom
    bgNoTint = false,       -- show a texture in its own colors instead of tinting it with the background color
    edgeAlpha = 0.95,       -- opacity of the window border
    titleAlpha = 1,         -- opacity of the title bar
    bankShowBags = true,    -- row of bank bag slots under the bank items
    bankSections = false,   -- each bank bag starts on its own row
    bankCompact = true,
    syncAll = true,         -- the bank and guild bank windows follow the Inventory look
    bankCols = 14,          -- slots per row in the Baggie bank and guild bank windows
    bankReplace = true,     -- use Baggie's bank window instead of the game's
    guildBankReplace = true,
    edgeStyle = "line",     -- line | tooltip | none
    edgeSize = 1,           -- thickness of the line border
    flair = "none",         -- none | gilded | royal: optional extra trim
    pulse = false,
    showTitleBar = true,
    titleMode = "name",     -- name | char | bags | none
    titleSize = 15,
    titleFont = "morpheus", -- morpheus | frizqt | arial | skurri
    font = "frizqt",        -- font for counts, item level and the bottom line
    slotStyle = "filled",   -- filled | gradient | texture | game | none
    slotAlpha = 1,
    slotColor2 = { 0.22, 0.22, 0.28 }, -- second color of the gradient style
    slotTexture = "leather",           -- tile used by the texture style
    slotEmptyAlpha = 1,                -- empty slots are drawn at this share of the opacity
    slotQualityTint = false,           -- tint a filled slot with the item's quality color
    slotQualityStrength = 0.35,
    slotEdge = "none",                 -- none | line | bevel | inset
    slotEdgeColor = { 0.88, 0.69, 0.29 },
    slotEdgeAlpha = 0.6,
    slotEdgeSize = 1,
    iconCrop = false,       -- trim the icon edges
    junkAlpha = 0.55,       -- how faded grey items are
    countSize = 11,
    countPos = "BOTTOMRIGHT",
    ilvlSize = 10,
    ilvlPos = "TOPRIGHT",
    ilvlQuality = false,    -- color the item level by item quality
    pinColor = { 0.88, 0.69, 0.29 },
    pinSize = 7,
    showMinimap = true,     -- minimap button: click = bags, right-click = options
    minimapAngle = 200,
    glowQuest = true,    -- quest items glow
    glowQuestColor = { 1, 0.82, 0.1 },
    glowStarts = true,   -- items that start a quest glow
    glowStartsColor = { 1, 0.95, 0.4 },
    glowMisc = false,    -- things the game files as quest items but that are really currencies (Blood Shard and the like)
    glowMiscColor = { 0.4, 0.8, 1 },
    glowQuality = false, -- glow items of high quality
    glowMinQuality = 4,  -- ... from this quality up (4 = epic)
    glowNew = false,     -- items that just arrived glow until you point at them
    glowStrength = 0.8,  -- how bright the glows are
    point = nil,         -- saved window position
    keyring = false,
    showReagent = true,  -- reagent bag as its own section (if the game has one)
    sectionLabels = true,
    showBags = true,     -- row of your equipped bag slots under the items
    layout = "real",     -- "real" = bag order, nothing moves; "gaps" = new items fill the top-most gap; "compact" = items first
    alpha = 0.96,        -- window background opacity
    cellSize = 37,
    ilvl = false,        -- item level on gear
    showSearch = true,
    showFooter = true,
    fillFront = true,    -- a new item goes to the first free slot (nothing else moves)
    showSort = true,     -- Sort button: only sorts when you click it
    showPinMark = true,
    ghostAlpha = 0.35,
    lockPos = false,
    autoOpen = true,     -- open at vendor / mailbox / auction house / bank
    sellButton = true,   -- "Sell junk" button while a vendor is open
    autoSell = false,    -- sell grey items automatically on vendor open
    sharedPins = false,  -- one set of saved spots for all characters
}

local function Merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            Merge(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

----------------------------------------------------------------------
-- Per-window settings: the bank and the guild bank can have their own look (Options tabs).
-- B.db.scopes.bank / .guild hold their own values. The look keys follow the Inventory unless
-- "sync all" is off; the layout keys (slot size, spacing, padding, slots per row) are always their own.
----------------------------------------------------------------------
B.LOOK = {}
for k in ("bgColor alpha edgeColor titleColor slotColor slotColor2 slotTexture slotEmptyAlpha slotQualityTint slotQualityStrength slotEdge slotEdgeColor slotEdgeAlpha slotEdgeSize bgStyle bgCustom bgNoTint edgeAlpha titleAlpha edgeStyle edgeSize flair pulse showTitleBar " ..
    "titleSize titleFont font slotStyle slotAlpha iconCrop iconInset junkAlpha countSize countPos ilvlSize ilvlPos ilvlQuality " ..
    "borderMode borderColor borderSize borderMinQuality glowQuest glowQuestColor glowStarts glowStartsColor glowMisc glowMiscColor glowQuality glowMinQuality glowStrength junkDim ilvl " ..
    "showFooter counterMode goldMode footerSize"):gmatch("%S+") do B.LOOK[k] = true end
B.LAYOUT = { cellSize = true, gap = true, padding = true, bankCols = true }

local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = DeepCopy(x) end
    return t
end

-- stage 1 (always): own layout values. stage 2 (when the look stops following the Inventory): a copy of the look
function B.EnsureScope(name, withLook)
    local db = B.db
    db.scopes = db.scopes or {}
    local sc = db.scopes[name]
    if not sc then sc = {} db.scopes[name] = sc end
    if not sc.layoutInit then
        sc.cellSize = tonumber(db.cellSize) or 37
        sc.gap = math.max(tonumber(db.gap) or 4, 6)
        sc.padding = tonumber(db.padding) or 12
        sc.bankCols = tonumber(db.bankCols) or 14
        sc.layoutInit = true
    end
    if withLook and not sc.lookInit then
        for k in pairs(B.LOOK) do
            local v = db[k]
            if v == nil then v = B.DEFAULTS[k] end
            sc[k] = DeepCopy(v)
        end
        sc.lookInit = true
    end
    return sc
end

-- run fn with B.db reading the settings of one window ("bank" or "guild"); anything else runs as the Inventory
function B.Scoped(scope, fn, ...)
    local real = B.db
    if not scope or not real then return fn(...) end
    local sc = B.EnsureScope(scope, real.syncAll == false)
    local sync = real.syncAll ~= false
    B.db = setmetatable({}, {
        __index = function(_, k)
            local v = sc[k]
            if v ~= nil and (B.LAYOUT[k] or (B.LOOK[k] and not sync)) then return v end
            return real[k]
        end,
        __newindex = function(_, k, v) real[k] = v end,
    })
    local ok, a, b = pcall(fn, ...)
    B.db = real
    if not ok then error(a, 0) end
    return a, b
end

function B.Print(msg) print("|cffe0b04aBaggie:|r " .. tostring(msg)) end

local reported = {}
function B.Safe(what, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok and not reported[what] then
            reported[what] = true
            B.Print("error in " .. what .. ": " .. tostring(err))
        end
    end
end

----------------------------------------------------------------------
-- Bag access that works with both the old and the C_Container API
----------------------------------------------------------------------
local C = _G.C_Container

function B.NumSlots(bag)
    local n
    if C and C.GetContainerNumSlots then n = C.GetContainerNumSlots(bag)
    elseif _G.GetContainerNumSlots then n = _G.GetContainerNumSlots(bag) end
    n = tonumber(n) or 0
    if n == 0 and bag == (_G.KEYRING_CONTAINER or -2) and _G.GetKeyRingSize then
        n = tonumber(_G.GetKeyRingSize()) or 0
    end
    return n
end

local function ItemID(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end
B.ItemID = ItemID

-- texture, count, locked, quality, link, itemID
-- The game files some ordinary items (a currency like Blood Shard) under the quest item class. Those should not
-- glow like real quest items: an item counts when no vendor buys it, or when a quest in your log asks for it.
local questNeeds, questNeedsAt = {}, -1
local function RefreshQuestNeeds()
    local now = _G.GetTime and _G.GetTime() or 0
    if now - questNeedsAt < 1 then return end
    questNeedsAt = now
    wipe(questNeeds)
    local GetN = _G.GetNumQuestLogEntries
    local Lead, NumObj = _G.GetQuestLogLeaderBoard, _G.GetNumQuestLeaderBoards
    if not (GetN and Lead and NumObj) then return end
    local okN, n = pcall(GetN)
    if not okN then return end
    for q = 1, tonumber(n) or 0 do
        local okC, cnt = pcall(NumObj, q)
        for o = 1, okC and tonumber(cnt) or 0 do
            local ok, text, kind = pcall(Lead, o, q)
            if ok and type(text) == "string" and (kind == nil or kind == "item") then
                questNeeds[#questNeeds + 1] = text:lower()
            end
        end
    end
end
function B.QuestItemOK(id)
    if not id then return true end
    local sell, name
    if _G.C_Item and _G.C_Item.GetItemInfo then
        local ok, nm, _, _, _, _, _, _, _, _, _, price = pcall(_G.C_Item.GetItemInfo, id)
        if ok then name, sell = nm, price end
    elseif _G.GetItemInfo then
        local nm, _, _, _, _, _, _, _, _, _, price = _G.GetItemInfo(id)
        name, sell = nm, price
    end
    if not name then return true end            -- not loaded yet: keep the glow for now
    if (tonumber(sell) or 0) == 0 then return true end
    RefreshQuestNeeds()
    local low = name:lower()
    for _, t in ipairs(questNeeds) do
        if t:find(low, 1, true) then return true end
    end
    return false
end

-- the glow color for a kind ("quest", "starts", "misc"), or nil when that kind is switched off
function B.KindColor(kind)
    local db = B.db
    if not (db and kind) then return end
    local key = kind == "quest" and "glowQuest" or kind == "starts" and "glowStarts" or kind == "misc" and "glowMisc"
    if not key or not db[key] then return end
    local c = db[key .. "Color"] or B.DEFAULTS and B.DEFAULTS[key .. "Color"]
    if type(c) ~= "table" then c = { 1, 0.82, 0.1 } end
    return c[1], c[2], c[3]
end

function B.SlotInfo(bag, slot)
    if C and C.GetContainerItemInfo then
        local i = C.GetContainerItemInfo(bag, slot)
        if type(i) == "table" then
            return i.iconFileID, i.stackCount, i.isLocked, i.quality, i.hyperlink, i.itemID or ItemID(i.hyperlink)
        end
        return nil
    end
    if _G.GetContainerItemInfo then
        local tex, count, locked, quality, _, _, link, _, _, id = _G.GetContainerItemInfo(bag, slot)
        if tex then return tex, count, locked, quality, link, id or ItemID(link) end
    end
end

function B.Pickup(bag, slot)
    if C and C.PickupContainerItem then return C.PickupContainerItem(bag, slot) end
    return _G.PickupContainerItem(bag, slot)
end

function B.Cooldown(bag, slot)
    if C and C.GetContainerItemCooldown then return C.GetContainerItemCooldown(bag, slot) end
    if _G.GetContainerItemCooldown then return _G.GetContainerItemCooldown(bag, slot) end
end

-- the main bags: backpack plus the four bag slots (saved spots live here)
function B.BagIDs()
    local ids = { 0 }
    local last = tonumber(_G.NUM_BAG_SLOTS) or 4
    for b = 1, last do ids[#ids + 1] = b end
    return ids
end

----------------------------------------------------------------------
-- Sort (only ever runs when you click the Sort button)
----------------------------------------------------------------------
-- cur[i] = { key = identity of item+stack, sk = sort key, id = item id } or false for an empty slot,
-- or { skip = true } for a slot that must not be touched (quiver and other special bags).
-- fixed[itemID] = position that item is saved to: those items are placed exactly there.
-- Returns the list of {from, to} moves: saved items in their spots, everything else packed
-- to the front in sort order, so the empty space ends up at the back.
function B.PlanSort(cur, fixed)
    local n = #cur
    local arr, avail, items = {}, {}, {}
    for i = 1, n do
        local v = cur[i]
        arr[i] = v
        if not (v and v.skip) then
            avail[#avail + 1] = i
            if v then items[#items + 1] = v end
        end
    end
    local isAvail = {}
    for _, i in ipairs(avail) do isAvail[i] = true end
    local tgt, used = {}, {}
    local pinList = {}
    for id, cell in pairs(fixed or {}) do
        if type(cell) == "table" then for _, x in ipairs(cell) do pinList[#pinList + 1] = { id = id, cell = x } end
        else pinList[#pinList + 1] = { id = id, cell = cell } end
    end
    table.sort(pinList, function(x, y) if x.cell ~= y.cell then return x.cell < y.cell end return tostring(x.id) < tostring(y.id) end)
    for _, p in ipairs(pinList) do
        if isAvail[p.cell] and not tgt[p.cell] then
            for k, v in ipairs(items) do
                if not used[k] and v.id == p.id then tgt[p.cell] = v used[k] = true break end
            end
        end
    end
    local rest = {}
    for k, v in ipairs(items) do if not used[k] then rest[#rest + 1] = v end end
    table.sort(rest, function(x, y)
        if x.sk ~= y.sk then return x.sk < y.sk end
        return x.key < y.key
    end)
    local r = 1
    for _, i in ipairs(avail) do
        if not tgt[i] then tgt[i] = rest[r] or false r = r + 1 end
    end
    local moves = {}
    for ai, i in ipairs(avail) do
        local want, have = tgt[i], arr[i]
        local same = (want and have and want.key == have.key) or (not want and not have)
        if not same then
            local j
            for aj = ai + 1, #avail do
                local k = avail[aj]
                local c = arr[k]
                if (want and c and c.key == want.key) or (not want and not c) then j = k break end
            end
            if not j then break end
            moves[#moves + 1] = { j, i }
            arr[i], arr[j] = arr[j], arr[i]
        end
    end
    return moves
end

local sorting = false
function B.Say(msg)   -- chat line plus a message in the middle of the screen
    B.Print(msg)
    if _G.UIErrorsFrame and _G.UIErrorsFrame.AddMessage then _G.UIErrorsFrame:AddMessage("Baggie: " .. tostring(msg), 1, 0.85, 0.2) end
end

-- what a bag can hold. Family numbers are the game's: 4 soul shards, 8 leather, 32 herbs, 64 enchanting,
-- 128 engineering, 512 gems, 1024 mining, 1 arrows, 2 bullets.
local FAMILY_BY_SUB = { [1] = 4, [2] = 32, [3] = 64, [4] = 128, [5] = 512, [6] = 1024, [7] = 8, [8] = 16 }
local SPECIAL_NAMES = { "herb", "mining", "enchant", "engineer", "gem", "jewel", "soul", "quiver", "ammo", "leatherworking" }
B.badBags = {}   -- bags that refused an item during a sort (learned, until you log out)

local function BagLink(bag)
    local inv
    local nb = tonumber(_G.NUM_BAG_SLOTS) or 4
    if bag > nb and _G.BankButtonIDToInvSlotID then inv = _G.BankButtonIDToInvSlotID(bag - nb, 1) end
    inv = inv or (B.BagInvID and B.BagInvID(bag))
    return inv and _G.GetInventoryItemLink and _G.GetInventoryItemLink("player", inv)
end

function B.ItemFamily(link)
    if not link then return 0 end
    local f = (_G.C_Item and _G.C_Item.GetItemFamily and _G.C_Item.GetItemFamily(link)) or (_G.GetItemFamily and _G.GetItemFamily(link))
    return tonumber(f) or 0
end

-- 0 for an ordinary bag, otherwise the kind of item it is limited to
function B.BagFamily(bag)
    if bag <= 0 then return 0 end
    local gf = (C and C.GetContainerNumFreeSlots) or _G.GetContainerNumFreeSlots
    if gf then
        local ok, _, kind = pcall(gf, bag)
        if ok and tonumber(kind) and kind ~= 0 then return kind end
    end
    local link = BagLink(bag)
    if link and _G.C_Item and _G.C_Item.GetItemInfoInstant then
        local ok, _, _, _, _, _, classID, subID = pcall(_G.C_Item.GetItemInfoInstant, link)
        if ok and classID == 1 then return FAMILY_BY_SUB[tonumber(subID) or 0] or 0 end
        if ok and classID == 11 then return (subID == 3) and 2 or 1 end
    end
    return 0
end

-- true for ordinary bags (and the bank itself); false for quivers, herb bags, soul bags and other special bags
function B.IsGeneralBag(bag)
    if bag <= 0 then return true end
    local link = BagLink(bag)
    if B.badBags[link and tostring(link) or ("bag" .. bag)] then return false end
    if B.BagFamily(bag) ~= 0 then return false end
    if link then
        if _G.C_Item and _G.C_Item.GetItemInfoInstant then
            local ok, _, _, _, _, _, classID, subID = pcall(_G.C_Item.GetItemInfoInstant, link)
            if ok and classID then
                if classID ~= 1 then return false end
                if (tonumber(subID) or 0) ~= 0 then return false end
            end
        end
        local name = (_G.C_Item and _G.C_Item.GetItemInfo and _G.C_Item.GetItemInfo(link)) or (_G.GetItemInfo and _G.GetItemInfo(link))
        if type(name) == "string" then
            name = name:lower()
            for _, w in ipairs(SPECIAL_NAMES) do if name:find(w, 1, true) then return false end end
        end
    end
    return true
end

function B.RememberBadBag(bag)
    local link = BagLink(bag)
    B.badBags[link and tostring(link) or ("bag" .. bag)] = true
end

-- Right-click an item in your bags while the bank is open: if it belongs in one of your special bank bags
-- (herbs in an herb bag and so on) it goes there first, merging with a stack that is already there.
-- Returns true when it moved the item.
function B.SmartBankStore(bag, slot)
    local ui = B.BankUI
    if not (ui and ui.IsOpen and ui.IsOpen()) then return false end
    if _G.CursorHasItem and _G.CursorHasItem() then return false end
    local _, count, locked, _, link, id = B.SlotInfo(bag, slot)
    if not link or locked then return false end
    local fam = B.ItemFamily(link)
    if fam == 0 or not _G.bit then return false end
    local first = (tonumber(_G.NUM_BAG_SLOTS) or 4) + 1
    local last = (tonumber(_G.NUM_BAG_SLOTS) or 4) + (tonumber(_G.NUM_BANKBAGSLOTS) or 7)
    local maxStack = 1
    local gi = (_G.C_Item and _G.C_Item.GetItemInfo) or _G.GetItemInfo
    if gi then
        local _, _, _, _, _, _, _, ms = gi(link)
        maxStack = tonumber(ms) or 1
    end
    for b = first, last do
        local bf = B.BagFamily(b)
        if bf ~= 0 and _G.bit.band(fam, bf) ~= 0 then
            local num = B.NumSlots(b)
            local freeSlot
            for sl = 1, num do
                local _, c2, _, _, l2, id2 = B.SlotInfo(b, sl)
                if not l2 then
                    freeSlot = freeSlot or sl
                elseif id2 == id and (tonumber(c2) or 1) + (tonumber(count) or 1) <= maxStack then
                    B.Pickup(bag, slot) B.Pickup(b, sl)
                    return true
                end
            end
            if freeSlot then
                B.Pickup(bag, slot) B.Pickup(b, freeSlot)
                return true
            end
        end
    end
    return false
end

-- Moving things from your bags into the bank ------------------------------------------------------------
-- a bank slot that can take this item: a stack of it with room first, else the first free slot
function B.BankTarget(link, id, count)
    local ui = B.BankUI
    if not (ui and ui.BagIDs) then return end
    local maxStack = 1
    local gi = (_G.C_Item and _G.C_Item.GetItemInfo) or _G.GetItemInfo
    if gi then
        local _, _, _, _, _, _, _, ms = gi(link)
        maxStack = tonumber(ms) or 1
    end
    local fam = B.ItemFamily(link)
    local freeB, freeS
    for _, b in ipairs(ui.BagIDs()) do
        local bf = (b > 0) and B.BagFamily(b) or 0
        if bf == 0 or (fam ~= 0 and _G.bit and _G.bit.band(fam, bf) ~= 0) then
            for sl = 1, B.NumSlots(b) do
                local _, c2, _, _, l2, id2 = B.SlotInfo(b, sl)
                if not l2 then
                    if not freeB then freeB, freeS = b, sl end
                elseif id2 == id and (tonumber(c2) or 1) + (tonumber(count) or 1) <= maxStack then
                    return b, sl
                end
            end
        end
    end
    return freeB, freeS
end

-- the bags you carry: backpack, bag slots and the reagent bag
function B.CarriedBagIDs()
    local ids = { 0 }
    for b = 1, tonumber(_G.NUM_BAG_SLOTS) or 4 do ids[#ids + 1] = b end
    local rb = _G.Enum and _G.Enum.BagIndex and _G.Enum.BagIndex.ReagentBag
    if rb and B.NumSlots(rb) > 0 then ids[#ids + 1] = rb end
    return ids
end

local depositQueue, depositRunning, depositMoved = {}, false, 0
local function DepositStep()
    local job = table.remove(depositQueue, 1)
    if not job then
        depositRunning = false
        if depositMoved > 0 then B.Say(("moved %d stack%s to the bank"):format(depositMoved, depositMoved == 1 and "" or "s")) end
        depositMoved = 0
        return
    end
    local ui = B.BankUI
    if not (ui and ui.IsOpen and ui.IsOpen()) then depositQueue, depositRunning, depositMoved = {}, false, 0 return end
    if _G.CursorHasItem and _G.CursorHasItem() then _G.ClearCursor() end
    local _, count, locked, _, link, id = B.SlotInfo(job.bag, job.slot)
    if link and not locked and id == job.id then
        local tb, ts = B.BankTarget(link, id, count)
        if not tb then
            B.Say("the bank is full")
            depositQueue, depositRunning = {}, false
            return
        end
        B.Pickup(job.bag, job.slot)
        B.Pickup(tb, ts)
        if _G.CursorHasItem and _G.CursorHasItem() then _G.ClearCursor() else depositMoved = depositMoved + 1 end
    end
    _G.C_Timer.After(0.2, DepositStep)
end
local function StartDeposit(jobs)
    if #jobs == 0 then return 0 end
    for _, j in ipairs(jobs) do depositQueue[#depositQueue + 1] = j end
    if not depositRunning then depositRunning = true DepositStep() end
    return #jobs
end

-- one stack (or every stack of that item) from your bags into the bank
function B.BankDeposit(bag, slot, allStacks)
    local ui = B.BankUI
    if not (ui and ui.IsOpen and ui.IsOpen()) then return 0 end
    local _, _, _, _, link, id = B.SlotInfo(bag, slot)
    if not link then return 0 end
    local jobs = {}
    if allStacks then
        for _, b in ipairs(B.CarriedBagIDs()) do
            for sl = 1, B.NumSlots(b) do
                local _, _, _, _, l2, id2 = B.SlotInfo(b, sl)
                if l2 and id2 == id then jobs[#jobs + 1] = { bag = b, slot = sl, id = id2 } end
            end
        end
    else
        jobs[1] = { bag = bag, slot = slot, id = id }
    end
    return StartDeposit(jobs)
end

-- every stack in your bags that test(itemID, classID, subclassID, quality) accepts; items with a saved spot stay put
function B.BankDepositWhere(test)
    local ui = B.BankUI
    if not (ui and ui.IsOpen and ui.IsOpen()) then B.Print("open the bank first") return 0 end
    local pins = B.Pins()
    local jobs = {}
    for _, b in ipairs(B.CarriedBagIDs()) do
        for sl = 1, B.NumSlots(b) do
            local _, _, locked, q, link, id = B.SlotInfo(b, sl)
            if link and id and not locked and not pins[id] then
                local cls, sub = 0, 0
                if _G.C_Item and _G.C_Item.GetItemInfoInstant then
                    local ok, _, _, _, _, _, c1, s1 = pcall(_G.C_Item.GetItemInfoInstant, id)
                    if ok then cls, sub = c1 or 0, s1 or 0 end
                end
                if test(id, cls, sub, q) then jobs[#jobs + 1] = { bag = b, slot = sl, id = id } end
            end
        end
    end
    local n = StartDeposit(jobs)
    if n == 0 then B.Print("nothing in your bags matches") end
    return n
end

-- sort entry for one item (see PlanSort)
function B.SortEntry(link, id, count, quality)
    local gi = (_G.C_Item and _G.C_Item.GetItemInfo) or _G.GetItemInfo
    local okI, name, _, q, _, _, typ, sub = pcall(gi or function() end, link)
    if not okI then name, q, typ, sub = nil end
    if not name then name = tostring(link):match("%[(.-)%]") end
    if not typ and _G.C_Item and _G.C_Item.GetItemInfoInstant then
        local okJ, _, t2, s2 = pcall(_G.C_Item.GetItemInfoInstant, link)
        if okJ then typ, sub = t2, s2 end
    end
    q = tonumber(q or quality) or 1
    return { id = id, key = (tostring(link):match("item:[^|]+") or tostring(id)) .. "x" .. string.format("%05d", tonumber(count) or 1),
        sk = string.format("%s|%s|%d|%s", tostring(typ or "~"), tostring(sub or ""), 9 - q, tostring(name or "")) }
end

-- opt (all optional): ids = bag ids to sort (default: your bags); noPins = ignore saved spots;
-- cells/cur = ready-made cell list and entries (used for the guild bank); locked(cell), pickup(cell), delay, refresh
function B.SortBags(opt)
    opt = type(opt) == "table" and opt or {}
    if sorting then B.Say("already sorting") return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then B.Say("can't sort in combat") return end
    if _G.GetCursorInfo and _G.GetCursorInfo() then B.Say("put down what you're holding first") return end
    local blocked = {}
    local Run
    Run = function(attempt)
        local cells, cur = opt.cells, opt.cur
        if not cells then
            cells, cur = {}, {}
            for _, bag in ipairs(opt.ids or B.BagIDs()) do
                local general = (not blocked[bag]) and B.IsGeneralBag(bag)
                for sl = 1, B.NumSlots(bag) do
                    cells[#cells + 1] = { bag, sl }                    -- same numbering as the window's cells
                    local _, count, _, quality, link, id = B.SlotInfo(bag, sl)
                    if not general then
                        cur[#cur + 1] = { skip = true }
                    elseif link then
                        cur[#cur + 1] = B.SortEntry(link, id, count, quality)
                    else
                        cur[#cur + 1] = false
                    end
                end
            end
        end
        -- items you saved to a spot stay in that spot; everything else is packed around them
        local fixed = {}
        if not opt.noPins then
            for id, p in pairs(opt.pins or B.Pins()) do
                local cs = B.Layout.CellsOf(p)
                if #cs > 0 then fixed[id] = cs end
            end
        end
        local moves = B.PlanSort(cur, fixed)
        if #moves == 0 then
            if attempt == 1 then B.Say("already sorted (" .. #cells .. " slots checked)") end
            return
        end
        if attempt == 1 then B.Say("sorting: " .. #moves .. " moves") end
        sorting = true
        local aborted, lastMove = false, nil
        local errF = _G.CreateFrame("Frame")
        errF:RegisterEvent("UI_ERROR_MESSAGE")
        errF:SetScript("OnEvent", function(_, _, a, b)
            local msg = type(b) == "string" and b or a
            if type(msg) ~= "string" then return end
            local wrong = _G.ERR_WRONG_BAG_TYPE or "That item doesn't go in that container."
            local wrong2 = _G.ERR_WRONG_BAG_TYPE2
            if msg == wrong or (wrong2 and msg == wrong2) or msg:find("go in that container", 1, true) then aborted = true end
        end)
        local function finish() errF:UnregisterAllEvents() errF:SetScript("OnEvent", nil) end
        local n, waits = 0, 0
        local step
        local lockedFn = opt.locked or function(c) local _, _, l = B.SlotInfo(c[1], c[2]) return l end
        local pickupFn = opt.pickup or function(c) B.Pickup(c[1], c[2]) end
        local function stepRaw()
            if _G.InCombatLockdown and _G.InCombatLockdown() then sorting = false finish() return end
            if aborted then
                sorting = false finish()
                if _G.ClearCursor then _G.ClearCursor() end
                -- the game refused a move: some bag only takes certain items. Leave that bag alone and plan again.
                local last = lastMove
                if last and not opt.cells and attempt < 8 then
                    local ba, bb = last[1][1], last[2][1]
                    local tex = B.SlotInfo(bb, last[2][2])
                    if ba ~= bb then
                        blocked[bb] = true
                        if tex then blocked[ba] = true end
                    else
                        blocked[bb] = true
                    end
                    return _G.C_Timer.After(0.3, function() Run(attempt + 1) end)
                end
                return
            end
            n = n + 1
            local m = moves[n]
            if not m then
                sorting = false finish()
                if opt.refresh then opt.refresh() elseif B.Frame and B.Frame.Refresh then B.Frame.Refresh() end
                return
            end
            local a, b = cells[m[1]], cells[m[2]]
            if lockedFn(a) or lockedFn(b) or (_G.GetCursorInfo and _G.GetCursorInfo()) then
                waits = waits + 1
                if waits > 40 then sorting = false finish() B.Say("sort stopped (items stayed locked)") return end
                n = n - 1
                return _G.C_Timer.After(0.1, step)
            end
            waits = 0
            lastMove = { a, b }
            pickupFn(a)
            pickupFn(b)
            if _G.GetCursorInfo and _G.GetCursorInfo() then pickupFn(a) end
            _G.C_Timer.After(opt.delay or 0.12, step)
        end
        step = function()
            local ok, err = pcall(stepRaw)
            if not ok then sorting = false finish() B.Say("sort error: " .. tostring(err)) end
        end
        step()
    end
    Run(1)
end

-- inventory slot number of an equipped bag (the game moved this function into C_Container)
function B.BagInvID(bag)
    local f = (C and C.ContainerIDToInventoryID) or _G.ContainerIDToInventoryID
    local id = f and f(bag)
    if tonumber(id) then return id end
    return 19 + bag
end

function B.ReagentBagID()
    local e = _G.Enum and _G.Enum.BagIndex
    if e and e.ReagentBag then return e.ReagentBag end
    if tonumber(_G.NUM_REAGENTBAG_SLOTS) and _G.NUM_REAGENTBAG_SLOTS > 0 then
        return (tonumber(_G.NUM_BAG_SLOTS) or 4) + 1
    end
end

-- the reagent bag and the keyring are shown as their own sections under the main bags
function B.ExtraSections()
    local out = {}
    if not B.db then return out end
    local r = B.ReagentBagID()
    if B.db.showReagent and r and B.NumSlots(r) > 0 then
        out[#out + 1] = { key = "reagent", title = "Reagent bag", bags = { r } }
    end
    local K = _G.KEYRING_CONTAINER or -2
    if B.db.keyring and B.NumSlots(K) > 0 then
        out[#out + 1] = { key = "keyring", title = "Keyring", bags = { K } }
    end
    return out
end

-- The real slots in bag order, as the layout engine wants them.
function B.ScanSlots()
    local slots = {}
    for _, bag in ipairs(B.BagIDs()) do
        for s = 1, B.NumSlots(bag) do
            local _, _, _, _, link, id = B.SlotInfo(bag, s)
            slots[#slots + 1] = { bag = bag, slot = s, itemID = id, link = link }
        end
    end
    return slots
end

----------------------------------------------------------------------
-- Saved spots (per character)
----------------------------------------------------------------------
function B.CharKey()
    local name = _G.UnitName and _G.UnitName("player") or "?"
    local realm = _G.GetRealmName and _G.GetRealmName() or "?"
    return name .. "-" .. realm
end

function B.Pins()
    if not B.db then return {} end
    if B.db.sharedPins then
        B.db.shared = B.db.shared or { pins = {} }
        B.db.shared.pins = B.db.shared.pins or {}
        return B.db.shared.pins
    end
    B.db.chars = B.db.chars or {}
    local key = B.CharKey()
    B.db.chars[key] = B.db.chars[key] or { pins = {} }
    B.db.chars[key].pins = B.db.chars[key].pins or {}
    return B.db.chars[key].pins
end

-- the bank window has its own saved spots (cells count from the top left of the bank window)
function B.BankPins()
    if not B.db then return {} end
    if B.db.sharedPins then
        B.db.shared = B.db.shared or { pins = {} }
        B.db.shared.bankPins = B.db.shared.bankPins or {}
        return B.db.shared.bankPins
    end
    B.db.chars = B.db.chars or {}
    local key = B.CharKey()
    B.db.chars[key] = B.db.chars[key] or { pins = {} }
    B.db.chars[key].bankPins = B.db.chars[key].bankPins or {}
    return B.db.chars[key].bankPins
end

function B.SetPin(itemID, cell, icon, name)
    local pins = B.Pins()
    B.Layout.Place(pins, itemID, cell)
    if icon then pins[itemID].icon = icon end
    if name then pins[itemID].name = name end
end

function B.ClearPin(itemID)
    B.Pins()[itemID] = nil
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------
local ev = CreateFrame("Frame")
B.events = ev
local handlers = {}
function B.On(event, fn) handlers[event] = fn ev:RegisterEvent(event) end

B.On("ADDON_LOADED", B.Safe("load", function(name)
    if name ~= ADDON_NAME then return end
    BaggieDB = BaggieDB or {}
    B.db = Merge(BaggieDB, B.DEFAULTS)
    if B.db.borders == false then B.db.borderMode = "none" end   -- older versions
    B.db.borders = nil
    B.EnsureScope("bank") B.EnsureScope("guild")
    if not B.db.bankFlow1 then B.db.bankFlow1 = true B.db.bankSections = false end   -- bank slots now run in one continuous grid
    if not B.db.freeRein2 then   -- v0.3.0: plain bag order, nothing moves by itself; Sort only on click
        B.db.freeRein2 = true
        B.db.showSort = true
        B.db.layout = "real"
    end
    if B.Frame and B.Frame.Setup then B.Frame.Setup() end
end))

ev:SetScript("OnEvent", function(_, event, ...)
    local h = handlers[event]
    if h then h(...) end
end)

----------------------------------------------------------------------
-- Slash command
----------------------------------------------------------------------
SLASH_BAGGIE1 = "/baggie"
SlashCmdList["BAGGIE"] = B.Safe("slash", function(msg)
    msg = (msg or ""):lower()
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    local function refresh() if B.Frame and B.Frame.Refresh then B.Frame.Refresh() end end
    if cmd == "" or cmd == "toggle" then
        B.Frame.Toggle()
    elseif cmd == "cols" then
        local n = tonumber(rest)
        if n and n >= 4 and n <= 24 then B.db.cols = math.floor(n) refresh() B.Print("columns: " .. B.db.cols)
        else B.Print("usage: /baggie cols 4-24 (now " .. B.db.cols .. ")") end
    elseif cmd == "scale" then
        local n = tonumber(rest)
        if n and n >= 0.6 and n <= 1.6 then B.db.scale = n B.Frame.ApplyScale() B.Print("scale: " .. n)
        else B.Print("usage: /baggie scale 0.6-1.6 (now " .. B.db.scale .. ")") end
    elseif cmd == "borders" then
        B.db.borderMode = (B.db.borderMode == "none") and "quality" or "none" refresh()
        B.Print("item borders: " .. B.db.borderMode)
    elseif cmd == "options" or cmd == "config" or cmd == "opt" then
        B.Options.Toggle()
    elseif cmd == "minimap" then
        B.db.showMinimap = not (B.db.showMinimap ~= false)
        if B.Minimap then B.Minimap.Update() end
        B.Print("minimap button " .. (B.db.showMinimap and "shown" or "hidden"))
    elseif cmd == "layout" then
        if rest == "compact" or rest == "real" or rest == "gaps" then B.db.layout = rest refresh() B.Print("layout: " .. rest)
        else B.Print("usage: /baggie layout real | gaps | compact (now " .. B.db.layout .. ")") end
    elseif cmd == "keyring" then
        B.db.keyring = not B.db.keyring refresh() B.Print("keyring " .. (B.db.keyring and "shown" or "hidden"))
        if B.db.keyring and B.NumSlots(_G.KEYRING_CONTAINER or -2) == 0 then B.Print("this character has no keyring slots to show") end
    elseif cmd == "unpin" and rest == "all" then
        for k in pairs(B.Pins()) do B.Pins()[k] = nil end
        for k in pairs(B.BankPins()) do B.BankPins()[k] = nil end
        refresh() B.Print("all saved spots cleared")
    elseif cmd == "pins" or cmd == "list" then
        local n = 0
        for id, p in pairs(B.Pins()) do
            n = n + 1
            B.Print(("cell %s: %s (%d)"):format(table.concat(B.Layout.CellsOf(p), ", "), p.name or "item", id))
        end
        if n == 0 then B.Print("no saved spots yet. Alt+click an item to save its spot.") end
    elseif cmd == "debug" then
        B.Frame.Debug()
    elseif cmd == "default" then
        B.db.enabled = not B.db.enabled B.Frame.ApplyOverrides()
        B.Print(B.db.enabled and "Baggie bags on" or "default bags back (applies fully after /reload)")
    elseif cmd == "reset" then
        B.db.point = nil B.Frame.ResetPosition() B.Print("window position reset")
    else
        B.Print("/baggie  open or close your bags")
        B.Print("Alt+click an item to save it to the spot it is in. Alt+click it again to free the spot.")
                B.Print("/baggie debug (prints what Baggie sees, for bug reports)")
        B.Print("/baggie options  (all settings in a window; also right-click the minimap button)")
        B.Print("/baggie layout real | gaps | compact   (real = bag order, nothing moves on its own; gaps = same, but new items land in the top-most empty cell)")
        B.Print("/baggie pins | unpin all | cols N | scale N | borders | keyring | default | reset")
    end
end)

----------------------------------------------------------------------
-- New loot goes to the first free slot (like a bag with no gaps at the front).
-- Only the item that just arrived is moved; nothing else is ever touched.
----------------------------------------------------------------------
function B.FirstFreeCell(cells)   -- cells: list of {bag, slot, filled}
    for i, c in ipairs(cells) do if not c[3] then return i end end
end

do
    local lastUser, prev, busy = 0, nil, false
    local function Touch() lastUser = (_G.GetTime and _G.GetTime()) or 0 end
    for _, n in ipairs({ "PickupContainerItem", "SplitContainerItem", "UseContainerItem" }) do
        if C and C[n] then hooksecurefunc(C, n, Touch) end
        if _G[n] then hooksecurefunc(n, Touch) end
    end

    local function Scan()
        local cells = {}
        local gf = (C and C.GetContainerNumFreeSlots) or _G.GetContainerNumFreeSlots
        for _, bag in ipairs(B.BagIDs()) do
            local ok = true
            if gf and bag > 0 then local _, kind = gf(bag) if kind and kind ~= 0 then ok = false end end
            if ok then
                for sl = 1, B.NumSlots(bag) do
                    local _, _, _, _, link = B.SlotInfo(bag, sl)
                    cells[#cells + 1] = { bag, sl, link ~= nil, link }
                end
            end
        end
        return cells
    end

    local function Snapshot(cells)
        local s, n = {}, 0
        for _, c in ipairs(cells) do
            if c[3] then s[c[1] .. ":" .. c[2]] = true n = n + 1 end
        end
        return s, n
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("BAG_UPDATE_DELAYED")
    f:SetScript("OnEvent", B.Safe("fill front", function()
        if not B.db or busy then return end
        local cells = Scan()
        local snap, n = Snapshot(cells)
        local old, oldN = prev, prev and prev.n or 0
        prev = snap prev.n = n
        if not B.db.fillFront or not old then return end
        if n <= oldN then return end                                   -- nothing new arrived
        local now = (_G.GetTime and _G.GetTime()) or 0
        if now - lastUser < 1.5 then return end                        -- you were moving things yourself
        if (_G.GetCursorInfo and _G.GetCursorInfo()) or (_G.InCombatLockdown and _G.InCombatLockdown()) then return end
        local free = B.FirstFreeCell(cells)
        if not free then return end
        for i = #cells, free + 1, -1 do                                -- new items, last slot first
            local c = cells[i]
            local key = c[1] .. ":" .. c[2]
            if c[3] and not old[key] then
                local _, _, locked = B.SlotInfo(c[1], c[2])
                if not locked then
                    local t = cells[free]
                    busy = true
                    B.Pickup(c[1], c[2])
                    B.Pickup(t[1], t[2])
                    if _G.GetCursorInfo and _G.GetCursorInfo() then B.Pickup(c[1], c[2]) end
                    _G.C_Timer.After(0.3, function() busy = false prev = nil end)
                end
                return
            end
        end
    end))
end


----------------------------------------------------------------------
-- Slot backgrounds: one painter for the bags, bank and guild bank.
-- bgTex is the slot's background texture, btn the slot button, filled whether an item sits in it.
----------------------------------------------------------------------
local SLOT_TILES = {
    leather = "Interface\\AddOns\\Baggie\\Media\\Tex_Leather", stone = "Interface\\AddOns\\Baggie\\Media\\Tex_Stone",
    linen = "Interface\\AddOns\\Baggie\\Media\\Tex_Linen", carbon = "Interface\\AddOns\\Baggie\\Media\\Tex_Carbon",
    brushed = "Interface\\AddOns\\Baggie\\Media\\Tex_Brushed", marble = "Interface\\FrameGeneral\\UI-Background-Marble",
    rock = "Interface\\FrameGeneral\\UI-Background-Rock", parchment = "Interface\\DialogFrame\\UI-DialogBox-Background",
}
B.SLOT_TILES = SLOT_TILES
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function Shade(c, f) return math.max(0, math.min(1, c * f)) end

function B.PaintSlot(btn, bgTex, filled, quality)
    local db = B.GetLookSettings and B.GetLookSettings() or B.db
    if not (bgTex and db) then return end
    local style = db.slotStyle or "filled"
    local c = db.slotColor or B.DEFAULTS.slotColor
    local a = tonumber(db.slotAlpha) or 1
    local c2tint
    if db.slotQualityTint and filled and (tonumber(quality) or 0) >= 1 and _G.ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local q, k = ITEM_QUALITY_COLORS[quality], math.max(0, math.min(1, tonumber(db.slotQualityStrength) or 0.35))
        c = { c[1] + (q.r - c[1]) * k, c[2] + (q.g - c[2]) * k, c[3] + (q.b - c[3]) * k }
    end
    if not filled then a = a * (tonumber(db.slotEmptyAlpha) or 1) end
    if style == "none" then
        bgTex:SetTexture(WHITE) bgTex:SetVertexColor(c[1], c[2], c[3], 0)
    elseif style == "gradient" then
        local c2 = db.slotColor2 or B.DEFAULTS.slotColor2
        bgTex:SetTexture(WHITE)
        bgTex:SetVertexColor(1, 1, 1, 1)
        local done = false
        if _G.CreateColor and bgTex.SetGradient then
            done = pcall(bgTex.SetGradient, bgTex, "VERTICAL", CreateColor(c[1], c[2], c[3], a), CreateColor(c2[1], c2[2], c2[3], a))
        end
        if not done and bgTex.SetGradientAlpha then
            pcall(bgTex.SetGradientAlpha, bgTex, "VERTICAL", c[1], c[2], c[3], a, c2[1], c2[2], c2[3], a)
        end
    elseif style == "texture" then
        bgTex:SetTexture(SLOT_TILES[db.slotTexture or "leather"] or SLOT_TILES.leather)
        bgTex:SetVertexColor(c[1] * 2, c[2] * 2, c[3] * 2, a)
    elseif style == "game" then
        bgTex:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
        bgTex:SetVertexColor(1, 1, 1, a)
    else
        bgTex:SetTexture(WHITE)
        bgTex:SetVertexColor(c[1], c[2], c[3], a)
    end
    if style ~= "gradient" and style ~= "game" then bgTex:SetTexCoord(0, 1, 0, 1) end
    if style == "game" then bgTex:SetTexCoord(0.1, 0.9, 0.1, 0.9) end

    -- edge: a line, a raised bevel or a sunken inset
    local mode = db.slotEdge or "none"
    local e = btn.slotEdge
    if mode == "none" or style == "none" and mode == "inset" then
        if e then for i = 1, 4 do e[i]:Hide() end end
        return
    end
    if not e then
        e = {}
        for i = 1, 4 do
            e[i] = btn:CreateTexture(nil, "BACKGROUND", nil, 2)
            e[i]:SetTexture(WHITE)
        end
        btn.slotEdge = e
    end
    local sz = math.max(1, tonumber(db.slotEdgeSize) or 1)
    local ea = tonumber(db.slotEdgeAlpha) or 0.6
    local ec = db.slotEdgeColor or B.DEFAULTS.slotEdgeColor
    local col = {}
    if mode == "line" then
        for i = 1, 4 do col[i] = { ec[1], ec[2], ec[3], ea } end
    else
        local hi, lo = 1.9, 0.45
        if mode == "inset" then hi, lo = 0.45, 1.9 end
        local light = { Shade(c[1], hi) + 0.05, Shade(c[2], hi) + 0.05, Shade(c[3], hi) + 0.05, ea }
        local dark = { Shade(c[1], lo), Shade(c[2], lo), Shade(c[3], lo), ea }
        col[1], col[2], col[3], col[4] = light, dark, light, dark   -- top, bottom, left, right
    end
    e[1]:ClearAllPoints() e[1]:SetPoint("TOPLEFT", btn, "TOPLEFT") e[1]:SetPoint("TOPRIGHT", btn, "TOPRIGHT") e[1]:SetHeight(sz)
    e[2]:ClearAllPoints() e[2]:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT") e[2]:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT") e[2]:SetHeight(sz)
    e[3]:ClearAllPoints() e[3]:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, -sz) e[3]:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, sz) e[3]:SetWidth(sz)
    e[4]:ClearAllPoints() e[4]:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, -sz) e[4]:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, sz) e[4]:SetWidth(sz)
    for i = 1, 4 do e[i]:SetVertexColor(col[i][1], col[i][2], col[i][3], col[i][4]) e[i]:Show() end
end
