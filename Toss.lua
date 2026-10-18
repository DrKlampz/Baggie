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

-- The game's own quest log: every quest's title, its objective lines and (when it can be read) its description.
-- An item counts as wanted when its name, or any distinctive word of its name, shows up anywhere in that text.
-- That errs on the side of keeping things: "Bundle of Reports" is kept because a quest called "The Warsong
-- Reports" is in the log, and "Letter to Jin'Zil" because its quest has the same name.
local STOP = { the = true, ["and"] = true, ["for"] = true, with = true, from = true, that = true, this = true, your = true }

local function Words(text)
    local t = {}
    text = tostring(text or ""):lower():gsub("'s%f[%A]", ""):gsub("[^%a]+", " ")
    for w in text:gmatch("%a+") do
        if #w >= 4 and not STOP[w] then t[#t + 1] = w end
    end
    return t
end

local logCache = { at = -100, full = false, text = nil }

local function QuestEntries()
    local list = {}
    local CQ = _G.C_QuestLog
    if CQ and CQ.GetNumQuestLogEntries and CQ.GetInfo then
        local ok, n = pcall(CQ.GetNumQuestLogEntries)
        for i = 1, ok and tonumber(n) or 0 do
            local okI, info = pcall(CQ.GetInfo, i)
            if okI and type(info) == "table" and not info.isHeader and info.questID then
                list[#list + 1] = { id = info.questID, index = i, title = info.title }
            end
        end
    elseif _G.GetNumQuestLogEntries and _G.GetQuestLogTitle then
        local ok, n = pcall(_G.GetNumQuestLogEntries)
        for i = 1, ok and tonumber(n) or 0 do
            local okI, title, _, _, isHeader, _, _, _, questID = pcall(_G.GetQuestLogTitle, i)
            if okI and not isHeader then list[#list + 1] = { id = questID, index = i, title = title } end
        end
    end
    return list
end

-- returns one lowercase string with everything the log says, or nil when the log cannot be read
local function LogText(full)
    local now = _G.GetTime and _G.GetTime() or 0
    if logCache.text and now - logCache.at < 3 and (logCache.full or not full) then return logCache.text end
    local entries = QuestEntries()
    local parts = {}
    local CQ = _G.C_QuestLog
    for _, q in ipairs(entries) do
        parts[#parts + 1] = tostring(q.title or "")
        if CQ and CQ.GetQuestObjectives and q.id then
            local ok, objs = pcall(CQ.GetQuestObjectives, q.id)
            if ok and type(objs) == "table" then
                for _, o in ipairs(objs) do parts[#parts + 1] = tostring(o.text or "") end
            end
        end
    end
    if full and #entries > 0 then
        -- descriptions are only readable for the selected quest; put the selection back afterwards
        local selOld
        if CQ and CQ.GetSelectedQuest then local ok, v = pcall(CQ.GetSelectedQuest) if ok then selOld = v end end
        for _, q in ipairs(entries) do
            local ok = false
            if CQ and CQ.SetSelectedQuest and q.id then ok = pcall(CQ.SetSelectedQuest, q.id)
            elseif _G.SelectQuestLogEntry and q.index then ok = pcall(_G.SelectQuestLogEntry, q.index) end
            if ok and _G.GetQuestLogQuestText then
                local okT, desc, obj = pcall(_G.GetQuestLogQuestText)
                if okT then parts[#parts + 1] = tostring(desc or "") parts[#parts + 1] = tostring(obj or "") end
            end
        end
        if selOld and CQ and CQ.SetSelectedQuest then pcall(CQ.SetSelectedQuest, selOld) end
    end
    local text = table.concat(parts, " \n "):lower()
    logCache = { at = now, full = full and true or false, text = text }
    return text
end

-- Questie, when it happens to be loaded, can only add protection: it never allows anything the game's log does not.
-- It matters: the log's own text does not always name an item you hand in (a liver, a shell), but Questie knows
local function QuestieWants(id)
    local QL = _G.QuestieLoader
    if not (QL and QL.ImportModule) then return false end
    local ok, tips = pcall(QL.ImportModule, QL, "QuestieTooltips")
    if not ok or type(tips) ~= "table" or type(tips.lookupByKey) ~= "table" then return false end
    local entry = tips.lookupByKey["i_" .. id]
    return entry ~= nil and next(entry) ~= nil
end

function T.HasQuestie()
    local QL = _G.QuestieLoader
    if not (QL and QL.ImportModule) then return false end
    local ok, tips = pcall(QL.ImportModule, QL, "QuestieTooltips")
    return ok and type(tips) == "table" and type(tips.lookupByKey) == "table"
end

-- "needed": a quest in your log looks like it wants it. "free": nothing in the log mentions it. "unknown": the log can't be read.
function T.Need(id, full)
    local name = _G.C_Item and _G.C_Item.GetItemNameByID and _G.C_Item.GetItemNameByID(id)
    if not name and _G.GetItemInfo then name = _G.GetItemInfo(id) end
    if not name then return "unknown" end
    local text = LogText(full)
    if not text then return "unknown" end
    if QuestieWants(id) then return "needed" end
    if text:find(name:lower(), 1, true) then return "needed" end
    for _, w in ipairs(Words(name)) do
        -- whole words only, so "iron" does not match "environment"
        if (" " .. text:gsub("[^%a]+", " ") .. " "):find(" " .. w .. " ", 1, true) then return "needed" end
    end
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
        local need = T.Need(id, true)
        if need == "needed" then Say("marked " .. name .. ", but your quest log still mentions it, so it will be kept")
        elseif need == "unknown" then Say("marked " .. name .. ". Baggie can't check your quests without Questie, so it will not be destroyed")
        else Say("marked " .. name .. " (your quest log never mentions it). Alt+click the minimap button to destroy marked items") end
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
                local need = T.Need(id, true)
                local _, starts = SlotFlags(bag, slot)
                local job = { bag = bag, slot = slot, id = id, count = tonumber(count) or 1, name = name, starts = starts }
                if need == "free" then go[#go + 1] = job
                else keep[#keep + 1] = { name = name, why = need == "needed" and "your quest log mentions it" or "can't read your quest log" } end
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
        local ok = tex and id == job.id and not locked and T.Marked(id) and T.Need(id, true) == "free"
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
    local go, keep = Scan()
    for _, k in ipairs(keep) do Say("keeping " .. k.name .. ": " .. k.why) end
    if #go == 0 then
        if #keep == 0 then Say("no items marked. Shift+Alt+click a quest item in your bags to mark it") end
        return
    end
    local lines = { "Destroy these quest items? Your quest log never mentions them." }
    for i, j in ipairs(go) do
        if i > 8 then lines[#lines + 1] = ("...and %d more"):format(#go - 8) break end
        lines[#lines + 1] = ("%s%s%s"):format(j.name, j.count > 1 and (" x" .. j.count) or "", j.starts and "  (starts a quest you haven't taken)" or "")
    end
    if #keep > 0 then lines[#lines + 1] = ("(%d marked item%s kept)"):format(#keep, #keep == 1 and "" or "s") end
    if not T.HasQuestie() then
        lines[#lines + 1] = "|cffff9933Questie isn't loaded, so this only compares names against your quest text. Items you hand in without it being named (a liver, a shell) can be missed. Check the list.|r"
    end
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
