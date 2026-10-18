-- Baggie: tidy up quest items nothing needs any more.
--
-- Shift+Alt+click a quest item in your bags to mark it. Nothing is ever destroyed by marking. To destroy the
-- marked items, Alt+click the minimap button (or /baggie toss). Baggie asks the Questie add-on which quests in
-- your log still want each item, and keeps anything a quest needs, so your quests are not affected:
--   * an item a quest in your log wants (including one you only need to hand in) is always kept;
--   * if Baggie cannot be sure (Questie missing or not ready, or you are in a big raid group) it keeps everything;
--   * every item is checked again at the moment it would be destroyed, and you confirm the list first.
local ADDON, B = ...
local T = {}
B.Toss = T

local function CharTable()
    if not B.db then return nil end
    B.db.chars = B.db.chars or {}
    local key = B.CharKey()
    B.db.chars[key] = B.db.chars[key] or { pins = {} }
    return B.db.chars[key]
end

function T.Marks()
    local c = CharTable()
    if not c then return {} end
    c.toss = c.toss or {}
    return c.toss
end

function T.Marked(id) return id ~= nil and T.Marks()[id] == true end

local function Say(msg) B.Print(msg) end

-- the game's own flags for a bag slot: is it a quest item, does it start a quest
local function SlotFlags(bag, slot)
    local isQuest, startsQuest = false, false
    local getQ = (_G.C_Container and _G.C_Container.GetContainerItemQuestInfo) or _G.GetContainerItemQuestInfo
    if getQ then
        local ok, a, b, c = pcall(getQ, bag, slot)
        if ok then
            local qid, active
            if type(a) == "table" then isQuest, qid, active = a.isQuestItem, a.questID, a.isActive
            else isQuest, qid, active = a, b, c end
            if qid and qid > 0 and not active then startsQuest = true end
        end
    end
    return isQuest and true or false, startsQuest
end

local function IsQuestClass(id)
    if id and _G.C_Item and _G.C_Item.GetItemInfoInstant then
        local ok, _, _, _, _, _, classID = pcall(_G.C_Item.GetItemInfoInstant, id)
        if ok and classID == 12 then return true end
    end
    return false
end

-- Questie's list of what each quest in your log wants. nil when it cannot be asked.
local function Questie()
    local QL = _G.QuestieLoader
    if not (QL and QL.ImportModule) then return nil end
    local ok, tips = pcall(QL.ImportModule, QL, "QuestieTooltips")
    if not ok or type(tips) ~= "table" or type(tips.lookupByKey) ~= "table" then return nil end
    local okP, player = pcall(QL.ImportModule, QL, "QuestiePlayer")
    if okP and type(player) == "table" and (tonumber(player.numberOfGroupMembers) or 0) > 6 then return nil end
    return tips
end

-- how many real quests the log holds
local function LogQuests()
    local n = 0
    local GetN, GetInfo = _G.GetNumQuestLogEntries, _G.GetQuestLogTitle
    if GetN and GetInfo then
        local ok, total = pcall(GetN)
        for i = 1, ok and tonumber(total) or 0 do
            local okI, _, _, _, isHeader = pcall(GetInfo, i)
            if okI and not isHeader then n = n + 1 end
        end
    elseif _G.C_QuestLog and _G.C_QuestLog.GetNumQuestLogEntries then
        local ok, total = pcall(_G.C_QuestLog.GetNumQuestLogEntries)
        for i = 1, ok and tonumber(total) or 0 do
            local okI, info = pcall(_G.C_QuestLog.GetInfo, i)
            if okI and type(info) == "table" and not info.isHeader then n = n + 1 end
        end
    end
    return n
end

-- "needed": a quest in your log wants it. "free": none does. "unknown": cannot tell, so treat it as needed.
function T.Need(id)
    local tips = Questie()
    if not tips then return "unknown" end
    -- Questie fills this in when it loads your quest log; empty while you hold quests means it is not ready
    if next(tips.lookupByKey) == nil and LogQuests() > 0 then return "unknown" end
    local entry = tips.lookupByKey["i_" .. id]
    if entry and next(entry) ~= nil then return "needed" end
    return "free"
end

-- mark or unmark the item in this slot
function T.Toggle(bag, slot)
    local tex, _, _, _, link, id = B.SlotInfo(bag, slot)
    if not (tex and id) then return end
    local isQuest = SlotFlags(bag, slot)
    if not (isQuest or IsQuestClass(id)) then
        Say("that is not a quest item, so it can't be marked here")
        return
    end
    local marks = T.Marks()
    local name = link and (tostring(link):match("%[(.-)%]")) or "item"
    if marks[id] then
        marks[id] = nil
        Say("unmarked " .. name)
    else
        marks[id] = true
        local need = T.Need(id)
        if need == "needed" then Say("marked " .. name .. ", but a quest in your log still needs it, so it will be kept")
        elseif need == "unknown" then Say("marked " .. name .. ". Baggie can't check your quests without Questie, so it will not be destroyed")
        else Say("marked " .. name .. " (no quest in your log needs it). Alt+click the minimap button to destroy marked items") end
    end
    if B.Frame and B.Frame.Refresh then B.Frame.Refresh() end
end

-- every marked stack in your bags, sorted into what may go and what stays
local function Scan()
    local marks = T.Marks()
    local go, keep = {}, {}
    for _, bag in ipairs(B.CarriedBagIDs()) do
        for slot = 1, B.NumSlots(bag) do
            local tex, count, _, _, link, id = B.SlotInfo(bag, slot)
            if tex and id and marks[id] then
                local name = link and (tostring(link):match("%[(.-)%]")) or ("item " .. id)
                local need = T.Need(id)
                local _, starts = SlotFlags(bag, slot)
                local job = { bag = bag, slot = slot, id = id, count = tonumber(count) or 1, name = name, starts = starts }
                if need == "free" then go[#go + 1] = job
                else keep[#keep + 1] = { name = name, why = need == "needed" and "a quest in your log needs it" or "can't check your quests" } end
            end
        end
    end
    return go, keep
end

local running = false
local function Go()
    if running then return end
    local jobs = Scan()
    if #jobs == 0 then Say("nothing to destroy") return end
    running = true
    local done, skipped = 0, 0
    local function Step()
        local job = table.remove(jobs, 1)
        if not job then
            running = false
            Say(("destroyed %d stack%s%s"):format(done, done == 1 and "" or "s", skipped > 0 and (", kept " .. skipped .. " that changed") or ""))
            if B.Frame and B.Frame.Refresh then B.Frame.Refresh() end
            return
        end
        -- check once more, right now: same item still there, and still nothing needs it
        local tex, _, locked, _, _, id = B.SlotInfo(job.bag, job.slot)
        local ok = tex and id == job.id and not locked and T.Marked(id) and T.Need(id) == "free"
            and not (_G.InCombatLockdown and _G.InCombatLockdown())
            and not (_G.GetCursorInfo and _G.GetCursorInfo())
        if ok then
            B.Pickup(job.bag, job.slot)
            if _G.GetCursorInfo and _G.GetCursorInfo() == "item" and _G.DeleteCursorItem then
                _G.DeleteCursorItem()
                done = done + 1
            else
                if _G.ClearCursor then _G.ClearCursor() end
                skipped = skipped + 1
            end
        else
            skipped = skipped + 1
        end
        _G.C_Timer.After(0.3, Step)
    end
    Step()
end

if _G.StaticPopupDialogs then
    _G.StaticPopupDialogs["BAGGIE_TOSS"] = {
        text = "%s",
        button1 = "Destroy",
        button2 = "Cancel",
        OnAccept = function() local ok, err = pcall(Go) if not ok then Say("destroy failed: " .. tostring(err)) end end,
        timeout = 0,
        whileDead = false,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- the minimap button, /baggie toss
function T.Run()
    if not B.db then return end
    if _G.InCombatLockdown and _G.InCombatLockdown() then Say("not in combat") return end
    if _G.GetCursorInfo and _G.GetCursorInfo() then Say("put down the item on your cursor first") return end
    if not Questie() then
        Say("Baggie needs the Questie add-on to be sure a quest does not want an item, so it won't destroy anything without it")
        return
    end
    local go, keep = Scan()
    for _, k in ipairs(keep) do Say("keeping " .. k.name .. ": " .. k.why) end
    if #go == 0 then
        if #keep == 0 then Say("no items marked. Shift+Alt+click a quest item in your bags to mark it") end
        return
    end
    local lines = { "Destroy these quest items? No quest in your log needs them." }
    for i, j in ipairs(go) do
        if i > 8 then lines[#lines + 1] = ("...and %d more"):format(#go - 8) break end
        lines[#lines + 1] = ("%s%s%s"):format(j.name, j.count > 1 and (" x" .. j.count) or "", j.starts and "  (starts a quest you haven't taken)" or "")
    end
    if #keep > 0 then lines[#lines + 1] = ("(%d marked item%s kept)"):format(#keep, #keep == 1 and "" or "s") end
    if _G.StaticPopup_Show then _G.StaticPopup_Show("BAGGIE_TOSS", table.concat(lines, "\n")) end
end

function T.List()
    local n = 0
    for id in pairs(T.Marks()) do
        n = n + 1
        local name = (_G.GetItemInfo and _G.GetItemInfo(id)) or ("item " .. id)
        Say(("marked: %s (%s)"):format(name, T.Need(id)))
    end
    if n == 0 then Say("no items marked") end
end
