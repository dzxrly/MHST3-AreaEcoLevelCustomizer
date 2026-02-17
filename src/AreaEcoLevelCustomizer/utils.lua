local M = {}
local pendingUserCmds = {}
local userCmdHookInstalled = false
local postUserCmdHook = nil
local enum_none = "NONE"
local enum_max = "MAX"
local enum_unknown = "UNKNOWN"
local enum_invalid = "INVALID"

local function installUserCmdHook()
    if userCmdHookInstalled then
        return
    end
    local methodDef = sdk.find_type_definition("app.GUIManager"):get_method("update()")
    if methodDef == nil then
        return
    end
    userCmdHookInstalled = true
    sdk.hook(methodDef, function(args)
        if #pendingUserCmds == 0 then
            return
        end
        local current = pendingUserCmds
        pendingUserCmds = {}
        for i = 1, #current do
            local ok, err = pcall(current[i])
            if not ok then
                print("[AreaEcoLevelCustomizer] executeUserCmd error: " .. tostring(err))
            end
        end
        if postUserCmdHook ~= nil then
            local ok, err = pcall(postUserCmdHook)
            if not ok then
                print("[AreaEcoLevelCustomizer] postUserCmdHook error: " .. tostring(err))
            end
        end
    end, function(retval)
        return retval
    end)
end

function M.isValidEnumName(enumName)
    -- filter enum_none, enum_max, enum_unknown, enum_invalid from enum
    return tostring(enumName) ~= enum_none and tostring(enumName) ~= enum_max and tostring(enumName) ~= enum_unknown and
               tostring(enumName) ~= enum_invalid
end

function M.flagByteToBool(flagByte, isToString)
    local flagBool = tostring(flagByte) == "255"
    if isToString then
        return tostring(flagBool)
    else
        return flagBool
    end
end

function M.appendEnumValue(enumState, enumName, enumValue)
    enumState.fixedIdToContent[enumValue] = enumName
    enumState.contentToFixedId[enumName] = enumValue
    table.insert(enumState.fixedId, enumValue)
    table.insert(enumState.content, enumName)
end

function M.parseEnumFields(typeName, enumState, dedupeByValue)
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
            if M.isValidEnumName(enumName) and (not dedupeByValue or not seenEnumValue[valueKey]) then
                seenEnumValue[valueKey] = true
                M.appendEnumValue(enumState, enumName, enumValue)
            end
        end
    end
end

function M.isTableEmpty(table)
    -- compatible with dictionary
    if table == nil then
        return true
    end
    local len = 0
    for _, _ in pairs(table) do
        len = len + 1
    end
    return len == 0
end

function M.uniqueImguiText(text, suffix)
    return text .. "##" .. suffix
end

function M.CSharpDictEnumerator(dictObj)
    if not dictObj then
        return {}
    end
    local count = dictObj:call("get_Count")
    if not count or count == 0 then
        return {}
    end
    local entries = dictObj:get_field("entries")
    if not entries then
        entries = dictObj:get_field("_entries")
    end
    if not entries then
        return {}
    end
    local items = entries:get_elements()
    local result = {}
    for i, entry in pairs(items) do
        if entry then
            local k = entry:get_field("key")
            local v = entry:get_field("value")
            if k ~= nil and v ~= nil then
                table.insert(result, {
                    key = k,
                    value = v
                })
            end
        end
    end
    return result
end

function M.createCSharpDictInt32Int16Instance(luaTable)
    if luaTable == nil then
        return nil
    end
    local typeName = "System.Collections.Generic.Dictionary`2<System.Int32,System.Int16>"
    local dictTypeDef = sdk.find_type_definition(typeName)
    if dictTypeDef == nil then
        print("createCSharpDictInt32Int16Instance: " .. typeName .. " not found")
        return nil
    end
    local dictInstance = dictTypeDef:create_instance()
    if dictInstance then
        dictInstance:call(".ctor()")
    else
        return nil
    end
    for k, v in pairs(luaTable) do
        local keyNum = tonumber(k)
        local valNum = tonumber(v)
        if keyNum and valNum then
            dictInstance:call("Add", keyNum, valNum)
        end
    end
    return dictInstance
end

function M.CSharpListEnumerator(listObj)
    if not listObj then
        return {}
    end
    local count = listObj:call("get_Count")
    if not count then
        count = listObj:get_field("_size")
    end
    if not count or count == 0 then
        return {}
    end
    local items_array = listObj:get_field("_items")
    if not items_array then
        return {}
    end
    local raw_elements = items_array:get_elements()
    local result = {}
    for i = 0, count - 1 do
        local val = raw_elements[i]
        if val then
            local num_val = tonumber(sdk.to_int64(val))
            table.insert(result, num_val)
        end
    end
    return result
end

function M.createCSharpListInstance(luaArray)
    if not luaArray then
        return nil
    end
    local typeName = "System.Collections.Generic.List`1<app.OtomonDef.ID_Fixed>"
    local listTypeDef = sdk.find_type_definition(typeName)
    if not listTypeDef then
        sdk.request_frame_output("错误: 找不到 List 类型定义: " .. typeName)
        return nil
    end
    local listInstance = listTypeDef:create_instance()
    if listInstance then
        listInstance:call(".ctor()") -- 必须调用构造函数
    else
        return nil
    end
    for _, value in ipairs(luaArray) do
        local num_val = tonumber(value)
        if num_val then
            listInstance:call("Add", num_val)
        end
    end
    return listInstance
end

function M.setUserCmdPostHook(hookFunc)
    postUserCmdHook = hookFunc
end

function M.executeUserCmd(executeFunc)
    if executeFunc == nil then
        return
    end
    installUserCmdHook()
    table.insert(pendingUserCmds, executeFunc)
end

return M
