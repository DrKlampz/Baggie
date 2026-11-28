-- Baggie: skip the banker's and the vendor's chat option.
-- Some bankers ask "Would you rather trust your goods with a goblin?" and only open the bank when you pick
-- "I would like to check my deposit box." With the option on (Options > Vendors and mail) Baggie picks it for you.
-- Hold Shift while talking to the banker to see the normal choices instead.
-- A vendor whose chat window offers nothing but "I would like to buy from you." opens its shop for you.
-- Hold Shift to see the chat window instead. Never taken when the chat has a quest or any other choice.
local ADDON, B = ...

local VENDOR_ICON = 132060   -- the gossip window's shopping-bag icon
local function LooksLikeVendor(name, icon, kind)
    if kind and tostring(kind):lower() == "vendor" then return true end
    if icon == VENDOR_ICON then return true end
    local t = tostring(name or ""):lower()
    return t:find("buy from you", 1, true) or t:find("browse your wares", 1, true) or t:find("see your wares", 1, true)
        or t:find("look at your wares", 1, true) or t:find("your goods", 1, true)
end

local function PickVendor()
    if not (B.db and B.db.autoVendorGossip ~= false) then return end
    if _G.IsShiftKeyDown and _G.IsShiftKeyDown() then return end
    local G = _G.C_GossipInfo
    if G and G.GetOptions and G.SelectOption then
        local opts = G.GetOptions()
        if type(opts) ~= "table" or #opts ~= 1 then return end
        if G.GetNumAvailableQuests and (G.GetNumAvailableQuests() or 0) > 0 then return end
        if G.GetNumActiveQuests and (G.GetNumActiveQuests() or 0) > 0 then return end
        local o = opts[1]
        if o.gossipOptionID and LooksLikeVendor(o.name or o.text, o.icon, nil) then G.SelectOption(o.gossipOptionID) end
    elseif _G.GetGossipOptions and _G.SelectGossipOption then
        local list = { _G.GetGossipOptions() }
        if #list ~= 2 then return end
        if _G.GetNumGossipAvailableQuests and (_G.GetNumGossipAvailableQuests() or 0) > 0 then return end
        if _G.GetNumGossipActiveQuests and (_G.GetNumGossipActiveQuests() or 0) > 0 then return end
        if LooksLikeVendor(list[1], nil, list[2]) then _G.SelectGossipOption(1) end
    end
end

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
ev:SetScript("OnEvent", function() pcall(Pick) pcall(PickVendor) end)
