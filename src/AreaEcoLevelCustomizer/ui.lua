local state = require("AreaEcoLevelCustomizer.state")
local coreApi = require("AreaEcoLevelCustomizer.utils")
local dataHelper = require("AreaEcoLevelCustomizer.data_helper")
local config = require("AreaEcoLevelCustomizer.config")
local rankLogic = require("AreaEcoLevelCustomizer.rank_logic")
local i18n = require("AreaEcoLevelCustomizer.i18n")

local M = {}

local function getCurrentSelectedAreaInfo()
    return state.areaInfo[tostring(state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx])]
end

local function drawRankBoundary(currentLv, ranks)
    imgui.same_line()
    local visibleRanks = rankLogic.getVisibleRanks(ranks)
    for i = 1, #visibleRanks do
        local rankText = tostring(visibleRanks[i].rank)
        if tostring(currentLv) == rankText then
            imgui.text_colored(rankText, config.CHECKED_COLOR)
        else
            imgui.text(rankText)
        end
        if i < #visibleRanks then
            imgui.same_line()
        end
    end
end

local function drawEcoDiffButtons(items, labelPrefix, buttonSize, onClick)
    if items == nil then
        return
    end

    for i = 1, #items do
        local item = items[i]
        local label = labelPrefix(item, i)
        if item.enabled then
            if imgui.button(label, buttonSize) then
                onClick(item.diff)
            end
        else
            imgui.begin_disabled(true)
            imgui.button(label, buttonSize)
            imgui.end_disabled()
        end

        if i % 2 == 1 and i < #items then
            imgui.same_line()
        end
    end
end

local function drawFixedSection()
    imgui.text(i18n.getUIText("fixed_monsters_max", getCurrentSelectedAreaInfo().fixedNum))
    state.selectedFixedOtomonChanged, state.currentSelectedFixedOtomonIdx = imgui.combo(i18n.getUIText(
        "selected_fixed_otomon_label") .. "##selected_fixed_otomon", state.currentSelectedFixedOtomonIdx,
        state.comboFixedOtomon.name)
    if state.selectedAreaChanged or state.selectedFixedOtomonChanged then
        dataHelper.setCurrentSelectedFixedOtomonInfo()
    end

    imgui.text(i18n.getUIText("current_selected_otomon_rank_boundary"))
    if state.currentSelectedFixedOtomonInfo ~= nil then
        drawRankBoundary(state.currentSelectedFixedOtomonInfo.currentLv,
            state.currentSelectedFixedOtomonInfo.rankLowerLimitPtsList)
    end

    drawEcoDiffButtons(state.currentSelectedFixedOtomonEcoPtsDiffList, function(item, idx)
        return i18n.getUIText("level_up_to", item.rank) .. "##fixed_lvup_" .. tostring(idx)
    end, config.SMALL_BTN, function(diff)
        dataHelper.addEcoPtsByAreaFixedIdAndOtomonFixedId(diff)
    end)
end

local function drawSingleVarySlot(slotI, slot)
    imgui.begin_group()
    imgui.push_item_width(config.VARY_GROUP_WIDTH)

    local changed, newIdx = imgui.combo(i18n.getUIText("slot_label", slotI) .. "##vary_combo_" .. tostring(slotI),
        slot.selectedIdx, slot.combo.name)
    if changed then
        dataHelper.onVarySlotChanged(slotI, newIdx)
    end

    if slot.otomonInfo ~= nil then
        if slot.otomonInfo.lockFlag == true then
            imgui.text_colored(i18n.getUIText("locked_yes"), config.CHECKED_COLOR)
        else
            imgui.text_colored(i18n.getUIText("locked_no"), config.ERROR_COLOR)
        end

        imgui.text(i18n.getUIText("rank_boundary"))
        drawRankBoundary(slot.otomonInfo.currentLv, slot.otomonInfo.rankLowerLimitPtsList)

        drawEcoDiffButtons(slot.ecoPtsDiffList, function(item, idx)
            return i18n.getUIText("to_rank", item.rank) .. "##vary_" .. tostring(slotI) .. "_" .. tostring(idx)
        end, config.VARY_BTN, function(diff)
            dataHelper.addEcoPtsForVarySlot(slotI, diff)
        end)
    end

    imgui.pop_item_width()
    imgui.end_group()
end

local function collectSelectedVaryList()
    local selectedVaryList = {}
    local seen = {}
    for i = 1, #state.varySlots do
        local slot = state.varySlots[i]
        if slot ~= nil and slot.selectedOtomonFixedId ~= nil and slot.otomonInfo ~= nil and
            rankLogic.isNonZeroRank(slot.otomonInfo.currentLv) then
            local idKey = tostring(slot.selectedOtomonFixedId)
            if not seen[idKey] then
                seen[idKey] = true
                table.insert(selectedVaryList, slot.selectedOtomonFixedId)
            end
        end
    end
    return selectedVaryList
end

function M.drawUI()
    if state.cUserSaveDataParam ~= nil and not coreApi.isTableEmpty(state.areaInfo) then
        state.selectedAreaChanged, state.currentSelectedAreaIdx = imgui.combo(
            i18n.getUIText("selected_area_label") .. "##selected_area", state.currentSelectedAreaIdx,
            state.comboAreaNameAndFixedId.name)
        if state.selectedAreaChanged then
            dataHelper.setComboOtomonFixedAndVaryListByAreaFixedId(
                state.comboAreaNameAndFixedId.fixedId[state.currentSelectedAreaIdx])
        end

        drawFixedSection()
        imgui.new_line()

        imgui.text(i18n.getUIText("vary_monsters_max", getCurrentSelectedAreaInfo().varyNum))
        for slotI = 1, #state.varySlots do
            local slot = state.varySlots[slotI]
            drawSingleVarySlot(slotI, slot)

            -- two groups per row
            if slotI % 2 == 1 and slotI < #state.varySlots then
                imgui.same_line()
            end
        end
        if imgui.button(i18n.getUIText("update_vary_list"), config.LARGE_BTN) then
            dataHelper.updateVaryOtomonEcoList(collectSelectedVaryList())
        end
    end
end

return M
