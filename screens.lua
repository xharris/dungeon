local M = {}

local log = require 'lib.log'
local lume = require 'ext.lume'
local images = require 'lib.images'

---@class ZoneRender
---@field ox number
---@field oy number
---@field angle1 number
---@field angle2 number

---@class Zone
---@field id string
---@field image any
---@field transform? any
---@field render ZoneRender
---@field render_target ZoneRender
---@field remove boolean
---@field replace_with? Zone replace this zone with a different zone 

---@type Zone[]
local zones = {}

---@type number[]
local angles = {}
local radius = 0
local t = 0

M.transition_duration = 20000

local function calc_angles()
    local out = {}
    local n = #zones

    local arc_size = 360 / #(lume.filter(zones, function (z)
        return z.remove == false
    end))
    local a2 = 270
    local a1 = 270 - arc_size

    local z = 1
    for i = 0, ((n - 1) * 2), 2 do
        if not zones[z].remove then
            out[i + 1] = a1
            out[i + 2] = a2

            a2 = a1
            a1 = a2 - arc_size
        end
        z = z + 1
    end

    return out
end

function M.get(id)
    for _, zone in ipairs(zones) do
        if zone.id == id then
            return zone
        end
    end
end

---@class ZonesSetValue
---@field id any
---@field image? Image love.Image

---@param values ZonesSetValue[]
function M.set(values)
    ---@type Zone[]
    local new_zones = {}
    local gw, gh = love.graphics.getDimensions()
    radius = math.sqrt((gw ^ 2) + (gh ^ 2))

    local no_animate = #zones == 0 and #values == 1

    for i, value in ipairs(values) do
        if value.image then
            local img = images.get(value.image)
            local w, h = img:getDimensions()
            local tform = love.math.newTransform()
            local scale = math.abs(gw - w) > math.abs(gh - h) and gh / h or gw / w

            -- center
            local offx, offy = math.abs(gw - (w * scale)), math.abs(gh - (h * scale))
            tform:translate(-offx/2, -offy/2)
            tform:scale(scale)

            ---@type Zone
            local zone = {
                id = value.id,
                image = img,
                transform = tform,
                render = {angle1=-90,angle2=-90,ox=0,oy=0},
                render_target = {angle1=0,angle2=0,ox=0,oy=0},
                remove = false,
            }

            if zones[i] then
                new_zones[i] = zones[i]
                new_zones[i].remove = false
                if zones[i].id ~= value.id then
                    new_zones[i].replace_with = zone
                end
            else
                new_zones[i] = zone
            end
        end
    end

    -- add removed zones
    for i = #new_zones + 1, #zones do
        new_zones[i] = zones[i]
        new_zones[i].remove = true
    end

    zones = new_zones

    -- set starting/target render values
    angles = calc_angles()
    local angle1, angle2 = 0, 0
    for i, zone in ipairs(zones) do
        local idx1, idx2 = ((i - 1) * 2) + 1, ((i - 1) * 2) + 2
        angle1, angle2 = angles[idx1], angles[idx2]

        local render_target = zone.render_target
        local render = zone.render

        if not zone.remove then
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

            render.ox = lume.lerp(render.ox, render_target.ox, t / d)
            render.oy = lume.lerp(render.oy, render_target.oy, t / d)
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
    for _, zone in ipairs(zones) do
        local render = zone.render
        love.graphics.stencil(stencil(gw, gh, radius, render), "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        zone.transform:translate(render.ox, render.oy)
        love.graphics.draw(zone.image, zone.transform)
        zone.transform:translate(-render.ox, -render.oy)
        love.graphics.setStencilTest()
    end

    -- draw zone contents
    for i, zone in ipairs(zones) do
        local render = zone.render
        if fn then
            love.graphics.stencil(stencil(gw, gh, radius, render), "replace", 1)
            love.graphics.setStencilTest("greater", 0)
            love.graphics.push('all')
            love.graphics.translate(render.ox / 2, render.oy / 2)
            fn(i, zone.id)
            love.graphics.pop()
            love.graphics.setStencilTest()
        end
    end

    love.graphics.pop()
end

return M