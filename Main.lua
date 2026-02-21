local pve = _G["PVEFrame"]
local frame = CreateFrame("Frame", "WeeklyVaultCucc")
--                  1      2            3            4              5               6          7               8              9           10
local vaultILvl = { 0, '250 (259H)', '250 (259H)', '253 (263H)', '256 (263H)', '259 (266H)', '259 (269H)', '263 (269H)', '263 (269H)', '266 (272M)' }

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("ADDON_LOADED")

frame:SetSize(600, 300)
frame:SetPoint("BOTTOMLEFT", pve, "BOTTOMLEFT", 15, -325)

local text = frame:CreateFontString(nil, "OVERLAY")
-- anchor text at the top of the frame with padding
text:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
text:SetJustifyH("LEFT")
text:SetJustifyV("TOP")
text:SetWidth(frame:GetWidth() - 16)
text:SetWordWrap(true)
text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
text:SetShadowColor(0, 0, 0, 0.8)
text:SetShadowOffset(0, -1)
text:SetText("")
text:Hide()

if pve then
    pve:HookScript("OnShow", function(self)
        text:Show()
    end)
    pve:HookScript("OnHide", function(self)
        text:Hide()
    end)
end

text:SetScript("OnShow", function(self, event, ...)
    self:SetText(GetMythicPlusRunText(vaultILvl));
end)

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" or event == "PLAYER_ENTERING_WORLD" or event == "CHALLENGE_MODE_COMPLETED" then
        text:SetText(GetMythicPlusRunText(vaultILvl))
    end
end)

function GetMythicPlusRunText(vaultILvl)
    local UnTimedRunColor, TimedRunColor = { 136, 136, 136 }, { 65, 238, 58 }
    local runHistory = C_MythicPlus.GetRunHistory(false, true)
    local totalRuns = #runHistory

    local result = "No M+ runs have been completed this week. Get going!"

    if totalRuns > 0 then
        local runsByDungeon = {}
        local vaultRuns = "Top runs (affect weekly rewards):\n"
        local dungeonRuns = "Runs by Dungeon (" .. totalRuns .. " total):\n"


        table.sort(runHistory, ComposeSorts(
            SortDescending({ "level" }),
            SortAscending({ "mapChallengeModeID" })
        ))

        for index = 1, totalRuns do
            local run = runHistory[index]
            local name = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
            local completed = run.completed
            local level = run.level
            local vaultRewardLevel = math.min(level, #vaultILvl)

            if index <= 8 then
                vaultRuns = vaultRuns ..
                ColorByCompleted(level, completed, UnTimedRunColor, TimedRunColor) .. " " .. name;

                if index == 1 or index == 4 or index == 8 then
                    vaultRuns = vaultRuns .. " |cffa335ee(" .. vaultILvl[vaultRewardLevel] .. " ilvl option)|r"
                end

                vaultRuns = vaultRuns .. "\n"
            end

            if runsByDungeon[name] == nil then
                runsByDungeon[name] = { run }
            else
                tinsert(runsByDungeon[name], run)
            end
        end

        for name, _ in pairs(runsByDungeon) do
            dungeonRuns = dungeonRuns .. name .. ": ["
            for index, run in ipairs(runsByDungeon[name]) do
                dungeonRuns = dungeonRuns .. ColorByCompleted(run.level, run.completed, UnTimedRunColor, TimedRunColor)
                if index ~= #runsByDungeon[name] then
                    dungeonRuns = dungeonRuns .. ", "
                end
            end
            dungeonRuns = dungeonRuns .. "]\n"
        end

        result = vaultRuns .. "\n" .. dungeonRuns
    end

    return result
end
