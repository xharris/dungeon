local M = {}

local lume = require 'ext.lume'

---@alias AssetLoader<D> fun(value?:D):any

---@type table<string, any>
local cache = {}

---@generic D
---@param o {default:D, key:fun(t:D):(any[]), create:fun(t:D):any}
---@return AssetLoader<D>
function M.create(o)
    return function (value)
        value = lume.merge(o.default, value)
        local key = table.concat(o.key(value),',')
        local object = cache[key]
        if not object then
            object = o.create(value)
            cache[key] = object
        end
        return object
    end
end

return M