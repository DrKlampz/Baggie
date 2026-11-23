-- Baggie: skip the banker's chat option.
-- Some bankers ask "Would you rather trust your goods with a goblin?" and only open the bank when you pick
-- "I would like to check my deposit box." With the option on (Options > Vendors and mail) Baggie picks it for you.
-- Hold Shift while talking to the banker to see the normal choices instead.
local ADDON, B = ...

local function Pick()
    if not (B.db and B.db.autoBankGossip ~= false) then return end
    if _G.IsShiftKeyDown and _G.IsShiftKeyDown() then return end
    local G = _G.C_GossipInfo
    if G and G.GetOptions and G.SelectOption then
        local opts = G.GetOptions()
        if type(opts) ~= "table" then return end
        for _, o in ipairs(opts) do
            local t = tostring(o.name or o.text or ""):lower()
            if t:find("deposit box", 1, true) and o.gossipOptionID then
                G.SelectOption(o.gossipOptionID)
                return
            end
        end
    elseif _G.GetGossipOptions and _G.SelectGossipOption then
        local list = { _G.GetGossipOptions() }
        for i = 1, #list, 2 do
            if tostring(list[i]):lower():find("deposit box", 1, true) then
                _G.SelectGossipOption((i + 1) / 2)
                return
            end
        end
    end
end

local ev = _G.CreateFrame("Frame")
ev:RegisterEvent("GOSSIP_SHOW")
ev:SetScript("OnEvent", function() pcall(Pick) end)
