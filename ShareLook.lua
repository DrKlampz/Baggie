local ADDON, B = ...
-- Share the look with David's other add-ons (the newest change wins). Uses the same hub as their Look files: _G.GreedLookShare.
local KEYS = { "bgColor", "edgeColor", "alpha", "edgeAlpha", "bgStyle", "bgCustom", "bgNoTint", "edgeStyle", "edgeSize" }
local Hub = _G.GreedLookShare
if not Hub then Hub = { m = {} } _G.GreedLookShare = Hub end
local sharing = false

local function Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = Copy(x) end
    return t
end
local function Sh(c, f) local k = f > 1 and (f - 1) * 0.03 or 0 return { math.min(1, c[1] * f + k), math.min(1, c[2] * f + k), math.min(1, c[3] * f + k) } end
local function On() return B.db and B.db.shareLook ~= false end
local function Snap()
    local d = B.db
    if not d then return nil end
    local s = { enabled = true }
    for _, k in ipairs(KEYS) do if d[k] ~= nil then s[k] = Copy(d[k]) end end
    return s
end
local function Sig(s)
    local keys = {}
    for k in pairs(s) do keys[#keys + 1] = k end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do
        local v = s[k]
        if type(v) == "table" then
            local p = {}
            for i = 1, #v do p[i] = string.format("%.3f", tonumber(v[i]) or 0) end
            v = table.concat(p, ",")
        elseif type(v) == "number" then
            v = string.format("%.4f", v)
        end
        out[#out + 1] = k .. "=" .. tostring(v)
    end
    return table.concat(out, ";")
end
local function Take(snap, stamp)
    local d = B.db
    if not (d and snap) then return end
    for _, k in ipairs(KEYS) do if snap[k] ~= nil then d[k] = Copy(snap[k]) end end
    if snap.bgColor then
        d.slotStyle, d.slotColor, d.slotColor2 = "filled", Sh(snap.bgColor, 2.2), Sh(snap.bgColor, 3)
        d.slotQualityTint = false
    end
    d.shareSig = Sig(Snap())
    d.shareStamp = stamp
    sharing = true
    if B.Frame and B.Frame.ApplyLook then B.Frame.ApplyLook() if B.Frame.Refresh then B.Frame.Refresh() end end
    if B.BankUI and B.BankUI.ApplyLook then B.BankUI.ApplyLook() end
    sharing = false
end
local function Push(snap, stamp)
    local mine = Hub.m.Baggie
    for _, m in pairs(Hub.m) do
        if m ~= mine and m.on() and m.stamp() < stamp then pcall(m.take, snap, stamp) end
    end
end
local function Pull()
    local d = B.db
    if not d then return false end
    local best, bs = nil, d.shareStamp or 0
    for _, m in pairs(Hub.m) do
        if m ~= Hub.m.Baggie and m.on() and m.stamp() > bs then best, bs = m, m.stamp() end
    end
    if best and best.snap then
        local snap = best.snap()
        if snap then Take(snap, bs) return true end
    end
    return false
end
-- called after Baggie's look is applied: a change you made here is shared
function B.ShareCheck()
    if sharing or not B.db then return end
    local snap = Snap()
    if not snap then return end
    local sig = Sig(snap)
    local d = B.db
    if d.shareSig == nil then d.shareSig = sig d.shareStamp = d.shareStamp or 0 return end
    if sig == d.shareSig then return end
    d.shareSig = sig
    d.shareStamp = time()
    if On() then Push(snap, d.shareStamp) end
end
-- the option was just switched on
function B.ShareLookOn()
    if Pull() then return end
    local snap = Snap()
    if not snap then return end
    B.db.shareSig = Sig(snap)
    B.db.shareStamp = time()
    Push(snap, B.db.shareStamp)
end
Hub.m.Baggie = {
    on = On,
    stamp = function() return B.db and B.db.shareStamp or 0 end,
    snap = Snap,
    take = Take,
    seed = function(stamp)
        if not B.db then return end
        B.db.shareSig = Sig(Snap())
        B.db.shareStamp = stamp
    end,
}
-- the very first time (nobody has shared yet): one add-on's look becomes the starting point for all of them
local function Elect()
    if Hub.elected then return end
    Hub.elected = true
    local names = {}
    for name, m in pairs(Hub.m) do
        if m.on() then
            if m.stamp() > 0 then return end
            names[#names + 1] = name
        end
    end
    if #names < 2 then return end
    table.sort(names)
    local lead = (Hub.m.Baggie and Hub.m.Baggie.on() and "Baggie") or names[1]
    local stamp = time()
    local m = Hub.m[lead]
    local snap = m.snap()
    if not snap then return end
    m.seed(stamp)
    Push(snap, stamp)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if B.Frame and B.Frame.ApplyLook then hooksecurefunc(B.Frame, "ApplyLook", function() B.ShareCheck() end) end
    C_Timer.After(1.5, function() if On() then pcall(Elect) Pull() end end)
end)
