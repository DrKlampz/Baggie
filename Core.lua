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
    bgColor = { 0.05, 0.05, 0.07 },
    edgeColor = { 0.88, 0.69, 0.29 },
    titleColor = { 0.13, 0.11, 0.07 },
    slotColor = { 0.13, 0.13, 0.16 },
    counterMode = "used",   -- used | free | freeonly | none
    goldMode = "icons",     -- icons | text | gold | none
    footerSize = 11,
    junkDim = true,      -- dim grey items
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
    for id, cell in pairs(fixed or {}) do pinList[#pinList + 1] = { id = id, cell = cell } end
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

function B.SortBags()
    if sorting then B.Say("already sorting") return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then B.Say("can't sort in combat") return end
    if _G.GetCursorInfo and _G.GetCursorInfo() then B.Say("put down what you're holding first") return end
    local cells, cur = {}, {}
    for _, bag in ipairs(B.BagIDs()) do
        local general = true
        local gf = (C and C.GetContainerNumFreeSlots) or _G.GetContainerNumFreeSlots
        if gf and bag > 0 then
            local _, kind = gf(bag)
            if kind and kind ~= 0 then general = false end   -- quivers, soul bags etc. keep their own rules
        end
        for sl = 1, B.NumSlots(bag) do
            cells[#cells + 1] = { bag, sl }                    -- same numbering as the window's cells
            local _, count, _, quality, link, id = B.SlotInfo(bag, sl)
            if not general then
                cur[#cur + 1] = { skip = true }
            elseif link then
                local gi = (_G.C_Item and _G.C_Item.GetItemInfo) or _G.GetItemInfo
                local okI, name, _, q, _, _, typ, sub = pcall(gi or function() end, link)
                if not okI then name, q, typ, sub = nil end
                if not name then name = tostring(link):match("%[(.-)%]") end
                if not typ and _G.C_Item and _G.C_Item.GetItemInfoInstant then
                    local okJ, _, t2, s2 = pcall(_G.C_Item.GetItemInfoInstant, link)
                    if okJ then typ, sub = t2, s2 end
                end
                q = tonumber(q or quality) or 1
                cur[#cur + 1] = { id = id, key = (tostring(link):match("item:[^|]+") or tostring(id)) .. "x" .. string.format("%05d", tonumber(count) or 1),
                    sk = string.format("%s|%s|%d|%s", tostring(typ or "~"), tostring(sub or ""), 9 - q, tostring(name or "")) }
            else
                cur[#cur + 1] = false
            end
        end
    end
    -- items you saved to a spot stay in that spot; everything else is packed around them
    local fixed = {}
    for id, p in pairs(B.Pins()) do
        if type(p) == "table" and type(p.cell) == "number" then fixed[id] = math.floor(p.cell) end
    end
    local moves = B.PlanSort(cur, fixed)
    if #moves == 0 then B.Say("already sorted (" .. #cells .. " slots checked)") return end
    B.Say("sorting: " .. #moves .. " moves")
    sorting = true
    local n, waits = 0, 0
    local step
    local function stepRaw()
        if _G.InCombatLockdown and _G.InCombatLockdown() then sorting = false return end
        n = n + 1
        local m = moves[n]
        if not m then sorting = false if B.Frame and B.Frame.Refresh then B.Frame.Refresh() end return end
        local a, b = cells[m[1]], cells[m[2]]
        local _, _, la = B.SlotInfo(a[1], a[2])
        local _, _, lb = B.SlotInfo(b[1], b[2])
        if la or lb or (_G.GetCursorInfo and _G.GetCursorInfo()) then
            waits = waits + 1
            if waits > 40 then sorting = false B.Say("sort stopped (items stayed locked)") return end
            n = n - 1
            return _G.C_Timer.After(0.1, step)
        end
        waits = 0
        B.Pickup(a[1], a[2])
        B.Pickup(b[1], b[2])
        if _G.GetCursorInfo and _G.GetCursorInfo() then B.Pickup(a[1], a[2]) end
        _G.C_Timer.After(0.12, step)
    end
    step = function()
        local ok, err = pcall(stepRaw)
        if not ok then sorting = false B.Say("sort error: " .. tostring(err)) end
    end
    step()
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
    elseif cmd == "layout" then
        if rest == "compact" or rest == "real" or rest == "gaps" then B.db.layout = rest refresh() B.Print("layout: " .. rest)
        else B.Print("usage: /baggie layout real | gaps | compact (now " .. B.db.layout .. ")") end
    elseif cmd == "keyring" then
        B.db.keyring = not B.db.keyring refresh() B.Print("keyring " .. (B.db.keyring and "shown" or "hidden"))
        if B.db.keyring and B.NumSlots(_G.KEYRING_CONTAINER or -2) == 0 then B.Print("this character has no keyring slots to show") end
    elseif cmd == "unpin" and rest == "all" then
        for k in pairs(B.Pins()) do B.Pins()[k] = nil end refresh() B.Print("all saved spots cleared")
    elseif cmd == "pins" or cmd == "list" then
        local n = 0
        for id, p in pairs(B.Pins()) do
            n = n + 1 B.Print(("cell %d: %s (%d)"):format(p.cell or 0, p.name or "item", id))
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
        B.Print("/baggie options  (all settings in a window)")
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
