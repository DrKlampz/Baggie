-- Baggie: item glows on the bank and the guild bank.
-- Baggie draws its own bag window; the bank and guild bank are the game's windows, so the same glows
-- (quest items, high quality) are laid over their slot buttons instead.
local ADDON_NAME, B = ...

local function QualityRGB(q)
    if _G.GetItemQualityColor and q then
        local r, g, b = _G.GetItemQualityColor(q)
        if r then return r, g, b end
    end
    local c = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[q or 1]
    if c then return c.r, c.g, c.b end
end

local function ClassOf(linkOrID)
    if linkOrID and _G.C_Item and _G.C_Item.GetItemInfoInstant then
        local ok, _, _, _, _, _, classID = pcall(_G.C_Item.GetItemInfoInstant, linkOrID)
        if ok then return classID end
    end
end

local function ContainerQuest(bag, slot)
    local getQ = (_G.C_Container and _G.C_Container.GetContainerItemQuestInfo) or _G.GetContainerItemQuestInfo
    if not getQ then return nil end
    local ok, a, b, c = pcall(getQ, bag, slot)
    if not ok then return nil end
    local isQuest, questID, active
    if type(a) == "table" then isQuest, questID, active = a.isQuestItem, a.questID, a.isActive
    else isQuest, questID, active = a, b, c end
    if questID and questID > 0 and not active then return "starts" end
    if isQuest then return "quest" end
end

local function Color(kind, quality)
    local db = B.db
    if not db then return end
    local r, g, b = B.KindColor(kind)
    if r then return r, g, b end
    if db.glowQuality and (quality or 0) >= (tonumber(db.glowMinQuality) or 4) then
        local qr, qg, qb = QualityRGB(quality)
        return qr, qg, qb, true
    end
end

-- glow size and brightness from the settings; the item quality glow has its own brightness
local function GlowLook(isQuality)
    local db = B.db
    local size = tonumber(db.glowSize) or 1.75
    local str = isQuality and (tonumber(db.glowQualityStrength) or 0.8) or (tonumber(db.glowStrength) or 0.8)
    return size, math.max(0.1, math.min(1, str))
end

local function Overlay(btn)
    local g = btn.baggieGlow
    if g then return g end
    g = btn:CreateTexture(nil, "OVERLAY", nil, 5)
    g:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    g:SetBlendMode("ADD")
    g:SetPoint("CENTER", btn, "CENTER", 0, 0)
    g:Hide()
    btn.baggieGlow = g
    return g
end

local function Apply(btn, r, g, b, isQuality)
    local o = Overlay(btn)
    if not r then o:Hide() return end
    local w = (btn:GetWidth() or 37)
    local size, str = GlowLook(isQuality)
    o:SetSize(w * size, w * size)
    o:SetVertexColor(r, g, b, str)
    o:Show()
end

-- main bank slots (bag -1)
local function RefreshBank()
    if not B.db then return end
    for i = 1, 40 do
        local btn = _G["BankFrameItem" .. i]
        if not btn then break end
        local tex, _, _, quality, _, id = B.SlotInfo(-1, i)
        if tex then
            local kind = ContainerQuest(-1, i)
            if kind == "quest" and not B.QuestItemOK(id) then kind = "misc" end
            if not kind and ClassOf(id) == 12 then kind = B.QuestItemOK(id) and "quest" or "misc" end
            Apply(btn, Color(kind, quality)) B.StartMark(btn, kind == "starts")
        else
            Apply(btn) B.StartMark(btn, false)
        end
    end
    -- bank bags, when they are shown as the game's own bag windows
    for f = 1, 13 do
        local frame = _G["ContainerFrame" .. f]
        local bag = frame and frame.GetID and frame:GetID()
        if frame and frame:IsShown() and type(bag) == "number" and bag >= 5 then
            for i = 1, 40 do
                local btn = _G["ContainerFrame" .. f .. "Item" .. i]
                if not btn then break end
                local slot = btn.GetID and btn:GetID() or i
                local tex, _, _, quality, _, id = B.SlotInfo(bag, slot)
                if tex then
                    local kind = ContainerQuest(bag, slot)
                    if kind == "quest" and not B.QuestItemOK(id) then kind = "misc" end
            if not kind and ClassOf(id) == 12 then kind = B.QuestItemOK(id) and "quest" or "misc" end
                    Apply(btn, Color(kind, quality)) B.StartMark(btn, kind == "starts")
                else
                    Apply(btn) B.StartMark(btn, false)
                end
            end
        end
    end
end

-- guild bank: columns 1-7, rows 1-14, slot = (column - 1) * 14 + row
local function RefreshGuildBank()
    if not (B.db and _G.GetCurrentGuildBankTab and _G.GetGuildBankItemInfo) then return end
    local tab = _G.GetCurrentGuildBankTab()
    for c = 1, 8 do
        for r = 1, 14 do
            local btn = _G["GuildBankColumn" .. c .. "Button" .. r]
            if not btn then break end
            local slot = (c - 1) * 14 + r
            local ok, tex, _, _, _, quality = pcall(_G.GetGuildBankItemInfo, tab, slot)
            if ok and tex then
                local link = _G.GetGuildBankItemLink and _G.GetGuildBankItemLink(tab, slot)
                local kind = (ClassOf(link) == 12) and (B.QuestItemOK(link) and "quest" or "misc") or nil
                Apply(btn, Color(kind, quality)) B.StartMark(btn, kind == "starts")
            else
                Apply(btn) B.StartMark(btn, false)
            end
        end
    end
end

local pending
local function Soon(fn)
    if pending then return end
    pending = true
    local after = (_G.C_Timer and _G.C_Timer.After)
    local run = function() pending = nil pcall(fn) end
    if after then after(0.1, run) else run() end
end

-- own event frame: B.On keeps one handler per event, and Frame.lua already uses some of these
local ef = CreateFrame("Frame")
for _, e in ipairs({ "BANKFRAME_OPENED", "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED", "BAG_UPDATE_DELAYED",
    "GUILDBANKFRAME_OPENED", "GUILDBANKBAGSLOTS_CHANGED" }) do
    pcall(ef.RegisterEvent, ef, e)
end
ef:SetScript("OnEvent", function(_, event)
    if event:find("^GUILDBANK") then Soon(RefreshGuildBank)
    elseif _G.BankFrame and _G.BankFrame:IsShown() then Soon(RefreshBank) end
end)
-- changing tab, and the game's own redraws
for _, name in ipairs({ "GuildBankFrame_Update", "GuildBankFrame_UpdateTabs" }) do
    if _G[name] then pcall(hooksecurefunc, name, function() Soon(RefreshGuildBank) end) end
end
for _, name in ipairs({ "BankFrame_UpdateItems", "BankFrameItemButton_Update", "ContainerFrame_Update" }) do
    if _G[name] then pcall(hooksecurefunc, name, function() if _G.BankFrame and _G.BankFrame:IsShown() then Soon(RefreshBank) end end) end
end

-- the options window calls this so a change shows straight away
function B.RefreshBankGlows()
    pcall(RefreshBank)
    pcall(RefreshGuildBank)
end

-- used by the Baggie bank and guild bank windows (BankFrame.lua), which carry their own glow texture
function B.GuildGlowKind(link)
    if link and ClassOf(link) == 12 then return "quest" end
end

function B.GlowButton(btn, kind, quality, cell, hasItem)
    local g = btn.glow
    if not g then return end
    local r, gg, b, isQuality
    if hasItem then r, gg, b, isQuality = Color(kind, quality) end
    B.StartMark(btn, hasItem and kind == "starts", cell)
    if not r then g:Hide() return end
    local w = tonumber(cell) or btn:GetWidth() or 37
    local size, str = GlowLook(isQuality)
    g:SetSize(w * size, w * size)
    g:SetVertexColor(r, gg, b, str)
    g:Show()
end
