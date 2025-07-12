local M = {}

local log = require 'lib.log'
local lume = require 'ext.lume'

local floor = math.floor
local lerp = lume.lerp

---@alias RarityLevel 'common'|'normal'|'rare'|'super_rare'

---@type table<RarityLevel, number>
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

---@type RarityLevel[]
M.RARITY_ORDER = {'common', 'normal', 'rare', 'super_rare'}

---@param scale number [0,1] closer to 1 yields higher chance of rarity
function M.random(scale)
    local chance = lume.clone(M.RARITY_CHANCE)
    local len = #M.RARITY_ORDER
    for i, v in ipairs(M.RARITY_ORDER) do
        chance[v] = floor(chance[v] * lerp(1 - scale, 0.5 + scale, i/len))
    end
    log.debug('random', chance)
    return lume.weightedchoice(chance)
end

---@param rarity Rarity
function M.get_chance(rarity)
    local keys = lume.keys(M.RARITY_CHANCE)
    return M.RARITY_CHANCE[rarity]
end

return log.log_methods('rarity', M)