local M = {}

local lume = require 'ext.lume'
local log = require 'lib.log'

---@class Timer
---@field after? number
---@field fn function
---@field tag string

---@type Timer[]
local instances = {}

local i = 0

---@param fn function
---@param ms number
---@param tag? string
---@return string tag
function M.after(fn, ms, tag)
    if not tag then
        i = i + 1
        tag = 'timer-after-'..tostring(i)
    end
    table.insert(instances, {
        fn = fn,
        after = ms,
        tag = tag
    } --[[@as Timer]])
    return tag
end

function M.update(dt)
    for i, t in lume.ripairs(instances) do
        if t.after then
            t.after = t.after - (dt * 1000)
            if t.after <= 0 then
                log.debug('timer done:', t.tag)
                t.fn()
                table.remove(instances, i)
            end
        end
    end
end

return log.log_methods('timer', M, {
    exclude = {'update'}
})