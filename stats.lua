local log = require "lib.log"
local M = {}

---@class Stats
---@field str number strength
---@field int number intelligence
---@field agi number agility

---@param stats Stats
function M.attack_speed(stats)
    return M.diminishing(stats.agi)
end

---@param def number
function M.defense(def)
    return M.diminishing(def)
end

---@param x number
function M.diminishing(x)
    return x / (x + 100) + 1
end

---@param ratio Stats
---@param stats Stats
function M.apply(ratio, stats)
    return (ratio.str * stats.str) +
           (ratio.int * stats.int) +
           (ratio.agi * stats.agi)
end

return log.log_methods('stats', M, {exclude={'attack_speed', 'diminishing', 'defense'}})