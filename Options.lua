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
    ember    = { name = "Ember",         bg = { 0.10, 0.05, 0.03 }, edge = { 0.95, 0.55, 0.15 }, title = { 0.22, 0.10, 0.05 }, slot = { 0.19, 0.10, 0.07 } },
    void     = { name = "Void purple",   bg = { 0.07, 0.04, 0.11 }, edge = { 0.65, 0.40, 0.95 }, title = { 0.16, 0.09, 0.25 }, slot = { 0.15, 0.10, 0.23 } },
    frost    = { name = "Frost",         bg = { 0.05, 0.09, 0.12 }, edge = { 0.55, 0.88, 0.98 }, title = { 0.09, 0.18, 0.24 }, slot = { 0.10, 0.18, 0.24 } },
    mono     = { name = "Black and white", bg = { 0.00, 0.00, 0.00 }, edge = { 0.95, 0.95, 0.95 }, title = { 0.12, 0.12, 0.12 }, slot = { 0.10, 0.10, 0.10 } },
    light    = { name = "Parchment",     bg = { 0.85, 0.82, 0.75 }, edge = { 0.45, 0.35, 0.20 }, title = { 0.70, 0.64, 0.50 }, slot = { 0.70, 0.66, 0.58 } },
}
local PRESET_ORDER = { "gold", "midnight", "slate", "forest", "crimson", "ember", "void", "frost", "mono", "light" }
O.PRESETS = PRESETS

local function Copy(t) return { t[1], t[2], t[3] } end

function O.ApplyPreset(id, t)
    local p = PRESETS[id]
    if not p then return end
    t = t or B.db
    t.preset = id
    t.bgColor, t.edgeColor = Copy(p.bg), Copy(p.edge)
    t.titleColor, t.slotColor = Copy(p.title), Copy(p.slot)
end


----------------------------------------------------------------------
-- What is in the window. scope: "all" = look settings (own tab values when "sync all" is off),
-- "inv" = Inventory tab only, "bank" / "guild" = that tab only.
----------------------------------------------------------------------
local BGNAMES = { solid = "Solid color", dark = "Dark panel", parchment = "Parchment", marble = "Marble", rock = "Rock",
    tooltip = "Tooltip", leather = "Leather", stone = "Stone", linen = "Linen", carbon = "Carbon fiber",
    brushed = "Brushed metal", gradient = "Fade, light to dark", custom = "Custom (path below)" }
local FONTNAMES = { morpheus = "Fancy (Morpheus)", frizqt = "Standard", arial = "Narrow (Arial)", skurri = "Rough (Skurri)" }
local CORNERS = { BOTTOMRIGHT = "Bottom right", BOTTOMLEFT = "Bottom left", TOPRIGHT = "Top right", TOPLEFT = "Top left", CENTER = "Center" }

local SECTIONS = {
    { id = "layout", title = "Layout", scope = "inv", rows = {
        { key = "layout", kind = "cycle", label = "Item layout", values = { "real", "gaps", "compact" },
          names = { real = "Bag order (nothing moves)", gaps = "Bag order, new items fill gaps", compact = "Compact (items first)" } },
        { key = "cols", kind = "slider", label = "Columns", min = 4, max = 24, step = 1 },
        { key = "scale", kind = "slider", label = "Window scale", min = 0.6, max = 1.6, step = 0.05, fmt = "%.2f" },
        { key = "cellSize", kind = "slider", label = "Slot size", min = 28, max = 56, step = 1 },
        { key = "gap", kind = "slider", label = "Space between slots", min = 0, max = 16, step = 1 },
        { key = "padding", kind = "slider", label = "Window padding", min = 4, max = 30, step = 1 },
    } },
    { id = "bankwin", title = "Bank window", scope = "bank", rows = {
        { key = "bankReplace", kind = "check", label = "Use Baggie's bank window (reopen the bank to apply)", base = true },
        { key = "bankShowBags", kind = "check", label = "Show your bank bag slots", base = true },
        { key = "bankCompact", kind = "check", label = "Pack bank items to the top (empty slots after)", base = true },
        { key = "bankSections", kind = "check", label = "Start each bank bag on its own row", base = true },
        { key = "bankCols", kind = "slider", label = "Slots per row", min = 7, max = 24, step = 1 },
        { key = "cellSize", kind = "slider", label = "Slot size", min = 28, max = 56, step = 1 },
        { key = "gap", kind = "slider", label = "Space between slots", min = 0, max = 16, step = 1 },
        { key = "padding", kind = "slider", label = "Window padding", min = 4, max = 30, step = 1 },
    } },
    { id = "guildwin", title = "Guild bank window", scope = "guild", rows = {
        { key = "guildBankReplace", kind = "check", label = "Use Baggie's guild bank window (reopen to apply)", base = true },
        { key = "bankCols", kind = "slider", label = "Slots per row", min = 7, max = 24, step = 1 },
        { key = "cellSize", kind = "slider", label = "Slot size", min = 28, max = 56, step = 1 },
        { key = "gap", kind = "slider", label = "Space between slots", min = 0, max = 16, step = 1 },
        { key = "padding", kind = "slider", label = "Window padding", min = 4, max = 30, step = 1 },
    } },
    { id = "colors", title = "Colors", scope = "all", rows = {
        { key = "preset", kind = "cycle", label = "Theme", values = PRESET_ORDER, preset = true },
        { key = "bgColor", kind = "color", label = "Window background" },
        { key = "edgeColor", kind = "color", label = "Border and title text" },
        { key = "titleColor", kind = "color", label = "Title bar" },
        { key = "slotColor", kind = "color", label = "Slot background" },
    } },
    { id = "bg", title = "Background and opacity", scope = "all", rows = {
        { key = "bgColor", kind = "color", label = "Background color (a solid fill, or the tint of a texture)" },
        { key = "bgStyle", kind = "cycle", label = "Background", values = { "solid", "dark", "parchment", "marble", "rock", "tooltip", "leather", "stone", "linen", "carbon", "brushed", "gradient", "custom" }, names = BGNAMES },
        { key = "bgCustom", kind = "text", label = "Custom texture: a file path or a SharedMedia background name",
          hint = "for example  Interface\\AddOns\\SomeAddon\\texture" },
        { key = "bgNoTint", kind = "check", label = "Show textures in their own colors (no tint)" },
        { key = "alpha", kind = "slider", label = "Window opacity", min = 0, max = 1, step = 0.02, fmt = "%.2f" },
        { key = "edgeAlpha", kind = "slider", label = "Border opacity", min = 0, max = 1, step = 0.05, fmt = "%.2f" },
        { key = "titleAlpha", kind = "slider", label = "Title bar opacity", min = 0, max = 1, step = 0.05, fmt = "%.2f" },
    } },
    { id = "frame", title = "Border and title", scope = "all", rows = {
        { key = "edgeStyle", kind = "cycle", label = "Window border", values = { "line", "tooltip", "none" },
          names = { line = "Thin line", tooltip = "Tooltip style", none = "None" } },
        { key = "edgeSize", kind = "slider", label = "Line border thickness", min = 1, max = 6, step = 1 },
        { key = "showTitleBar", kind = "check", label = "Show the title bar" },
        { key = "titleSize", kind = "slider", label = "Title size", min = 10, max = 22, step = 1 },
        { key = "titleFont", kind = "cycle", label = "Title font", values = { "morpheus", "frizqt", "arial", "skurri" }, names = FONTNAMES },
    } },
    { id = "slots", title = "Slots and text", scope = "all", rows = {
        { key = "slotStyle", kind = "cycle", label = "Slot background style", values = { "filled", "gradient", "texture", "game", "none" },
          names = { filled = "Flat color", gradient = "Gradient (two colors)", texture = "Textured tile", game = "The game's own slot art", none = "None (icons only)" } },
        { key = "slotColor2", kind = "color", label = "Gradient: second color" },
        { key = "slotTexture", kind = "cycle", label = "Textured tile", values = { "leather", "stone", "linen", "carbon", "brushed", "marble", "rock", "parchment" },
          names = { leather = "Leather", stone = "Stone", linen = "Linen", carbon = "Carbon", brushed = "Brushed metal", marble = "Marble", rock = "Rock", parchment = "Parchment" } },
        { key = "slotAlpha", kind = "slider", label = "Slot background opacity", min = 0, max = 1, step = 0.05, fmt = "%.2f" },
        { key = "slotEmptyAlpha", kind = "slider", label = "Empty slots: share of that opacity", min = 0, max = 1, step = 0.05, fmt = "%.2f" },
        { key = "slotQualityTint", kind = "check", label = "Tint each slot with its item's quality color" },
        { key = "slotQualityStrength", kind = "slider", label = "Quality tint strength", min = 0.05, max = 1, step = 0.05, fmt = "%.2f" },
        { key = "slotEdge", kind = "cycle", label = "Slot edge", values = { "none", "line", "bevel", "inset" },
          names = { none = "None", line = "Thin line", bevel = "Raised bevel", inset = "Sunken inset" } },
        { key = "slotEdgeColor", kind = "color", label = "Slot edge color (thin line)" },
        { key = "slotEdgeAlpha", kind = "slider", label = "Slot edge opacity", min = 0.1, max = 1, step = 0.05, fmt = "%.2f" },
        { key = "slotEdgeSize", kind = "slider", label = "Slot edge thickness", min = 1, max = 4, step = 1 },
        { key = "iconInset", kind = "slider", label = "Icon padding inside slot", min = 0, max = 10, step = 1 },
        { key = "iconCrop", kind = "check", label = "Trim icon edges" },
        { key = "junkDim", kind = "check", label = "Dim grey items" },
        { key = "junkAlpha", kind = "slider", label = "Grey item opacity", min = 0.1, max = 1, step = 0.05, fmt = "%.2f" },
        { key = "font", kind = "cycle", label = "Font for counts and the bottom line", values = { "frizqt", "arial", "morpheus", "skurri" }, names = FONTNAMES },
        { key = "countSize", kind = "slider", label = "Stack count size", min = 8, max = 18, step = 1 },
        { key = "countPos", kind = "cycle", label = "Stack count corner", values = { "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT", "CENTER" }, names = CORNERS },
        { key = "ilvl", kind = "check", label = "Show item level on gear" },
        { key = "ilvlSize", kind = "slider", label = "Item level size", min = 8, max = 16, step = 1 },
        { key = "ilvlPos", kind = "cycle", label = "Item level corner", values = { "TOPRIGHT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT", "CENTER" }, names = CORNERS },
        { key = "ilvlQuality", kind = "check", label = "Color item level by quality" },
    } },
    { id = "borders", title = "Item borders", scope = "all", rows = {
        { key = "borderMode", kind = "cycle", label = "Border style", values = { "quality", "custom", "slots", "none" },
          names = { quality = "By item quality", custom = "One color, items only", slots = "One color, every slot", none = "None" } },
        { key = "borderColor", kind = "color", label = "Border color (one-color styles)" },
        { key = "borderSize", kind = "slider", label = "Border thickness", min = 1, max = 4, step = 1 },
        { key = "borderMinQuality", kind = "slider", label = "Quality borders start at (2 = green)", min = 0, max = 5, step = 1 },
    } },
    { id = "glows", title = "Item glows", scope = "all", rows = {
        { key = "glowQuest", kind = "check", label = "Glow quest items (gold)" },
        { key = "glowQuality", kind = "check", label = "Glow high-quality items" },
        { key = "glowMinQuality", kind = "slider", label = "Quality glows start at (4 = epic)", min = 2, max = 6, step = 1 },
        { key = "glowStrength", kind = "slider", label = "Glow brightness", min = 0.2, max = 1, step = 0.05, fmt = "%.2f" },
    } },
    { id = "flair", title = "Flair", scope = "all", rows = {
        { key = "flair", kind = "cycle", label = "Window trim", values = { "none", "gilded", "royal" },
          names = { none = "None", gilded = "Gilded line and studs", royal = "Royal: double line, diamonds, title rule" } },
        { key = "pulse", kind = "check", label = "Pulse the item glows" },
    } },
    { id = "footer", title = "Bottom line", scope = "all", rows = {
        { key = "showFooter", kind = "check", label = "Show the slot counter (gold is set below)" },
        { key = "counterMode", kind = "cycle", label = "Slot counter", values = { "used", "free", "freeonly", "none" },
          names = { used = "Used / total", free = "Free of total", freeonly = "Free only", none = "Hidden" } },
        { key = "goldMode", kind = "cycle", label = "Gold display", values = { "icons", "text", "gold", "none" },
          names = { icons = "Coin icons", text = "Colored 12g 34s 56c", gold = "Gold only", none = "Hidden" } },
        { key = "footerSize", kind = "slider", label = "Bottom line text size", min = 9, max = 18, step = 1 },
    } },
    { id = "window", title = "Bag window", scope = "inv", rows = {
        { key = "titleMode", kind = "cycle", label = "Title text", values = { "name", "char", "bags", "none" },
          names = { name = "Baggie", char = "Your character's bags", bags = "Bags", none = "None" } },
        { key = "showBags", kind = "check", label = "Show your equipped bag slots" },
        { key = "showSearch", kind = "check", label = "Search box" },
        { key = "showSort", kind = "check", label = "Sort button (only sorts when clicked)" },
        { key = "fillFront", kind = "check", label = "New items go to the first free slot" },
        { key = "glowNew", kind = "check", label = "Glow new items until you point at them" },
        { key = "lockPos", kind = "check", label = "Lock window position (shows a padlock in the title bar)" },
        { key = "showMinimap", kind = "check", label = "Minimap button (right-click it for options)" },
        { key = "followGreedUI", kind = "check", label = "Follow GreedUI's colors and look (only when GreedUI is installed)" },
        { key = "showReagent", kind = "check", label = "Show reagent bag (if this game has one)" },
        { key = "keyring", kind = "check", label = "Show keyring (if this character has one)" },
        { key = "sectionLabels", kind = "check", label = "Label and separate those extra sections" },
    } },
    { id = "pins", title = "Saved spots", scope = "inv", rows = {
        { key = "showPinMark", kind = "check", label = "Mark on saved items" },
        { key = "pinColor", kind = "color", label = "Mark color" },
        { key = "pinSize", kind = "slider", label = "Mark size", min = 4, max = 14, step = 1 },
        { key = "ghostAlpha", kind = "slider", label = "Empty saved spot opacity", min = 0.1, max = 0.9, step = 0.05, fmt = "%.2f" },
        { key = "sharedPins", kind = "check", label = "Share saved spots across characters" },
    } },
    { id = "vendor", title = "Vendors and mail", scope = "inv", rows = {
        { key = "autoOpen", kind = "check", label = "Open bags at vendor, mail, bank, auction house" },
        { key = "sellButton", kind = "check", label = "Sell junk button at vendors" },
        { key = "debugBank", kind = "check", label = "Print bank diagnostics to chat (for troubleshooting)" },
        { key = "autoSell", kind = "check", label = "Sell grey items automatically at vendors" },
    } },
}
O.SECTIONS = SECTIONS

local TABS = {
    { id = "inv", name = "Inventory" },
    { id = "bank", name = "Bank" },
    { id = "guild", name = "Guild Bank" },
}

local FONT = "Fonts\\FRIZQT__.TTF"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BW = 420                       -- width of a row
local PANEL = { 0.03, 0.03, 0.035 }
local FIELD = { 0.06, 0.06, 0.07 }
local LINE = { 0.34, 0.27, 0.12 }
local DIM = { 0.62, 0.62, 0.68 }

local views = {}                     -- per tab: { body, items, widgets }
local curTab = "inv"
local scroll

local function Box(parent, w, h, bg, border)
    local f = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    if w then f:SetSize(w, h) end
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    bg, border = bg or FIELD, border or LINE
    f:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    f:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    return f
end

local function Text(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size or 11, "")
    color = color or { 1, 1, 1 }
    fs:SetTextColor(color[1], color[2], color[3])
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function FlatButton(parent, label, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    b:SetSize(w, h or 22)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    b:SetBackdropColor(FIELD[1], FIELD[2], FIELD[3], 1)
    b:SetBackdropBorderColor(LINE[1], LINE[2], LINE[3], 1)
    b.text = Text(b, 11, { 1, 1, 1 }, "CENTER")
    b.text:SetPoint("CENTER")
    b.text:SetText(label)
    b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(LINE[1], LINE[2], LINE[3], 1) end)
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end

local function Target(tab)
    if tab == "inv" then return B.db end
    return B.EnsureScope(tab, B.db.syncAll == false)
end

local function Synced() return B.db.syncAll ~= false end

local function Apply()
    if B.Frame then B.Frame.ApplyLook() B.Frame.Refresh() end
    if B.BankUI then B.BankUI.ApplyLook() end
    if B.RefreshBankGlows then B.RefreshBankGlows() end
    if B.Minimap then B.Minimap.Update() end
end

-- color <-> text, so a color can be copied to and pasted from other add-ons
local function ToHex(c)
    local function h(v) return ("%02X"):format(math.floor(math.max(0, math.min(1, tonumber(v) or 0)) * 255 + 0.5)) end
    return "#" .. h(c[1]) .. h(c[2]) .. h(c[3])
end
local function FromText(str)
    if type(str) ~= "string" then return end
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    local hex = str:match("^#?(%x%x%x%x%x%x)$") or str:match("^#?%x%x(%x%x%x%x%x%x)$") or str:match("^|c%x%x(%x%x%x%x%x%x)")
    if hex then
        return { tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255 }
    end
    local a, b, c = str:match("^[{%[(]?%s*([%d%.]+)[%s,;]+([%d%.]+)[%s,;]+([%d%.]+)")
    a, b, c = tonumber(a), tonumber(b), tonumber(c)
    if a and b and c then
        if a > 1 or b > 1 or c > 1 then a, b, c = a / 255, b / 255, c / 255 end
        return { math.min(1, a), math.min(1, b), math.min(1, c) }
    end
end

-- the game's color picker (new and old style), with an opacity slider for the colors that have one and a
-- share box for copying a color to, or pasting one from, other add-ons
local ALPHA_KEY = { bgColor = "alpha", edgeColor = "edgeAlpha", titleColor = "titleAlpha", slotColor = "slotAlpha", slotEdgeColor = "slotEdgeAlpha" }
local share

local function Hex2(v) return ("%02X"):format(math.floor(math.max(0, math.min(1, tonumber(v) or 0)) * 255 + 0.5)) end

local function PickColor(t, key, done)
    local P = _G.ColorPickerFrame
    if not P then return end
    local alphaKey = ALPHA_KEY[key]
    local cur = t[key] or B.DEFAULTS[key]
    local r, g, b = cur[1], cur[2], cur[3]
    local a0 = alphaKey and (tonumber(t[alphaKey]) or tonumber(B.DEFAULTS[alphaKey]) or 1) or nil
    local inverted = false      -- some versions of the picker count opacity the other way round

    local function ReadAlpha()
        if not alphaKey then return nil end
        local v
        if P.GetColorAlpha then v = P:GetColorAlpha()
        elseif _G.OpacitySliderFrame then v = _G.OpacitySliderFrame:GetValue() end
        v = tonumber(v)
        if not v then return nil end
        if inverted or (not P.GetColorAlpha) then v = 1 - v end
        return math.max(0, math.min(1, v))
    end

    local ShareSync
    local function Changed()
        local nr, ng, nb = P:GetColorRGB()
        t[key] = { nr, ng, nb }
        local al = ReadAlpha()
        if al then t[alphaKey] = al end
        done()
        if ShareSync then ShareSync() end
    end
    local function Cancel()
        t[key] = { r, g, b }
        if alphaKey then t[alphaKey] = a0 end
        done()
    end

    if P.SetupColorPickerAndShow then
        P:SetupColorPickerAndShow({ r = r, g = g, b = b, opacity = a0, hasOpacity = alphaKey ~= nil,
            swatchFunc = Changed, opacityFunc = Changed, cancelFunc = Cancel })
        if alphaKey and P.GetColorAlpha then
            -- find out which way round this picker counts: it should hand back what we gave it
            local got = tonumber(P:GetColorAlpha())
            if got and math.abs(got - a0) > 0.02 and math.abs(got - (1 - a0)) <= 0.02 then inverted = true end
        end
    else
        P.hasOpacity = alphaKey ~= nil
        P.opacity = alphaKey and (1 - a0) or 0
        P.opacityFunc = Changed
        P.func = Changed
        P.cancelFunc = Cancel
        P.previousValues = { r = r, g = g, b = b, opacity = P.opacity }
        P:SetColorRGB(r, g, b)
        if alphaKey and _G.OpacitySliderFrame then _G.OpacitySliderFrame:SetValue(1 - a0) end
        P:Hide() P:Show()
    end

    -- share box under the picker
    if not share then
        share = Box(P, 10, 66, PANEL, GOLD)
        share:SetPoint("TOPLEFT", P, "BOTTOMLEFT", 0, -4)
        share:SetPoint("TOPRIGHT", P, "BOTTOMRIGHT", 0, -4)
        share.label = Text(share, 11, GOLD)
        share.label:SetPoint("TOPLEFT", 10, -8)
        share.label:SetText("Share code")
        share.hint = Text(share, 10, DIM)
        share.hint:SetPoint("TOPRIGHT", -10, -9)
        share.hint:SetText("Ctrl+C to copy, Ctrl+V to paste")
        share.eb = CreateFrame("EditBox", nil, share, BackdropTemplateMixin and "BackdropTemplate" or nil)
        share.eb:SetHeight(22)
        share.eb:SetPoint("TOPLEFT", 10, -26)
        share.eb:SetPoint("TOPRIGHT", -150, -26)
        share.eb:SetAutoFocus(false)
        share.eb:SetFont(FONT, 11, "")
        share.eb:SetTextInsets(6, 6, 0, 0)
        share.eb:SetMaxLetters(32)
        share.eb:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        share.eb:SetBackdropColor(FIELD[1], FIELD[2], FIELD[3], 1)
        share.eb:SetBackdropBorderColor(LINE[1], LINE[2], LINE[3], 1)
        share.copy = FlatButton(share, "Copy", 60, 22, function() share.eb:SetFocus() share.eb:HighlightText() end)
        share.copy:SetPoint("LEFT", share.eb, "RIGHT", 6, 0)
        share.apply = FlatButton(share, "Apply", 76, 22)
        share.apply:SetPoint("LEFT", share.copy, "RIGHT", 6, 0)
        share.msg = Text(share, 10, DIM)
        share.msg:SetPoint("BOTTOMLEFT", 10, 6)
        share.eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        share.eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    end
    local function ApplyText()
        local txt = share.eb:GetText() or ""
        local col, alpha
        local h6, h2 = txt:match("^%s*#?(%x%x%x%x%x%x)(%x%x)%s*$")   -- RRGGBBAA, as this box writes it
        if h6 then
            col = FromText(h6)
            alpha = tonumber(h2, 16) / 255
        else
            col = FromText(txt)
        end
        if not col then share.msg:SetText("Couldn't read that. Use a code like #E0B04A or #E0B04AFF, or three numbers.") return end
        P:SetColorRGB(col[1], col[2], col[3])
        t[key] = { col[1], col[2], col[3] }
        if alphaKey and alpha then
            t[alphaKey] = alpha
            local v = inverted and (1 - alpha) or alpha
            if P.SetColorAlpha then P:SetColorAlpha(v)
            elseif _G.OpacitySliderFrame then _G.OpacitySliderFrame:SetValue(1 - alpha) end
        end
        done()
        share.msg:SetText("Applied.")
        ShareSync()
        share.eb:ClearFocus()
    end
    share.apply:SetScript("OnClick", ApplyText)
    share.eb:SetScript("OnEnterPressed", ApplyText)
    ShareSync = function()
        if share.eb:HasFocus() then return end
        local c = t[key] or { r, g, b }
        local txt = "#" .. Hex2(c[1]) .. Hex2(c[2]) .. Hex2(c[3])
        if alphaKey then txt = txt .. Hex2(tonumber(t[alphaKey]) or a0) end
        share.eb:SetText(txt)
        share.msg:SetText(alphaKey and "The last two digits are the opacity." or "")
    end
    share:Show()
    ShareSync()
end

----------------------------------------------------------------------
-- dropdown list
----------------------------------------------------------------------
local menu, catcher

local function CloseMenu()
    if menu then menu:Hide() end
    if catcher then catcher:Hide() end
end

local function Label(row, v)
    if row.preset then return PRESETS[v] and PRESETS[v].name or tostring(v) end
    return (row.names and row.names[v]) or tostring(v)
end

local function OpenDropdown(anchor, row, get, set)
    if menu and menu:IsShown() and menu.row == row and menu.anchor == anchor then CloseMenu() return end
    if not catcher then
        catcher = CreateFrame("Button", nil, UIParent)
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("FULLSCREEN")
        catcher:SetScript("OnClick", CloseMenu)
        catcher:Hide()
    end
    if not menu then
        menu = Box(UIParent, 10, 10, { 0.07, 0.07, 0.09 }, GOLD)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu.items = {}
        menu:Hide()
    end
    menu.row, menu.anchor = row, anchor
    local cur = get()
    local n = #row.values
    menu:SetSize(math.max(anchor:GetWidth(), 170), n * 22 + 6)
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -1)
    for i = 1, math.max(n, #menu.items) do
        local it = menu.items[i]
        if i <= n then
            if not it then
                it = CreateFrame("Button", nil, menu)
                it:SetHeight(22)
                it.hl = it:CreateTexture(nil, "BACKGROUND")
                it.hl:SetAllPoints(it)
                it.hl:SetTexture(WHITE)
                it.hl:SetVertexColor(1, 1, 1, 0.12)
                it.hl:Hide()
                it.text = Text(it, 11)
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
            it:SetScript("OnClick", function() CloseMenu() set(v) end)
            it:Show()
        elseif it then
            it:Hide()
        end
    end
    catcher:Show()
    menu:Show()
end

----------------------------------------------------------------------
-- row widgets: each makes one container frame of BW x height and returns { frame, height, refresh }
----------------------------------------------------------------------
local RefreshAll, Relayout

local function MakeRow(parent, tab, row)
    local c = CreateFrame("Frame", nil, parent)
    c:SetWidth(BW)
    local function T() return row.base and B.db or Target(tab) end
    local function get() local v = T()[row.key] if v == nil then v = B.DEFAULTS[row.key] end return v end
    local function set(v)
        T()[row.key] = v
        Apply()
        RefreshAll()
    end
    local w = { frame = c, row = row }

    if row.kind == "check" then
        c:SetHeight(24)
        local box = Box(c, 16, 16)
        box:SetPoint("LEFT", c, "LEFT", 12, 0)
        local tick = box:CreateTexture(nil, "OVERLAY")
        tick:SetTexture(WHITE)
        tick:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
        tick:SetPoint("TOPLEFT", 3, -3) tick:SetPoint("BOTTOMRIGHT", -3, 3)
        local lbl = Text(c, 11)
        lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
        lbl:SetWidth(BW - 50)
        lbl:SetText(row.label)
        local btn = CreateFrame("Button", nil, c)
        btn:SetAllPoints(c)
        btn:SetScript("OnClick", function() set(not get()) end)
        btn:SetScript("OnEnter", function() box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1) end)
        btn:SetScript("OnLeave", function() box:SetBackdropBorderColor(LINE[1], LINE[2], LINE[3], 1) end)
        w.refresh = function() tick:SetShown(get() and true or false) end

    elseif row.kind == "slider" then
        c:SetHeight(40)
        local lbl = Text(c, 11)
        lbl:SetPoint("TOPLEFT", c, "TOPLEFT", 12, -4)
        lbl:SetText(row.label)
        local val = Text(c, 11, GOLD, "RIGHT")
        val:SetPoint("TOPRIGHT", c, "TOPRIGHT", -14, -4)
        local s = CreateFrame("Slider", nil, c)
        s:SetOrientation("HORIZONTAL")
        s:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 14, 7)
        s:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -14, 7)
        s:SetHeight(14)
        local track = s:CreateTexture(nil, "BACKGROUND")
        track:SetTexture(WHITE)
        track:SetVertexColor(FIELD[1] + 0.05, FIELD[2] + 0.05, FIELD[3] + 0.05, 1)
        track:SetPoint("LEFT") track:SetPoint("RIGHT") track:SetHeight(4)
        s:SetThumbTexture(WHITE)
        local th = s:GetThumbTexture()
        th:SetSize(8, 14)
        th:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
        s:SetMinMaxValues(row.min, row.max)
        s:SetValueStep(row.step)
        if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
        local fmt = row.fmt or "%d"
        s:SetScript("OnValueChanged", function(self, v)
            if self.quiet then return end
            v = math.floor(v / row.step + 0.5) * row.step
            val:SetText(fmt:format(v))
            if get() ~= v then T()[row.key] = v Apply() end
        end)
        w.refresh = function()
            local v = tonumber(get()) or row.min
            s.quiet = true
            s:SetValue(v)
            s.quiet = false
            val:SetText(fmt:format(v))
        end

    elseif row.kind == "cycle" then
        c:SetHeight(28)
        local lbl = Text(c, 11)
        lbl:SetPoint("LEFT", c, "LEFT", 12, 0)
        lbl:SetWidth(BW - 224)
        lbl:SetText(row.label)
        local b = FlatButton(c, "", 196, 20)
        b:SetPoint("RIGHT", c, "RIGHT", -12, 0)
        b.text:ClearAllPoints()
        b.text:SetPoint("LEFT", 8, 0) b.text:SetPoint("RIGHT", -20, 0) b.text:SetJustifyH("LEFT")
        local arrow = Text(b, 10, GOLD, "RIGHT")
        arrow:SetPoint("RIGHT", -7, 0)
        arrow:SetText("v")
        b:SetScript("OnClick", function(self)
            OpenDropdown(self, row, get, function(v)
                if row.preset then O.ApplyPreset(v, T()) else T()[row.key] = v end
                Apply() RefreshAll()
            end)
        end)
        w.refresh = function() b.text:SetText(Label(row, get())) end

    elseif row.kind == "color" then
        c:SetHeight(28)
        local lbl = Text(c, 11)
        lbl:SetPoint("LEFT", c, "LEFT", 12, 0)
        lbl:SetWidth(BW - 150)
        lbl:SetText(row.label)
        local eb = CreateFrame("EditBox", nil, c, BackdropTemplateMixin and "BackdropTemplate" or nil)
        eb:SetSize(74, 20)
        eb:SetPoint("RIGHT", c, "RIGHT", -12, 0)
        eb:SetAutoFocus(false)
        eb:SetFont(FONT, 11, "")
        eb:SetTextInsets(6, 6, 0, 0)
        eb:SetMaxLetters(24)
        eb:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        eb:SetBackdropColor(FIELD[1], FIELD[2], FIELD[3], 1)
        eb:SetBackdropBorderColor(LINE[1], LINE[2], LINE[3], 1)
        local sw = CreateFrame("Button", nil, c)
        sw:SetSize(22, 20)
        sw:SetPoint("RIGHT", eb, "LEFT", -6, 0)
        sw.edge = sw:CreateTexture(nil, "BACKGROUND")
        sw.edge:SetTexture(WHITE)
        sw.edge:SetVertexColor(0.75, 0.75, 0.78, 1)
        sw.edge:SetAllPoints(sw)
        sw.tex = sw:CreateTexture(nil, "ARTWORK")
        sw.tex:SetTexture(WHITE)
        sw.tex:SetPoint("TOPLEFT", 1, -1) sw.tex:SetPoint("BOTTOMRIGHT", -1, 1)
        local function Commit(self)
            local col = FromText(self:GetText())
            self:ClearFocus()
            if col then
                T()[row.key] = col
                Apply() RefreshAll()
            else
                B.Print("couldn't read that color - use a hex code like #E0B04A, or three numbers like 224 176 74")
                RefreshAll()
            end
        end
        local function Tip(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Color code", 1, 1, 1)
            GameTooltip:AddLine("Click, then Ctrl+C to copy it or Ctrl+V to paste one, then press Enter.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end
        eb:SetScript("OnEnter", Tip)
        eb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        eb:SetScript("OnEnterPressed", Commit)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() RefreshAll() end)
        eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        eb:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
        sw:SetScript("OnClick", function() PickColor(T(), row.key, function() Apply() RefreshAll() end) end)
        sw:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP") GameTooltip:SetText("Click to pick a color") GameTooltip:Show()
        end)
        sw:SetScript("OnLeave", function() GameTooltip:Hide() end)
        w.refresh = function()
            local col = get()
            sw.tex:SetVertexColor(col[1], col[2], col[3], 1)
            if not eb:HasFocus() then eb:SetText(ToHex(col)) end
        end

    elseif row.kind == "text" then
        c:SetHeight(row.hint and 62 or 48)
        local lbl = Text(c, 11)
        lbl:SetPoint("TOPLEFT", c, "TOPLEFT", 12, -4)
        lbl:SetWidth(BW - 24)
        lbl:SetText(row.label)
        local eb = CreateFrame("EditBox", nil, c, BackdropTemplateMixin and "BackdropTemplate" or nil)
        eb:SetSize(BW - 24, 22)
        eb:SetPoint("TOPLEFT", c, "TOPLEFT", 12, -22)
        eb:SetAutoFocus(false)
        eb:SetFont(FONT, 11, "")
        eb:SetTextInsets(6, 6, 0, 0)
        eb:SetMaxLetters(200)
        eb:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        eb:SetBackdropColor(FIELD[1], FIELD[2], FIELD[3], 1)
        eb:SetBackdropBorderColor(LINE[1], LINE[2], LINE[3], 1)
        local function Commit(self)
            T()[row.key] = self:GetText() or ""
            Apply()
        end
        eb:SetScript("OnEnterPressed", function(self) Commit(self) self:ClearFocus() end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() RefreshAll() end)
        eb:SetScript("OnEditFocusLost", Commit)
        if row.hint then
            local h = Text(c, 10, DIM)
            h:SetPoint("TOPLEFT", c, "TOPLEFT", 12, -47)
            h:SetWidth(BW - 24)
            h:SetText(row.hint)
        end
        w.refresh = function()
            local v = get()
            if not eb:HasFocus() then eb:SetText(type(v) == "string" and v or "") end
        end
    end
    return w
end

----------------------------------------------------------------------
-- a tab's contents: collapsible sections, built the first time the tab is shown
----------------------------------------------------------------------
local function SectionVisible(tab, sec)
    if sec.scope == "inv" then return tab == "inv" end
    if sec.scope == "all" then return tab == "inv" or not Synced() end
    return sec.scope == tab
end

local function OpenState(tab, sec, first)
    B.db.optOpen = B.db.optOpen or {}
    local v = B.db.optOpen[tab .. ":" .. sec.id]
    if v == nil then return first end
    return v
end

local function BuildView(tab)
    local v = { items = {} }
    views[tab] = v
    v.body = CreateFrame("Frame", nil, scroll)
    v.body:SetSize(BW, 600)
    v.body:Hide()
    v.banner = Box(v.body, BW - 8, 60, { 0.10, 0.12, 0.08 }, { 0.35, 0.5, 0.3 })
    local bt = Text(v.banner, 11, { 0.8, 0.95, 0.75 })
    bt:SetPoint("TOPLEFT", 10, -8) bt:SetPoint("BOTTOMRIGHT", -10, 8)
    bt:SetJustifyV("TOP")
    bt:SetText("The look of this window follows your Inventory settings (colors, textures, opacity, text, glows). Turn off \"Sync all windows\" at the top to give it its own.")
    v.banner:Hide()
    local firstDone = false
    for _, sec in ipairs(SECTIONS) do
        if sec.scope == "all" or sec.scope == tab or (sec.scope == "inv" and tab == "inv") then
            local it = { sec = sec, rows = {} }
            local first = not firstDone
            firstDone = true
            it.first = first
            local h = CreateFrame("Button", nil, v.body)
            h:SetSize(BW, 28)
            local bar = h:CreateTexture(nil, "BACKGROUND")
            bar:SetAllPoints(h)
            bar:SetTexture(WHITE)
            bar:SetVertexColor(1, 1, 1, 0.05)
            local line = h:CreateTexture(nil, "ARTWORK")
            line:SetTexture(WHITE)
            line:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.55)
            line:SetPoint("BOTTOMLEFT") line:SetPoint("BOTTOMRIGHT") line:SetHeight(1)
            h.arrow = Text(h, 11, GOLD)
            h.arrow:SetPoint("LEFT", 10, 0)
            h.label = Text(h, 12, GOLD)
            h.label:SetPoint("LEFT", 26, 0)
            h.label:SetText(sec.title)
            h:SetScript("OnClick", function()
                B.db.optOpen[tab .. ":" .. sec.id] = not OpenState(tab, sec, first)
                Relayout(tab)
            end)
            h:SetScript("OnEnter", function() bar:SetVertexColor(1, 1, 1, 0.1) end)
            h:SetScript("OnLeave", function() bar:SetVertexColor(1, 1, 1, 0.05) end)
            it.header = h
            for _, row in ipairs(sec.rows) do
                it.rows[#it.rows + 1] = MakeRow(v.body, tab, row)
            end
            v.items[#v.items + 1] = it
        end
    end
    return v
end

Relayout = function(tab)
    local v = views[tab]
    if not v then return end
    local y = -6
    local synced = Synced()
    if tab ~= "inv" and synced then
        v.banner:ClearAllPoints()
        v.banner:SetPoint("TOPLEFT", v.body, "TOPLEFT", 4, y)
        v.banner:Show()
        y = y - 68
    else
        v.banner:Hide()
    end
    for _, it in ipairs(v.items) do
        local vis = SectionVisible(tab, it.sec)
        if not vis then
            it.header:Hide()
            for _, r in ipairs(it.rows) do r.frame:Hide() end
        else
            it.header:ClearAllPoints()
            it.header:SetPoint("TOPLEFT", v.body, "TOPLEFT", 0, y)
            it.header:Show()
            y = y - 32
            local open = OpenState(tab, it.sec, it.first)
            it.header.arrow:SetText(open and "-" or "+")
            for _, r in ipairs(it.rows) do
                if open then
                    r.frame:ClearAllPoints()
                    r.frame:SetPoint("TOPLEFT", v.body, "TOPLEFT", 0, y)
                    r.frame:Show()
                    y = y - r.frame:GetHeight() - 2
                else
                    r.frame:Hide()
                end
            end
            y = y - 6
        end
    end
    v.body:SetHeight(-y + 10)
end

RefreshAll = function()
    for _, v in pairs(views) do
        for _, it in ipairs(v.items) do
            for _, r in ipairs(it.rows) do if r.refresh then r.refresh() end end
        end
    end
end

local function ShowTab(tab)
    if not win then return end
    CloseMenu()
    curTab = tab
    local v = views[tab] or BuildView(tab)
    for id, view in pairs(views) do view.body:SetShown(id == tab) end
    scroll:SetScrollChild(v.body)
    scroll:SetVerticalScroll(0)
    Relayout(tab)
    RefreshAll()
    for _, t in ipairs(TABS) do
        local b = win.tabs[t.id]
        local on = (t.id == tab)
        b.sel:SetShown(on)
        b.text:SetTextColor(on and GOLD[1] or 0.85, on and GOLD[2] or 0.85, on and GOLD[3] or 0.85)
    end
    win.clear:SetShown(tab == "inv")
end

----------------------------------------------------------------------
-- the window
----------------------------------------------------------------------
local function Build()
    win = Box(UIParent, 472, 660, PANEL, GOLD)
    _G.BaggieOptions = win
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetPoint("CENTER")
    win:SetMovable(true) win:EnableMouse(true) win:SetClampedToScreen(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(s) s:StartMoving() end)
    win:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
    local t = win:CreateFontString(nil, "OVERLAY")
    t:SetFont("Fonts\\MORPHEUS.TTF", 17, "")
    t:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    t:SetPoint("TOPLEFT", 16, -12)
    t:SetText("Baggie")
    local sub = Text(win, 11, DIM)
    sub:SetPoint("LEFT", t, "RIGHT", 8, -1)
    sub:SetText("options")
    local x = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    x:SetPoint("TOPRIGHT", 2, 2)
    table.insert(_G.UISpecialFrames, "BaggieOptions")

    -- sync switch
    local sync = Box(win, 16, 16)
    sync:SetPoint("TOPLEFT", win, "TOPLEFT", 16, -44)
    local tick = sync:CreateTexture(nil, "OVERLAY")
    tick:SetTexture(WHITE)
    tick:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
    tick:SetPoint("TOPLEFT", 3, -3) tick:SetPoint("BOTTOMRIGHT", -3, 3)
    local sl = Text(win, 11)
    sl:SetPoint("LEFT", sync, "RIGHT", 8, 0)
    sl:SetText("Sync all windows (bank and guild bank follow the Inventory look)")
    local sbtn = CreateFrame("Button", nil, win)
    sbtn:SetPoint("TOPLEFT", sync, "TOPLEFT", -4, 4)
    sbtn:SetPoint("BOTTOMRIGHT", sl, "BOTTOMRIGHT", 4, -4)
    local function SyncDraw() tick:SetShown(Synced()) end
    sbtn:SetScript("OnClick", function()
        B.db.syncAll = not Synced()
        if not B.db.syncAll then B.EnsureScope("bank", true) B.EnsureScope("guild", true) end
        SyncDraw()
        Apply()
        for id in pairs(views) do Relayout(id) end
        RefreshAll()
    end)
    win.SyncDraw = SyncDraw

    -- tabs
    win.tabs = {}
    local prev
    for _, td in ipairs(TABS) do
        local b = CreateFrame("Button", nil, win)
        b:SetSize(140, 26)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -70) end
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints(b)
        b.bg:SetTexture(WHITE)
        b.bg:SetVertexColor(1, 1, 1, 0.05)
        b.sel = b:CreateTexture(nil, "ARTWORK")
        b.sel:SetTexture(WHITE)
        b.sel:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
        b.sel:SetPoint("BOTTOMLEFT") b.sel:SetPoint("BOTTOMRIGHT") b.sel:SetHeight(2)
        b.text = Text(b, 12, { 0.85, 0.85, 0.85 }, "CENTER")
        b.text:SetPoint("CENTER")
        b.text:SetText(td.name)
        b:SetScript("OnEnter", function(self) self.bg:SetVertexColor(1, 1, 1, 0.12) end)
        b:SetScript("OnLeave", function(self) self.bg:SetVertexColor(1, 1, 1, 0.05) end)
        b:SetScript("OnClick", function() ShowTab(td.id) end)
        win.tabs[td.id] = b
        prev = b
    end

    scroll = CreateFrame("ScrollFrame", "BaggieOptionsScroll", win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -102)
    scroll:SetPoint("BOTTOMRIGHT", -30, 46)

    local reset = FlatButton(win, "Reset this tab", 120, 24, function()
        local tab = curTab
        local tt = Target(tab)
        for _, it in ipairs(views[tab] and views[tab].items or {}) do
            if SectionVisible(tab, it.sec) then
                for _, r in ipairs(it.rows) do
                    local k = r.row.key
                    if k ~= "preset" and not r.row.base then
                        local d = B.DEFAULTS[k]
                        if tab ~= "inv" and k == "gap" then d = 6 end
                        if type(d) == "table" then d = { d[1], d[2], d[3] } end
                        tt[k] = d
                    end
                end
            end
        end
        Apply() RefreshAll()
    end)
    reset:SetPoint("BOTTOMLEFT", 14, 14)
    win.clear = FlatButton(win, "Clear saved spots", 130, 24, function()
        for k in pairs(B.Pins()) do B.Pins()[k] = nil end
        Apply() B.Print("all saved spots cleared")
    end)
    win.clear:SetPoint("BOTTOMRIGHT", -14, 14)
    win:SetScript("OnShow", function() SyncDraw() RefreshAll() end)
    win:SetScript("OnHide", CloseMenu)
    win:Hide()
end

function O.Toggle(tab)
    if not B.db then return end
    if not win then Build() end
    if win:IsShown() and not tab then win:Hide() return end
    win:Show()
    win.SyncDraw()
    ShowTab(tab or curTab)
end
