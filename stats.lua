local log = require "lib.log"
local util= require "lib.util"
local M = {}

M.stats_fields = {'str', 'int', 'agi', 'crit'}

---@class Stats
---@field str number strength
---@field int number intelligence
---@field agi number agility
---@field crit? number [0, 1] percent

---shortcut to create Stats object
---@param v {agi?:number, str?:number, int?:number, crit?:number}
---@return Stats
function M.create(v)
    v.agi = v.agi or 0
    v.int = v.int or 0
    v.str = v.str or 0
    v.crit = v.crit or 0
    return v
end

---@param stats Stats
function M.attack_speed(stats)
    return util.diminishing(stats.agi)
end

---@param def number
function M.defense(def)
    return util.diminishing(def)
end

---@param ratio Stats
---@param stats Stats
function M.apply(ratio, stats)
    return (ratio.str * stats.str) +
           (ratio.int * stats.int) +
           (ratio.agi * stats.agi)
end

return log.log_methods('stats', M, {exclude={'attack_speed', 'diminishing', 'defense'}})