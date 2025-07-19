local M = {}

local lume = require 'ext.lume'
local log = require 'lib.log'
local signal = require 'lib.signal'
local color  = require 'lib.color'
local vector = require 'lib.vector'

local lerp = lume.lerp
local max = math.max
local min = math.min
local abs = math.abs

---@class Animation
---@field id string
---@field object table
---@field step number
---@field speed number
---@field enabled boolean
---@field steps AnimationStep[]
---@field _t number
---@field on_end? fun()

---@class AnimationStep
---@field object? table
---@field _from? table<string, number>
---@field to? table<string, number>
---@field duration number ms
---@field delay? number ms
---@field data? table
---@field ease_fn? fun(number):number
---@field on_end? fun()

M.signals = signal.create 'animation'
M.SIGNALS = {
    -- data?:table
    animation_step_end ='animation_step_end'
}

---@type Animation[]
local animations = {}

---@type table<string, Animation>
local animation_hash = {}

---@param x number
local linear = function(x) return x end

---@param dt number
function M.update(dt)
    for _, a in ipairs(animations) do
        if a.enabled and #a.steps > 0 and a.step <= #a.steps then
            local step = a.steps[a.step]
            if step then
                local object = step.object or a.object
                local t = max(0, a._t - (step.delay or 0))
                local ease_fn = step.ease_fn or linear

                if t > step.duration then
                    -- finish animation step
                    t = 0
                    a.step = a.step + 1
                    if step.on_end then
                        step.on_end()
                    end
                    if a.on_end and a.step > #a.steps then
                        a.on_end()
                    end
                    M.signals.emit(M.SIGNALS.animation_step_end, step.data)
                else
                    -- animate
                    t = t + (dt * 1000 * a.speed)
                    local amt = min(1, max(0, ease_fn(t / step.duration)))
                    if step.to then
                        -- interpolate between 2 values
                        for k, v in pairs(step.to) do
                            object[k] = lerp(step._from[k], v, amt)
                        end
                    end
                end
                a._t = t
            end
        end
    end
end

---@generic T
---@param id string
---@param object T object that will be updated
function M.create(id, object)
    ---@type Animation
    local a = {
        id = id,
        object = object,
        step = 1,
        speed = 1,
        enabled = false,
        steps = {},
        _t = 0
    }

    table.insert(animations, a)

    local N = {}

    ---@param v number
    function N.speed(v)
        a.speed = v
        return N
    end

    ---@param ... AnimationStep
    function N.add(...)
        for i = 1, select("#", ...) do
            ---@type AnimationStep
            local step = select(i, ...)
            step.duration = step.duration or 1000
            step._from = {}
            if step.to then
                -- get values to interpolate *from*
                for k in pairs(step.to) do
                    step._from[k] = a.object[k]
                end
            end
            table.insert(a.steps, step)
        end
        return N
    end

    function N.clear()
        a.step = 1
        a.steps = {}
        return N
    end

    function N.start()
        a.enabled = true
        return a.id
    end

    ---@param fn fun()
    function N.on_end(fn)
        a.on_end = fn
        return N
    end

    return log.log_methods('animation.'..id, N)
end

function M.draw() end

return log.log_methods('animation', M, {
    exclude={'update', 'draw'}
})