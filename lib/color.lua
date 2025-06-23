local M = {}
local lume = require 'ext.lume'

M.hex2rgba = lume.memoize(
    ---@param hex string
    function(hex)
        hex = hex:gsub("#","")
        return tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255
    end
)

---@param rgb table
---@param a? number
function M.set(rgb, a)
    a = a or 1
    local color = {rgb[1], rgb[2], rgb[3], a}
    love.graphics.setColor(color)
end

M.MUI = {
    WHITE = {1, 1, 1},
    BLACK = {0, 0, 0},
    GREY_900 = {M.hex2rgba('#212121')}
}

return M