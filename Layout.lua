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
function L.BuildCompact(slots, pins)
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

-- Real bag order (the default): every slot stays exactly where the game has it. The only
-- things that move are the items you saved to a spot. A saved item swaps places with
-- whatever sat in its cell; a saved spot with no item reserves its cell, and the slot it
-- covered moves into the cell of an empty slot (or is simply not drawn if it is empty).
function L.BuildReal(slots, pins)
    local n = #slots
    pins = pins or {}
    local order = {}
    for itemID, p in pairs(pins) do
        if type(p) == "table" and type(p.cell) == "number" and p.cell >= 1 and p.cell <= n then
            order[#order + 1] = { id = itemID, cell = math.floor(p.cell) }
        end
    end
    table.sort(order, function(a, b)
        if a.cell ~= b.cell then return a.cell < b.cell end
        return tostring(a.id) < tostring(b.id)
    end)
    local seen, valid, pinnedCell = {}, {}, {}
    for _, p in ipairs(order) do
        if not seen[p.cell] then seen[p.cell] = true valid[#valid + 1] = p pinnedCell[p.cell] = true end
    end

    local cells = {}                     -- cells[c] = { kind="slot", index=i } | { kind="ghost", itemID=id }
    local where = {}                     -- slot index -> cell currently holding it
    for i = 1, n do cells[i] = { kind = "slot", index = i } where[i] = i end

    local placedSlot = {}                -- slot index fixed in its pinned cell
    local ghosts = {}
    for _, p in ipairs(valid) do
        local found
        for i = 1, n do
            if slots[i].itemID == p.id and not placedSlot[i] then found = i break end
        end
        if found then
            local from = where[found]
            if from ~= p.cell then
                local a, b = cells[from], cells[p.cell]
                -- plain swap: whatever sat in the saved cell takes the cell the item came from.
                -- (Never bump it elsewhere: dropping an item on that cell would then jump away.)
                cells[from], cells[p.cell] = b, a
                if a.kind == "slot" then where[a.index] = p.cell end
                if b.kind == "slot" then where[b.index] = from end
            end
            placedSlot[found] = true
        else
            ghosts[#ghosts + 1] = p
        end
    end

    local extra = {}
    for _, p in ipairs(ghosts) do
        local x = cells[p.cell]
        cells[p.cell] = { kind = "ghost", itemID = p.id }
        if x.kind == "slot" and slots[x.index].itemID then
            -- an item lost its cell: take the cell of an empty slot, counting from the end
            local took
            for c = n, 1, -1 do
                local y = cells[c]
                if y.kind == "slot" and not slots[y.index].itemID and not pinnedCell[c] then
                    cells[c] = x where[x.index] = c took = true break
                end
            end
            if not took then extra[#extra + 1] = x end
        end
    end
    local count = n
    for _, x in ipairs(extra) do count = count + 1 cells[count] = x end
    return cells, count
end

-- "Fill gaps": every slot keeps the cell it has, nothing is pushed to the front. The only
-- difference from real bag order is where a NEW item shows up: in the top-most empty cell
-- instead of wherever the game happened to put it. This swaps the cells of two EMPTY slots
-- (invisible), so no item ever moves. st remembers the cell of each slot between refreshes:
--   st = { perm = { ["bag:slot"] = cell }, prev = { ["bag:slot"] = true if it held an item }, count = n }
-- allowMove = false (the player is carrying or just dropped an item) leaves new items where they are.
function L.BuildGaps(slots, pins, st, allowMove)
    local n = #slots
    st = st or {}
    local keys = {}
    for i = 1, n do keys[i] = slots[i].bag .. ":" .. slots[i].slot end
    local same = st.perm ~= nil and st.n == n
    if same then for i = 1, n do if st.perm[keys[i]] == nil then same = false break end end end
    if not same then
        st.perm, st.prev, st.n = {}, nil, n
        for i = 1, n do st.perm[keys[i]] = i end
    end
    local filled, rose = {}, 0
    for i = 1, n do
        if slots[i].itemID then filled[keys[i]] = true end
    end
    if st.prev and allowMove then
        local before, after = 0, 0
        for _ in pairs(st.prev) do before = before + 1 end
        for _ in pairs(filled) do after = after + 1 end
        rose = after - before
        if rose > 0 then
            local owner = {}                                -- cell -> slot index
            for i = 1, n do owner[st.perm[keys[i]]] = i end
            for i = 1, n do
                if rose > 0 and filled[keys[i]] and not st.prev[keys[i]] then
                    local cur = st.perm[keys[i]]
                    for c = 1, cur - 1 do
                        local o = owner[c]
                        if o and not slots[o].itemID then
                            st.perm[keys[i]], st.perm[keys[o]] = c, cur
                            owner[c], owner[cur] = i, o
                            break
                        end
                    end
                    rose = rose - 1
                end
            end
        end
    end
    st.prev = filled

    local ordered, orig = {}, {}
    for i = 1, n do
        local c = st.perm[keys[i]]
        ordered[c], orig[c] = slots[i], i
    end
    local cells, count = L.BuildReal(ordered, pins)
    for c = 1, count do
        local x = cells[c]
        if x and x.kind == "slot" then cells[c] = { kind = "slot", index = orig[x.index] } end
    end
    return cells, count
end

function L.Build(slots, pins, mode, st, allowMove)
    if mode == "compact" then return L.BuildCompact(slots, pins) end
    if mode == "gaps" then return L.BuildGaps(slots, pins, st, allowMove) end
    return L.BuildReal(slots, pins)
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
function L.Place(pins, itemID, target, from)
    local old = (pins[itemID] and pins[itemID].cell) or from
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
