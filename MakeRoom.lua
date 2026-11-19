-- Baggie: make room when the bags are full.
-- Off until you turn it on (Options > Vendors and mail). When every general bag slot is taken, Baggie destroys
-- the cheapest grey (junk) item to open a slot. Only grey items are ever touched: nothing white or better,
-- no quest items, nothing while you are in combat, at a vendor, bank, mailbox or auction house, or holding
-- something on the cursor. With no grey item in your bags, it does nothing.
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

local function Cheapest()
    local best
    for _, bag in ipairs(B.CarriedBagIDs()) do
        for slot = 1, B.NumSlots(bag) do
            local tex, count, locked, quality, link, id = B.SlotInfo(bag, slot)
            if tex and link and id and quality == 0 and not locked and not IsQuestSlot(bag, slot)
                and not (B.Toss and B.Toss.Marked and B.Toss.Marked(id)) then
                local price = 0
                if _G.GetItemInfo then price = tonumber(select(11, _G.GetItemInfo(link))) or 0 end
                local value = price * (tonumber(count) or 1)
                if not best or value < best.value then
                    best = { bag = bag, slot = slot, id = id, link = link, value = value }
                end
            end
        end
    end
    return best
end

local busy, lastAt, warned = false, 0, false
local function Busy()
    if _G.InCombatLockdown and _G.InCombatLockdown() then return true end
    if _G.GetCursorInfo and _G.GetCursorInfo() then return true end
    local at = _G.MerchantFrame and _G.MerchantFrame:IsShown()
        or _G.BankFrame and _G.BankFrame:IsShown()
        or _G.MailFrame and _G.MailFrame:IsShown()
        or _G.AuctionFrame and _G.AuctionFrame:IsShown()
        or _G.AuctionHouseFrame and _G.AuctionHouseFrame:IsShown()
        or _G.TradeFrame and _G.TradeFrame:IsShown()
    return at and true or false
end

function M.Check()
    if not (B.db and B.db.makeRoom) or busy or Busy() then return end
    if _G.GetTime and _G.GetTime() - lastAt < 1 then return end
    if FreeGeneralSlots() > 0 then warned = false return end
    local job = Cheapest()
    if not job then
        if not warned then warned = true Say("bags are full and there is no grey item to destroy") end
        return
    end
    busy = true
    local function Do()
        busy = false
        -- check once more, right now
        local tex, _, locked, quality, _, id = B.SlotInfo(job.bag, job.slot)
        if not (tex and id == job.id and quality == 0 and not locked) or Busy() then return end
        B.Pickup(job.bag, job.slot)
        if _G.GetCursorInfo and _G.GetCursorInfo() == "item" and _G.DeleteCursorItem then
            _G.DeleteCursorItem()
            lastAt = _G.GetTime and _G.GetTime() or 0
            local coin = _G.GetCoinTextureString and job.value > 0 and (" (worth " .. _G.GetCoinTextureString(job.value) .. ")") or ""
            Say("bags full: destroyed " .. tostring(job.link) .. coin)
        elseif _G.ClearCursor then
            _G.ClearCursor()
        end
    end
    if _G.C_Timer then _G.C_Timer.After(0.3, Do) else Do() end
end

local ev = _G.CreateFrame("Frame")
ev:RegisterEvent("BAG_UPDATE_DELAYED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
    local ok, err = pcall(M.Check)
    if not ok then busy = false end
end)
