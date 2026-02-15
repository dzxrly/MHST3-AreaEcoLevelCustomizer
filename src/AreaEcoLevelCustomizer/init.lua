local coreApi = require("AreaEcoLevelCustomizer.utils")
local state = require("AreaEcoLevelCustomizer.state")
local dataHelper = require("AreaEcoLevelCustomizer.data_helper")
local config = require("AreaEcoLevelCustomizer.config")

local M = {}

local function appendEnumValue(enumState, enumName, enumValue)
    enumState.fixedIdToContent[enumValue] = enumName
    enumState.contentToFixedId[enumName] = enumValue
    table.insert(enumState.fixedId, enumValue)
    table.insert(enumState.content, enumName)
end

local function parseEnumFields(typeName, enumState, dedupeByValue)
    local typeDef = sdk.find_type_definition(typeName)
    if typeDef == nil then
        return
    end

    local enumFields = typeDef:get_fields()
    if enumFields == nil then
        return
    end

    local seenEnumValue = {}
    for _, field in ipairs(enumFields) do
        if field:is_static() then
            local enumName = field:get_name()
            local enumValue = field:get_data(nil)
            local valueKey = tostring(enumValue)
            if coreApi.isValidEnumName(enumName) and (not dedupeByValue or not seenEnumValue[valueKey]) then
                seenEnumValue[valueKey] = true
                appendEnumValue(enumState, enumName, enumValue)
            end
        end
    end
end


local function getCSaveDataHelper()
    return sdk.get_managed_singleton("app.SaveDataManager"):get_field("_Helper")
end


local function rankEnumParser()
    parseEnumFields("app.EcoDef.ECOLOGY_RANK_Fixed", state.ecoRankFixedEnum, false)
end

local function areaFixedIdEnumParser()
    parseEnumFields("app.StageDef.AreaID_Fixed", state.areaFixedIdEnum, false)
end

local function otomonFixedIdEnumParser()
    parseEnumFields("app.OtomonDef.ID_Fixed", state.otomonFixedIdEnum, true)

    local cSaveDataHelperEgg = getCSaveDataHelper():get_field("_Egg")
    -- filter out invalid otomon from state.otomonFixedIdEnum
    local validOtomonFixedIdEnum = {
        fixedIdToContent = {},
        contentToFixedId = {},
        fixedId = {},
        content = {},
    }
    local seenValidFixedId = {}
    for i = 1, #state.otomonFixedIdEnum.fixedId do
        local fixedId = state.otomonFixedIdEnum.fixedId[i]
        local content = state.otomonFixedIdEnum.fixedIdToContent[fixedId]
        local fixedIdKey = tostring(fixedId)
        if cSaveDataHelperEgg:call("isHatchedOtomon(app.OtomonDef.ID_Fixed)", fixedId) and
            fixedId ~= config.RATH_FIXED_ID and
            not seenValidFixedId[fixedIdKey] then
            seenValidFixedId[fixedIdKey] = true
            validOtomonFixedIdEnum.fixedIdToContent[fixedId] = content
            validOtomonFixedIdEnum.contentToFixedId[content] = fixedId
            table.insert(validOtomonFixedIdEnum.fixedId, fixedId)
            table.insert(validOtomonFixedIdEnum.content, content)
        end
    end
    state.otomonFixedIdEnum = validOtomonFixedIdEnum
end



function M.modInit()
    print("Initializing...")
    state.cUserSaveDataParam = sdk.get_managed_singleton("app.SaveDataManager"):call("get_UserSaveData()")
    state.ecoManager = sdk.get_managed_singleton("app.EcoManager")
    state.cSaveDataHelperArea = getCSaveDataHelper():get_field("_Area")
    state.cSaveDataHelperOption = getCSaveDataHelper():get_field("_Option")
    state.stateManager = sdk.get_managed_singleton("app.StageManager")
    state.stageAreaParamTableData = state.stateManager:call("get_AreaParamTableUserData()")
    state.languageIdx = getCSaveDataHelper():get_field("_Option"):call("getCharacterLanguage()")

    print("Language Index: " .. tostring(state.languageIdx))

    rankEnumParser()
    areaFixedIdEnumParser()
    otomonFixedIdEnumParser()

    print("Initialization complete")
end

function M.onStart()
    M.modInit()
    dataHelper.getAreaInfo()
end

return M
