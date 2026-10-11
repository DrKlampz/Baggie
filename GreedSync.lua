local ADDON, B = ...
-- Optional link to GreedUI: when it is installed and "Follow GreedUI" is on, Baggie takes its colors from it.
local function Sh(c, f) return { math.min(1, c[1] * f), math.min(1, c[2] * f), math.min(1, c[3] * f) } end
local function Sync(theme)
    if not (B.db and B.db.followGreedUI ~= false and theme) then return end
    local d = B.db
    if theme.bg then
        d.bgColor = { theme.bg[1], theme.bg[2], theme.bg[3] }
        d.bgStyle, d.bgNoTint = "solid", false
        d.slotStyle, d.slotColor = "filled", Sh(theme.bg, 2.2)
        d.slotQualityTint = false
    end
    d.alpha = math.max(0.9, tonumber(theme.bgAlpha) or 0.95)
    if theme.accent then
        local a = theme.accent
        d.edgeColor = { a[1], a[2], a[3] }
        d.edgeStyle, d.edgeSize, d.edgeAlpha = "line", tonumber(theme.borderSize) or 1, 1
        d.titleColor = Sh(a, 0.2)
        d.slotEdge, d.slotEdgeColor, d.slotEdgeAlpha, d.slotEdgeSize = "line", { a[1], a[2], a[3] }, 0.35, 1
        d.pinColor = { a[1], a[2], a[3] }
    end
    if B.Frame and B.Frame.ApplyLook then B.Frame.ApplyLook() B.Frame.Refresh() end
    if B.BankUI and B.BankUI.ApplyLook then B.BankUI.ApplyLook() end
    if B.RefreshBankGlows then B.RefreshBankGlows() end
end
B.SyncGreedUI = function() local G = _G.GreedUI if G and G.GetTheme then Sync(G.GetTheme()) end end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    local G = _G.GreedUI
    if not G then return end
    if G.RegisterPlugin then G.RegisterPlugin("Baggie", {
        open = function() if B.Options and B.Options.Toggle then B.Options.Toggle() end end,
        refresh = B.SyncGreedUI,
    }) end
    if G.OnTheme then G.OnTheme(Sync) end
end)
