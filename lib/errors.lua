local lume = require 'ext.lume'
local serialize = lume.serialize

return {
    ---@param name string
    ---@param id? any
    not_found = function (name, id)
        return name.." not found: "..serialize(id)
    end
}