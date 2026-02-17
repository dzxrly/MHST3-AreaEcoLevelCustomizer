local function createEnumState()
    return {
        fixedIdToContent = {},
        contentToFixedId = {},
        fixedId = {},
        content = {}
    }
end

local function createState()
    return {
        cUserSaveDataParam = nil,
        languageIdx = 1, -- default to English
        ecoManager = nil,
        ecoRankFixedEnum = createEnumState(),
        areaFixedIdEnum = createEnumState(),
        otomonFixedIdEnum = createEnumState(),
        cSaveDataHelperArea = nil,
        cSaveDataHelperOption = nil,
        stateManager = nil,
        stageAreaParamTableData = nil,
        areaInfo = {},
        comboAreaNameAndFixedId = {
            name = {},
            fixedId = {}
        },
        comboFixedOtomon = {
            name = {},
            fixedId = {}
        },
        currentSelectedAreaIdx = 1,
        selectedAreaChanged = false,
        currentSelectedAreaInfo = nil,
        currentSelectedFixedOtomonIdx = 1,
        selectedFixedOtomonChanged = false,
        currentSelectedFixedOtomonInfo = nil,
        currentSelectedFixedOtomonEcoPtsDiffList = {},
        varyOtomonPool = {},
        varyOptionDict = {},
        varySlots = {}
    }
end

local M = createState()

function M.resetState()
    local nextState = createState()

    for key, value in pairs(nextState) do
        M[key] = value
    end
end

return M
