--- Language Index:
--- 0: Japanese
--- 1: English
--- 11: Korean
--- 12: Chinese (Traditional)
--- 13: Chinese (Simplified)
local coreApi = require("AreaEcoLevelCustomizer.utils")

local M = {
    languageIdx = 1,
    text = {
        [0] = {
            save_data_warning = "使用前に必ずセーブデータをバックアップしてください！！！",
            selected_area_label = "選択エリア",
            fixed_monsters_max = "固定モンスター: (最大: %s)",
            selected_fixed_otomon_label = "選択中の固定オトモン",
            current_selected_otomon_rank_boundary = "現在選択中のオトモンのランク境界:",
            level_up_to = "%s までレベルアップ",
            slot_label = "スロット %d",
            locked_yes = "ロック: はい",
            locked_no = "ロック: いいえ",
            rank_boundary = "ランク境界:",
            to_rank = "%s まで",
            vary_monsters_max = "変動モンスター: (最大: %s)",
            update_vary_list = "変動リストを更新",
            read_area_eco_info = "エリア生態情報を読み込む"
        },
        [1] = {
            save_data_warning = "Please BACK UP your save data before use!!!",
            selected_area_label = "Selected Area",
            fixed_monsters_max = "Fixed Monsters: (Max: %s)",
            selected_fixed_otomon_label = "Selected Fixed Monsties",
            current_selected_otomon_rank_boundary = "Current Selected Monsties Rank Boundary:",
            level_up_to = "Level Up to %s",
            slot_label = "Slot %d",
            locked_yes = "Locked: Yes",
            locked_no = "Locked: No",
            rank_boundary = "Rank Boundary:",
            to_rank = "To %s",
            vary_monsters_max = "Vary Monsters: (Max: %s)",
            update_vary_list = "Update Vary List",
            read_area_eco_info = "Read Area Eco Info"
        },
        [11] = {
            save_data_warning = "사용 전 반드시 세이브 데이터를 백업해 주세요!!!",
            selected_area_label = "선택 지역",
            fixed_monsters_max = "고정 몬스터: (최대: %s)",
            selected_fixed_otomon_label = "선택한 고정 동료몬",
            current_selected_otomon_rank_boundary = "현재 선택 동료몬 랭크 경계:",
            level_up_to = "%s까지 레벨 업",
            slot_label = "슬롯 %d",
            locked_yes = "잠금: 예",
            locked_no = "잠금: 아니오",
            rank_boundary = "랭크 경계:",
            to_rank = "%s까지",
            vary_monsters_max = "변동 몬스터: (최대: %s)",
            update_vary_list = "변동 목록 업데이트",
            read_area_eco_info = "지역 생태 정보 읽기"
        },
        [12] = {
            save_data_warning = "使用前請務必備份存檔！！！",
            selected_area_label = "目前區域",
            fixed_monsters_max = "固定魔物： (上限：%s)",
            selected_fixed_otomon_label = "目前固定隨行獸",
            current_selected_otomon_rank_boundary = "目前所選隨行獸等級界線：",
            level_up_to = "升級至 %s",
            slot_label = "欄位 %d",
            locked_yes = "鎖定：是",
            locked_no = "鎖定：否",
            rank_boundary = "等級界線：",
            to_rank = "至 %s",
            vary_monsters_max = "可變魔物： (上限：%s)",
            update_vary_list = "更新可變清單",
            read_area_eco_info = "讀取區域生態資訊"
        },
        [13] = {
            save_data_warning = "使用前请务必备份存档！！！",
            selected_area_label = "当前区域",
            fixed_monsters_max = "固定怪物：（上限：%s）",
            selected_fixed_otomon_label = "当前固定随行兽",
            current_selected_otomon_rank_boundary = "当前所选随行兽等级边界：",
            level_up_to = "升级到 %s",
            slot_label = "栏位 %d",
            locked_yes = "锁定：是",
            locked_no = "锁定：否",
            rank_boundary = "等级边界：",
            to_rank = "到 %s",
            vary_monsters_max = "可变怪物：（上限：%s）",
            update_vary_list = "更新可变列表",
            read_area_eco_info = "读取区域生态信息"
        }
    }
}

local function getCurrentTextLanguage()
    return tonumber(M.languageIdx) or 1
end

local function getCharacterLanguage(cSaveDataHelperOption)
    if cSaveDataHelperOption == nil then
        return nil
    end
    local textLang = cSaveDataHelperOption:call("getCharacterLanguage()")
    if textLang ~= nil then
        return tonumber(textLang)
    end
    return nil
end

function M.initLanguage(cSaveDataHelperOption)
    local existingLangOpts = coreApi.collectTableNumberKeys(M.text)
    local inGameLang = getCharacterLanguage(cSaveDataHelperOption)

    if inGameLang == nil then
        local saveDataManager = sdk.get_managed_singleton("app.SaveDataManager")
        if saveDataManager ~= nil then
            local helper = saveDataManager:get_field("_Helper")
            if helper ~= nil then
                local optionHelper = helper:get_field("_Option")
                inGameLang = getCharacterLanguage(optionHelper)
            end
        end
    end

    M.languageIdx = coreApi.getSupportedLanguageOrDefault(inGameLang, existingLangOpts, 1)
    return M.languageIdx
end

function M.getUIText(key, ...)
    return coreApi.getLocalizedText(M.text, key, getCurrentTextLanguage(), 1, ...)
end

function M.getTextLanguage(guid, cSaveDataHelperOption)
    local textLang = getCharacterLanguage(cSaveDataHelperOption) or getCurrentTextLanguage()
    return coreApi.getGuidTextByLanguage(guid, textLang)
end

return M
