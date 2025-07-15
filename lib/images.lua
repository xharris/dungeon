local M = {}

local lume = require 'ext.lume'
local log  = require 'lib.log'

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

---@type table<string, any>
local images = {}

---@param t Image
---@return any image love.Image
function M.get(t)
    t.filter = t.filter or {}
    t.filter.min = t.filter.min or 'linear'
    t.filter.max = t.filter.max or 'nearest'
    t.ox = t.ox or 0
    t.oy = t.oy or 0
    t.sx = t.sx or 1
    t.sy = t.sy or t.sx or 1
    t.r = t.r or 0

    local key = table.concat({t.path, t.filter.min, t.filter.max, t.ox, t.oy, t.sx, t.sy, t.r}, ',')
    
    local img = images[key]
    if not img then
        img = love.graphics.newImage(t.path)
        img:setFilter(t.filter.min, t.filter.max)
        images[key] = img
    end
    return img
end

---@param image Image?
---@param v Renderable?
---@return Renderable
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
            sx = image.sx,
            sy = image.sy,
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