local M = {}

local lume = require 'ext.lume'

---@type table<Rarity, number>
M.RARITY_CHANCE = {
    common      = 200,
    normal      = 100,
    rare        = 60,
    super_rare  = 20,
}

---@enum Rarity
M.RARITY = {
    common      = 'common',
    normal      = 'normal',
    rare        = 'rare',
    super_rare  = 'super_rare',
}

---@return Rarity
function M.random()
    return lume.weightedchoice(M.RARITY_CHANCE)
end

---@param rarity Rarity
function M.get_chance(rarity)
    return M.RARITY_CHANCE[rarity]
end

return M