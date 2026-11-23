-- Baggie: make room when the bags are full.
-- On by default, and each part can be turned off in Options > Vendors and mail.
--  * makeRoom: when you try to loot and every general bag slot is taken, Baggie destroys the cheapest grey
--    (junk) items to open room for the loot, as many as the loot needs, on every full-bag loot attempt, until no grey item is left.
--    Only grey items are ever destroyed: never white or better, never quest items, nothing at a vendor, bank,
--    mailbox, auction house or trade window, and nothing while you hold something on the cursor.
--  * makeRoomQuest: when the loot holds a quest item and no grey item is left, the cheapest white or green item
--    is destroyed instead, one per quest item. Never a quest item, a bag, a saved-spot item, the hearthstone or
--    anything rare or better, and only items the game gives a vendor price for.
--  * makeRoomMark: with the bags full and no grey item left, the cheapest white (common) item gets a trash can
--    on it. That is only a suggestion: Baggie never destroys a white item by itself.
local ADDON, B = ...
local M = {}
B.MakeRoom = M

local function Say(msg) B.Print(msg) end

local function FreeGeneralSlots()
    local c = _G.C_Container
    local n = 0
    for _, bag in ipairs(B.CarriedBagIDs()) do
        local free, bagType
        if c and c.GetContainerNumFreeSlots then free, bagType = c.GetContainerNumFreeSlots(bag)
        elseif _G.GetContainerNumFreeSlots then free, bagType = _G.GetContainerNumFreeSlots(bag) end
        if free == nil then
            free = 0
            for slot = 1, B.NumSlots(bag) do if not B.SlotInfo(bag, slot) then free = free + 1 end end
        end
        if (bagType or 0) == 0 then n = n + (free or 0) end
    end
    return n
end

local function IsQuestSlot(bag, slot)
    local getQ = (_G.C_Container and _G.C_Container.GetContainerItemQuestInfo) or _G.GetContainerItemQuestInfo
    if not getQ then return false end
    local ok, a = pcall(getQ, bag, slot)
    if not ok then return false end
    if type(a) == "table" then return a.isQuestItem and true or false end
    return a and true or false
end

local function Price(link, count)
    local p = _G.GetItemInfo and tonumber(select(11, _G.GetItemInfo(link)))
    if p == nil then return nil end
    return p * (tonumber(count) or 1)
end

local function ClassOf(id)
    if id and _G.C_Item and _G.C_Item.GetItemInfoInstant then
        local ok, _, _, _, _, _, classID = pcall(_G.C_Item.GetItemInfoInstant, id)
        if ok then return classID end
    end
end

-- every grey item that may be destroyed, cheapest first
local function Greys()
    local list = {}
    for _, bag in ipairs(B.CarriedBagIDs()) do
        for slot = 1, B.NumSlots(bag) do
            local tex, count, locked, quality, link, id = B.SlotInfo(bag, slot)
            if tex and link and id and quality == 0 and not locked and not IsQuestSlot(bag, slot)
                and not (B.Toss and B.Toss.Marked and B.Toss.Marked(id)) then
                list[#list + 1] = { bag = bag, slot = slot, id = id, link = link, value = Price(link, count) or 0 }
            end
        end
    end
    table.sort(list, function(a, b) return a.value < b.value end)
    return list
end

-- the cheapest white item, or nil. Never a quest item, a bag, a saved-spot item or the hearthstone.
local function CheapestCommon()
    local best
    local pins = B.Pins and B.Pins() or {}
    for _, bag in ipairs(B.CarriedBagIDs()) do
        for slot = 1, B.NumSlots(bag) do
            local tex, count, locked, quality, link, id = B.SlotInfo(bag, slot)
            if tex and link and id and quality == 1 and not locked and id ~= 6948 and pins[id] == nil
                and not IsQuestSlot(bag, slot) and ClassOf(id) ~= 1 and ClassOf(id) ~= 12 then
                local v = Price(link, count)
                if v and v > 0 and (not best or v < best.value) then
                    best = { bag = bag, slot = slot, id = id, link = link, value = v }
                end
            end
        end
    end
    return best
end

-- white and green items that may be destroyed for a quest item, cheapest first
local function Cheapest()
    local list = {}
    local pins = B.Pins and B.Pins() or {}
    for _, bag in ipairs(B.CarriedBagIDs()) do
        for slot = 1, B.NumSlots(bag) do
            local tex, count, locked, quality, link, id = B.SlotInfo(bag, slot)
            if tex and link and id and (quality == 1 or quality == 2) and not locked and id ~= 6948 and pins[id] == nil
                and not IsQuestSlot(bag, slot) and ClassOf(id) ~= 1 and ClassOf(id) ~= 12
                and not (B.Toss and B.Toss.Marked and B.Toss.Marked(id)) then
                local v = Price(link, count)
                if v and v > 0 then list[#list + 1] = { bag = bag, slot = slot, id = id, link = link, value = v, q = quality } end
            end
        end
    end
    table.sort(list, function(a, b) return a.value < b.value end)
    return list
end

-- Frame.lua asks this for every button. Cached for the current frame so a refresh scans the bags once.
local cacheAt, cacheVal
function M.MarkTarget()
    if not (B.db and B.db.makeRoomMark ~= false) then return nil end
    local now = _G.GetTime and _G.GetTime() or 0
    if cacheAt == now then return cacheVal end
    cacheAt, cacheVal = now, nil
    if FreeGeneralSlots() == 0 and not Greys()[1] then cacheVal = CheapestCommon() end
    return cacheVal
end

local function Busy()
    if _G.GetCursorInfo and _G.GetCursorInfo() then return true end
    local at = _G.MerchantFrame and _G.MerchantFrame:IsShown()
        or _G.BankFrame and _G.BankFrame:IsShown()
        or _G.MailFrame and _G.MailFrame:IsShown()
        or _G.AuctionFrame and _G.AuctionFrame:IsShown()
        or _G.AuctionHouseFrame and _G.AuctionHouseFrame:IsShown()
        or _G.TradeFrame and _G.TradeFrame:IsShown()
    return at and true or false
end

local warned = false

-- need = how many slots the loot wants (at least 1)
function M.MakeRoom(need, questLoot)
    if not (B.db and B.db.makeRoom ~= false) or Busy() then return end
    need = math.max(1, (tonumber(need) or 1) - FreeGeneralSlots())
    if FreeGeneralSlots() > 0 and need <= 0 then return end
    local greys = Greys()
    local quest = false
    if not greys[1] and questLoot and questLoot > 0 and B.db.makeRoomQuest ~= false then
        greys = Cheapest()
        need = math.min(need, questLoot)
        quest = true
    end
    if not greys[1] then
        if not warned then
            warned = true
            Say("bags are full and there is no grey item left to destroy")
            cacheAt = nil
            if B.Frame and B.Frame.Refresh then pcall(B.Frame.Refresh) end
        end
        return
    end
    warned = false
    local jobs = {}
    for i = 1, math.min(need, #greys) do jobs[#jobs + 1] = greys[i] end
    -- the game only lets an add-on destroy an item from a real click, not from the loot event: try it, and when it
    -- is refused put the item back and ask with a button instead (a button click is allowed)
    local _, blocked = M.Destroy(jobs, quest)
    if blocked then M.Ask(jobs, quest) end
end

-- destroys the jobs; returns how many went, and true when the game refused (the cursor still holds the item)
function M.Destroy(jobs, quest)
    local done, blocked = 0, false
    for _, job in ipairs(jobs) do
        local tex, _, locked, quality, _, id = B.SlotInfo(job.bag, job.slot)
        if tex and id == job.id and quality == (job.q or 0) and not locked and not Busy() then
            B.Pickup(job.bag, job.slot)
            if _G.GetCursorInfo and _G.GetCursorInfo() == "item" and _G.DeleteCursorItem then
                _G.DeleteCursorItem()
                if _G.GetCursorInfo and _G.GetCursorInfo() == "item" then
                    if _G.ClearCursor then _G.ClearCursor() end
                    blocked = true
                    break
                end
                done = done + 1
                local coin = _G.GetCoinTextureString and job.value > 0 and (" (worth " .. _G.GetCoinTextureString(job.value) .. ")") or ""
                Say((quest and "room for a quest item: destroyed " or "bags full: destroyed ") .. tostring(job.link) .. coin)
            elseif _G.ClearCursor then
                _G.ClearCursor()
            end
        end
    end
    cacheAt = nil
    return done, blocked
end

local pendingJobs, pendingQuest
function M.Ask(jobs, quest)
    if not _G.StaticPopupDialogs or not _G.StaticPopup_Show then return end
    local names = {}
    for _, j in ipairs(jobs) do names[#names + 1] = tostring(j.link) end
    pendingJobs, pendingQuest = jobs, quest
    if not _G.StaticPopupDialogs["BAGGIE_MAKEROOM"] then
        _G.StaticPopupDialogs["BAGGIE_MAKEROOM"] = {
            text = "%s",
            button1 = "Destroy",
            button2 = "Keep",
            OnAccept = function()
                local ok, _, blocked = pcall(M.Destroy, pendingJobs or {}, pendingQuest)
                if ok and blocked then Say("the game would not let Baggie destroy it; drag it out of your bag to destroy it yourself") end
            end,
            timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
        }
    end
    _G.StaticPopup_Show("BAGGIE_MAKEROOM", "Bags are full. Destroy to make room:\n" .. table.concat(names, ", ") .. "?")
end

local function LootCount()
    local n = 0
    for i = 1, (_G.GetNumLootItems and _G.GetNumLootItems() or 0) do
        local isItem = true
        if _G.LootSlotHasItem then isItem = _G.LootSlotHasItem(i) end
        if isItem then n = n + 1 end
    end
    return n
end

-- how many quest items are in the open loot window
local function QuestLootCount()
    local n = 0
    for i = 1, (_G.GetNumLootItems and _G.GetNumLootItems() or 0) do
        local isItem = true
        if _G.LootSlotHasItem then isItem = _G.LootSlotHasItem(i) end
        if isItem then
            local q = false
            local link = _G.GetLootSlotLink and _G.GetLootSlotLink(i)
            local id = link and tonumber(tostring(link):match("item:(%d+)"))
            if id and ClassOf(id) == 12 then q = true end
            if not q and _G.GetLootSlotInfo then
                local r = { _G.GetLootSlotInfo(i) }
                if r[6] == true or r[7] == true then q = true end
            end
            if q then n = n + 1 end
        end
    end
    return n
end

local ev = _G.CreateFrame("Frame")
ev:RegisterEvent("LOOT_OPENED")
ev:RegisterEvent("UI_ERROR_MESSAGE")
ev:RegisterEvent("BAG_UPDATE_DELAYED")
ev:SetScript("OnEvent", function(_, event, a, b)
    local ok = pcall(function()
        if event == "LOOT_OPENED" then
            local n = LootCount()
            if n > 0 and FreeGeneralSlots() < n then M.MakeRoom(n, QuestLootCount()) end
        elseif event == "UI_ERROR_MESSAGE" then
            local msg = type(b) == "string" and b or a
            if msg == _G.ERR_INV_FULL or msg == _G.INVENTORY_FULL then
                M.MakeRoom(1, QuestLootCount())
            end
        else
            cacheAt = nil
        end
    end)
    if not ok then cacheAt = nil end
end)
