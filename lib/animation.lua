local M = {}

local lume = require 'ext.lume'
local log = require 'lib.log'
local signal = require 'lib.signal'
local color  = require 'lib.color'
local vector = require 'lib.vector'
local errors = require 'lib.errors'

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
---@field progress number [0, 1]
---@field on_end? fun()
---@field on_step? fun(me:Animation)
---@field on_killed? fun(me:Animation)
---@field destroy? boolean

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
    for i, a in lume.ripairs(animations) do
        if a.destroy then
            table.remove(animations, i)
        elseif a.enabled and #a.steps > 0 and a.step <= #a.steps then
            local step = a.steps[a.step]
            if step then
                local object = step.object or a.object
                local ease_fn = step.ease_fn or linear

                local t = a._t - (step.delay or 0)
                a._t = a._t + (dt * 1000 * a.speed)

                if t > step.duration then
                    -- finish animation step
                    M.next_step(a.id)
                else
                    -- animate
                    if t >= 0 and step.to then
                        a.progress = min(1, max(0, ease_fn(t / step.duration)))
                        -- interpolate between 2 values
                        for k, v in pairs(step.to) do
                            if step._from[k] == nil then
                                log.error(errors.missing_field('animation.object.'..tostring(k), a.object))
                            end
                            object[k] = lerp(step._from[k], v, a.progress)
                        end
                    end
                    if a.on_step then
                        a.on_step(a)
                    end
                end
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
        step = 0,
        speed = 1,
        enabled = false,
        steps = {},
        _t = 0,
        progress = 0,
    }
    if type(object) ~= 'table' then
        return nil, errors.invalid_type('table', object)
    end

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
            local step = select(i, ...)
            table.insert(a.steps, step)
        end
        return N
    end

    function N.clear()
        a.step = 0
        a.steps = {}
        return N
    end

    function N.start()
        -- kill current animation
        M.kill(a.id)
        -- start this animation
        animation_hash[a.id] = a
        local err = M.next_step(a.id)
        log.error_if(err, err)
        a.enabled = true
        return a.id
    end

    ---@param fn fun(me:Animation)
    function N.on_killed(fn)
        a.on_killed = fn
        return N
    end

    ---@param fn fun()
    function N.on_end(fn)
        a.on_end = fn
        return N
    end

    ---@param fn fun(me:Animation)
    function N.on_step(fn)
        a.on_step = fn
        return N
    end

    return log.log_methods('animation.'..id, N)
end

---force animation to move onto the next step
---@param id string
---@return string? error
function M.next_step(id)
    local a = animation_hash[id]
    if not a then return errors.not_found('animation', id) end

    -- end current step
    local step = a.steps[a.step]
    if step then
        if step.on_end then
            step.on_end()
        end
        M.signals.emit(M.SIGNALS.animation_step_end, a.id, step.data)
    end

    -- move to next step
    a._t = 0
    a.step = a.step + 1
    step = a.steps[a.step]

    if not step then
        -- all done
        if a.on_end then
            a.on_end()
        end
        a.destroy = true
        return
    end

    step.duration = step.duration or 1000
    step._from = {}

    -- get values to interpolate *from*
    for k in pairs(step.to) do
        if a.object[k] == nil then
            local err = errors.missing_field('animation.object.'..tostring(k), a.object)
            log.error(err)
            return err
        end
        step._from[k] = a.object[k]
    end
end

---stop and destroy animation
---@param id string
---@return string? error
function M.kill(id)
    local current = animation_hash[id]
    if not current then return errors.not_found('animation', id) end
    if current.destroy then
        -- already destroyed/killed
        return
    end
    if current.on_killed then
        current.on_killed(current)
    end
    current.destroy = true
    animation_hash[id] = nil
end

function M.draw() end

return log.log_methods('animation', M, {
    exclude={'update', 'draw', 'next_step'}
})