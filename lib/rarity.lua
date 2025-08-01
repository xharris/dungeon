local M = {}

local log = require 'lib.log'
local lume = require 'ext.lume'
local const= require 'const'

local floor = math.floor
local lerp = lume.lerp
local max = math.max
local min = math.min

---@alias RarityLevel 'common'|'rare'|'super_rare'|'ultra_rare'|'legendary'

---@type table<RarityLevel, number>
M.RARITY_CHANCE = {
    common      = 100,
    rare        = 50,
    super_rare  = 12.5,
    ultra_rare = 3,
    legendary = 1,
}

---@type RarityLevel[]
M.RARITY_ORDER = {'common', 'rare', 'super_rare', 'ultra_rare', 'legendary'}

---@param scale number [0,1] closer to 1 yields higher chance of rarity
function M.random(scale)
    ---@type table<RarityLevel, number>
    local chance = {}
    local len = #M.RARITY_ORDER
    scale = min(1, max(0, scale))
    local rarity_max = const.RARITY_SCALE_MAX - scale
    local rarity_min = const.RARITY_SCALE_MIN + scale
    for i, v in ipairs(M.RARITY_ORDER) do
        chance[v] = floor(M.RARITY_CHANCE[v] * lerp(rarity_max, rarity_min, i/len))
    end
    log.debug('chance', chance)
    return lume.weightedchoice(chance)
end

---@param rarity RarityLevel
function M.get_chance(rarity)
    return M.RARITY_CHANCE[rarity]
end

---common < rare = true
---@param a RarityLevel
---@param b RarityLevel
function M.le(a, b)
    return lume.find(M.RARITY_ORDER, a) < lume.find(M.RARITY_ORDER, b)
end

return log.log_methods('rarity', M)