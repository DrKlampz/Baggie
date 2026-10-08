-- Baggie options window: layout, sizes, colors, borders, footer, vendor helpers.
local ADDON_NAME, B = ...
local O = {}
B.Options = O
local GOLD = { 0.88, 0.69, 0.29 }
local win

local PRESETS = {
    gold     = { name = "Dark gold",     bg = { 0.05, 0.05, 0.07 }, edge = { 0.88, 0.69, 0.29 }, title = { 0.13, 0.11, 0.07 }, slot = { 0.13, 0.13, 0.16 } },
    midnight = { name = "Midnight blue", bg = { 0.04, 0.06, 0.12 }, edge = { 0.35, 0.55, 0.95 }, title = { 0.08, 0.12, 0.24 }, slot = { 0.10, 0.14, 0.24 } },
    slate    = { name = "Slate",         bg = { 0.10, 0.10, 0.11 }, edge = { 0.60, 0.60, 0.65 }, title = { 0.17, 0.17, 0.19 }, slot = { 0.17, 0.17, 0.19 } },
    forest   = { name = "Forest",        bg = { 0.04, 0.09, 0.06 }, edge = { 0.45, 0.80, 0.40 }, title = { 0.08, 0.16, 0.10 }, slot = { 0.09, 0.17, 0.12 } },
    crimson  = { name = "Crimson",       bg = { 0.09, 0.04, 0.05 }, edge = { 0.85, 0.25, 0.30 }, title = { 0.20, 0.07, 0.09 }, slot = { 0.17, 0.09, 0.10 } },
    light    = { name = "Parchment",     bg = { 0.85, 0.82, 0.75 }, edge = { 0.45, 0.35, 0.20 }, title = { 0.70, 0.64, 0.50 }, slot = { 0.70, 0.66, 0.58 } },
}
local PRESET_ORDER = { "gold", "midnight", "slate", "forest", "crimson", "light" }
O.PRESETS = PRESETS

local function Copy(t) return { t[1], t[2], t[3] } end

function O.ApplyPreset(id)
    local p = PRESETS[id]
    if not p then return end
    B.db.preset = id
    B.db.bgColor, B.db.edgeColor = Copy(p.bg), Copy(p.edge)
    B.db.titleColor, B.db.slotColor = Copy(p.title), Copy(p.slot)
end

-- kind: check | slider | cycle | color
local ROWS = {
    { h = "Layout" },
    { key = "layout", kind = "cycle", label = "Item layout", values = { "real", "compact" },
      names = { real = "Bag order (nothing moves)", compact = "Compact (items first)" } },
    { key = "cols", kind = "slider", label = "Columns", min = 4, max = 24, step = 1 },
    { key = "scale", kind = "slider", label = "Window scale", min = 0.6, max = 1.6, step = 0.05, fmt = "%.2f" },
    { key = "cellSize", kind = "slider", label = "Slot size", min = 28, max = 56, step = 1 },
    { key = "iconInset", kind = "slider", label = "Icon padding inside slot", min = 0, max = 10, step = 1 },
    { key = "gap", kind = "slider", label = "Space between slots", min = 0, max = 16, step = 1 },
    { key = "padding", kind = "slider", label = "Window padding", min = 4, max = 30, step = 1 },

    { h = "Colors" },
    { key = "preset", kind = "cycle", label = "Theme", values = PRESET_ORDER, preset = true },
    { key = "bgColor", kind = "color", label = "Window background" },
    { key = "alpha", kind = "slider", label = "Background opacity", min = 0.2, max = 1, step = 0.02, fmt = "%.2f" },
    { key = "edgeColor", kind = "color", label = "Window border and title" },
    { key = "titleColor", kind = "color", label = "Title bar" },
    { key = "slotColor", kind = "color", label = "Slot background" },

    { h = "Item borders" },
    { key = "borderMode", kind = "cycle", label = "Border style", values = { "quality", "custom", "slots", "none" },
      names = { quality = "By item quality", custom = "One color, items only", slots = "One color, every slot", none = "None" } },
    { key = "borderColor", kind = "color", label = "Border color (one-color styles)" },
    { key = "borderSize", kind = "slider", label = "Border thickness", min = 1, max = 4, step = 1 },
    { key = "borderMinQuality", kind = "slider", label = "Quality borders start at (2 = green)", min = 0, max = 5, step = 1 },

    { h = "Items" },
    { key = "junkDim", kind = "check", label = "Dim grey items" },
    { key = "ilvl", kind = "check", label = "Show item level on gear" },
    { key = "keyring", kind = "check", label = "Show keyring (if this character has one)" },

    { h = "Saved spots" },
    { key = "showPinMark", kind = "check", label = "Gold mark on saved items" },
    { key = "ghostAlpha", kind = "slider", label = "Empty saved spot opacity", min = 0.1, max = 0.9, step = 0.05, fmt = "%.2f" },
    { key = "sharedPins", kind = "check", label = "Share saved spots across characters" },

    { h = "Window" },
    { key = "showBags", kind = "check", label = "Show bags (your equipped bag slots)" },
    { key = "showSearch", kind = "check", label = "Search box" },
    { key = "showSort", kind = "check", label = "Sort button (only sorts when clicked)" },
    { key = "lockPos", kind = "check", label = "Lock window position" },
    { key = "showFooter", kind = "check", label = "Show the bottom line (slots and gold)" },
    { key = "counterMode", kind = "cycle", label = "Slot counter", values = { "used", "free", "freeonly", "none" },
      names = { used = "Used / total  (32 / 60)", free = "Free of total  (28 free of 60)", freeonly = "Free only  (28 free)", none = "Hidden" } },
    { key = "goldMode", kind = "cycle", label = "Gold display", values = { "icons", "text", "gold", "none" },
      names = { icons = "Coin icons", text = "Colored 12g 34s 56c", gold = "Gold only  (1,234g)", none = "Hidden" } },
    { key = "footerSize", kind = "slider", label = "Bottom line text size", min = 9, max = 18, step = 1 },

    { h = "Vendors and mail" },
    { key = "autoOpen", kind = "check", label = "Open bags at vendor, mail, bank, auction house" },
    { key = "sellButton", kind = "check", label = "Sell junk button at vendors" },
    { key = "autoSell", kind = "check", label = "Sell grey items automatically at vendors" },
}
O.ROWS = ROWS

local widgets = {}

local function Apply()
    if B.Frame then B.Frame.ApplyLook() B.Frame.Refresh() end
end

-- the game's color picker, new and old style
local function PickColor(key, done)
    local cur = B.db[key] or B.DEFAULTS[key]
    local r, g, b = cur[1], cur[2], cur[3]
    local P = _G.ColorPickerFrame
    if not P then return end
    local function Changed()
        local nr, ng, nb = P:GetColorRGB()
        B.db[key] = { nr, ng, nb }
        done()
    end
    local function Cancel()
        B.db[key] = { r, g, b }
        done()
    end
    if P.SetupColorPickerAndShow then
        P:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false, swatchFunc = Changed, cancelFunc = Cancel })
    else
        P.hasOpacity = false
        P.opacityFunc = nil
        P.func = Changed
        P.cancelFunc = Cancel
        P.previousValues = { r = r, g = g, b = b }
        P:SetColorRGB(r, g, b)
        P:Hide() P:Show()
    end
end

local menu, catcher

local function CloseMenu()
    if menu then menu:Hide() end
    if catcher then catcher:Hide() end
end

local function Label(row, v)
    if row.preset then return PRESETS[v] and PRESETS[v].name or tostring(v) end
    return (row.names and row.names[v]) or tostring(v)
end

local Sync

function O.OpenDropdown(anchor, row)
    if menu and menu:IsShown() and menu.row == row then CloseMenu() return end
    if not catcher then
        catcher = CreateFrame("Button", nil, UIParent)
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("FULLSCREEN")
        catcher:SetScript("OnClick", CloseMenu)
        catcher:Hide()
    end
    if not menu then
        menu = CreateFrame("Frame", "BaggieDropdown", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        menu:SetBackdropColor(0.07, 0.07, 0.09, 1)
        menu:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
        menu.items = {}
        menu:Hide()
    end
    menu.row = row
    local cur = B.db[row.key]
    local n = #row.values
    menu:SetSize(anchor:GetWidth() or 300, n * 22 + 6)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
    for i = 1, math.max(n, #menu.items) do
        local it = menu.items[i]
        if i <= n then
            if not it then
                it = CreateFrame("Button", nil, menu)
                it:SetHeight(22)
                it.hl = it:CreateTexture(nil, "BACKGROUND")
                it.hl:SetAllPoints(it)
                it.hl:SetTexture("Interface\\Buttons\\WHITE8X8")
                it.hl:SetVertexColor(1, 1, 1, 0.12)
                it.hl:Hide()
                it.text = it:CreateFontString(nil, "OVERLAY")
                it.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                it.text:SetPoint("LEFT", 8, 0)
                it:SetScript("OnEnter", function(self) self.hl:Show() end)
                it:SetScript("OnLeave", function(self) self.hl:Hide() end)
                menu.items[i] = it
            end
            it:ClearAllPoints()
            it:SetPoint("TOPLEFT", menu, "TOPLEFT", 3, -3 - (i - 1) * 22)
            it:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -3, -3 - (i - 1) * 22)
            local v = row.values[i]
            it.text:SetText(Label(row, v))
            if v == cur then it.text:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) else it.text:SetTextColor(1, 1, 1) end
            it:SetScript("OnClick", function()
                if row.preset then O.ApplyPreset(v) else B.db[row.key] = v end
                CloseMenu()
                Sync() Apply()
            end)
            it:Show()
        elseif it then
            it:Hide()
        end
    end
    catcher:Show()
    menu:Show()
end

Sync = function()
    for _, w in ipairs(widgets) do
        local row, v = w.row, B.db[w.row.key]
        if row.kind == "check" then w.f:SetChecked(v and true or false)
        elseif row.kind == "slider" then w.f:SetValue(tonumber(v) or row.min)
        elseif row.kind == "cycle" then
            w.f:SetText(Label(row, v))
        elseif row.kind == "color" then
            local c = v or B.DEFAULTS[row.key]
            w.f.tex:SetVertexColor(c[1], c[2], c[3], 1)
        end
    end
end

local function Build()
    win = CreateFrame("Frame", "BaggieOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    win:SetFrameStrata("DIALOG")
    win:SetSize(360, 640)
    win:SetPoint("CENTER")
    win:SetMovable(true) win:EnableMouse(true) win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(s) s:StartMoving() end)
    win:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
    win:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    win:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
    win:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9)
    local t = win:CreateFontString(nil, "OVERLAY")
    t:SetFont("Fonts\\MORPHEUS.TTF", 15, "")
    t:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    t:SetPoint("TOPLEFT", 14, -10)
    t:SetText("Baggie options")
    local x = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    x:SetPoint("TOPRIGHT", 2, 1)
    table.insert(_G.UISpecialFrames, "BaggieOptions")

    local scroll = CreateFrame("ScrollFrame", "BaggieOptionsScroll", win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -34)
    scroll:SetPoint("BOTTOMRIGHT", -28, 44)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(310, 1000)
    scroll:SetScrollChild(body)

    local y, n = -4, 0
    for _, row in ipairs(ROWS) do
        if row.h then
            y = y - 8
            local h = body:CreateFontString(nil, "OVERLAY")
            h:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
            h:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
            h:SetPoint("TOPLEFT", 6, y)
            h:SetText(row.h)
            y = y - 20
        elseif row.kind == "check" then
            n = n + 1
            local cb = CreateFrame("CheckButton", "BaggieOpt" .. n, body, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", 6, y + 2)
            local lbl = body:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            lbl:SetText(row.label)
            cb:SetScript("OnClick", function(self)
                B.db[row.key] = self:GetChecked() and true or false
                Apply()
            end)
            widgets[#widgets + 1] = { row = row, f = cb }
            y = y - 22
        elseif row.kind == "slider" then
            n = n + 1
            local s = CreateFrame("Slider", "BaggieOpt" .. n, body, "OptionsSliderTemplate")
            s:SetPoint("TOPLEFT", 10, y - 14)
            s:SetWidth(230)
            s:SetMinMaxValues(row.min, row.max)
            s:SetValueStep(row.step)
            if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
            local lowT, highT, textT = _G[s:GetName() .. "Low"], _G[s:GetName() .. "High"], _G[s:GetName() .. "Text"]
            if lowT then lowT:SetText("") end
            if highT then highT:SetText("") end
            local fmt = row.fmt or "%d"
            local function Label(v) if textT then textT:SetText(row.label .. ": " .. fmt:format(v)) end end
            s:SetScript("OnValueChanged", function(self, v)
                v = math.floor(v / row.step + 0.5) * row.step
                Label(v)
                if B.db[row.key] ~= v then
                    B.db[row.key] = v
                    Apply()
                end
            end)
            widgets[#widgets + 1] = { row = row, f = s, label = Label }
            y = y - 38
        elseif row.kind == "cycle" then
            local lbl = body:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            lbl:SetPoint("TOPLEFT", 8, y - 3)
            lbl:SetText(row.label)
            local b = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
            b:SetSize(300, 22)
            b:SetPoint("TOPLEFT", 6, y - 20)
            local arrow = b:CreateTexture(nil, "OVERLAY")
            arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
            arrow:SetSize(14, 14)
            arrow:SetPoint("RIGHT", b, "RIGHT", -6, 0)
            b:SetScript("OnClick", function(self) O.OpenDropdown(self, row) end)
            widgets[#widgets + 1] = { row = row, f = b }
            y = y - 48
        elseif row.kind == "color" then
            local sw = CreateFrame("Button", nil, body)
            sw:SetSize(22, 22)
            sw:SetPoint("TOPLEFT", 8, y + 1)
            sw.edge = sw:CreateTexture(nil, "BACKGROUND")
            sw.edge:SetTexture("Interface\\Buttons\\WHITE8X8")
            sw.edge:SetVertexColor(0.8, 0.8, 0.8, 1)
            sw.edge:SetAllPoints(sw)
            sw.tex = sw:CreateTexture(nil, "ARTWORK")
            sw.tex:SetTexture("Interface\\Buttons\\WHITE8X8")
            sw.tex:SetPoint("TOPLEFT", 1, -1) sw.tex:SetPoint("BOTTOMRIGHT", -1, 1)
            local lbl = body:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            lbl:SetPoint("LEFT", sw, "RIGHT", 8, 0)
            lbl:SetText(row.label .. "  (click to change)")
            sw:SetScript("OnClick", function()
                PickColor(row.key, function() Sync() Apply() end)
            end)
            widgets[#widgets + 1] = { row = row, f = sw }
            y = y - 28
        end
    end
    body:SetHeight(-y + 20)

    local reset = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    reset:SetSize(110, 20) reset:SetText("Defaults")
    reset:SetPoint("BOTTOMLEFT", 14, 14)
    reset:SetScript("OnClick", function()
        for _, w in ipairs(widgets) do
            local d = B.DEFAULTS[w.row.key]
            if type(d) == "table" then d = { d[1], d[2], d[3] } end
            B.db[w.row.key] = d
        end
        Sync() Apply()
    end)
    local clear = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    clear:SetSize(130, 20) clear:SetText("Clear saved spots")
    clear:SetPoint("BOTTOMRIGHT", -14, 14)
    clear:SetScript("OnClick", function()
        for k in pairs(B.Pins()) do B.Pins()[k] = nil end
        Apply() B.Print("all saved spots cleared")
    end)
    win:SetScript("OnShow", function() Sync() end)
    win:SetScript("OnHide", CloseMenu)
    win:Hide()
end

function O.Toggle()
    if not B.db then return end
    if not win then Build() end
    if win:IsShown() then win:Hide() else win:Show() end
end
