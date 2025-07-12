local M = {}

local lume = require 'ext.lume'

---@alias Datastore<D> fun(id:string):D

---@generic S
---@param default S
---@return Datastore<S>
function M.create(default)
    local storage = {}

    return function (id)
        local v = storage[id] or lume.clone(default)
        storage[id] = v
        return v
    end
end

return M