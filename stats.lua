local M = {}

---@class Stats
---@field str number strength
---@field int number intelligence
---@field agi number agility

---@param stats Stats
function M.attack_speed(stats)
    return stats.agi / (stats.agi + 100) + 1
end

---@param ratio Stats
---@param stats Stats
function M.damage(ratio, stats)
    return (ratio.str * stats.str) +
           (ratio.int * stats.int) +
           (ratio.agi * stats.agi)
end

return M