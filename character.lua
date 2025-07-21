local M = {}

local log = require 'lib.log'
local entity = require 'lib.entity'
local lume = require 'ext.lume'
local const = require 'const'
local ctrl = require 'lib.controls'
local render = require 'render'
local screens = require 'screens'
local images = require 'lib.images'
local assets = require 'assets.index'
local errors = require 'lib.errors'
local items = require 'items'
local signal = require 'lib.signal'
local zindex = require 'zindex'
local stats = require 'stats'

local abs = math.abs
local min = math.min
local max = math.max
local floor = math.floor

---@class CharacterEscortClient
---@field name string
---@field health Health
---@field stats Stats
---@field items? ItemData[]
---@field money? number

M.signals = signal.create 'character'
M.SIGNALS = {
    change_health = 'change_health' -- entity_id, number
}

---@param e Entity
---@param v number can be negative to lose money
---@return boolean has_enough_money
function M.add_money(e, v)
    if v < 0 and e.money < abs(v) then
        return false
    end
    e.money = (e.money or 0) + v
    -- TODO add/lose money animation
    return true
end

---@param entity_id string
---@param v number can be negative to lose health
---@return string? error
function M.add_health(entity_id, v)
    local e = entity.get(entity_id)
    if not e then return errors.not_found('entity', entity_id) end

    v = floor(v)

    e.health.current = max(0, min(e.health.max, e.health.current + v))
    M.signals.emit(M.SIGNALS.change_health, e._id, v)
end

---@return Entity|false
function M.get_player()
    for _, e in ipairs(entity.find('group')) do
        if e.group == 'player' then
            return e
        end
    end
    log.error("player not found")
    return false
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
        return false
    end
    local client_entity = entity.add{
        tag = 'escortclient-'..client.name,
        group = 'ally',
        name = client.name,
        health = client.health,
        stats = client.stats,
        equipped_items = client.items,
        money = client.money,
    }
    table.insert(escort.escort_clients, client_entity._id)
    return true
end

function M.arrange()
    local screen_x, _, w, _ = screens.rect()
    local player = M.get_player()
    local sep = const.CHAR_ARRANGE_SEP

    local ally_x = (0.25 * w) + screen_x
    local enemy_x = (0.75 * w) + screen_x

    if player then
        player.x = ally_x
        ally_x = ally_x - sep
    end

    for _, e in ipairs(entity.all()) do
        if not player or e._id ~= player._id then
            if e.group == 'ally' then
                e.x = ally_x
                ally_x = ally_x - sep
                local r = e.render_character and render.get(e.render_character)
                if r then
                    -- ally faces to the right
                    r.sx = abs(r.sx)
                end
            end
            if e.group == 'enemy' then
                e.x = enemy_x
                enemy_x = enemy_x + sep
                local r = e.render_character and render.get(e.render_character)
                if r then
                    -- enemy faces to the left
                    r.sx = -abs(r.sx)
                end
            end
        end
    end
end

---@param v Entity?
---@param renderable Renderable?
---@return Entity
function M.create(v, renderable)
    local name = v and v.name or 'player'
    log.debug('name =', name)
    local e = entity.add(lume.extend(
        {
            tag = v and v.tag or name,
            group = 'player',
            name = name,
            class = 'warrior',
            inventory = {},
            equipped_items = {},
            max_equipped_items = const.MAX_EQUIPPED_ITEMS,
            max_inventory_items = const.MAX_INVENTORY_ITEMS,
            health = {
                current = const.HEALTH,
                max = const.HEALTH,
            },
            money = 0,
            x = 0,
            y = const.FLOOR_Y,
            floor_y = const.FLOOR_Y,
            gravity = 700,
            vy = 0,
            jump_velocity = const.JUMP_VELOCITY,
            max_jumps = const.MAX_JUMPS,
        } --[[@as Entity]],
        v or {}
    ))
    -- default class stats
    if e.class then
        e.stats = const.CLASS_STATS[e.class]
        log.warn_if(not e.stats, 'default stats not found for class:', e.class)
    end
    -- set screen
    local screen_id = M.get_screen_id(e._id)
    if e.group ~= 'player' then
        local player = M.get_player()
        if player then
            screen_id = M.get_screen_id(player._id)
        end
    end
    e.screen_id = screen_id
    -- add sprite
    render.set_collection(screen_id)
    e.render_character = render.add(lume.extend(
        {
            tex = images.get{
                path = assets.ohmydungeon_v11,
            },
            frames = {{x=0, y=144, w=16, h=16}},
            current_frame = 1,
            x = e.x,
            y = e.y,
            ox = 8, oy = 8,
            sx = 2, sy = 2,
            z = zindex.character,
        } --[[@as Renderable]],
        renderable or {}
    ))
    render.set_collection()
    -- add weapon sprite
    for _, data in ipairs(e.inventory) do
        local item = items.get(data.id)
        if item and item.class_starter then
            local idx = M.add_item_to_inventory(e._id, data)
            M.equip_item(e._id, idx)
        end
    end
    M.arrange()
    return e
end

---@param e Entity
---@return string? error
local function position_equipped_items(e)
    if not e.equipped_items then
        return "entity does not have equipped_items"
    end
    for _, equip in ipairs(e.equipped_items) do
        local item = items.get(equip.id)
        local r_equip = render.get(equip.renderable)
        if item and r_equip and e.x and e.y then
            local cx, cy = 
                (item.render_on_character and item.render_on_character.x or 0),
                (item.render_on_character and item.render_on_character.y or 0)
            local z =
                item.render_on_character and
                item.render_on_character.z or
                zindex.equipped_item_back

            r_equip.x = e.x + cx
            r_equip.y = e.y + cy
            if not r_equip.z then
                r_equip.z = z
            end
        end
    end
end

---@param entity_id string
---@param idx number inventory index
---@param swap_idx? number
---@return string? error
function M.equip_item(entity_id, idx, swap_idx)
    swap_idx = swap_idx or 1
    local e = entity.get(entity_id)
    if not e then
        return "entity not found"
    end
    if #e.equipped_items >= e.max_equipped_items then
        return "reached max equipped items"
    end
    
    local inventory_data = e.inventory[idx]
    local equipped_data = e.equipped_items[swap_idx]

    if equipped_data and equipped_data.renderable then
        -- remove renderable for previously equipped item
        render.remove(equipped_data.renderable)
    end

    local inventory_item = items.get(inventory_data.id)
    if not inventory_item then
        return "inventory item not found"
    end
    if inventory_item.render_on_character then
        -- add renderable for newly equipped item
        if e.screen_id then
            render.set_collection(e.screen_id)
        end
        inventory_data.renderable = render.add(
            images.renderable(inventory_item.image, {
                tag = inventory_item.id
            })
        )
        render.set_collection()
    end

    -- swap items
    e.inventory[idx] = equipped_data
    e.equipped_items[swap_idx] = inventory_data

    position_equipped_items(e)
end

---@param entity_id string
---@param item_data ItemData
---@return number,string?
function M.add_item_to_inventory(entity_id, item_data)
    local e = entity.get(entity_id)
    if not e then
        return 0, "entity not found"
    end
    if #e.inventory >= e.max_inventory_items then
        return 0, "reached max inventory items"
    end
    local item = items.get(item_data.id)
    if not item then
        return 0, "item not found"
    end
    table.insert(e.inventory, item_data)
    return #e.inventory
end

---@param entity_id string
---@return string? error
function M.kill(entity_id)
    local e = entity.get(entity_id)
    if not e then
        return errors.not_found("entity", entity_id)
    end
end

---@param args {equipped_items?:ItemData[], stats?:Stats, inventory?:ItemData[]}
---@return number power
function M.power_level(args)
    local power = 0
    local count = 0

    ---@param data ItemData
    local add_item_power = function (data)
        local item = items.get(data.id)
        if not item then
            return
        end
        if item and item.stats_ratio and args.stats then
            power = power + stats.apply(item.stats_ratio, args.stats)
            count = count + 1
        elseif item and item.defense then
            power = power + stats.diminishing(item.defense)
            count = count + 1
        end
    end

    for _, data in ipairs(args.inventory or {}) do
        add_item_power(data)
    end

    for _, data in ipairs(args.equipped_items or {}) do
        add_item_power(data)
    end

    return power / count
end

---@param dt number
function M.update(dt)
    for _, e in ipairs(entity.all()) do
        -- character physics
        local on_floor = e.floor_y and e.y and e.y >= e.floor_y
        local should_stand = not e.floor_behavior or e.floor_behavior == 'stand'
        local should_bounce = e.floor_behavior == 'bounce'
        local can_jump = e.jump_velocity and e.jump_velocity ~= 0
        local has_jumps_left = e.jumps and e.max_jumps and e.jumps < e.max_jumps
        local is_falling = e.vy and e.vy > 0

        -- apply velocity
        if e.x and e.vx then
            e.x = e.x + e.vx * dt
        end
        if e.y and e.vy then
            e.y = e.y + e.vy * dt
        end

        if e.gravity and not on_floor then
            -- apply gravity
            e.vy = (e.vy or 0) + e.gravity * dt
        end

        if on_floor and should_stand and is_falling then
            -- stand on floor
            e.vy = 0
            e.y = e.floor_y or const.FLOOR_Y
            if can_jump then
                -- reset jumps
                e.jumps = 0
            end
        end

        if on_floor and should_bounce and is_falling then
            -- bounce off floor
            e.vy = -e.vy * 0.6
            e.y = e.floor_y or const.FLOOR_Y
            if e.vy < 0 and e.vy >= const.BOUNCE_VY_THRESHOLD then
                -- stop bouncing
                e.vy = 0
                if can_jump then
                    -- reset jumps
                    e.jumps = 0
                end
            end
        end

        if can_jump and has_jumps_left and ctrl:pressed 'up' then
            -- jump
            e.jumps = (e.jumps or 0) + 1
            e.vy = e.jump_velocity
        end

        -- character rendering
        local r = e.render_character and render.get(e.render_character)
        if r and e.x and e.y then
            r.x = e.x
            r.y = e.y
        end

        -- text rendering
        local r_text = e.render_text and render.get(e.render_text)
        if r_text and e.x and e.y then
            r_text.x = e.x
            r_text.y = e.y
        end

        -- rendering for equipped items
        -- position_equipped_items(e)
    end
end

return log.log_methods('character', M, {
    exclude={'update', 'get_player'}
})