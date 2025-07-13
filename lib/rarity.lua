local M = {}

local log = require 'lib.log'
local lume = require 'ext.lume'
local const= require 'const'

local floor = math.floor
local lerp = lume.lerp
local max = math.max
local min = math.min

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
    scale = min(1, max(0, scale))
    local rarity_max = const.RARITY_SCALE_MAX - scale
    local rarity_min = const.RARITY_SCALE_MIN + scale
    for i, v in ipairs(M.RARITY_ORDER) do
        chance[v] = floor(chance[v] * lerp(rarity_max, rarity_min, i/len))
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