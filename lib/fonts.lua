local M = {}

local assets = require 'lib.assets'

M.FONT_SIZE = 12

---@class Font
---@field path string
---@field size? number

---@type AssetLoader<Font>
M.get = assets.create{
    default = {
        path = '',
        size = M.FONT_SIZE,
    } --[[@as Font]],

    ---@param t Font
    create = function (t)
        return love.graphics.newFont(t.path, t.size)
    end,

    ---@param t Font
    key = function (t)
        return {t.path, t.size}
    end
}

function M.set(t)
    love.graphics.setFont(M.get(t))
end

return M