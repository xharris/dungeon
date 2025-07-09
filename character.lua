local M = {}

-- local render = require 'render'
local log = require 'lib.log'
local entity = require 'lib.entity'

local abs = math.abs
local min = math.min
local max = math.max

---@param e Entity
---@param v number can be negative to lose money
---@return boolean ok
function M.add_money(e, v)
    if v < 0 and e.money < abs(v) then
        log.info(e.name, "insufficient money ("..tostring(abs(v))..")")
        return false
    end
    log.info(e.name, v >= 0 and "gain" or "lose", v, "money")
    e.money = (e.money or 0) + v
    -- TODO add/lose money animation
    return true
end

---@param e Entity
---@param v number can be negative to lose health
---@return boolean ok
function M.add_health(e, v)
    log.info(e.name, v >= 0 and "gain" or "lose", v, "health")
    e.health.current = max(0, min(e.health.max, e.health.current + v))
    return true
end

---@return Entity?
function M.get_player()
    for _, e in ipairs(entity.find('group')) do
        if e.group == 'player' then
            return e
        end
    end
    log.error("player not found")
end

---@param player_id string
function M.get_screen_id(player_id)
    return 'entity-'..tostring(player_id)
end

return M