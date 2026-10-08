-- Baggie options window.
local ADDON_NAME, B = ...
local O = {}
B.Options = O
local GOLD = { 0.88, 0.69, 0.29 }
local win

-- kind: check | slider | cycle
local ROWS = {
    { h = "Layout" },
    { key = "layout", kind = "cycle", label = "Item layout", values = { "real", "compact" },
      names = { real = "Bag order (nothing moves)", compact = "Compact (items first)" } },
    { key = "cols", kind = "slider", label = "Columns", min = 4, max = 24, step = 1 },
    { key = "cellSize", kind = "slider", label = "Slot size", min = 28, max = 52, step = 1 },
    { key = "scale", kind = "slider", label = "Window scale", min = 0.6, max = 1.6, step = 0.05, fmt = "%.2f" },
    { key = "alpha", kind = "slider", label = "Background opacity", min = 0.2, max = 1, step = 0.02, fmt = "%.2f" },
    { h = "Items" },
    { key = "borders", kind = "check", label = "Quality colored borders" },
    { key = "junkDim", kind = "check", label = "Dim grey items" },
    { key = "ilvl", kind = "check", label = "Show item level on gear" },
    { key = "keyring", kind = "check", label = "Show keyring" },
    { h = "Saved spots" },
    { key = "showPinMark", kind = "check", label = "Gold mark on saved items" },
    { key = "ghostAlpha", kind = "slider", label = "Empty saved spot opacity", min = 0.1, max = 0.9, step = 0.05, fmt = "%.2f" },
    { key = "sharedPins", kind = "check", label = "Share saved spots across characters" },
    { h = "Window" },
    { key = "showSearch", kind = "check", label = "Search box" },
    { key = "showFooter", kind = "check", label = "Free slots and money" },
    { key = "showSort", kind = "check", label = "Sort button (manual, only when clicked)" },
    { key = "lockPos", kind = "check", label = "Lock window position" },
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

local function Sync()
    for _, w in ipairs(widgets) do
        local v = B.db[w.row.key]
        if w.row.kind == "check" then w.f:SetChecked(v and true or false)
        elseif w.row.kind == "slider" then w.f:SetValue(tonumber(v) or w.row.min)
        elseif w.row.kind == "cycle" then w.f:SetText(w.row.names[v] or tostring(v)) end
    end
end

local function Build()
    win = CreateFrame("Frame", "BaggieOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    win:SetFrameStrata("DIALOG")
    win:SetSize(330, 640)
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

    local y = -36
    local n = 0
    for _, row in ipairs(ROWS) do
        if row.h then
            y = y - 6
            local h = win:CreateFontString(nil, "OVERLAY")
            h:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
            h:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
            h:SetPoint("TOPLEFT", 14, y)
            h:SetText(row.h)
            y = y - 18
        elseif row.kind == "check" then
            n = n + 1
            local cb = CreateFrame("CheckButton", "BaggieOpt" .. n, win, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("TOPLEFT", 14, y + 2)
            local lbl = win:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            lbl:SetText(row.label)
            cb:SetScript("OnClick", function(self)
                B.db[row.key] = self:GetChecked() and true or false
                if row.key == "keyring" or row.key == "sharedPins" then B.Frame.Refresh() end
                Apply()
            end)
            widgets[#widgets + 1] = { row = row, f = cb }
            y = y - 22
        elseif row.kind == "slider" then
            n = n + 1
            local s = CreateFrame("Slider", "BaggieOpt" .. n, win, "OptionsSliderTemplate")
            s:SetPoint("TOPLEFT", 18, y - 14)
            s:SetWidth(200)
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
            local lbl = win:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            lbl:SetPoint("TOPLEFT", 18, y - 4)
            lbl:SetText(row.label)
            local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
            b:SetSize(190, 20)
            b:SetPoint("TOPLEFT", 100, y)
            b:SetScript("OnClick", function()
                local cur = B.db[row.key]
                for i, v in ipairs(row.values) do
                    if v == cur then cur = row.values[i % #row.values + 1] break end
                end
                if cur == B.db[row.key] then cur = row.values[1] end
                B.db[row.key] = cur
                Sync() Apply()
            end)
            widgets[#widgets + 1] = { row = row, f = b }
            y = y - 28
        end
    end
    win:SetHeight(-y + 50)

    local reset = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    reset:SetSize(110, 20) reset:SetText("Defaults")
    reset:SetPoint("BOTTOMLEFT", 14, 12)
    reset:SetScript("OnClick", function()
        for _, w in ipairs(widgets) do B.db[w.row.key] = B.DEFAULTS[w.row.key] end
        Sync() Apply()
    end)
    local clear = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    clear:SetSize(130, 20) clear:SetText("Clear saved spots")
    clear:SetPoint("BOTTOMRIGHT", -14, 12)
    clear:SetScript("OnClick", function()
        for k in pairs(B.Pins()) do B.Pins()[k] = nil end
        Apply() B.Print("all saved spots cleared")
    end)
    win:SetScript("OnShow", Sync)
    win:Hide()
end

function O.Toggle()
    if not B.db then return end
    if not win then Build() end
    if win:IsShown() then win:Hide() else win:Show() end
end
