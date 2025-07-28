--[[
# Day/Night cycle rendering
]]
local M = {}

local lume = require 'ext.lume'

M.SEGMENTS = 20
M.FLOOR_Y = nil

---@class Sky
---@field main_star? Image
---@field from? Color
---@field to? Color
---@field duration? number

---@type Sky[]
local instances = {}

local t = 0

local canvas

---@param ... Sky
function M.add(...)
    if not canvas then
        canvas = love.graphics.newCanvas()
    end
    for i = 1, select('#', ...) do
        local t = select(i, ...)
        t = t or {}
        t.from = t.from or {236/255, 239/255, 241/255}
        t.to = t.to or {176/255, 190/255, 197/255}
        t.duration = t.duration or 1000
        table.insert(instances, t)
    end
end

---@param dt number
function M.update(dt)
    local first = instances[1]
    if first then
        local gw, gh = love.graphics.getDimensions()
        if M.FLOOR_Y then
            gh = M.FLOOR_Y
        end
        local p = 0
        canvas:renderTo(function ()
            if first.main_star then
                -- circles
                local min_r = 30
                local max_r = math.sqrt(gw^2 + gh^2)
                for i = 0, M.SEGMENTS-1 do
                    p = i / (M.SEGMENTS-1)
                    love.graphics.setColor{
                        lume.lerp(first.from[1], first.to[1], p),
                        lume.lerp(first.from[2], first.to[2], p),
                        lume.lerp(first.from[3], first.to[3], p),
                    }
                    love.graphics.circle('fill', 0, 0, lume.lerp(min_r, max_r, p))
                end
            else
                -- horizontal rectangles
                local h = gh / M.SEGMENTS
                for i = 0, M.SEGMENTS-1 do
                    p = i / (M.SEGMENTS-1)
                    love.graphics.setColor{
                        lume.lerp(first.from[1], first.to[1], p),
                        lume.lerp(first.from[2], first.to[2], p),
                        lume.lerp(first.from[3], first.to[3], p),
                    }
                    love.graphics.rectangle('fill', 0, i*h, gw, h)
                end
            end
        end)
    end
end

---@param fn? function
function M.draw(fn)
    local first = instances[1]
    if first then
        love.graphics.draw(canvas)
        if fn then
            fn()
        end
    elseif fn then
        fn()
    end
end

return M