local coreApi = require("AreaEcoLevelCustomizer.utils")
local state = require("AreaEcoLevelCustomizer.state")
local dataHelper = require("AreaEcoLevelCustomizer.data_helper")
local config = require("AreaEcoLevelCustomizer.config")
local i18n = require("AreaEcoLevelCustomizer.i18n")

local M = {}

local function getCSaveDataHelper()
    return sdk.get_managed_singleton("app.SaveDataManager"):get_field("_Helper")
end

local function rankEnumParser()
    coreApi.parseEnumFields("app.EcoDef.ECOLOGY_RANK_Fixed", state.ecoRankFixedEnum, false)
end

local function areaFixedIdEnumParser()
    coreApi.parseEnumFields("app.StageDef.AreaID_Fixed", state.areaFixedIdEnum, false)
end

local function otomonFixedIdEnumParser()
    coreApi.parseEnumFields("app.OtomonDef.ID_Fixed", state.otomonFixedIdEnum, true)

    local cSaveDataHelperEgg = getCSaveDataHelper():get_field("_Egg")
    -- filter out invalid otomon from state.otomonFixedIdEnum
    local validOtomonFixedIdEnum = {
        fixedIdToContent = {},
        contentToFixedId = {},
        fixedId = {},
        content = {}
    }
    local seenValidFixedId = {}
    for i = 1, #state.otomonFixedIdEnum.fixedId do
        local fixedId = state.otomonFixedIdEnum.fixedId[i]
        local content = state.otomonFixedIdEnum.fixedIdToContent[fixedId]
        local fixedIdKey = tostring(fixedId)

        if fixedId ~= config.RATH_FIXED_ID and not seenValidFixedId[fixedIdKey] and
            dataHelper.isOtomomCanGetEggInAnyArea(fixedId) then
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

    i18n.initLanguage()
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
