local M = {}

local log = require 'lib.log'
local lume = require 'ext.lume'

---@class ZoneRender
---@field ox number
---@field oy number
---@field angle1 number
---@field angle2 number

---@class Zone
---@field image any
---@field transform? any
---@field render ZoneRender
---@field render_target ZoneRender

---@type Zone[]
local zones = {}

local radius = 0
local t = 0

M.transition_duration = 20000

---@param images any[]
function M.set(images)
    zones = {}
    local gw, gh = love.graphics.getDimensions()
    radius = math.sqrt((gw ^ 2) + (gh ^ 2))
    
    for _, image in ipairs(images) do
        local w, h = image:getDimensions()
        local tform = love.math.newTransform()
        local scale = math.abs(gw - w) > math.abs(gh - h) and gh / h or gw / w

        -- center
        local offx, offy = math.abs(gw - (w * scale)), math.abs(gh - (h * scale))
        tform:translate(-offx/2, -offy/2)
        tform:scale(scale)

        ---@type Zone
        local zone = {
            image = image,
            transform = tform,
            render = {angle1=0,angle2=0,ox=0,oy=0},
            render_target = {angle1=0,angle2=0,ox=0,oy=0},
        }
        table.insert(zones, zone)
    end

    -- set starting/target render values
    local len = #zones
    local arc_size = 360 / len
    local angle1, angle2 = 0, 0
    for i, zone in ipairs(zones) do
        angle1, angle2 = ((i - 1) * arc_size), (i * arc_size)

        local render_target = zone.render_target
        render_target.angle1 = angle1
        render_target.angle2 = angle2

        local render = zone.render
        render.angle1 = 0
        render.angle2 = i == 1 and 360 or 0

        -- TODO angles don't look right
        log.debug(i, 'from', render.angle1, render.angle2, 'to', angle1, angle2)
    end

    t = 0
end

---@param dt number
function M.update(dt)
    t = t + (dt * 1000)
    local d = M.transition_duration
    local gw, gh = love.graphics.getDimensions()

    if t < d then 
        for i, zone in ipairs(zones) do
            local render = zone.render
            local render_target = zone.render_target

            render.angle1 = lume.lerp(render.angle1, render_target.angle1, t / d)
            render.angle2 = lume.lerp(render.angle2, render_target.angle2, t / d)
            local _
            render.ox, _ = lume.vector(math.rad((render.angle2 + render.angle1) / 2), gw / 2)
            _, render.oy = lume.vector(math.rad((render.angle2 + render.angle1) / 2), gh / 2)
        end
    end
end

---@param fn? fun(i:number) draw inside the stencil
function M.draw(fn)
    local gw, gh = love.graphics.getDimensions()
    love.graphics.push('all')
    for i, zone in ipairs(zones) do
        local render = zone.render
        love.graphics.stencil(function()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.arc('fill', gw / 2, gh / 2, radius, math.rad(render.angle1), math.rad(render.angle2), 60)
        end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        love.graphics.setColor(1, 1, 1, 1)
        zone.transform:translate(render.ox, render.oy)
        love.graphics.draw(zone.image, zone.transform)
        if fn then
            love.graphics.push('all')
            love.graphics.translate(render.ox / 2, render.oy / 2)
            fn(i)
            love.graphics.pop()
        end
        zone.transform:translate(-render.ox, -render.oy)
        love.graphics.setStencilTest()
    end
    love.graphics.pop()
end

return M