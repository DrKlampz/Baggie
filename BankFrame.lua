-- Baggie: the bank and the guild bank, drawn as Baggie windows (same look, search, glows and options).
-- The game's own bank windows are moved into a hidden holder while Baggie's are shown.
-- If anything here fails, the game's windows are put back so the bank always stays usable.
local ADDON_NAME, B = ...
local BU = {}
B.BankUI = BU
local F = B.Frame
local GOLD = { 0.88, 0.69, 0.29 }

local hider
local function Hider()
    if not hider then hider = CreateFrame("Frame") hider:Hide() end
    return hider
end

local function CellMetrics()
    local cell = math.max(24, math.min(56, tonumber(B.db.cellSize) or 37))
    local gap = math.max(0, math.min(16, tonumber(B.db.gap) or 4))
    local pad = math.max(4, math.min(30, tonumber(B.db.padding) or 12))
    return cell, gap, pad
end

local function BankGap()
    local _, gap = CellMetrics()
    return gap
end

local function MoneyText(money)
    local gm = B.db.goldMode
    local g, s, c = math.floor(money / 10000), math.floor(money / 100) % 100, money % 100
    if gm == "none" then return "" end
    if gm == "gold" then
        return tostring(g):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") .. "|cffffd700g|r"
    elseif gm == "icons" and _G.GetCoinTextureString then
        return _G.GetCoinTextureString(money)
    end
    return ("|cffffd700%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r"):format(g, s, c)
end

local function Label(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(B.FontPath(B.db.font), size or 11, "")
    fs:SetTextColor(1, 1, 1)
    return fs
end

local function Button(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 20)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

-- a window with the common pieces: backdrop, title bar, close, search box, footer
local function MakeWindow(name, key)
    local w = CreateFrame("Frame", name, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    w:SetFrameStrata("HIGH")
    w:SetToplevel(true)
    w:SetClampedToScreen(true)
    w:SetMovable(true)
    w:EnableMouse(true)
    w:RegisterForDrag("LeftButton")
    w:SetScript("OnDragStart", function(self) if not B.db.lockPos then self:StartMoving() end end)
    w:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        B.db[key] = { p, rp, x, y }
    end)
    w.bar = w:CreateTexture(nil, "ARTWORK")
    w.bar:SetTexture("Interface\\Buttons\\WHITE8X8")
    w.bar:SetHeight(26)
    w.title = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    w.title:SetPoint("TOPLEFT", 12, -7)
    local close = CreateFrame("Button", nil, w, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 1)
    w.search = CreateFrame("EditBox", name .. "Search", w, "InputBoxTemplate")
    w.search:SetSize(120, 18)
    w.search:SetPoint("TOPRIGHT", -34, -33)
    w.search:SetAutoFocus(false)
    w.search:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    w.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    w.searchLabel = Label(w, 11)
    w.searchLabel:SetPoint("RIGHT", w.search, "LEFT", -6, 0)
    w.searchLabel:SetText("Search")
    w.free = Label(w, 11)
    w.free:SetPoint("BOTTOMLEFT", 12, 10)
    w.money = Label(w, 11)
    w.money:SetPoint("BOTTOMRIGHT", -12, 10)
    table.insert(_G.UISpecialFrames, name)
    w:Hide()
    return w
end

local function Place(w, key, dx)
    local p = B.db[key]
    w:ClearAllPoints()
    if p then w:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else w:SetPoint("LEFT", UIParent, "LEFT", dx or 40, 0) end
end

----------------------------------------------------------------------
-- Bank
----------------------------------------------------------------------
local bw, bankBags, bankBtns, bagSlotBtns = nil, {}, {}, {}
local bankOpen = false
local blizzBank
local SoonBank

local function BankBagIDs()
    local ids = { -1 }
    local first = (tonumber(_G.NUM_BAG_SLOTS) or 4) + 1
    local last = (tonumber(_G.NUM_BAG_SLOTS) or 4) + (tonumber(_G.NUM_BANKBAGSLOTS) or 7)
    for b = first, last do ids[#ids + 1] = b end
    return ids
end

local function BagFrame(bag)
    if bankBags[bag] then return bankBags[bag] end
    local f = CreateFrame("Frame", "BaggieBankBag" .. (bag < 0 and ("K" .. -bag) or bag), bw)
    f:SetID(bag)
    f:SetAllPoints(bw)
    bankBags[bag] = f
    return f
end

local function BankButton(bag, slot)
    local key = bag .. ":" .. slot
    local btn = bankBtns[key]
    if btn then return btn end
    local parent = BagFrame(bag)
    local name = ("BaggieBankItem%s_%d"):format(bag < 0 and ("K" .. -bag) or bag, slot)
    local cell = CellMetrics()
    local ok, made = pcall(CreateFrame, "ItemButton", name, parent, "ContainerFrameItemButtonTemplate")
    if not ok or not made then ok, made = pcall(CreateFrame, "Button", name, parent, "ContainerFrameItemButtonTemplate") end
    if not ok or not made then made = CreateFrame("Button", name, parent) end
    btn = made
    btn:SetID(slot)
    btn:SetSize(cell, cell)
    btn.bag, btn.slot, btn.noPins = bag, slot, true
    F.Decorate(btn)
    bankBtns[key] = btn
    return btn
end

local BankRefresh
local function BankRefreshRaw()
    if not (bw and bw:IsShown() and B.db) then return end
    local cell, _, pad = CellMetrics()
    local gap = BankGap()
    local cols = math.max(6, math.min(24, tonumber(B.db.bankCols) or 14))
    local text = (bw.search:GetText() or ""):lower()
    local used, total = 0, 0
    local live = {}
    local col, row, secExtra = 0, 0, 0
    local compact = B.db.bankCompact ~= false
    local list, tail = {}, {}
    local function place(btn, bag, slot)
        live[btn] = true
        btn:SetSize(cell, cell)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", bw, "TOPLEFT", pad + col * (cell + gap), -(62 + row * (cell + gap) + secExtra))
        btn:Show()
        F.UpdateButton(btn, text)
        col = col + 1
        if col >= cols then col, row = 0, row + 1 end
    end
    if compact then
        -- everything packs to the top: filled slots first, then the empty ones; reagent bags go last
        local filled, empty, reagent = {}, {}, {}
        for _, bag in ipairs(BankBagIDs()) do
            local num = B.NumSlots(bag)
            local isReagent = false
            if bag > 0 and _G.C_Container and _G.C_Container.GetContainerNumFreeSlots then
                local ok, _, fam = pcall(_G.C_Container.GetContainerNumFreeSlots, bag)
                if ok and type(fam) == "number" and fam ~= 0 and bit and bit.band(fam, 0x20) ~= 0 then isReagent = true end
            end
            for slot = 1, num do
                local _, _, _, _, link = B.SlotInfo(bag, slot)
                total = total + 1
                if link then used = used + 1 end
                local e = { bag = bag, slot = slot }
                if isReagent then reagent[#reagent + 1] = e
                elseif link then filled[#filled + 1] = e else empty[#empty + 1] = e end
            end
        end
        for _, e in ipairs(filled) do place(BankButton(e.bag, e.slot), e.bag, e.slot) end
        for _, e in ipairs(empty) do place(BankButton(e.bag, e.slot), e.bag, e.slot) end
        if #reagent > 0 then
            if col ~= 0 then col, row = 0, row + 1 end
            secExtra = secExtra + 8
            for _, e in ipairs(reagent) do place(BankButton(e.bag, e.slot), e.bag, e.slot) end
        end
    else
    local first = true
    for _, bag in ipairs(BankBagIDs()) do
        local num = B.NumSlots(bag)
        if num > 0 then
            if not first and B.db.bankSections ~= false then
                if col ~= 0 then col, row = 0, row + 1 end
                secExtra = secExtra + 8
            end
            first = false
            for slot = 1, num do
                local btn = BankButton(bag, slot)
                place(btn, bag, slot)
                local _, _, _, _, link = B.SlotInfo(bag, slot)
                total = total + 1
                if link then used = used + 1 end
            end
        end
    end
    end
    for _, btn in pairs(bankBtns) do if not live[btn] then btn:Hide() end end
    local rows = row + (col > 0 and 1 or 0)
    bw:SetSize(pad * 2 + cols * cell + (cols - 1) * gap, 62 + rows * (cell + gap) + secExtra + (B.db.bankShowBags ~= false and 44 or 30))
    local cm = B.db.counterMode
    if cm == "free" then bw.free:SetText(("%d free of %d"):format(total - used, total))
    elseif cm == "freeonly" then bw.free:SetText(("%d free"):format(total - used))
    else bw.free:SetText(("%d / %d"):format(used, total)) end
    bw.free:SetShown(B.db.showFooter and cm ~= "none")
    bw.money:SetText(MoneyText(_G.GetMoney and _G.GetMoney() or 0))
    -- the bank's bag slots
    local numBought, full = 0, true
    if _G.GetNumBankSlots then numBought, full = _G.GetNumBankSlots() end
    for i, b in ipairs(bagSlotBtns) do
        local inv = _G.BankButtonIDToInvSlotID and _G.BankButtonIDToInvSlotID(i, 1)
        local tex = inv and _G.GetInventoryItemTexture and _G.GetInventoryItemTexture("player", inv)
        b.inv = inv
        if tex then b.icon:SetTexture(tex) b.icon:Show() else b.icon:Hide() end
        b:SetShown(B.db.bankShowBags ~= false)
        b:SetAlpha(i <= (tonumber(numBought) or 0) and 1 or 0.35)
    end
    bw.buy:SetShown(not full and B.db.bankShowBags ~= false)
end
BankRefresh = function() return B.Scoped("bank", BankRefreshRaw) end

local function BankCreate()
    if bw then return end
    bw = MakeWindow("BaggieBankFrame", "bankPoint")
    Place(bw, "bankPoint", 40)
    bw:SetScript("OnShow", function() BankRefresh() end)
    bw:SetScript("OnHide", function()
        if bankOpen and _G.CloseBankFrame then pcall(_G.CloseBankFrame) end
        bankOpen = false
    end)
    bw.search:SetScript("OnTextChanged", function() BankRefresh() end)
    bw.free:ClearAllPoints()
    bw.free:SetPoint("BOTTOMLEFT", 12, 10)
    -- bag slots along the bottom
    local nSlots = tonumber(_G.NUM_BANKBAGSLOTS) or 7
    for i = 1, nSlots do
        local b = CreateFrame("Button", nil, bw)
        b:SetSize(24, 24)
        b:SetPoint("BOTTOMLEFT", bw, "BOTTOMLEFT", 12 + (i - 1) * 28, 30)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints(b)
        b.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        b.bg:SetVertexColor(0.13, 0.13, 0.16, 1)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetPoint("TOPLEFT", 2, -2) b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        b:RegisterForClicks("LeftButtonUp")
        b:RegisterForDrag("LeftButton")
        local function click(self)
            if not self.inv then return end
            if _G.CursorHasItem and _G.CursorHasItem() then
                if _G.PutItemInBag then pcall(_G.PutItemInBag, self.inv) end
            elseif _G.PickupBagFromSlot then
                pcall(_G.PickupBagFromSlot, self.inv)
            end
        end
        b:SetScript("OnClick", click)
        b:SetScript("OnDragStart", click)
        b:SetScript("OnReceiveDrag", click)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.inv and _G.GetInventoryItemTexture and _G.GetInventoryItemTexture("player", self.inv) then
                GameTooltip:SetInventoryItem("player", self.inv)
            else
                GameTooltip:AddLine("Bank bag slot " .. i, 1, 1, 1)
                GameTooltip:AddLine("Drop a bag here", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        bagSlotBtns[i] = b
    end
    bw.sort = Button(bw, "Sort", 46, function()
        local ok, err = pcall(B.SortBags, { ids = BankBagIDs(), noPins = true, refresh = SoonBank })
        if not ok then B.Say("sort error: " .. tostring(err)) end
    end)
    bw.sort:SetPoint("TOPLEFT", bw, "TOPLEFT", 12, -33)
    bw.buy = Button(bw, "Buy bag slot", 90, function()
        if _G.StaticPopup_Show then pcall(_G.StaticPopup_Show, "CONFIRM_BUY_BANK_SLOT") end
    end)
    bw.buy:SetPoint("BOTTOMRIGHT", bw, "BOTTOMRIGHT", -12, 30)
    bw.buy:Hide()
end

local function HideBlizzardBank()
    local f = _G.BankFrame
    if not f or InCombatLockdown() then return end
    blizzBank = f
    pcall(f.SetParent, f, Hider())
end

local function RestoreBlizzardBank()
    local f = _G.BankFrame
    if f and not InCombatLockdown() then pcall(f.SetParent, f, UIParent) end
end

-- sorting and the repeated refreshes are all driven by events
local ev = CreateFrame("Frame")
for _, e in ipairs({ "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED",
    "BAG_UPDATE", "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "PLAYER_MONEY", "INVENTORY_CHANGED" }) do
    pcall(ev.RegisterEvent, ev, e)
end

local pendingBank
SoonBank = function()
    if pendingBank then return end
    pendingBank = true
    C_Timer.After(0.1, function() pendingBank = nil if bw and bw:IsShown() then pcall(BankRefresh) end end)
end

ev:SetScript("OnEvent", function(_, event)
    if not B.db then return end
    if event == "BANKFRAME_OPENED" then
        if B.db.bankReplace == false then RestoreBlizzardBank() return end
        local ok, err = pcall(function()
            BankCreate()
            F.ApplyLook()
            bankOpen = true
            HideBlizzardBank()
            bw:Show()
        end)
        if not ok then
            B.Print("bank window error, using the game's bank instead: " .. tostring(err))
            B.db.bankReplace = false
            bankOpen = false
            RestoreBlizzardBank()
        end
    elseif event == "BANKFRAME_CLOSED" then
        bankOpen = false
        if bw and bw:IsShown() then bw:Hide() end
    else
        if bw and bw:IsShown() then SoonBank() end
    end
end)

----------------------------------------------------------------------
-- Guild bank
----------------------------------------------------------------------
local gw, gBtns, tabBtns = nil, {}, {}
local gOpen = false
local SLOTS = 98

local function GuildTab() return (_G.GetCurrentGuildBankTab and _G.GetCurrentGuildBankTab()) or 1 end

local function GuildButton(i)
    local btn = gBtns[i]
    if btn then return btn end
    btn = CreateFrame("Button", "BaggieGuildItem" .. i, gw)
    btn.slot = i
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints(btn)
    btn.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", 2, -2) btn.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    btn.count = btn:CreateFontString(nil, "OVERLAY")
    btn.count:SetPoint("BOTTOMRIGHT", -3, 3)
    btn.count:SetTextColor(1, 1, 1)
    btn.border = CreateFrame("Frame", nil, btn)
    btn.border:SetAllPoints(btn)
    btn.border.edges = {}
    for k = 1, 4 do
        local t = btn.border:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        btn.border.edges[k] = t
    end
    btn.glow = btn:CreateTexture(nil, "OVERLAY", nil, 5)
    btn.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.glow:SetBlendMode("ADD")
    btn.glow:SetPoint("CENTER")
    btn.glow:Hide()
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn.SplitStack = function(self, split)
        if _G.SplitGuildBankItem then _G.SplitGuildBankItem(GuildTab(), self.slot, split) end
    end
    btn:SetScript("OnClick", function(self, mouse)
        local tab, slot = GuildTab(), self.slot
        local link = _G.GetGuildBankItemLink and _G.GetGuildBankItemLink(tab, slot)
        if link and _G.IsModifiedClick and _G.IsModifiedClick("CHATLINK") and _G.HandleModifiedItemClick then
            if _G.HandleModifiedItemClick(link) then return end
        end
        if mouse == "RightButton" then
            if link and _G.AutoStoreGuildBankItem then _G.AutoStoreGuildBankItem(tab, slot) end
        elseif link and _G.IsShiftKeyDown and _G.IsShiftKeyDown() and not (_G.CursorHasItem and _G.CursorHasItem()) then
            local _, count, locked = _G.GetGuildBankItemInfo(tab, slot)
            if (tonumber(count) or 1) > 1 and _G.OpenStackSplitFrame then
                _G.OpenStackSplitFrame(count, self, "BOTTOMLEFT", "TOPLEFT")
            else
                _G.PickupGuildBankItem(tab, slot)
            end
        else
            _G.PickupGuildBankItem(tab, slot)
        end
    end)
    btn:SetScript("OnDragStart", function(self) _G.PickupGuildBankItem(GuildTab(), self.slot) end)
    btn:SetScript("OnReceiveDrag", function(self) _G.PickupGuildBankItem(GuildTab(), self.slot) end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if _G.GetGuildBankItemLink and _G.GetGuildBankItemLink(GuildTab(), self.slot) then
            GameTooltip:SetGuildBankItem(GuildTab(), self.slot)
            GameTooltip:Show()
        else
            GameTooltip:Hide()
        end
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    gBtns[i] = btn
    return btn
end

local function StyleEdges(border, r, g, b, size)
    size = math.max(1, math.min(4, tonumber(size) or 1))
    local e = border.edges
    for k = 1, 4 do e[k]:SetVertexColor(r, g, b, 1) e[k]:ClearAllPoints() end
    e[1]:SetPoint("TOPLEFT") e[1]:SetPoint("TOPRIGHT") e[1]:SetHeight(size)
    e[2]:SetPoint("BOTTOMLEFT") e[2]:SetPoint("BOTTOMRIGHT") e[2]:SetHeight(size)
    e[3]:SetPoint("TOPLEFT") e[3]:SetPoint("BOTTOMLEFT") e[3]:SetWidth(size)
    e[4]:SetPoint("TOPRIGHT") e[4]:SetPoint("BOTTOMRIGHT") e[4]:SetWidth(size)
end

local GuildRefresh
local function GuildRefreshRaw()
    if not (gw and gw:IsShown() and B.db and _G.GetGuildBankItemInfo) then return end
    local cell, _, pad = CellMetrics()
    local gap = BankGap()
    local cols = math.max(7, math.min(24, tonumber(B.db.bankCols) or 14))
    local tab = GuildTab()
    local text = (gw.search:GetText() or ""):lower()
    local bc = B.db.borderColor or B.DEFAULTS.borderColor
    local font = B.FontPath(B.db.font)
    for i = 1, SLOTS do
        local btn = GuildButton(i)
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        btn:SetSize(cell, cell)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", gw, "TOPLEFT", pad + col * (cell + gap), -(62 + row * (cell + gap)))
        btn:Show()
        btn.count:SetFont(font, tonumber(B.db.countSize) or 11, "OUTLINE")
        local ok, tex, count, locked, _, quality = pcall(_G.GetGuildBankItemInfo, tab, i)
        local link = ok and tex and _G.GetGuildBankItemLink and _G.GetGuildBankItemLink(tab, i)
        B.PaintSlot(btn, btn.bg, (ok and tex) and true or false, quality)
        if ok and tex then
            btn.icon:SetTexture(tex)
            btn.icon:Show()
            btn.icon:SetDesaturated(locked and true or false)
            if B.db.iconCrop then btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) else btn.icon:SetTexCoord(0, 1, 0, 1) end
        else
            btn.icon:Hide()
        end
        local c = tonumber(count) or 0
        btn.count:SetText((tex and c > 1) and tostring(c) or "")
        -- border
        local mode = B.db.borderMode
        local show, r, g, b = false
        if tex and mode == "quality" and (quality or 0) >= (tonumber(B.db.borderMinQuality) or 2) then
            show = true r, g, b = F.QualityColor(quality)
        elseif (mode == "custom" and tex) or mode == "slots" then
            show = true r, g, b = bc[1], bc[2], bc[3]
        end
        if show then StyleEdges(btn.border, r, g, b, B.db.borderSize) btn.border:Show() else btn.border:Hide() end
        -- glows
        local kind = (B.GuildGlowKind and tex) and B.GuildGlowKind(link) or nil
        if B.GlowButton then B.GlowButton(btn, tex and kind or nil, quality, cell, tex ~= nil) else btn.glow:Hide() end
        -- search and junk
        local dim = 1
        if tex and quality == 0 and B.db.junkDim then dim = tonumber(B.db.junkAlpha) or 0.55 end
        if text ~= "" then
            local name = (type(link) == "string" and link:match("%[(.-)%]") or ""):lower()
            if not name:find(text, 1, true) then dim = 0.25 end
        end
        btn:SetAlpha(dim)
    end
    local rows = math.ceil(SLOTS / cols)
    gw:SetSize(pad * 2 + cols * cell + (cols - 1) * gap, 62 + rows * (cell + gap) + 78)
    -- tabs
    local n = (_G.GetNumGuildBankTabs and _G.GetNumGuildBankTabs()) or 0
    for i = 1, math.max(n, #tabBtns) do
        local t = tabBtns[i]
        if i <= n then
            if not t then
                t = CreateFrame("Button", nil, gw)
                t:SetSize(28, 28)
                t:SetPoint("BOTTOMLEFT", gw, "BOTTOMLEFT", 12 + (i - 1) * 32, 32)
                t.bg = t:CreateTexture(nil, "BACKGROUND")
                t.bg:SetAllPoints(t)
                t.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                t.icon = t:CreateTexture(nil, "ARTWORK")
                t.icon:SetPoint("TOPLEFT", 2, -2) t.icon:SetPoint("BOTTOMRIGHT", -2, 2)
                t:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
                t:SetScript("OnClick", function(self)
                    if _G.SetCurrentGuildBankTab then _G.SetCurrentGuildBankTab(self.tab) end
                    if _G.QueryGuildBankTab then _G.QueryGuildBankTab(self.tab) end
                    GuildRefresh()
                end)
                t:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(self.tabName or ("Tab " .. self.tab), 1, 1, 1)
                    GameTooltip:Show()
                end)
                t:SetScript("OnLeave", function() GameTooltip:Hide() end)
                tabBtns[i] = t
            end
            local name, icon, viewable = _G.GetGuildBankTabInfo(i)
            t.tab, t.tabName = i, name
            t.icon:SetTexture(icon)
            t.icon:SetDesaturated(not viewable)
            local sel = (i == tab)
            local look = B.GetLookSettings and B.GetLookSettings() or B.db
            local e = look.edgeColor or B.DEFAULTS.edgeColor
            t.bg:SetVertexColor(sel and e[1] or 0.13, sel and e[2] or 0.13, sel and e[3] or 0.16, 1)
            t:Show()
        elseif t then
            t:Hide()
        end
    end
    -- no tab you may view: say so, like the game's window does
    local viewable = 0
    for i = 1, n do
        local _, _, v = _G.GetGuildBankTabInfo(i)
        if v then viewable = viewable + 1 end
    end
    if not gw.noPerm then
        gw.noPerm = gw:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        gw.noPerm:SetPoint("CENTER", gw, "CENTER", 0, 0)
        gw.noPerm:SetText("You do not have permission to view any Guild Bank tabs.")
    end
    local blocked = (n > 0 and viewable == 0)
    gw.noPerm:SetShown(blocked)
    if blocked then for _, b in pairs(gBtns) do b:Hide() end end
    local tname = _G.GetGuildBankTabInfo and select(1, _G.GetGuildBankTabInfo(tab))
    gw.free:SetText(tname or "")
    gw.free:SetShown(true)
    gw.money:SetText(MoneyText(_G.GetGuildBankMoney and _G.GetGuildBankMoney() or 0))
end
GuildRefresh = function() return B.Scoped("guild", GuildRefreshRaw) end

local function GuildCreate()
    if gw then return end
    gw = MakeWindow("BaggieGuildBankFrame", "guildPoint")
    Place(gw, "guildPoint", 40)
    gw:SetScript("OnShow", function() GuildRefresh() end)
    gw:SetScript("OnHide", function()
        if gOpen and _G.CloseGuildBankFrame then pcall(_G.CloseGuildBankFrame) end
        gOpen = false
    end)
    gw.search:SetScript("OnTextChanged", function() GuildRefresh() end)
    gw.money:ClearAllPoints()
    gw.money:SetPoint("BOTTOMRIGHT", -12, 10)
    gw.withdraw = Button(gw, "Withdraw", 70, function() if _G.StaticPopup_Show then _G.StaticPopup_Show("GUILDBANK_WITHDRAW") end end)
    gw.deposit = Button(gw, "Deposit", 70, function() if _G.StaticPopup_Show then _G.StaticPopup_Show("GUILDBANK_DEPOSIT") end end)
    gw.sort = Button(gw, "Sort", 46, function() B.GuildSort() end)
    gw.sort:SetPoint("TOPLEFT", gw, "TOPLEFT", 12, -33)
    gw.deposit:SetPoint("BOTTOMRIGHT", gw, "BOTTOMRIGHT", -12, 30)
    gw.withdraw:SetPoint("RIGHT", gw.deposit, "LEFT", -4, 0)
end

-- Sort the current guild bank tab. Needs the right to take items out and put them in; each move waits for the server.
function B.GuildSort()
    local tab = GuildTab()
    local cells, cur = {}, {}
    for i = 1, SLOTS do
        cells[i] = { tab, i }
        local ok, tex, count, _, _, quality = pcall(_G.GetGuildBankItemInfo, tab, i)
        local link = ok and tex and _G.GetGuildBankItemLink and _G.GetGuildBankItemLink(tab, i)
        if link then
            local id = tonumber(tostring(link):match("item:(%d+)"))
            cur[i] = B.SortEntry(link, id, count, quality)
        else
            cur[i] = false
        end
    end
    B.SortBags({
        cells = cells, cur = cur, noPins = true, delay = 0.6,
        locked = function(c)
            local ok, _, _, l = pcall(_G.GetGuildBankItemInfo, c[1], c[2])
            return ok and l
        end,
        pickup = function(c) _G.PickupGuildBankItem(c[1], c[2]) end,
        refresh = function() if gw and gw:IsShown() then GuildRefresh() end end,
    })
end

local gev = CreateFrame("Frame")
for _, e in ipairs({ "GUILDBANKFRAME_OPENED", "GUILDBANKFRAME_CLOSED", "GUILDBANKBAGSLOTS_CHANGED", "GUILDBANK_UPDATE_TABS",
    "GUILDBANK_UPDATE_MONEY", "GUILDBANK_ITEM_LOCK_CHANGED" }) do
    pcall(gev.RegisterEvent, gev, e)
end

local pendingG
local function SoonGuild()
    if pendingG then return end
    pendingG = true
    C_Timer.After(0.1, function() pendingG = nil if gw and gw:IsShown() then pcall(GuildRefresh) end end)
end

local hooked
local function HideBlizzardGuildBank()
    local f = _G.GuildBankFrame
    if not f then return end
    if not hooked then
        hooked = true
        -- the game shows its window after the event too, so keep it out of sight while Baggie's is up
        pcall(f.HookScript, f, "OnShow", function(self)
            if gOpen and not InCombatLockdown() then pcall(self.SetParent, self, Hider()) end
        end)
    end
    if not InCombatLockdown() then pcall(f.SetParent, f, Hider()) end
end

local function OpenGuild()
    if gOpen and gw and gw:IsShown() then HideBlizzardGuildBank() return end
    local ok, err = pcall(function()
        GuildCreate()
        F.ApplyLook()
        gOpen = true
        HideBlizzardGuildBank()
        gw:Show()
        GuildRefresh()
    end)
    if not ok then
        B.Print("guild bank window error, using the game's guild bank instead: " .. tostring(err))
        B.db.guildBankReplace = false
        gOpen = false
        local f = _G.GuildBankFrame
        if f then pcall(f.SetParent, f, UIParent) end
    end
end

-- the guild bank window belongs to a load-on-demand add-on that may not exist when the event fires,
-- so hide it again once it is there and also open Baggie's from its own OnShow
local gl = CreateFrame("Frame")
gl:RegisterEvent("ADDON_LOADED")
gl:SetScript("OnEvent", function(_, _, name)
    if name == "Blizzard_GuildBankUI" and _G.GuildBankFrame and B.db then
        _G.GuildBankFrame:HookScript("OnShow", function()
            if B.db.guildBankReplace ~= false and not gOpen then OpenGuild() end
        end)
        hooked = true
        _G.GuildBankFrame:HookScript("OnShow", function(self)
            if gOpen and not InCombatLockdown() then pcall(self.SetParent, self, Hider()) end
        end)
    end
end)

gev:SetScript("OnEvent", function(_, event)
    if not B.db then return end
    if event == "GUILDBANKFRAME_OPENED" then
        if B.db.guildBankReplace == false then return end
        OpenGuild()
        -- the game's window can appear a moment later: put it away again
        C_Timer.After(0.05, function() if gOpen then HideBlizzardGuildBank() end end)
        C_Timer.After(0.4, function() if gOpen then HideBlizzardGuildBank() end end)
    elseif event == "GUILDBANKFRAME_CLOSED" then
        gOpen = false
        if gw and gw:IsShown() then gw:Hide() end
        local f = _G.GuildBankFrame
        if f and not InCombatLockdown() then pcall(f.SetParent, f, UIParent) end
    else
        if gw and gw:IsShown() then SoonGuild() end
    end
end)

function BU.IsOpen() return bankOpen end

function BU.ApplyLook()
    if not B.db then return end
    B.styleVer = (B.styleVer or 0) + 1
    if bw then pcall(B.Scoped, "bank", F.StyleFrame, bw, "Bank") pcall(BankRefresh) end
    if gw then pcall(B.Scoped, "guild", F.StyleFrame, gw, "Guild Bank") pcall(GuildRefresh) end
end
