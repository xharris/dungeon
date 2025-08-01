local M = {}

local log = require 'lib.log'
local lume = require 'ext.lume'
local images = require 'lib.images'
local signal = require 'lib.signal'

---@class ScreenRender
---@field ox number
---@field oy number
---@field angle1 number
---@field angle2 number

---@class Screen
---@field id string
---@field image? Image
---@field transform? any
---@field render ScreenRender
---@field render_target ScreenRender
---@field remove boolean
---@field replace_with? Screen replace this instance with a different instance 
---@field ox number
---@field oy number

---@type Screen[]
local instances = {}

---@type number[]
local angles = {}
local radius = 0
local t = 0

M.transition_duration = 20000

M.signals = signal.create 'screens'
M.SIGNALS = {
    on_change = 'on_change'
}

local function calc_angles()
    local out = {}
    local n = #instances

    local arc_size = 360 / #(lume.filter(instances, function (z)
        return z.remove == false
    end))
    local a2 = 270
    local a1 = 270 - arc_size

    local z = 1
    for i = 0, ((n - 1) * 2), 2 do
        if not instances[z].remove then
            out[i + 1] = a1
            out[i + 2] = a2

            a2 = a1
            a1 = a2 - arc_size
        end
        z = z + 1
    end

    return out
end

---@param id string
---@return Screen?
function M.get(id)
    for _, instance in ipairs(instances) do
        if instance.id == id then
            return instance
        end
    end
end

function M.all()
    return instances
end

---@class InstancesSetValue
---@field id any
---@field image? Image love.Image

---@param values InstancesSetValue[]
function M.set(values)
    ---@type Screen[]
    local new_instances = {}
    local gw, gh = love.graphics.getDimensions()
    radius = math.sqrt((gw ^ 2) + (gh ^ 2))

    local no_animate = #instances == 0 and #values == 1

    for i, value in ipairs(values) do
        local img = value.image and images.get(value.image) or nil
        local tform = love.math.newTransform()
        if img then
            -- scale background image
            local w, h = img:getDimensions()
            local scale = math.abs(gw - w) > math.abs(gh - h) and gh / h or gw / w

            -- center
            local offx, offy = math.abs(gw - (w * scale)), math.abs(gh - (h * scale))
            tform:translate(-offx/2, -offy/2)
            tform:scale(scale)
        end

        ---@type Screen
        local instance = {
            id = value.id,
            image = img,
            transform = tform,
            render = {angle1=-90,angle2=-90,ox=0,oy=0},
            render_target = {angle1=0,angle2=0,ox=0,oy=0},
            remove = false,
            ox = 0,
            oy = 0,
        }

        if instances[i] then
            new_instances[i] = instances[i]
            new_instances[i].remove = false
            if instances[i].id ~= value.id then
                new_instances[i].replace_with = instance
            end
        else
            new_instances[i] = instance
        end
    end

    -- add removed instances
    for i = #new_instances + 1, #instances do
        new_instances[i] = instances[i]
        new_instances[i].remove = true
    end

    instances = new_instances

    -- set starting/target render values
    angles = calc_angles()
    local angle1, angle2 = 0, 0
    for i, instance in ipairs(instances) do
        local idx1, idx2 = ((i - 1) * 2) + 1, ((i - 1) * 2) + 2
        angle1, angle2 = angles[idx1], angles[idx2]

        local render_target = instance.render_target
        local render = instance.render

        if not instance.remove then
            render_target.angle1 = angle1
            render_target.angle2 = angle2
        else
            render_target.angle1 = -90
            render_target.angle2 = -90
        end

        if i == 1 and no_animate then
            render.angle1 = render_target.angle1
            render.angle2 = render_target.angle2
        end
    
        if render_target.angle1 == -90 and render_target.angle2 == 270 then
            render_target.ox, render_target.oy = 0, 0
        else
            render_target.ox, _ = lume.vector(math.rad((render_target.angle1 + render_target.angle2) / 2), gw / 2)
            _, render_target.oy = lume.vector(math.rad((render_target.angle1 + render_target.angle2) / 2), gh / 2)
        end
    end

    t = 0
    M.signals.emit(M.SIGNALS.on_change)
end

---@param screen_id? string
function M.rect(screen_id)
    local ox, oy = 0, 0
    local screen = screen_id and M.get(screen_id)
    if screen then
        ox = screen.ox
        oy = screen.oy
    end
    local w, h = love.graphics.getDimensions()
    if #instances > 1 then
        return (w/4) + ox, oy, w / 2, h
    end
    return ox, oy, w, h
end

function M.count()
    return #instances
end

---@param dt number
function M.update(dt)
    t = t + (dt * 1000)
    local d = M.transition_duration

    if t < d then
        for _, instance in ipairs(instances) do
            local render = instance.render
            local render_target = instance.render_target

            render.angle1 = lume.lerp(render.angle1, render_target.angle1, t / d)
            render.angle2 = lume.lerp(render.angle2, render_target.angle2, t / d)

            render.ox = lume.lerp(render.ox, render_target.ox, t / d)
            render.oy = lume.lerp(render.oy, render_target.oy, t / d)
            instance.ox = render.ox
            instance.oy = render.oy
        end
    end
end

local stencil = function(game_w, game_h, radius, render)
    return function ()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.arc('fill', game_w / 2, game_h / 2, radius, math.rad(render.angle1), math.rad(render.angle2), 60)
    end
end

---@param fn? fun(i:number, id:any) draw inside the stencil
function M.draw(fn)
    local gw, gh = love.graphics.getDimensions()

    love.graphics.push('all')
    love.graphics.setColor(1, 1, 1, 1)

    -- draw backgrounds
    for _, instance in ipairs(instances) do
        if instance.image then
            local img = images.get(instance.image)
            local render = instance.render
            love.graphics.stencil(stencil(gw, gh, radius, render), "replace", 1)
            love.graphics.setStencilTest("greater", 0)
            instance.transform:translate(render.ox, render.oy)
            love.graphics.draw(img, instance.transform)
            instance.transform:translate(-render.ox, -render.oy)
            love.graphics.setStencilTest()
        end
    end

    -- draw instance contents
    for i, instance in ipairs(instances) do
        local render = instance.render
        if fn then
            love.graphics.stencil(stencil(gw, gh, radius, render), "replace", 1)
            love.graphics.setStencilTest("greater", 0)
            love.graphics.push('all')
            love.graphics.translate(render.ox / 2, render.oy / 2)
            fn(i, instance.id)
            love.graphics.pop()
            love.graphics.setStencilTest()
        end
    end

    love.graphics.pop()
end

return M