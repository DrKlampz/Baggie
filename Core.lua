-- Baggie: one bag window where you choose where items sit.
-- Core.lua holds settings, bag access, events and the slash command.
local ADDON_NAME, B = ...
B.name = ADDON_NAME
_G.Baggie = B

B.DEFAULTS = {
    enabled = true,      -- replace the default bag windows
    cols = 10,           -- cells per row
    scale = 1,
    borders = true,      -- quality colored borders
    junkDim = true,      -- dim grey items
    point = nil,         -- saved window position
    keyring = false,
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
    return tonumber(n) or 0
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

function B.BagIDs()
    local ids = { 0 }
    local last = tonumber(_G.NUM_BAG_SLOTS) or 4
    for b = 1, last do ids[#ids + 1] = b end
    if B.db and B.db.keyring and B.NumSlots(-2) > 0 then ids[#ids + 1] = -2 end
    return ids
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
        B.db.borders = not B.db.borders refresh() B.Print("quality borders " .. (B.db.borders and "on" or "off"))
    elseif cmd == "keyring" then
        B.db.keyring = not B.db.keyring refresh() B.Print("keyring " .. (B.db.keyring and "shown" or "hidden"))
    elseif cmd == "unpin" and rest == "all" then
        for k in pairs(B.Pins()) do B.Pins()[k] = nil end refresh() B.Print("all saved spots cleared")
    elseif cmd == "pins" or cmd == "list" then
        local n = 0
        for id, p in pairs(B.Pins()) do
            n = n + 1 B.Print(("cell %d: %s (%d)"):format(p.cell or 0, p.name or "item", id))
        end
        if n == 0 then B.Print("no saved spots yet. Alt+click an item, then Alt+click a cell.") end
    elseif cmd == "default" then
        B.db.enabled = not B.db.enabled B.Frame.ApplyOverrides()
        B.Print(B.db.enabled and "Baggie bags on" or "default bags back (applies fully after /reload)")
    elseif cmd == "reset" then
        B.db.point = nil B.Frame.ResetPosition() B.Print("window position reset")
    else
        B.Print("/baggie  open or close your bags")
        B.Print("Alt+click an item, then Alt+click any cell to save the item to that spot.")
        B.Print("Alt+right-click a saved cell to free it. The Pin button does the same without Alt.")
        B.Print("/baggie pins | unpin all | cols N | scale N | borders | keyring | default | reset")
    end
end)
