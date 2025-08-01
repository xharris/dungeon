local M = {}
local lume = require 'ext.lume'
local vivid = require 'ext.vivid'

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

---@param color Color
---@param amt number
function M.lighten(color, amt)
    return {vivid.lighten(amt, color)}
end

---@param color Color
---@param amt number
function M.darken(color, amt)
    return {vivid.darken(amt, color)}
end

--[[

// from http://www.w3.org/TR/WCAG20/#relativeluminancedef
function relativeLuminanceW3C(R8bit, G8bit, B8bit) {

    var RsRGB = R8bit/255;
    var GsRGB = G8bit/255;
    var BsRGB = B8bit/255;

    var R = (RsRGB <= 0.03928) ? RsRGB/12.92 : Math.pow((RsRGB+0.055)/1.055, 2.4);
    var G = (GsRGB <= 0.03928) ? GsRGB/12.92 : Math.pow((GsRGB+0.055)/1.055, 2.4);
    var B = (BsRGB <= 0.03928) ? BsRGB/12.92 : Math.pow((BsRGB+0.055)/1.055, 2.4);

    // For the sRGB colorspace, the relative luminance of a color is defined as: 
    var L = 0.2126 * R + 0.7152 * G + 0.0722 * B;

    return L;
}

]]

---http://www.w3.org/TR/WCAG20/#relativeluminancedef
---@param c Color
function M.luminance(c)
    local rgb = {c[1], c[2], c[3]}

    for i, v in ipairs(rgb) do
        rgb[i] = v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055)^2.4
    end

    return (0.2126 * rgb[1]) + (0.7152 * rgb[2]) + (0.0722 * rgb[3])
end

M.RESET_COLOR = {1, 1, 1, 1}

M.TRANSPARENT = {1,1,1,0}

M.MUI = {
    WHITE = {1, 1, 1},
    BLACK = {0, 0, 0},
    RED_500 = {M.hex2rgba('#F44336')},
    BLUE_600 = {M.hex2rgba('#1E88E5')},
    LIGHT_BLUE_100 = {M.hex2rgba('#B3E5FC')},
    GREY_900 = {M.hex2rgba('#212121')},
    GREEN_500 = {M.hex2rgba('#4CAF50')},
    ORANGE_500 = {M.hex2rgba('#FF9800')},
    BROWN_500 = {M.hex2rgba('#795548')},
    BROWN_900 = {M.hex2rgba('#3E2723')}
}

return M