local M = {}

local lume = require 'ext.lume'

---@class State
---@field enter? fun()
---@field update? fun(dt:number)
---@field draw? fun()
---@field leave? fun()

---@type table<string, State>
local states = {}

---@type string[]
local stack = {}

---@param require_path string
---@return State
local function get(require_path)
    if not states[require_path] then
        states[require_path] = require(require_path)
    end
    return states[require_path]
end

function M.push(require_path)
    local state = get(require_path)
    if not M.is_active(require_path) then
        table.insert(stack, require_path)
        if state.enter then
            state.enter()
        end
    end
end

---@return boolean ok
function M.pop()
    if #stack > 0 then
        local removed = table.remove(stack, #stack)
        local state = get(removed)
        if state.leave then
            state.leave()
        end
        return true
    end
    return false
end

---@return boolean
function M.is_active(require_path)
    return lume.find(stack, require_path) ~= nil
end

---@param dt number
function M.update(dt)
    for _, path in ipairs(stack) do
        local state = get(path)
        if state.update then
            state.update(dt)
        end
    end
end

function M.draw()
    for _, path in ipairs(stack) do
        local state = get(path)
        if state.draw then
            state.draw()
        end
    end
end

return M