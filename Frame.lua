-- Baggie window: one frame for the backpack and all bags, with saved spots.
local ADDON_NAME, B = ...
local F = {}
B.Frame = F

local CELL, GAP, PAD, TOP, BOTTOM = 37, 4, 12, 62, 34
local merchantOpen, openedByUs = false, false
local QuietTemplate
local GOLD = { 0.88, 0.69, 0.29 }

local win, bagFrames, buttons, ghosts = nil, {}, {}, {}
local lastCells, lastCount = {}, 0
local editMode, pick = false, nil          -- pick = { itemID=, cell= }
local pending = false
local relayoutAfterCombat = false

local function InCombat() return _G.InCombatLockdown and _G.InCombatLockdown() end

----------------------------------------------------------------------
-- Item names and search
----------------------------------------------------------------------
local function ItemName(link)
    if type(link) ~= "string" then return nil end
    return link:match("%[(.-)%]")
end

local function Matches(text, link)
    if text == "" then return true end
    if not link then return false end
    local name = (ItemName(link) or ""):lower()
    if name:find(text, 1, true) then return true end
    if _G.GetItemInfo then
        local _, _, _, _, _, itype, subtype = _G.GetItemInfo(link)
        if type(itype) == "string" and itype:lower():find(text, 1, true) then return true end
        if type(subtype) == "string" and subtype:lower():find(text, 1, true) then return true end
    end
    return false
end

----------------------------------------------------------------------
-- Visuals for one item button
----------------------------------------------------------------------
local function QualityColor(q)
    if _G.GetItemQualityColor and q then
        local r, g, b = _G.GetItemQualityColor(q)
        if r then return r, g, b end
    end
    local c = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[q or 1]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function SetIcon(btn, tex)
    if _G.SetItemButtonTexture then _G.SetItemButtonTexture(btn, tex)
    elseif type(btn.icon) == "table" then btn.icon:SetTexture(tex) end
end

local function SetDesat(btn, on)
    if _G.SetItemButtonDesaturated then _G.SetItemButtonDesaturated(btn, on)
    elseif type(btn.icon) == "table" and btn.icon.SetDesaturated then btn.icon:SetDesaturated(on) end
end

local function StyleBorder(b, r, g, bl, size)
    size = math.max(1, math.min(4, tonumber(size) or 1))
    local e = b.edges
    for i = 1, 4 do e[i]:SetVertexColor(r, g, bl, 1) end
    if b.sized ~= size then
        b.sized = size
        for i = 1, 4 do e[i]:ClearAllPoints() end
        e[1]:SetPoint("TOPLEFT") e[1]:SetPoint("TOPRIGHT") e[1]:SetHeight(size)
        e[2]:SetPoint("BOTTOMLEFT") e[2]:SetPoint("BOTTOMRIGHT") e[2]:SetHeight(size)
        e[3]:SetPoint("TOPLEFT") e[3]:SetPoint("BOTTOMLEFT") e[3]:SetWidth(size)
        e[4]:SetPoint("TOPRIGHT") e[4]:SetPoint("BOTTOMRIGHT") e[4]:SetWidth(size)
    end
end

local function UpdateButton(btn, text)
    local tex, count, locked, quality, link, id = B.SlotInfo(btn.bag, btn.slot)
    btn.itemID, btn.link = id, link
    pcall(SetIcon, btn, tex)
    pcall(SetDesat, btn, locked and true or false)
    if tex then
        btn.baggieIcon:SetTexture(tex)
        btn.baggieIcon:Show()
        btn.baggieIcon:SetDesaturated(locked and true or false)
    else
        btn.baggieIcon:Hide()
    end
    local n = tonumber(count) or 0
    btn.baggieCount:SetText((tex and n > 1) and tostring(n) or "")
    QuietTemplate(btn)

    local mode = B.db.borderMode
    local sc = B.db.slotColor or B.DEFAULTS.slotColor
    btn.baggieBg:SetVertexColor(sc[1], sc[2], sc[3], 1)
    local show, br, bg, bb = false
    if tex and mode == "quality" and (quality or 0) >= (tonumber(B.db.borderMinQuality) or 2) then
        show = true br, bg, bb = QualityColor(quality)
    elseif (mode == "custom" and tex) or mode == "slots" then
        local c = B.db.borderColor or B.DEFAULTS.borderColor
        show = true br, bg, bb = c[1], c[2], c[3]
    end
    if show then
        StyleBorder(btn.border, br, bg, bb, B.db.borderSize)
        btn.border:Show()
    else
        btn.border:Hide()
    end

    local dim = 1
    if tex and quality == 0 and B.db.junkDim then dim = 0.55 end
    if text ~= "" and not Matches(text, link) then dim = 0.25 end
    btn:SetAlpha(dim)

    local il = ""
    if B.db.ilvl and link and quality and quality >= 2 then
        local ok, lvl = pcall(function()
            if _G.GetDetailedItemLevelInfo then return (_G.GetDetailedItemLevelInfo(link)) end
            return select(4, _G.GetItemInfo(link))
        end)
        local _, _, _, _, _, _, _, _, equipLoc = _G.GetItemInfo and _G.GetItemInfo(link) or nil
        if ok and tonumber(lvl) and lvl > 1 and equipLoc and equipLoc ~= "" then il = tostring(lvl) end
    end
    btn.baggieIlvl:SetText(il)

    local start, dur, enable = B.Cooldown(btn.bag, btn.slot)
    local cd = type(btn.Cooldown) == "table" and btn.Cooldown or (type(btn.cooldown) == "table" and btn.cooldown)
    if cd and _G.CooldownFrame_Set then _G.CooldownFrame_Set(cd, tonumber(start) or 0, tonumber(dur) or 0, tonumber(enable) or 0) end

    -- the little pin mark: this item type has a saved spot
    local pins = B.Pins()
    btn.pinMark:SetShown(B.db.showPinMark and id ~= nil and pins[id] ~= nil)
    if id and pins[id] then
        if tex then pins[id].icon = tex end
        local n = ItemName(link)
        if n then pins[id].name = n end
    end
end

----------------------------------------------------------------------
-- Pinning gestures
----------------------------------------------------------------------
local function ContentAt(c)
    local x = lastCells[c]
    if not x then return nil end
    if x.kind == "ghost" then return x.itemID, "ghost" end
    local s = B.slotsNow and B.slotsNow[x.index]
    return s and s.itemID, "slot"
end

local function PinnedItemAtCell(c)
    for id, p in pairs(B.Pins()) do
        if p.cell == c then return id end
    end
end

function F.CellClick(c, mouse)
    if not c then B.Print("saved spots only work in the main bags, not the reagent bag or keyring.") return end
    local pins = B.Pins()
    local id, kind = ContentAt(c)
    if mouse == "RightButton" then
        local held = PinnedItemAtCell(c)
        if held then
            local name = pins[held].name or "item"
            B.ClearPin(held)
            B.Print("freed the saved spot for " .. name)
            F.Refresh()
        end
        return
    end
    -- left click: save the item that is in this spot, to this spot (click again to free it)
    if not id then B.Print("Alt+click an item to save it to the spot it is in.") return end
    if kind == "ghost" or (pins[id] and pins[id].cell == c) then
        local name = pins[id] and pins[id].name or "item"
        B.ClearPin(id)
        B.Print("freed the saved spot for " .. name)
        F.Refresh()
        return
    end
    local icon, name
    for _, s in ipairs(B.slotsNow or {}) do
        if s.itemID == id then
            local tex = B.SlotInfo(s.bag, s.slot)
            icon, name = tex, ItemName(s.link) break
        end
    end
    local holder = PinnedItemAtCell(c)
    if holder and holder ~= id then
        B.Print("that spot is saved for " .. (pins[holder].name or "another item") .. ". Alt+click its empty spot to free it first.")
        return
    end
    B.Layout.Place(pins, id, c)
    if icon then pins[id].icon = icon end
    if name then pins[id].name = name end
    B.Print("saved " .. (name or "item") .. " to this spot")
    F.Refresh()
end

-- Pinning clicks are caught by Baggie's own transparent overlay, shown only while Alt is held
-- or Pin mode is on. The game's item buttons are never touched, so using, equipping and
-- dragging items stay untainted.
local overlays = {}
local function Wrap(btn)
    local o = CreateFrame("Button", nil, btn)
    o:SetAllPoints(btn)
    o:SetFrameLevel((btn:GetFrameLevel() or 1) + 8)
    o:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    o:SetScript("OnClick", function(_, mouse) F.CellClick(btn.cell, mouse) end)
    o:Hide()
    o.owner = btn
    btn.overlay = o
    overlays[#overlays + 1] = o
end

function F.UpdateOverlays()
    if InCombat() then return end
    local on = editMode or (_G.IsAltKeyDown and _G.IsAltKeyDown()) and true or false
    for _, o in ipairs(overlays) do
        local p = o.owner
        o:SetShown(on and p:IsShown())
    end
end

----------------------------------------------------------------------
-- Building the cell pieces
----------------------------------------------------------------------
local function MakeBagFrame(bag)
    if bagFrames[bag] then return bagFrames[bag] end
    local f = CreateFrame("Frame", "BaggieBag" .. (bag < 0 and ("K" .. -bag) or bag), win)
    f:SetID(bag)
    f:SetAllPoints(win)
    bagFrames[bag] = f
    return f
end

local TEMPLATE_GLOWS = { "NewItemTexture", "BattlepayItemTexture", "IconOverlay", "IconOverlay2", "IconBorder",
    "UpgradeIcon", "JunkIcon", "ItemContextOverlay", "searchOverlay", "ExtendedSlot", "flash" }
QuietTemplate = function(btn)
    -- the template's own stack count would sit under Baggie's, so keep it hidden
    local nm = btn.GetName and btn:GetName()
    for _, c in ipairs({ btn.Count, btn.count, nm and _G[nm .. "Count"] }) do
        if type(c) == "table" and c.Hide then c:SetText("") c:Hide() end
    end
    for _, k in ipairs(TEMPLATE_GLOWS) do
        local t = btn[k]
        if type(t) == "table" then
            if t.SetAlpha then t:SetAlpha(0) end
            if t.Hide then t:Hide() end
        end
    end
    for _, k in ipairs({ "flashAnim", "newitemglowAnim" }) do
        local a = btn[k]
        if type(a) == "table" and a.Stop then a:Stop() end
    end
end

local function Decorate(btn)
    -- the game's template paints its own glows (new-item flash, quality, junk, upgrade); Baggie draws its own
    for _, r in ipairs({ btn:GetRegions() }) do
        if type(r) == "table" and r.SetAlpha then r:SetAlpha(0) if r.Hide then r:Hide() end end
    end
    QuietTemplate(btn)
    -- Baggie draws its own slot, icon and count so it never depends on the template's helpers
    btn.baggieBg = btn:CreateTexture(nil, "BACKGROUND")
    btn.baggieBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    btn.baggieBg:SetVertexColor(0.13, 0.13, 0.16, 1)
    btn.baggieBg:SetAllPoints(btn)

    btn.baggieIcon = btn:CreateTexture(nil, "ARTWORK", nil, 2)
    btn.baggieIcon:SetPoint("TOPLEFT", 2, -2)
    btn.baggieIcon:SetPoint("BOTTOMRIGHT", -2, 2)
    btn.baggieIcon:Hide()

    btn.baggieCount = btn:CreateFontString(nil, "OVERLAY")
    btn.baggieCount:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    btn.baggieCount:SetPoint("BOTTOMRIGHT", -3, 3)
    btn.baggieCount:SetTextColor(1, 1, 1)

    btn.baggieIlvl = btn:CreateFontString(nil, "OVERLAY")
    btn.baggieIlvl:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    btn.baggieIlvl:SetPoint("TOPRIGHT", -2, -3)
    btn.baggieIlvl:SetTextColor(1, 0.9, 0.5)

    btn.border = CreateFrame("Frame", nil, btn)
    btn.border:SetAllPoints(btn)
    btn.border:SetFrameLevel((btn:GetFrameLevel() or 1) + 2)
    btn.border.edges = {}
    for i = 1, 4 do
        local t = btn.border:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        btn.border.edges[i] = t
    end
    btn.border:Hide()

    btn.pinMark = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    btn.pinMark:SetTexture("Interface\\Buttons\\WHITE8X8")
    btn.pinMark:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
    btn.pinMark:SetSize(7, 7)
    btn.pinMark:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    btn.pinMark:Hide()

    btn.pickGlow = btn:CreateTexture(nil, "OVERLAY", nil, 6)
    btn.pickGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    btn.pickGlow:SetVertexColor(0.3, 0.9, 1, 0.45)
    btn.pickGlow:SetAllPoints(btn)
    btn.pickGlow:Hide()
end

local function GetButton(bag, slot)
    local key = bag .. ":" .. slot
    local btn = buttons[key]
    if btn then return btn end
    local parent = MakeBagFrame(bag)
    local name = ("BaggieItem%s_%d"):format(bag < 0 and ("K" .. -bag) or bag, slot)
    local used = "ContainerFrameItemButtonTemplate"
    -- Same frame type the game's own bags use ("ItemButton"): with a plain "Button" the template's
    -- click handler runs on a frame it does not expect, and using a spell item (soul stone,
    -- grimoire) was blocked as a tainted action.
    local ok, made = pcall(CreateFrame, "ItemButton", name, parent, used)
    if not ok or not made then ok, made = pcall(CreateFrame, "Button", name, parent, used) end
    if not ok or not made then
        used = "ItemButtonTemplate"
        ok, made = pcall(CreateFrame, "Button", name, parent, used)
    end
    if not ok or not made then used = "none (plain button)" made = CreateFrame("Button", name, parent) end
    btn = made
    btn.baggieTemplate = used
    btn:SetID(slot)
    btn:SetSize(CELL, CELL)
    btn.bag, btn.slot = bag, slot
    Decorate(btn)
    Wrap(btn)
    buttons[key] = btn
    return btn
end

local function GetGhost(c)
    local g = ghosts[c]
    if g then return g end
    g = CreateFrame("Button", "BaggieGhost" .. c, win)
    g:SetSize(CELL, CELL)
    g.bg = g:CreateTexture(nil, "BACKGROUND")
    g.bg:SetAllPoints(g)
    g.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    g.bg:SetVertexColor(0.1, 0.09, 0.05, 0.8)
    g.icon = g:CreateTexture(nil, "ARTWORK")
    g.icon:SetPoint("TOPLEFT", 3, -3) g.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    g.icon:SetAlpha(0.35)
    g.frameEdge = g:CreateTexture(nil, "BORDER")
    g.frameEdge:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    g.frameEdge:SetPoint("TOPLEFT", -10, 10) g.frameEdge:SetPoint("BOTTOMRIGHT", 10, -10)
    g.frameEdge:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.8)
    g.pinMark = g:CreateTexture(nil, "OVERLAY")
    g.pinMark:SetTexture("Interface\\Buttons\\WHITE8X8")
    g.pinMark:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
    g.pinMark:SetSize(7, 7) g.pinMark:SetPoint("TOPLEFT", 1, -1)
    g.pickGlow = g:CreateTexture(nil, "OVERLAY", nil, 6)
    g.pickGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    g.pickGlow:SetVertexColor(0.3, 0.9, 1, 0.45)
    g.pickGlow:SetAllPoints(g)
    g.pickGlow:Hide()
    g:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    g:SetScript("OnClick", function(self, mouse)
        if editMode or (_G.IsAltKeyDown and _G.IsAltKeyDown()) then
            F.CellClick(self.cell, mouse)
        elseif mouse == "LeftButton" and _G.CursorHasItem and _G.CursorHasItem() then
            -- drop what you are carrying into the first empty real slot
            for _, s in ipairs(B.slotsNow or {}) do
                if not s.itemID then B.Pickup(s.bag, s.slot) return end
            end
            B.Print("no free bag slot")
        elseif mouse == "RightButton" then
            F.CellClick(self.cell, mouse)
        end
    end)
    g:SetScript("OnEnter", function(self)
        if not _G.GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.name or "Saved spot", GOLD[1], GOLD[2], GOLD[3])
        GameTooltip:AddLine("Saved spot. Drop one here and it sits here.", 1, 1, 1, true)
        GameTooltip:AddLine("Alt+click to free this spot.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    g:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
    ghosts[c] = g
    return g
end

----------------------------------------------------------------------
-- Layout and refresh
----------------------------------------------------------------------
local function CellPosition(c)
    local cols = B.db.cols
    local col = (c - 1) % cols
    local row = math.floor((c - 1) / cols)
    return PAD + col * (CELL + GAP), -(TOP + row * (CELL + GAP))
end

local sectionHeaders = {}

-- reagent bag and keyring: their own labeled grids under the main bags, in real order
local function PlaceSections(startY, inset)
    for _, h in pairs(sectionHeaders) do h.text:Hide() h.line:Hide() end
    local y = startY
    for _, sec in ipairs(B.ExtraSections()) do
        y = y + 8
        if B.db.sectionLabels then
            local h = sectionHeaders[sec.key]
            if not h then
                h = { text = win:CreateFontString(nil, "OVERLAY"), line = win:CreateTexture(nil, "ARTWORK") }
                h.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                h.line:SetTexture("Interface\\Buttons\\WHITE8X8")
                sectionHeaders[sec.key] = h
            end
            local e = B.db.edgeColor or B.DEFAULTS.edgeColor
            h.text:SetTextColor(e[1], e[2], e[3])
            h.text:SetText(sec.title)
            h.text:ClearAllPoints() h.text:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -y)
            h.line:SetVertexColor(e[1], e[2], e[3], 0.5)
            h.line:ClearAllPoints()
            h.line:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -(y - 14))
            h.line:SetPoint("TOPRIGHT", win, "TOPRIGHT", -PAD, -(y - 14))
            h.line:SetHeight(1)
            h.text:Show() h.line:Show()
            y = y + 18
        end
        local n = 0
        for _, bag in ipairs(sec.bags) do
            for slot = 1, B.NumSlots(bag) do
                local btn = GetButton(bag, slot)
                local col, row = n % B.db.cols, math.floor(n / B.db.cols)
                n = n + 1
                btn.cell = nil
                btn:SetSize(CELL, CELL)
                if btn.inset ~= inset then
                    btn.inset = inset
                    btn.baggieIcon:ClearAllPoints()
                    btn.baggieIcon:SetPoint("TOPLEFT", inset, -inset)
                    btn.baggieIcon:SetPoint("BOTTOMRIGHT", -inset, inset)
                end
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + col * (CELL + GAP), -(y + row * (CELL + GAP)))
                btn:Show()
            end
        end
        y = y + math.ceil(n / B.db.cols) * (CELL + GAP) - GAP
    end
    return y
end

local function Relayout(slots, text)
    local pins = B.Pins()
    CELL = math.max(24, math.min(56, tonumber(B.db.cellSize) or 37))
    GAP = math.max(0, math.min(16, tonumber(B.db.gap) or 4))
    PAD = math.max(4, math.min(30, tonumber(B.db.padding) or 12))
    local inset = math.max(0, math.min(10, tonumber(B.db.iconInset) or 2))
    -- a new item only goes to the top-most gap when it came from outside (loot, mail, a vendor), not
    -- while you are moving things around yourself
    local now = _G.GetTime and _G.GetTime() or 0
    if _G.GetCursorInfo and _G.GetCursorInfo() then B.lastCursor = now end
    local allowMove = not (B.lastCursor and now - B.lastCursor < 1.5)
    B.gapState = B.gapState or {}
    local cells, count = B.Layout.Build(slots, pins, B.db.layout, B.gapState, allowMove)
    lastCells, lastCount = cells, count
    B.slotsNow = slots

    for _, b in pairs(buttons) do b.cell = nil b:Hide() b.pickGlow:Hide() end
    for _, g in pairs(ghosts) do g.cell = nil g:Hide() end

    for c = 1, count do
        local x = cells[c]
        local px, py = CellPosition(c)
        if x and x.kind == "slot" then
            local s = slots[x.index]
            local btn = GetButton(s.bag, s.slot)
            btn.cell = c
            btn:SetSize(CELL, CELL)
            if btn.inset ~= inset then
                btn.inset = inset
                btn.baggieIcon:ClearAllPoints()
                btn.baggieIcon:SetPoint("TOPLEFT", inset, -inset)
                btn.baggieIcon:SetPoint("BOTTOMRIGHT", -inset, inset)
            end
                        btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", win, "TOPLEFT", px, py)
            btn:Show()
            if pick and pick.cell == c then btn.pickGlow:Show() end
        elseif x and x.kind == "ghost" then
            local g = GetGhost(c)
            local p = pins[x.itemID] or {}
            g.cell = c
            g:SetSize(CELL, CELL)
            g.icon:SetAlpha(tonumber(B.db.ghostAlpha) or 0.35)
            g.name = p.name
            g.icon:SetTexture(p.icon)
            g.pickGlow:SetShown(pick ~= nil and pick.cell == c)
            g:ClearAllPoints()
            g:SetPoint("TOPLEFT", win, "TOPLEFT", px, py)
            g:Show()
        end
    end

    F.UpdateOverlays()
    local rows = math.max(1, math.ceil(count / B.db.cols))
    local bottom = BOTTOM + (B.db.showBags and 30 or 0)
    local endY = PlaceSections(TOP + rows * (CELL + GAP) - GAP, inset)
    win:SetSize(PAD * 2 + B.db.cols * (CELL + GAP) - GAP, endY + bottom)
end

local function Footer(slots)
    local free, total = 0, #slots
    for _, s in ipairs(slots) do if not s.itemID then free = free + 1 end end
    local cm = B.db.counterMode
    if cm == "free" then win.free:SetText(("%d free of %d"):format(free, total))
    elseif cm == "freeonly" then win.free:SetText(("%d free"):format(free))
    else win.free:SetText(("%d / %d"):format(total - free, total)) end
    win.free:SetShown(B.db.showFooter and cm ~= "none")

    local money = _G.GetMoney and _G.GetMoney() or 0
    local gm = B.db.goldMode
    local g, s, c = math.floor(money / 10000), math.floor(money / 100) % 100, money % 100
    local text
    if gm == "gold" then
        text = tostring(g):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") .. "|cffffd700g|r"
    elseif gm == "icons" and _G.GetCoinTextureString then
        text = _G.GetCoinTextureString(money)
    else
        text = ("|cffffd700%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r"):format(g, s, c)
    end
    win.money:SetText(text)
    win.money:SetShown(B.db.showFooter and gm ~= "none")
    win.hint:Hide()
    F.UpdateBagBar()
end

function F.UpdateBagBar()
    if not win or not win.bagBar then return end
    win.bagBar:SetShown(B.db.showBags and true or false)
    if not B.db.showBags then return end
    for _, b in ipairs(win.bagBtns) do
        local inv = B.BagInvID(b.bag)
        local tex = inv and _G.GetInventoryItemTexture and _G.GetInventoryItemTexture("player", inv)
        if tex then
            b.icon:SetTexture(tex) b.icon:SetVertexColor(1, 1, 1, 1) b.icon:Show()
        else
            b.icon:Hide()
        end
    end
end

function F.Refresh()
    if not win or not B.db then return end
    if not win:IsShown() then return end
    local text = (win.search:GetText() or ""):lower()
    local slots = B.ScanSlots()
    if InCombat() then
        -- only refresh pictures in combat; moving buttons waits
        for _, b in pairs(buttons) do if b:IsShown() then UpdateButton(b, text) end end
        relayoutAfterCombat = true
        Footer(B.slotsNow or slots)
        return
    end
    Relayout(slots, text)
    for _, b in pairs(buttons) do if b:IsShown() then UpdateButton(b, text) end end
    Footer(slots)
end

local function Schedule()
    if pending then return end
    pending = true
    C_Timer.After(0.05, function()
        pending = false
        F.Refresh()
    end)
end
F.Schedule = Schedule

----------------------------------------------------------------------
-- The window
----------------------------------------------------------------------
local function SavePosition()
    local p, _, rp, x, y = win:GetPoint()
    if p then B.db.point = { p, rp, x, y } end
end

local function RestorePosition()
    win:ClearAllPoints()
    local pt = B.db.point
    if type(pt) == "table" and pt[1] then
        win:SetPoint(pt[1], UIParent, pt[2] or pt[1], tonumber(pt[3]) or 0, tonumber(pt[4]) or 0)
    else
        win:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -60, 110)
    end
end

function F.ResetPosition() if win then RestorePosition() end end
function F.ApplyLook()
    if not win or not B.db then return end
    local bg, edge, tc = B.db.bgColor or B.DEFAULTS.bgColor, B.db.edgeColor or B.DEFAULTS.edgeColor, B.db.titleColor or B.DEFAULTS.titleColor
    win:SetBackdropColor(bg[1], bg[2], bg[3], tonumber(B.db.alpha) or 0.96)
    win:SetBackdropBorderColor(edge[1], edge[2], edge[3], 0.95)
    win.bar:SetVertexColor(tc[1], tc[2], tc[3], 1)
    win.title:SetTextColor(edge[1], edge[2], edge[3])
    local fs = tonumber(B.db.footerSize) or 11
    win.free:SetFont("Fonts\\FRIZQT__.TTF", fs, "")
    win.money:SetFont("Fonts\\FRIZQT__.TTF", fs, "")
    win.search:SetShown(B.db.showSearch)
    win.searchLabel:SetShown(B.db.showSearch)
    win.sortBtn:SetShown(B.db.showSort and true or false)
    win.sellBtn:SetShown(B.db.sellButton and merchantOpen)
    F.ApplyScale()
end

function F.ApplyScale() if win then win:SetScale(B.db.scale or 1) end end

local function Label(parent, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    fs:SetTextColor(r or 1, g or 1, b or 1)
    return fs
end

local function Button(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 20)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Create()
    if win then return end
    win = CreateFrame("Frame", "BaggieFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    B.window = win
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)   -- clicking raises the window with all its contents above other addon windows
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self) if not B.db.lockPos then self:StartMoving() end end)
    win:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() SavePosition() end)
    win:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    win:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
    win:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9)

    local bar = win:CreateTexture(nil, "ARTWORK")
    win.bar = bar
    bar:SetTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetVertexColor(0.13, 0.11, 0.07, 1)
    bar:SetPoint("TOPLEFT", 1, -1) bar:SetPoint("TOPRIGHT", -1, -1) bar:SetHeight(26)

    local title = Label(win, 14, GOLD[1], GOLD[2], GOLD[3])
    win.title = title
    title:SetFont("Fonts\\MORPHEUS.TTF", 15, "")
    title:SetPoint("TOPLEFT", 12, -7)
    title:SetText("Baggie")

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 1)
    close:SetScript("OnClick", function() F.Close() end)

    win.search = CreateFrame("EditBox", "BaggieSearch", win, "InputBoxTemplate")
    win.search:SetSize(120, 18)
    win.search:SetPoint("TOPRIGHT", -34, -5)
    win.search:SetAutoFocus(false)
    win.search:SetScript("OnTextChanged", function() Schedule() end)
    win.search:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    win.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    win.searchLabel = Label(win, 11, 0.8, 0.8, 0.8)
    win.searchLabel:SetPoint("RIGHT", win.search, "LEFT", -6, 0)
    win.searchLabel:SetText("Search:")

    win.sortBtn = Button(win, "Sort", 46, function()
        local ok, err = pcall(B.SortBags)
        if not ok then B.Say("sort error: " .. tostring(err)) end
    end)
    win.sortBtn:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -33)

    win.sellBtn = Button(win, "Sell junk", 62, function() F.SellJunk() end)
    win.sellBtn:SetPoint("LEFT", win.sortBtn, "RIGHT", 4, 0)
    win.sellBtn:Hide()

    win.gear = Button(win, "Options", 54, function() B.Options.Toggle() end)
    win.gear:SetPoint("TOPRIGHT", win, "TOPRIGHT", -26, -4)
    win.search:ClearAllPoints()
    win.search:SetPoint("TOPRIGHT", win, "TOPRIGHT", -34, -33)

    win.hint = Label(win, 10, 0.5, 0.85, 1)
    win.hint:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -50)
    win.hint:Hide()

    -- the equipped bag slots
    win.bagBar = CreateFrame("Frame", nil, win)
    win.bagBar:SetSize(190, 26)
    win.bagBar:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 30)
    win.bagBtns = {}
    for i = 1, tonumber(_G.NUM_BAG_SLOTS) or 4 do
        local b = CreateFrame("Button", nil, win.bagBar)
        b:SetSize(26, 26)
        b:SetPoint("LEFT", win.bagBar, "LEFT", (i - 1) * 30, 0)
        b.bag = i
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints(b)
        b.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        b.bg:SetVertexColor(0.13, 0.13, 0.16, 1)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetPoint("TOPLEFT", 2, -2) b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        b:RegisterForClicks("LeftButtonUp")
        b:SetScript("OnClick", function(self)
            local inv = B.BagInvID(self.bag)
            if not inv or InCombat() then return end
            if _G.CursorHasItem and _G.CursorHasItem() then
                if _G.PutItemInBag then _G.PutItemInBag(inv) end
            elseif _G.PickupBagFromSlot then _G.PickupBagFromSlot(inv) end
        end)
        b:SetScript("OnEnter", function(self)
            if not _G.GameTooltip then return end
            local inv = B.BagInvID(self.bag)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if inv and _G.GetInventoryItemLink and _G.GetInventoryItemLink("player", inv) then
                GameTooltip:SetInventoryItem("player", inv)
            else
                GameTooltip:AddLine("Empty bag slot", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Drop a bag here to equip it.", 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
        win.bagBtns[i] = b
    end

    local rb = B.ReagentBagID()
    if rb then
        local last = win.bagBtns[#win.bagBtns]
        local b = CreateFrame("Button", nil, win.bagBar)
        b:SetSize(26, 26)
        b:SetPoint("LEFT", last, "RIGHT", 14, 0)
        b.bag = rb
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints(b)
        b.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        b.bg:SetVertexColor(0.13, 0.13, 0.16, 1)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetPoint("TOPLEFT", 2, -2) b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        b:RegisterForClicks("LeftButtonUp")
        b:SetScript("OnClick", last:GetScript("OnClick"))
        b:SetScript("OnEnter", last:GetScript("OnEnter"))
        b:SetScript("OnLeave", last:GetScript("OnLeave"))
        win.bagBtns[#win.bagBtns + 1] = b
    end

    win.free = Label(win, 11, 0.8, 0.8, 0.8)
    win.free:SetPoint("BOTTOMLEFT", PAD, 10)
    win.money = Label(win, 11, 1, 0.85, 0.4)
    win.money:SetPoint("BOTTOMRIGHT", -PAD, 10)

    win:SetScript("OnShow", function() F.Refresh() end)
    win:SetScript("OnHide", function() editMode, pick = false, nil F.UpdateOverlays() end)
    table.insert(_G.UISpecialFrames, "BaggieFrame")
    win:Hide()
end

function F.SellJunk()
    if not merchantOpen then return end
    local c = _G.C_Container
    local n = 0
    for _, s in ipairs(B.ScanSlots()) do
        local _, _, locked, quality, link = B.SlotInfo(s.bag, s.slot)
        if link and quality == 0 and not locked then
            if c and c.UseContainerItem then c.UseContainerItem(s.bag, s.slot)
            elseif _G.UseContainerItem then _G.UseContainerItem(s.bag, s.slot) end
            n = n + 1
        end
    end
    B.Print(n > 0 and ("sold " .. n .. " grey item stack(s)") or "no grey items to sell")
end

function F.Debug()
    local function T(v) return tostring(v) end
    local P = B.Print
    local c = _G.C_Container
    P("api: C_Container=" .. T(c ~= nil) .. " GetContainerItemInfo(new)=" .. T(c and c.GetContainerItemInfo ~= nil)
      .. " GetContainerItemInfo(old)=" .. T(_G.GetContainerItemInfo ~= nil))
    local ids = B.BagIDs()
    local parts = {}
    for _, bag in ipairs(ids) do parts[#parts + 1] = bag .. "=" .. B.NumSlots(bag) end
    P("bag sizes: " .. table.concat(parts, " ") .. "  (NUM_BAG_SLOTS=" .. T(_G.NUM_BAG_SLOTS) .. ")")
    local K = _G.KEYRING_CONTAINER or -2
    P(("keyring: container %s slots %d  GetKeyRingSize=%s  enabled=%s"):format(T(K), B.NumSlots(K),
      T(_G.GetKeyRingSize and _G.GetKeyRingSize() or "n/a"), T(B.db.keyring)))
    local slots = B.ScanSlots()
    local items = 0
    for _, s in ipairs(slots) do if s.itemID then items = items + 1 end end
    P(("slots %d, with items %d, cells %d, window %s"):format(#slots, items, lastCount,
      win and (T(win:GetWidth()) .. "x" .. T(win:GetHeight()) .. " scale " .. T(win:GetScale())) or "none"))
    -- the first slot that holds an item, raw
    for _, s in ipairs(slots) do
        if s.itemID then
            local raw
            if c and c.GetContainerItemInfo then raw = c.GetContainerItemInfo(s.bag, s.slot) end
            P(("first item: bag %d slot %d id %d  raw type=%s"):format(s.bag, s.slot, s.itemID, type(raw)))
            if type(raw) == "table" then
                local keys = {}
                for k, v in pairs(raw) do keys[#keys + 1] = k .. "=" .. T(v) end
                table.sort(keys)
                P("  fields: " .. table.concat(keys, ", "))
            end
            local btn = buttons[s.bag .. ":" .. s.slot]
            if btn then
                local pt, _, rp, x, y = btn:GetPoint()
                P(("  button: shown=%s cell=%s size=%sx%s alpha=%s level=%s point=%s %s %s"):format(
                    T(btn:IsShown()), T(btn.cell), T(btn:GetWidth()), T(btn:GetHeight()),
                    T(btn:GetAlpha()), T(btn:GetFrameLevel()), T(pt), T(x), T(y)))
                P(("  icon: shown=%s texture=%s  template=%s"):format(T(btn.baggieIcon:IsShown()),
                    T(btn.baggieIcon:GetTexture()), T(btn.baggieTemplate)))
            else
                P("  no button was made for this slot")
            end
            break
        end
    end
    if win then P(("window: shown=%s strata=%s level=%s alpha=%s"):format(T(win:IsShown()),
        T(win:GetFrameStrata()), T(win:GetFrameLevel()), T(win:GetAlpha()))) end
end

function F.Open()
    if not win then return end
    if not win:IsShown() then win:Show() else F.Refresh() end
end
function F.Close() if win and win:IsShown() then win:Hide() end end
function F.Toggle()
    if not win then return end
    if win:IsShown() then win:Hide() else win:Show() end
end

----------------------------------------------------------------------
-- Taking over the default bag buttons and keys
----------------------------------------------------------------------
-- The game's bag functions are never replaced (that taints them, and a tainted bag function in the
-- game's call chain blocks right-click use of spell items). They are hooked instead: the game's own
-- bag frames are moved into a hidden holder and Baggie opens, closes or toggles its window.
local hooked = false
local blizzHidden
local lastToggle = 0

local function HideBlizzardBags()
    if InCombat() then return end
    if not blizzHidden then
        blizzHidden = CreateFrame("Frame")
        blizzHidden:Hide()
    end
    for i = 1, 13 do
        local f = _G["ContainerFrame" .. i]
        if f then pcall(f.SetParent, f, blizzHidden) end
    end
    if _G.ContainerFrameCombinedBags then pcall(_G.ContainerFrameCombinedBags.SetParent, _G.ContainerFrameCombinedBags, blizzHidden) end
end

local function Hook(name, fn)
    if type(_G[name]) == "function" then hooksecurefunc(name, fn) end
end

local function RestoreBlizzardBags()
    if InCombat() or not blizzHidden then return end
    local home = _G.ContainerFrameContainer or UIParent
    for i = 1, 13 do
        local f = _G["ContainerFrame" .. i]
        if f then pcall(f.SetParent, f, home) end
    end
    if _G.ContainerFrameCombinedBags then pcall(_G.ContainerFrameCombinedBags.SetParent, _G.ContainerFrameCombinedBags, home) end
end

function F.ApplyOverrides()
    if not B.db.enabled then RestoreBlizzardBags() return end
    if not hooked then
        hooked = true
        local function onToggle()
            if not B.db.enabled then return end
            local now = GetTime()
            if now == lastToggle then return end   -- one key press can reach two of the game's toggles
            lastToggle = now
            F.Toggle()
            HideBlizzardBags()
        end
        local function onOpen() if B.db.enabled then F.Open() HideBlizzardBags() end end
        local function onClose() if B.db.enabled then F.Close() end end
        Hook("ToggleBackpack", onToggle)
        Hook("ToggleBag", onToggle)
        Hook("ToggleAllBags", onToggle)
        Hook("OpenAllBags", onOpen)
        Hook("OpenBackpack", onOpen)
        Hook("OpenBag", onOpen)
        Hook("CloseAllBags", onClose)
        Hook("CloseBackpack", onClose)
    end
    HideBlizzardBags()
end

function F.Setup()
    Create()
    F.ApplyLook()
    RestorePosition()
    F.ApplyOverrides()
end

for _, e in ipairs({ "BAG_UPDATE", "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "ITEM_LOCK_CHANGED",
                     "PLAYER_MONEY", "BAG_NEW_ITEMS_UPDATED", "UNIT_INVENTORY_CHANGED" }) do
    B.On(e, B.Safe(e, function() if win and win:IsShown() then Schedule() end end))
end
B.On("PLAYER_REGEN_ENABLED", B.Safe("regen", function()
    if relayoutAfterCombat then relayoutAfterCombat = false F.Refresh() end
end))
B.On("PLAYER_ENTERING_WORLD", B.Safe("enter", function() if win then F.ApplyOverrides() end end))

-- vendor / mail / auction house / bank: open on arrival, close on leaving
local function Arrive(isMerchant)
    if not win or not B.db or not B.db.enabled then return end
    if isMerchant then
        merchantOpen = true
        win.sellBtn:SetShown(B.db.sellButton)
    end
    if B.db.autoOpen and not win:IsShown() then openedByUs = true win:Show() end
    if isMerchant and B.db.autoSell then F.SellJunk() end
end
local function Leave(isMerchant)
    if not win then return end
    if isMerchant then merchantOpen = false win.sellBtn:Hide() end
    if openedByUs and win:IsShown() then win:Hide() end
    openedByUs = false
end
B.On("MERCHANT_SHOW", B.Safe("merchant", function() Arrive(true) end))
B.On("MERCHANT_CLOSED", B.Safe("merchantx", function() Leave(true) end))
B.On("MAIL_SHOW", B.Safe("mail", function() Arrive(false) end))
B.On("MAIL_CLOSED", B.Safe("mailx", function() Leave(false) end))
B.On("BANKFRAME_OPENED", B.Safe("bank", function() Arrive(false) end))
B.On("BANKFRAME_CLOSED", B.Safe("bankx", function() Leave(false) end))
B.On("AUCTION_HOUSE_SHOW", B.Safe("ah", function() Arrive(false) end))
B.On("AUCTION_HOUSE_CLOSED", B.Safe("ahx", function() Leave(false) end))

B.On("MODIFIER_STATE_CHANGED", B.Safe("mod", function() if win and win:IsShown() then F.UpdateOverlays() end end))
B.On("ADDON_ACTION_BLOCKED", function(addon, func)
    if addon == ADDON_NAME and B.db then
        B.db.blocked = B.db.blocked or {}
        B.db.blocked[tostring(func)] = (B.db.blocked[tostring(func)] or 0) + 1
        local kind = "?"
        for _, b in pairs(buttons) do if b.baggieTemplate then kind = b:GetObjectType() .. "/" .. b.baggieTemplate break end end
        B.Print("the game blocked: " .. tostring(func) .. " [" .. kind .. "] (please send me this)")
    end
end)
