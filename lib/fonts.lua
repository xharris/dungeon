local M = {}

local assets = require 'lib.assets'

M.FONT_SIZE = 12

---@class Font
---@field path string
---@field size? number
---@field filter? {min:'linear'|'nearest', max:'linear'|'nearest'}


---@type AssetLoader<Font>
M.get = assets.create{
    default = {
        path = '',
        size = M.FONT_SIZE,
        filter = {
            min = 'linear',
            max = 'nearest',
        }
    } --[[@as Font]],

    ---@param t Font
    create = function (t)
        local font = love.graphics.newFont(t.path, t.size)
        font:setFilter(t.filter.min, t.filter.max)
        return font
    end,

    ---@param t Font
    key = function (t)
        return {t.path, t.size}
    end
}

local original_font

local function get_original_font()
    if not original_font then
        original_font = love.graphics.getFont()
    end
    return original_font
end

---@param t? Font
function M.set(t)
    if not t and not original_font then
        return
    end
    if not t then
        love.graphics.setFont(get_original_font())
        return
    end
    love.graphics.setFont(M.get(t))
end

---@param text? any
---@param t? Font
function M.dimensions(text, t)
    text = tostring(text or ' ')
    local font
    if not t then
        font = get_original_font()
    else
        font = M.get(t)
    end
    return font:getWidth(text), (select(2, string.gsub(text, "\n", "")) + 1) * font:getHeight()
end

return M