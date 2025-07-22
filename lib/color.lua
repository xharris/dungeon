local M = {}
local lume = require 'ext.lume'

---@alias Color number[]

M.hex2rgba = lume.memoize(
    ---@param hex string
    function(hex)
        hex = hex:gsub("#","")
        return tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255
    end
)

---@param rgb? Color
---@param a? number
function M.set(rgb, a)
    local color = rgb and M.alpha(rgb, a or rgb[4] or 1) or M.RESET_COLOR
    love.graphics.setColor(color)
end

function M.reset()
    love.graphics.setColor(M.MUI.WHITE)
end

---@param rgb table
---@param a number
---@return Color
function M.alpha(rgb, a)
    return {rgb[1], rgb[2], rgb[3], a}
end

M.RESET_COLOR = {1, 1, 1, 1}

M.MUI = {
    WHITE = {1, 1, 1},
    BLACK = {0, 0, 0},
    RED_500 = {M.hex2rgba('#F44336')},
    GREY_900 = {M.hex2rgba('#212121')},
    GREEN_500 = {M.hex2rgba('#4CAF50')},
    ORANGE_500 = {M.hex2rgba('#FF9800')}
}

return M