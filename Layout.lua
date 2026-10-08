-- Baggie layout: decides which real bag slot is drawn in which cell of the window.
-- Pure logic with no WoW calls, so it can be tested on its own.
local ADDON_NAME, B = ...
B = B or {}
B.Layout = B.Layout or {}
local L = B.Layout

-- slots: array of { bag=, slot=, itemID= (nil when empty) } in real bag order.
-- pins:  itemID -> { cell = n }  (the cell the player saved that item type to)
-- Returns cells (array indexed by cell number) and the number of cells.
--   cells[c] = { kind = "slot", index = i }            a real bag slot is drawn here
--            = { kind = "ghost", itemID = id }         a reserved, empty saved spot
-- The window has at least as many cells as real slots. It grows by whole cells only
-- when saved spots would otherwise push a real item out of the window.
function L.Build(slots, pins)
    local n = #slots
    pins = pins or {}

    local order = {}
    for itemID, p in pairs(pins) do
        if type(p) == "table" and type(p.cell) == "number" and p.cell >= 1 then
            order[#order + 1] = { id = itemID, cell = math.floor(p.cell) }
        end
    end
    table.sort(order, function(a, b)
        if a.cell ~= b.cell then return a.cell < b.cell end
        return tostring(a.id) < tostring(b.id)
    end)

    -- two pins on the same cell: the lower item id keeps it, the other is not drawn
    local seen, valid = {}, {}
    for _, p in ipairs(order) do
        if not seen[p.cell] then
            seen[p.cell] = true
            valid[#valid + 1] = p
        end
    end

    local used = {}          -- slot index -> true once placed
    local placed = {}        -- cell -> content
    local pinnedCells = 0
    local maxPinCell = 0
    for _, p in ipairs(valid) do
        pinnedCells = pinnedCells + 1
        if p.cell > maxPinCell then maxPinCell = p.cell end
        local found
        for i = 1, n do
            if not used[i] and slots[i].itemID == p.id then found = i break end
        end
        if found then
            used[found] = true
            placed[p.cell] = { kind = "slot", index = found }
        else
            placed[p.cell] = { kind = "ghost", itemID = p.id }
        end
    end

    -- everything left, real items first (in bag order), then empty slots
    local rest, empties = {}, {}
    for i = 1, n do
        if not used[i] then
            if slots[i].itemID then rest[#rest + 1] = i else empties[#empties + 1] = i end
        end
    end

    -- the window must be big enough to show every real item next to the saved spots
    local total = n
    if total < maxPinCell then total = maxPinCell end
    while (total - pinnedCells) < #rest do total = total + 1 end

    local cells = {}
    local ri, ei = 1, 1
    for c = 1, total do
        if placed[c] then
            cells[c] = placed[c]
        elseif ri <= #rest then
            cells[c] = { kind = "slot", index = rest[ri] } ri = ri + 1
        elseif ei <= #empties then
            cells[c] = { kind = "slot", index = empties[ei] } ei = ei + 1
        end
    end
    -- trailing cells with nothing to show (all empties already placed) are dropped
    local count = total
    while count > 0 and cells[count] == nil do count = count - 1 end
    -- pins beyond the last drawn cell stay valid; keep the window at least that big
    if count < maxPinCell then count = maxPinCell end
    return cells, count
end

-- Which cell currently shows the given real slot index (nil if none).
function L.CellOfSlot(cells, count, index)
    for c = 1, count do
        local x = cells[c]
        if x and x.kind == "slot" and x.index == index then return c end
    end
end

-- Moves (or swaps) a saved spot. Returns the new pins table entries it changed.
-- pins[itemID] = { cell = n, ... }. target is a cell number. If another item is saved
-- there and the moved item already had a spot, the two swap; otherwise the other is freed.
function L.Place(pins, itemID, target)
    local old = pins[itemID] and pins[itemID].cell
    local other
    for id, p in pairs(pins) do
        if id ~= itemID and p.cell == target then other = id end
    end
    local freed
    if other then
        if old then pins[other].cell = old else pins[other] = nil freed = other end
    end
    pins[itemID] = pins[itemID] or {}
    pins[itemID].cell = target
    return other, freed
end
