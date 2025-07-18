local lume = require 'ext.lume'
local serialize = lume.serialize

return {
    ---@param name string
    ---@param id? any
    not_found = function (name, id)
        return name.." not found: "..serialize(id)
    end,

    ---@param key_path string
    ---@param object? table
    missing_field = function (key_path, object)
        return "missing field: "..key_path..(object and ' '..serialize(object) or '')
    end
}