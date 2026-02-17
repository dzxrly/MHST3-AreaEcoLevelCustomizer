local coreApi = require("AreaEcoLevelCustomizer.utils")
local state = require("AreaEcoLevelCustomizer.state")
local rankLogic = require("AreaEcoLevelCustomizer.rank_logic")
local i18n = require("AreaEcoLevelCustomizer.i18n")

local M = {}

local invalidOtomonFixedId = "-1679201920"

local function getFixedIdKey(fixedId)
    if fixedId == nil then
        return nil
    end

    local enumContent = state.otomonFixedIdEnum.fixedIdToContent[fixedId]
    if enumContent ~= nil then
        return tostring(enumContent)
    end

    local raw = tostring(fixedId)
    for enumFixedId, content in pairs(state.otomonFixedIdEnum.fixedIdToContent) do
        if tostring(enumFixedId) == raw then
            return tostring(content)
        end
    end

    return raw
end

local function buildVaryComboLabel(info)
    return "[" .. tostring(info.otomonFixedId) .. "] " .. info.otomonName .. " - Lv." .. tostring(info.currentLv)
end

local function buildSortedRankLowerLimitPtsList(otomonFixedId)
    local rankLowerLimitPtsList = {}
    for i = 1, #state.ecoRankFixedEnum.fixedId do
        local rankLowerLimitPts =
            M.getLowerLimitPtsByOtoFixedIdAndRank(otomonFixedId, state.ecoRankFixedEnum.content[i])
        rankLowerLimitPtsList[state.ecoRankFixedEnum.fixedId[i]] = rankLowerLimitPts
    end

    local sortedRankLowerLimitPtsList = {}
    for key, val in pairs(rankLowerLimitPtsList) do
        table.insert(sortedRankLowerLimitPtsList, {
            rank = tostring(state.ecoRankFixedEnum.fixedIdToContent[key]),
            pts = val
        })
    end
    table.sort(sortedRankLowerLimitPtsList, function(a, b)
        return a.pts > b.pts
    end)
    return sortedRankLowerLimitPtsList
end

local function buildAreaOtomonItem(areaIdx, areaFixedId, areaName, cAreaWork, otomonFixedId, pts, fixedFlag, lockFlag)
    return {
        areaIdx = areaIdx,
        areaFixedId = areaFixedId,
        areaContent = state.areaFixedIdEnum.content[areaIdx],
        areaName = areaName,
        cAreaWork = cAreaWork,
        otomonFixedId = otomonFixedId,
        otomonName = M.getOtoNameByOtoFixedId(otomonFixedId),
        ecoPts = pts,
        currentLv = M.getCurrentLvByOtoFixedId(otomonFixedId, pts),
        fixedFlag = coreApi.flagByteToBool(fixedFlag),
        lockFlag = coreApi.flagByteToBool(lockFlag),
        rankLowerLimitPtsList = buildSortedRankLowerLimitPtsList(otomonFixedId)
    }
end

local function getCurrentRankSortValue(info)
    if info == nil then
        return 0
    end
    if info.rankLowerLimitPtsList ~= nil and info.currentLv ~= nil then
        for i = 1, #info.rankLowerLimitPtsList do
            local rankItem = info.rankLowerLimitPtsList[i]
            if rankItem.rank == info.currentLv then
                return tonumber(rankItem.pts) or 0
            end
        end
    end
    return tonumber(info.ecoPts) or 0
end

local function clearVaryOptionSelectedFlag()
    for _, option in pairs(state.varyOptionDict) do
        option.selected = false
        option.selectedBy = nil
    end
end

local function getAvailableVaryOptionsForSlot(slotIdx)
    local options = {}
    for i = 1, #state.varyOtomonPool do
        local info = state.varyOtomonPool[i]
        local key = getFixedIdKey(info.otomonFixedId)
        local option = state.varyOptionDict[key]
        if option ~= nil and (not option.selected or option.selectedBy == slotIdx) then
            table.insert(options, info)
        end
    end
    return options
end

local function assignSlotSelectionFromOptions(slot, availableOptions, preferKey)
    slot.combo = {
        name = {},
        fixedId = {}
    }

    for i = 1, #availableOptions do
        table.insert(slot.combo.name, buildVaryComboLabel(availableOptions[i]))
        table.insert(slot.combo.fixedId, availableOptions[i].otomonFixedId)
    end

    slot.selectedIdx = 1
    if preferKey ~= nil then
        for i = 1, #slot.combo.fixedId do
            if getFixedIdKey(slot.combo.fixedId[i]) == preferKey then
                slot.selectedIdx = i
                break
            end
        end
    end

    if #slot.combo.fixedId > 0 then
        slot.selectedOtomonFixedId = slot.combo.fixedId[slot.selectedIdx]
    else
        slot.selectedOtomonFixedId = nil
        slot.selectedIdx = 1
    end
end

local function buildOtomonInfoByAreaAndFixedId(areaFixedId, otomonFixedId)
    if areaFixedId == nil or otomonFixedId == nil then
        return nil
    end

    local pts = state.cSaveDataHelperArea:call(
        "getOtCurrentEcoPtsFromTable(app.StageDef.AreaID_Fixed, app.OtomonDef.ID_Fixed)", areaFixedId, otomonFixedId)
    if pts == nil then
        pts = 0
    end

    return {
        otomonFixedId = otomonFixedId,
        otomonName = M.getOtoNameByOtoFixedId(otomonFixedId),
        ecoPts = pts,
        currentLv = M.getCurrentLvByOtoFixedId(otomonFixedId, pts),
        rankLowerLimitPtsList = buildSortedRankLowerLimitPtsList(otomonFixedId)
    }
end

local function findAreaCDataByAreaFixedId(areaFixedId)
    if state.stageAreaParamTableData ~= nil then
        local len = state.stageAreaParamTableData:call("getDataNum()")
        for i = 0, len - 1 do
            local cData = state.stageAreaParamTableData:call("getDataByIndex(System.Int32)", i)
            if cData ~= nil and cData:call("get_ID()") == areaFixedId then
                return {
                    obj = cData,
                    idx = i
                }
            end
        end
    end
    return {
        obj = nil,
        idx = -1
    }
end

function M.getOtoNameByOtoFixedId(otomonFixedId)
    local otomonDef = sdk.find_type_definition("app.OtomonDef"):get_method("Data(app.OtomonDef.ID_Fixed)")
    if otomonDef ~= nil then
        local otomonData = otomonDef(nil, otomonFixedId)
        if otomonData ~= nil then
            local otoNameGuid = otomonData:call("get_otomonName()")
            return tostring(i18n.getTextLanguage(otoNameGuid))
        end
    end
    return "[Unknown]" .. tostring(otomonFixedId)
end

function M.getAreaNameByAreaFixedId(areaFixedId)
    local cData = findAreaCDataByAreaFixedId(areaFixedId)
    if cData.obj ~= nil then
        return tostring(i18n.getTextLanguage(cData.obj:call("get_Name()")))
    end
    return "[Unknown]" .. tostring(areaFixedId)
end

function M.getCurrentLvByOtoFixedId(otomonFixedId, ecoPts)
    local lv = state.ecoManager:call("getEcoRankFixedFromPts(System.Int16, app.OtomonDef.ID_Fixed)", ecoPts,
        otomonFixedId)
    if lv ~= nil then
        return state.ecoRankFixedEnum.fixedIdToContent[lv] or ("[Unknown]" .. tostring(lv))
    end
    return "[Unknown]" .. tostring(ecoPts)
end

function M.getLowerLimitPtsByOtoFixedIdAndRank(otomonFixedId, rankContent)
    local pts = state.ecoManager:call(
        "getEcoRankLowerLimitPoint(app.EcoDef.ECOLOGY_RANK_Fixed, app.OtomonDef.ID_Fixed)",
        state.ecoRankFixedEnum.contentToFixedId[rankContent], otomonFixedId)
    if pts ~= nil then
        return tonumber(pts)
    end
    return 0
end

function M.getMaxNumByAreaFixedId(areaFixedId)
    local maxNum = state.ecoManager:call("getEcoTableMaxNumFromArea(app.StageDef.AreaID_Fixed)", areaFixedId)
    if maxNum ~= nil then
        return tonumber(maxNum)
    end
    return 0
end

function M.getVaryNumByAreaFixedId(areaFixedId)
    local varyNum = state.ecoManager:call("getVaryNumFromAreaTable(app.StageDef.AreaID_Fixed)", areaFixedId)
    if varyNum ~= nil then
        return tonumber(varyNum)
    end
    return 0
end

function M.setCurrentSelectedFixedOtomonInfo()
    local areaFixedId = state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx]
    if areaFixedId == nil then
        state.currentSelectedFixedOtomonInfo = nil
        state.currentSelectedFixedOtomonEcoPtsDiffList = {}
        return
    end
    local areaData = state.areaInfo[tostring(areaFixedId)]
    if areaData == nil or areaData.fixed == nil or areaData.fixed[state.currentSelectedFixedOtomonIdx] == nil then
        state.currentSelectedFixedOtomonInfo = nil
        state.currentSelectedFixedOtomonEcoPtsDiffList = {}
        return
    end
    state.currentSelectedFixedOtomonInfo = areaData.fixed[state.currentSelectedFixedOtomonIdx]
    state.currentSelectedFixedOtomonEcoPtsDiffList = rankLogic.buildEcoPtsDiffList(state.currentSelectedFixedOtomonInfo)
end

function M.setComboOtomonFixedAndVaryListByAreaFixedId(areaFixedId)
    -- save currently selected fixed otomon fixedId before resetting
    local prevFixedOtomonFixedId = state.comboFixedOtomon.fixedId[state.currentSelectedFixedOtomonIdx]

    state.comboFixedOtomon = {
        name = {},
        fixedId = {}
    }
    state.currentSelectedFixedOtomonIdx = 1
    state.currentSelectedFixedOtomonInfo = nil
    local singleAreaInfo = state.areaInfo[tostring(areaFixedId)]
    if singleAreaInfo ~= nil then
        for i = 1, #singleAreaInfo.fixed do
            local flag = true
            for j = 1, #state.comboFixedOtomon.fixedId do
                if tostring(state.comboFixedOtomon.fixedId[j]) == tostring(singleAreaInfo.fixed[i].otomonFixedId) then
                    flag = false
                    break
                end
            end
            if flag then
                local displayVal = "[" .. tostring(singleAreaInfo.fixed[i].otomonFixedId) .. "] " ..
                                       singleAreaInfo.fixed[i].otomonName .. " - Lv." ..
                                       tostring(singleAreaInfo.fixed[i].currentLv)
                table.insert(state.comboFixedOtomon.name, displayVal)
                table.insert(state.comboFixedOtomon.fixedId, singleAreaInfo.fixed[i].otomonFixedId)
            end
        end
    end

    -- restore fixed selection if previously selected otomon still exists in the new list
    if prevFixedOtomonFixedId ~= nil then
        for i = 1, #state.comboFixedOtomon.fixedId do
            if tostring(state.comboFixedOtomon.fixedId[i]) == tostring(prevFixedOtomonFixedId) then
                state.currentSelectedFixedOtomonIdx = i
                break
            end
        end
    end

    local prevAreaFixedId = nil
    if state.currentSelectedAreaInfo ~= nil then
        prevAreaFixedId = state.currentSelectedAreaInfo.areaFixedId
    end
    local areaChanged = (prevAreaFixedId == nil) or (tostring(prevAreaFixedId) ~= tostring(areaFixedId))

    state.currentSelectedAreaInfo = singleAreaInfo
    M.setCurrentSelectedFixedOtomonInfo()

    -- build vary otomon pool and initialize/rebuild vary slots
    M.buildVaryOtomonPool(areaFixedId)
    M.initVarySlots(areaChanged)
end

-- Build vary otomon pool from otomonFixedIdEnum, excluding fixed otomon fixedIds.
function M.buildVaryOtomonPool(areaFixedId)
    state.varyOtomonPool = {}
    state.varyOptionDict = {}
    local areaData = state.areaInfo[tostring(areaFixedId)]
    if areaData == nil then
        return
    end

    -- collect fixed otomon fixedIds as a set for exclusion
    local fixedOtomonSet = {}
    for i = 1, #areaData.fixed do
        local fixedKey = getFixedIdKey(areaData.fixed[i].otomonFixedId)
        if fixedKey ~= nil then
            fixedOtomonSet[fixedKey] = true
        end
    end

    local lockFlagByKey = {}
    if areaData.unlocked ~= nil then
        for i = 1, #areaData.unlocked do
            local unlockedKey = getFixedIdKey(areaData.unlocked[i].otomonFixedId)
            if unlockedKey ~= nil then
                lockFlagByKey[unlockedKey] = areaData.unlocked[i].lockFlag == true
            end
        end
    end

    local seenVaryKey = {}

    -- candidates are strictly constrained to otomonFixedIdEnum
    for i = 1, #state.otomonFixedIdEnum.fixedId do
        local enumFixedId = state.otomonFixedIdEnum.fixedId[i]
        local enumKey = getFixedIdKey(enumFixedId)
        if enumKey ~= nil and not fixedOtomonSet[enumKey] and not seenVaryKey[enumKey] then
            seenVaryKey[enumKey] = true
            local info = buildOtomonInfoByAreaAndFixedId(areaFixedId, enumFixedId)
            if info ~= nil then
                info.lockFlag = lockFlagByKey[enumKey] == true
                table.insert(state.varyOtomonPool, info)
                state.varyOptionDict[enumKey] = {
                    info = info,
                    selected = false,
                    selectedBy = nil
                }
            end
        end
    end

    -- Priority order:
    -- 1) lockFlag=true first
    -- 2) then by rank descending
    -- 3) finally by fixedId for stable output
    table.sort(state.varyOtomonPool, function(a, b)
        local aLock = a.lockFlag == true
        local bLock = b.lockFlag == true
        if aLock ~= bLock then
            return aLock
        end

        local aRank = getCurrentRankSortValue(a)
        local bRank = getCurrentRankSortValue(b)
        if aRank ~= bRank then
            return aRank > bRank
        end

        return tostring(a.otomonFixedId) < tostring(b.otomonFixedId)
    end)
end

-- Initialize vary slots based on varyNum, preserving previous selections
function M.initVarySlots(resetSelections)
    local areaFixedId = state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx]
    if areaFixedId == nil then
        state.varySlots = {}
        return
    end
    local areaData = state.areaInfo[tostring(areaFixedId)]
    if areaData == nil then
        state.varySlots = {}
        return
    end

    local varyNum = areaData.varyNum
    -- save previous selections for restoration (same area refresh only)
    local prevSelections = {}
    if not resetSelections then
        for i = 1, #state.varySlots do
            prevSelections[i] = state.varySlots[i].selectedOtomonFixedId
        end
    end

    state.varySlots = {}
    for i = 1, varyNum do
        state.varySlots[i] = {
            combo = {
                name = {},
                fixedId = {}
            },
            selectedIdx = 1,
            selectedOtomonFixedId = prevSelections[i],
            otomonInfo = nil,
            ecoPtsDiffList = {}
        }
    end

    M.rebuildVarySlotCombos()
end

-- Rebuild all vary slot combos with mutual exclusion logic
function M.rebuildVarySlotCombos()
    clearVaryOptionSelectedFlag()

    -- First pass: resolve each slot selection in order and mark selected flag.
    for i = 1, #state.varySlots do
        local slot = state.varySlots[i]
        local preferKey = getFixedIdKey(slot.selectedOtomonFixedId)
        local availableOptions = getAvailableVaryOptionsForSlot(i)
        assignSlotSelectionFromOptions(slot, availableOptions, preferKey)

        local selectedKey = getFixedIdKey(slot.selectedOtomonFixedId)
        if selectedKey ~= nil and state.varyOptionDict[selectedKey] ~= nil then
            state.varyOptionDict[selectedKey].selected = true
            state.varyOptionDict[selectedKey].selectedBy = i
        end
    end

    -- Second pass: rebuild combo arrays by final selected flags.
    for i = 1, #state.varySlots do
        local slot = state.varySlots[i]
        local keepKey = getFixedIdKey(slot.selectedOtomonFixedId)
        local availableOptions = getAvailableVaryOptionsForSlot(i)
        assignSlotSelectionFromOptions(slot, availableOptions, keepKey)
        M.setVarySlotOtomonInfo(i)
    end
end

function M.onVarySlotChanged(slotIdx, newIdx)
    local slot = state.varySlots[slotIdx]
    if slot == nil then
        return
    end

    slot.selectedIdx = newIdx
    slot.selectedOtomonFixedId = slot.combo.fixedId[newIdx]

    -- After any combo change, validate all sub-dictionaries and remove overlaps.
    M.rebuildVarySlotCombos()
end

-- Set otomon info and ecoPtsDiffList for a vary slot
function M.setVarySlotOtomonInfo(slotIdx)
    local slot = state.varySlots[slotIdx]
    if slot == nil then
        return
    end

    slot.otomonInfo = nil
    slot.ecoPtsDiffList = {}

    local areaFixedId = state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx]
    if areaFixedId == nil then
        return
    end

    local selectedFixedId = slot.selectedOtomonFixedId
    if selectedFixedId == nil then
        return
    end

    -- find from vary pool (already constrained by enum and filtered by fixed exclusion)
    local selectedKey = getFixedIdKey(selectedFixedId)
    for i = 1, #state.varyOtomonPool do
        if getFixedIdKey(state.varyOtomonPool[i].otomonFixedId) == selectedKey then
            slot.otomonInfo = state.varyOtomonPool[i]
            break
        end
    end

    if slot.otomonInfo == nil then
        return
    end

    slot.ecoPtsDiffList = rankLogic.buildEcoPtsDiffList(slot.otomonInfo)
end

-- Level up for a vary slot
function M.addEcoPtsForVarySlot(slotIdx, ecoPtsDiff)
    coreApi.executeUserCmd(function()
        local slot = state.varySlots[slotIdx]
        if slot == nil or slot.otomonInfo == nil then
            return
        end

        local areaFixedId = state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx]
        local otomonFixedId = slot.selectedOtomonFixedId

        state.cSaveDataHelperArea:call(
            "addEcoPointToTable(app.StageDef.AreaID_Fixed, System.Collections.Generic.Dictionary`2<System.Int32,System.Int16>)",
            areaFixedId, coreApi.createCSharpDictInt32Int16Instance({
                [otomonFixedId] = ecoPtsDiff
            }))

        M.getAreaInfo()
    end)
end

function M.getAreaInfo()
    if state.cUserSaveDataParam ~= nil and state.cSaveDataHelperArea ~= nil then
        local prevSelectedAreaFixedId = state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx]

        -- clear combo cache before rebuilding to avoid duplicated entries
        state.comboAreaNameAndFixedId = {
            name = {},
            fixedId = {}
        }

        local areaInfoTemp = {}

        for i = 1, #state.areaFixedIdEnum.fixedId do
            local cAreaWork = state.cSaveDataHelperArea:call(
                "getAreaSaveData(app.StageDef.AreaID_Fixed, app.savedata.cUserSaveDataParam)",
                state.areaFixedIdEnum.fixedId[i], state.cUserSaveDataParam)
            if cAreaWork ~= nil then
                local ecoTableWorkList = cAreaWork:get_field("_EcoTable")

                if ecoTableWorkList ~= nil then
                    for j = 0, #ecoTableWorkList - 1 do
                        local ecoTableWork = ecoTableWorkList[j]

                        if ecoTableWork ~= nil then
                            local otomonIdFixed = ecoTableWork:get_field("OtID_Fixed")
                            if tostring(otomonIdFixed) ~= invalidOtomonFixedId then
                                local pts = state.cSaveDataHelperArea:call(
                                    "getOtCurrentEcoPtsFromTable(app.StageDef.AreaID_Fixed, app.OtomonDef.ID_Fixed)",
                                    state.areaFixedIdEnum.fixedId[i], otomonIdFixed)
                                local fixedFlag = ecoTableWork:get_field("FixedFlag")
                                local lockFlag = ecoTableWork:get_field("LockFlag")
                                local item = buildAreaOtomonItem(i, state.areaFixedIdEnum.fixedId[i],
                                    M.getAreaNameByAreaFixedId(state.areaFixedIdEnum.fixedId[i]), cAreaWork,
                                    otomonIdFixed, pts, fixedFlag, lockFlag)
                                table.insert(areaInfoTemp, item)
                            end
                        end
                    end
                end
            else
                print("[Error] Failed to get area save data for area " .. tostring(state.areaFixedIdEnum.content[i]))
            end
        end

        -- reconstruct the areaInfo table by areaFixedId and then by fixedFlag
        local areaInfoByAreaFixedId = {}
        for i = 1, #areaInfoTemp do
            if areaInfoTemp[i].areaFixedId ~= nil then
                local fixedId = tostring(areaInfoTemp[i].areaFixedId)
                areaInfoByAreaFixedId[fixedId] = {
                    areaName = areaInfoTemp[i].areaName,
                    areaFixedId = areaInfoTemp[i].areaFixedId,
                    cAreaWork = areaInfoTemp[i].cAreaWork,
                    fixedNum = M.getMaxNumByAreaFixedId(areaInfoTemp[i].areaFixedId) -
                        M.getVaryNumByAreaFixedId(areaInfoTemp[i].areaFixedId),
                    varyNum = M.getVaryNumByAreaFixedId(areaInfoTemp[i].areaFixedId),
                    fixed = {},
                    unlocked = {}
                }

                if areaInfoTemp[i].areaName ~= nil and areaInfoTemp[i].areaName ~= "" then
                    -- only keep single instance of the area name
                    local flag = true
                    for j = 1, #state.comboAreaNameAndFixedId.fixedId do
                        if tostring(state.comboAreaNameAndFixedId.fixedId[j]) == tostring(areaInfoTemp[i].areaFixedId) then
                            flag = false
                            break
                        end
                    end
                    if flag then
                        table.insert(state.comboAreaNameAndFixedId.name,
                            "[" .. tostring(areaInfoTemp[i].areaFixedId) .. "] " .. areaInfoTemp[i].areaName)
                        table.insert(state.comboAreaNameAndFixedId.fixedId, areaInfoTemp[i].areaFixedId)
                    end
                end
            end
        end
        for i = 1, #areaInfoTemp do
            if areaInfoTemp[i].areaFixedId ~= nil then
                local fixedId = tostring(areaInfoTemp[i].areaFixedId)
                if areaInfoTemp[i].fixedFlag then
                    table.insert(areaInfoByAreaFixedId[fixedId].fixed, areaInfoTemp[i])
                else
                    table.insert(areaInfoByAreaFixedId[fixedId].unlocked, areaInfoTemp[i])
                end
            end
        end
        state.areaInfo = areaInfoByAreaFixedId

        -- restore selected area if possible
        state.currentSelectedAreaIdx = 1
        if prevSelectedAreaFixedId ~= nil then
            for i = 1, #state.comboAreaNameAndFixedId.fixedId do
                if tostring(state.comboAreaNameAndFixedId.fixedId[i]) == tostring(prevSelectedAreaFixedId) then
                    state.currentSelectedAreaIdx = i
                    break
                end
            end
        end

        -- set ComboOtomonFixedAndVaryListByAreaFixedId in init/refresh
        local currentSelectedAreaFixedId = state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx]
        if currentSelectedAreaFixedId ~= nil then
            M.setComboOtomonFixedAndVaryListByAreaFixedId(currentSelectedAreaFixedId)
        end
        M.setCurrentSelectedFixedOtomonInfo()
    end
end

function M.addEcoPtsByAreaFixedIdAndOtomonFixedId(ecoPtsDiff)
    coreApi.executeUserCmd(function()
        local areaFixedId = state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx]
        local otomonFixedId = state.currentSelectedFixedOtomonInfo.otomonFixedId
        state.cSaveDataHelperArea:call(
            "addEcoPointToTable(app.StageDef.AreaID_Fixed, System.Collections.Generic.Dictionary`2<System.Int32,System.Int16>)",
            areaFixedId, coreApi.createCSharpDictInt32Int16Instance({
                [otomonFixedId] = ecoPtsDiff
            }))
        M.getAreaInfo()
    end)
end

function M.updateVaryOtomonEcoList(newOtomonList)
    coreApi.executeUserCmd(function()
        if newOtomonList == nil or #newOtomonList == 0 then
            return
        end

        local areaFixedId = state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx]
        if areaFixedId == nil then
            return
        end

        local reList = coreApi.createCSharpListInstance(newOtomonList)
        if reList == nil then
            return
        end
        state.cSaveDataHelperArea:call(
            "overwriteEcoTable(app.StageDef.AreaID_Fixed, System.Collections.Generic.List`1<app.OtomonDef.ID_Fixed>)",
            areaFixedId, reList)
        M.getAreaInfo()
    end)
end

function M.isOtomomCanGetEggInAnyArea(otomonFixedId)
    local areaList = state.ecoManager:call("getEggAreaList(app.OtomonDef.ID_Fixed)", otomonFixedId)
    if areaList == nil then
        return false
    end
    return areaList:call("get_Count()") > 0
end

return M
