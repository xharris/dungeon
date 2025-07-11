local M = {}

-- local render = require 'render'
local log = require 'lib.log'
local entity = require 'lib.entity'
local lume = require 'ext.lume'
local const= require 'const'

local abs = math.abs
local min = math.min
local max = math.max

---@class CharacterEscortClient
---@field name string
---@field health Health
---@field stats Stats
---@field items? ItemData[]
---@field money? number

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

---@param e Entity
---@param data ItemData
function M.add_item(e, data)
    table.insert(e.items, data)
end

---@return Entity?
function M.get_player()
    for _, e in ipairs(entity.find('group')) do
        if e.group == 'player' then
            return e
        end
    end
    log.error_if(true, "player not found")
end

---@param player_id string
function M.get_screen_id(player_id)
    return 'entity-'..tostring(player_id)
end

---@param escort_id string id of player (Entity) that will escort the client
---@param client CharacterEscortClient
---@return boolean ok
function M.add_escort_client(escort_id, client)
    local escort = entity.get(escort_id)
    if not escort then
        log.error("escort not found")
        return false
    end
    local client_entity = entity.add{
        group = 'ally',
        name = client.name,
        health = client.health,
        stats = client.stats,
        items = client.items,
        money = client.money,
    }
    table.insert(escort.escort_clients, client_entity._id)
    return true
end

---@param v Entity?
function M.create(v)
    return entity.add(lume.extend(
        {
            group = 'player',
            name = 'Player',
            items = {},
            health = {
                current = const.CHAR_HEALTH,
                max = const.CHAR_HEALTH,
            },
            stats = {agi=1, str=1, int=1},
            money = 0,
            x = 0,
            y = 0,
            floor_y = const.FLOOR_Y,
            gravity = 0.8,
            velocity_y = 0,
        } --[[@as Entity]],
        v or {}
    ))
end

return M