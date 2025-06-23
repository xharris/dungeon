local M = {}

local lume = require 'ext.lume'

---@class Datastore<D>: { get: (fun(key:string):D), storage: (fun():table<string, D>) }

---@generic T
---@param default T
---@return Datastore<T>
function M.new(default)
    local storage = {}
    
    return {
        get = function(key)
            local data = storage[key]
            if data == nil and default then
                data = lume.clone(default)
            end
            if data == nil then
                data = {}
            end
            storage[key] = data
            return data
        end,

        storage = function()
            return storage
        end
    }
end

return M