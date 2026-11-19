local ADDON, B = ...
-- The look of Baggie's windows comes from the same Look system as David's other add-ons (Look.lua).
B.WinLook.Setup({
    title = "Baggie",
    slash = "baggielook",
    media = "Interface\\AddOns\\Baggie\\Media\\",
    db = function() return B.db end,
    windows = {
        { id = "bags", name = "Inventory", global = "BaggieFrame", strip = "backdrop", noScale = true, noAlpha = true, defaultOn = true, hide = { "bar" }, title = function(f) return f.title end },
        { id = "bank", name = "Bank", global = "BaggieBankFrame", strip = "backdrop", noScale = true, noAlpha = true, defaultOn = true, hide = { "bar" }, title = function(f) return f.title end },
        { id = "guild", name = "Guild Bank", global = "BaggieGuildBankFrame", strip = "backdrop", noScale = true, noAlpha = true, defaultOn = true, hide = { "bar" }, title = function(f) return f.title end },
    },
})

-- once: carry Baggie's old color, background and border settings over to the shared look
local seed = CreateFrame("Frame")
seed:RegisterEvent("PLAYER_LOGIN")
seed:SetScript("OnEvent", function()
    local d = B.db
    if not d or d.lookSeeded then return end
    d.lookSeeded = true
    local L = B.WinLook
    for _, id in ipairs({ "bags", "bank", "guild" }) do
        local o = L.Get(id)
        if o then
            for _, k in ipairs({ "bgColor", "edgeColor", "bgStyle", "bgCustom", "bgNoTint", "alpha", "edgeAlpha", "edgeStyle", "edgeSize" }) do
                if d[k] ~= nil then o[k] = type(d[k]) == "table" and { d[k][1], d[k][2], d[k][3] } or d[k] end
            end
            if d.edgeColor then o.titleColor = { d.edgeColor[1], d.edgeColor[2], d.edgeColor[3] } end
            if d.flair then o.flair = d.flair end
            o.enabled = true
        end
    end
    L.Apply()
end)
