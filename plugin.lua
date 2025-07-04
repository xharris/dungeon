local M = {}

---@class PluginOptions
---@field on_load fun()

---@type PluginOptions[]
local plugins = {}

---@param t PluginOptions
function M.add(t)
    table.insert(plugins, t)
end

function M.load()
    for _, plugin in ipairs(plugins) do
        plugin.on_load()
    end
end

return M