local M = {}

local lume = require 'ext.lume'
local log  = require 'lib.log'
local assets = require 'lib.assets'

---@class Image
---@field path string
---@field frames? RenderableFrame[]
---@field current_frame? number
---@field filter? {min:'linear'|'nearest', max:'linear'|'nearest'}
---@field ox? number
---@field oy? number
---@field sx? number
---@field sy? number
---@field r? number

---returns love.Image
---@type AssetLoader<Image>
M.get = assets.create{
    default = {
        path = '',
        filter = {
            min = 'linear',
            max = 'nearest',
        },
        ox = 0,
        oy = 0,
        sx = 1,
        sy = 1,
        r = 0,
    } --[[@as Image]],

    ---@param t Image
    key = function (t)
        return {
            t.path,
            t.filter.min,
            t.filter.max,
             t.ox, t.oy,
             t.sx, t.sy,
             t.r,
        }
    end,

    ---@param t Image
    create = function (t)
        local img = love.graphics.newImage(t.path)
        img:setFilter(t.filter.min, t.filter.max)
        return img
    end
}

---@param image Image?
---@param v Renderable?
---@return Renderable, string? error
function M.renderable(image, v)
    if not image then
        return v or {}
    end
    return lume.extend(
        {
            tex = M.get(image),
            ox = image.ox,
            oy = image.oy,
            frames = image.frames,
            current_frame = image.current_frame,
            sx = image.sx or 1,
            sy = image.sy or image.sy,
            r = image.r,
        } --[[@as Renderable]],
        v or {}
    )
end

---@param t Image
---@return number x,number y
function M.dimensions(t)
    local img = M.get(t)
    return img:getWidth(), img:getHeight()
end

return log.log_methods('images', M, {
    exclude={'get'}
})