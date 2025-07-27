local lume = require 'ext.lume'
local serialize = lume.serialize

return {
    ---@param name string
    ---@param id? any
    ---@return string
    not_found = function (name, id)
        return name.." not found: "..serialize(id)
    end,

    ---@param key_path string
    ---@param object? table
    ---@return string
    missing_field = function (key_path, object)
        return "missing field: "..key_path..(object and ' '..serialize(object) or '')
    end,

    ---@param expected string
    ---@param value any
    ---@return string
    invalid_type = function (expected, value)
        return "invalid type: expected="..expected..', got='..type(value)..' ('..serialize(value)..')'
    end
}