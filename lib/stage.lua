local M = {}

local game = require 'game'
local color = require 'lib.color'
local lume = require 'ext.lume'
local animation = require 'lib.animation'
local util      = require 'lib.util'
local log = require 'lib.log'

M.EASE_DURATION = 1000
M.EASE_FN = function (x) return x end

M.FLOOR = {
    COLOR = color.MUI.GREY_900,
    VISIBLE = true,
    Y = 300 * (3/5),
}

M.floor = {}

---@class Floor
---@field y? number
---@field color? Color
---@field duration? number

---@type Floor?
local floor

---@param t? Floor
function M.floor.set(t)
    t = util.deepcopy(t or {})
    t.y = t.y or M.FLOOR.Y
    t.color = t.color or M.FLOOR.COLOR
    t.duration = t.duration or M.EASE_DURATION
    if not floor then
        floor = t
    else
        animation
            .create('stage.floor', floor)
            .add{
                to={y=t.y},
                duration=t.duration,
            }
            .start()
        animation
            .create('stage.color', floor.color)
            .add{
                to=t.color,
                duration=t.duration,
            }
            .start()
    end
    return t
end

function M.floor.get()
    return floor
end

M.sky = {}

M.SKY = {
    SEGMENTS = 20,
    ---@type Color
    FROM = {236/255, 239/255, 241/255},
    ---@type Color
    TO = {176/255, 190/255, 197/255},
}

---@class Sky
---@field main_star? any texture
---@field from? Color
---@field to? Color
---@field duration? number
---@field segments? number

local canvas

---@type Sky?
local sky

---@param t? Sky
function M.sky.set(t)
    t = util.deepcopy(t or {})
    t.from = t.from or M.SKY.FROM
    t.to = t.to or M.SKY.TO
    t.duration = t.duration or M.SKY.DURATION
    t.segments = t.segments or M.SKY.SEGMENTS
    
    if not canvas then
        canvas = love.graphics.newCanvas()
    end
    if not sky then
        sky = t
    else
        animation
            .create('stage.sky.from', sky.from)
            .add{
                duration=t.duration,
                ease_fn=M.SKY.EASE_FN,
                to=t.from,
            }
            .start()
        animation
            .create('stage.sky.to', sky.to)
            .add{
                duration=t.duration,
                ease_fn=M.EASE_FN,
                to=t.to,
            }
            .start()
        animation
            .create('stage.sky.segments', sky)
            .add{
                duration=t.duration,
                ease_fn=M.EASE_FN,
                to={segments=t.segments},
            }
            .start()
    end
    return t
end

function M.sky.get()
    return sky
end

---@param dt number
function M.update(dt)
    -- sky
    if sky then
        local gw, gh = love.graphics.getDimensions()
        if M.FLOOR.Y then
            gh = M.FLOOR.Y
        end
        local p = 0
        local min_r = 30
        local max_r = math.sqrt(gw^2 + gh^2)
        local h = gh / M.SKY.SEGMENTS
        
        canvas:renderTo(function ()
            love.graphics.push("all")
            love.graphics.clear()

            for i = 0, M.SKY.SEGMENTS-1 do
                p = i / (M.SKY.SEGMENTS-1)
                if sky.main_star then
                    love.graphics.setColor(
                        lume.lerp(sky.to[1], sky.from[1], p),
                        lume.lerp(sky.to[2], sky.from[2], p),
                        lume.lerp(sky.to[3], sky.from[3], p)
                    )
                    -- circles
                    love.graphics.circle('fill', 0, 0, lume.lerp(max_r, min_r, p))
                    -- star
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.draw(
                        sky.main_star, 
                        0, 0, 0, 1, 1, 
                        sky.main_star:getWidth()/2,
                        sky.main_star:getHeight()/2
                    )
                else
                    love.graphics.setColor(
                        lume.lerp(sky.from[1], sky.to[1], p),
                        lume.lerp(sky.from[2], sky.to[2], p),
                        lume.lerp(sky.from[3], sky.to[3], p)
                    )
                    -- horizontal boxes
                    love.graphics.rectangle('fill', 0, i*h, gw, h)
                end
            end
            love.graphics.pop()
        end)
    end
end

---@param fn? function
function M.draw(fn)
    -- sky
    if sky then
        love.graphics.draw(canvas)
        if fn then
            fn()
        end
    elseif fn then
        fn()
    end
    -- floor
    if M.FLOOR.VISIBLE and floor then
        love.graphics.push('all')
        color.set(floor.color)
        love.graphics.rectangle('fill', 0, floor.y, game.width, game.height - floor.y)
        love.graphics.pop()
    end
end

M.floor = log.log_methods('stage.floor', M.floor, {
    exclude={'get'}
})

M.sky = log.log_methods('stage.sky', M.sky, {
    exclude={'get'}
})

return M