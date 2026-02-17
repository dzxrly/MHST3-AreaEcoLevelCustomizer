--- Area Eco Level Custom
--- Author: Egg Targaryen
--- For Monster Hunter Stories 3
local init = require("AreaEcoLevelCustomizer.init")
local ui = require("AreaEcoLevelCustomizer.ui")
local state = require("AreaEcoLevelCustomizer.state")
local coreApi = require("AreaEcoLevelCustomizer.utils")
local config = require("AreaEcoLevelCustomizer.config")
local i18n = require("AreaEcoLevelCustomizer.i18n")

local isBtnClicked = false

-- DO NOT CHANGE THE NEXT LINE, ONLY UPDATE THE VERSION NUMBER
local modVersion = "v0.3.0"
-- DO NOT CHANGE THE PREVIOUS LINE

sdk.hook(sdk.find_type_definition("app.SaveDataManager"):get_method("getTitleText()"), function(args)
end, function(retval)
    state.resetState()
    init.onStart()
    coreApi.setUserCmdPostHook(init.modInit)
    return retval
end)

-- re.on_application_entry("UpdateScene", function()
--     if state.cUserSaveDataParam == nil then
--         state.resetState()
--         init.onStart()
--         coreApi.setUserCmdPostHook(init.modInit)
--     end
-- end)

re.on_draw_ui(function()
    if imgui.tree_node("Area Eco Level Custom") then
        imgui.text("VERSION: " .. modVersion .. " | by Egg Targaryen")
        imgui.text_colored(i18n.getUIText("save_data_warning"), config.ERROR_COLOR)
        imgui.text_colored(i18n.getUIText("save_data_warning"), config.ERROR_COLOR)
        imgui.text_colored(i18n.getUIText("save_data_warning"), config.ERROR_COLOR)
        imgui.new_line()

        if imgui.button(i18n.getUIText("read_area_eco_info"), config.LARGE_BTN) then
            coreApi.executeUserCmd(function()
                state.resetState()
                init.onStart()
                isBtnClicked = true
            end)
        end
        imgui.new_line()

        if state.cUserSaveDataParam ~= nil and not coreApi.isTableEmpty(state.areaInfo) and isBtnClicked then
            ui.drawUI()
        end
        imgui.new_line()

        imgui.tree_pop()
    end
end)
