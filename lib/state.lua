local M = {}

local lume = require 'ext.lume'
local log = require 'lib.log'

---@class State
---@field enter? fun(...:any):string?
---@field update? fun(dt:number)
---@field pre_draw? fun()
---@field draw? fun()
---@field leave? fun()
---@field _skip_first_update? boolean

---@type table<string, State>
local states = {}

---@type string[]
local stack = {}

---@param require_path string
---@return State
local function get(require_path)
    if not states[require_path] then
        states[require_path] = log.log_methods(require_path, require(require_path), {
            exclude = {'update', 'draw', 'pre_draw'}
        })
    end
    return states[require_path]
end

---Push a state onto the stack
---@param require_path string
---@param ... any
function M.push(require_path, ...)
    local state = get(require_path)
    if not M.is_active(require_path) then
        table.insert(stack, require_path)
        state._skip_first_update = true
        if state.enter then
            state.enter(...)
        end
    end
end

function M.pop()
    if #stack > 0 then
        local removed = table.remove(stack, #stack)
        local state = get(removed)
        if state.leave then
            state.leave()
        end
    end
    return M
end

---@return boolean
function M.is_active(require_path)
    return lume.find(stack, require_path) ~= nil
end

---@param dt number
function M.update(dt)
    for _, path in ipairs(stack) do
        local state = get(path)
        if state.update and not state._skip_first_update then
            state.update(dt)
        end
        state._skip_first_update = false
    end
end

function M.pre_draw()
    for _, path in ipairs(stack) do
        local state = get(path)
        if state.pre_draw then
            state.pre_draw()
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

return log.log_methods('state', M, {exclude={'update', 'pre_draw', 'draw', 'get', 'is_active'}})