local M = {}

---@class Image
---@field path string
---@field frames? RenderableFrame[]]
---@field filter? {min:'linear'|'nearest', max:'linear'|'nearest'}

---@type table<string, any>
local images = {}

---@param t Image
---@return any image love.Image
function M.get(t)
    t.filter = t.filter or {}
    t.filter.min = t.filter.min or 'linear'
    t.filter.max = t.filter.max or 'nearest'
    local key = t.path
    
    local img = images[key]
    if not img then
        img = love.graphics.newImage(t.path)
        img:setFilter(t.filter.min, t.filter.max)
        images[key] = img
    end
    return img
end

return M