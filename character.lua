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
local util  = require 'lib.util'
local game  = require 'game'

local abs = math.abs
local min = math.min
local max = math.max
local floor = math.floor
local rad = math.rad

---@class CharacterEscortClient
---@field name string
---@field health Health
---@field stats Stats
---@field items? ItemData[]
---@field money? number

---@alias CharacterExpression 'neutral'|'happy'|'ouch'|'angry'|'sad'|'blink'|'suspicious'

---@class CharacterSprite
---@field facing? 'left'|'right'
---@field looking? 'straight'|'up'|'down'
---@field default_expression? CharacterExpression
---@field expression? CharacterExpression
---@field hand_r? Vector2 position relative to center of body
---@field hand_l? Vector2 position relative to center of body
---@field renderables? {root?:string, body?:string, eyes?:string, arm_r?:string, arm_l?:string, hand_r?:string, hand_l?:string}

M.signals = signal.create 'character'
M.SIGNALS = {
    change_health = 'change_health', -- entity_id, number
    death = 'death' -- entity_id,
}

M.sprite = {}

---@type table<CharacterExpression, Image>
local expression_images = {
    neutral = {
        path = assets.character_template,
        frames = {{x=64, y=16, w=8, h=7}},
        ox = 3, oy = 3.5,
    },
    angry = {
        path = assets.character_template,
        frames = {{x=54, y=16, w=8, h=7}},
        ox = 3, oy = 3.5,
    }
}

---@type Image
local hand_image = {
    path = assets.character_template,
    frames = {{x=32, y=0, w=8, h=8}},
    ox = 4, oy = 4,
}

---@type Image
local body_image = {
    path = assets.character_template,
    frames = {
        {x=0, y=0, w=32, h=32},
    },
    ox = 16, oy = 16,
}

---set character expression (eyes)
---@param entity_id string
---@param v? CharacterExpression
---@return string? error
function M.sprite.expression(entity_id, v)
    local e = entity.get(entity_id)
    local spr = e and e.character_sprite
    v = v or spr and spr.expression or spr and spr.default_expression or 'neutral'
    local image = expression_images[v]

    if not e then return errors.not_found('entity', entity_id) end
    if not spr then return errors.missing_field('character_sprite', e) end
    if not image then return errors.not_found('expression image', v) end

    render.set_collection(e.screen_id)
    spr.expression = v
    local r = spr.renderables.eyes and render.get(spr.renderables.eyes)
    if not r then
        -- create new renderable
        _, r = render.add(images.renderable(image, {
            tag='char_eyes',
            parent=e.character_sprite.renderables.root,
        }))
    else
        -- update existing renderable
        r = lume.extend(r, images.renderable(image))
    end
    render.set_collection()

    spr.renderables.eyes = r.id
    r.y = -6

    r.z = zindex.character_eyes
end

---@param entity_id string
---@return string? error
function M.sprite.reset_hands(entity_id)
    local e = entity.get(entity_id)
    local spr = e and e.character_sprite

    if not e then return errors.not_found('entity', entity_id) end
    if not spr then return errors.missing_field('character_sprite', e) end

    render.set_collection(e.screen_id)
    -- get/create renderables
    if not spr.renderables.hand_l then
        spr.renderables.hand_l = render.add(images.renderable(hand_image, {
            tag='char_hand_l',
            parent=e.character_sprite.renderables.root,
            r2_radius = 6,
        }))
    end
    if not spr.renderables.hand_r then
        spr.renderables.hand_r = render.add(images.renderable(hand_image, {
            tag='char_hand_r',
            parent=e.character_sprite.renderables.root,
            r2_radius = 6,
        }))
    end
    render.set_collection()

    local r = M.sprite.renderables(entity_id)
    local r_hand_l, r_hand_r = r.hand_l, r.hand_r

    local has_item_with_swing_animation =
        e.equipped_items and
        lume.any(e.equipped_items, function (v)
            local item = items.get(v.id)
            return item and item.attack_animation and item.attack_animation.swing ~= nil or false
        end)

    if e.is_in_combat and has_item_with_swing_animation then
        r_hand_l.r2 = const.ITEM_SWING.UP_ANGLE
        r_hand_r.r2 = rad(135)
    else
        r_hand_l.r2 = rad(45)
        r_hand_r.r2 = rad(135)
    end

    r_hand_l.z = zindex.character_hand_back
    r_hand_r.z = zindex.character_hand_front
end

---@param entity_id string
function M.sprite.body(entity_id)
    local e = entity.get(entity_id)
    local spr = e and e.character_sprite

    if not e then return errors.not_found('entity', entity_id) end
    if not spr then return errors.missing_field('character_sprite', e) end

    local r_body
    if not spr.renderables.body then
        render.set_collection(e.screen_id)
        spr.renderables.body, r_body = render.add(
            images.renderable(body_image, {
                tag='char_body',
                parent=e.character_sprite.renderables.root,
            })
        )
        render.set_collection()
    else
        r_body = render.get(spr.renderables.body)
    end
    r_body.z = zindex.character_body
end

---@param entity_id string
---@return {root?:Renderable, body?:Renderable, eyes?:Renderable, hand_l?:Renderable, hand_r?:Renderable}, string? error
function M.sprite.renderables(entity_id)
    local e = entity.get(entity_id)
    local spr = e and e.character_sprite
    local ids = e and spr and spr.renderables
    if not e then return {}, errors.not_found('entity', entity_id) end
    if not ids then return {}, errors.missing_field('entity.character_sprite.renderables', e) end

    return {
        root = render.get(ids.root),
        body = render.get(ids.body),
        eyes = render.get(ids.eyes),
        hand_l = render.get(ids.hand_l),
        hand_r = render.get(ids.hand_r),
    }
end

M.sprite = log.log_methods('character.sprite', M.sprite, {
    exclude = {'renderables'}
})

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

    -- v = floor(v)

    e.health.current = max(0, min(e.health.max, e.health.current + v))
    M.signals.emit(M.SIGNALS.change_health, e._id, v)
end

---@return Entity|false
function M.get_player()
    for _, e in entity.filter('group') do
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

    local ally_count, enemy_count = 0, 0
    for _, e in entity.filter('character_sprite', 'group') do
        if e.group == 'ally' or e.group == 'player' then
            ally_count = ally_count + 1
        end
        if e.group == 'enemy' then
            enemy_count =enemy_count + 1
        end
    end

    local ally_sep = math.min(const.CHAR_ARRANGE_SEP, (0.25 * w) / ally_count)
    local enemy_sep = math.min(const.CHAR_ARRANGE_SEP, (0.25 * w) / enemy_count)
    
    local ally_x = (0.25 * w) + screen_x
    local enemy_x = (0.75 * w) + screen_x

    if player then
        player.x = ally_x
        ally_x = ally_x - ally_sep
    end

    for _, e in ipairs(entity.all()) do
        if not player or e._id ~= player._id then
            if e.group == 'ally' then
                e.x = ally_x
                ally_x = ally_x - ally_sep
                e.character_sprite.facing = 'right'
            end
            if e.group == 'enemy' then
                e.x = enemy_x
                enemy_x = enemy_x + enemy_sep
                e.character_sprite.facing = 'left'
            end
        end
    end
end

---@param v Entity?
---@param renderable Renderable?
---@return Entity, string? error
function M.create(v, renderable)
    local name = v and v.name or 'player'
    log.debug('name =', name)
    local e = entity.add(util.merge(
        {
            tag = v and v.tag or name,
            group = 'player',
            name = name,
            inventory = {},
            equipped_items = {},
            max_equipped_items = const.MAX_EQUIPPED_ITEMS,
            max_inventory_items = const.MAX_INVENTORY_ITEMS,
            class = 'adventurer',
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
            stats = lume.clone(const.BASE_STATS),
            defense = 0,
            critical = {
                chance = 0,
                damage = const.CRITICAL_DAMAGE,
            },
            character_sprite = {
                default_expression = 'neutral',
                facing = 'right',
                looking = 'straight',
                renderables = {
                    root = render.add{tag='char_root', sx=2, sy=2, ox=16, oy=16},
                },
            }
        } --[[@as Entity]],
        v or {}
    ))
    -- set screen
    local screen_id = M.get_screen_id(e._id)
    if e.group ~= 'player' then
        local player = M.get_player()
        if player then
            screen_id = M.get_screen_id(player._id)
        end
    end
    e.screen_id = screen_id

    -- add character sprites
    M.sprite.expression(e._id)
    M.sprite.reset_hands(e._id)
    M.sprite.body(e._id)

    -- add weapon sprite
    for _, data in ipairs(e.inventory) do
        local item = items.get(data.id)
        if item and item.is_starter then
            local idx = M.add_item_to_inventory(e._id, data)
            M.equip_item(e._id, idx)
        end
    end
    M.arrange()
    return e
end

---update stats based on item effects
---@param e Entity
local function update_stats(e)
    e.stats = lume.clone(const.BASE_STATS)

    ---@param base_value number
    ---@param transform_field string
    ---@param operation ItemTransformOperation
    local function update_stat(base_value, transform_field, operation)
        local value = base_value
        for _, data in M.all_items(e._id) do
            local item = items.get(data.id)
            local transform_stats = item and item.transform_stats and item.transform_stats[transform_field]
            local operation = (transform_stats and transform_stats.operation == operation) and transform_stats.operation or nil
            local v = transform_stats and transform_stats.value

            if v then
                if operation == 'add' then
                    value = value + v
                elseif operation == 'sub' then
                    value = value - v
                elseif operation == 'mult' then
                    value = value * v
                elseif operation == 'set' then
                    value = v
                end
            end
        end
        return value
    end

    ---@type Health
    local new_hp = {current=0, max=const.HEALTH}
    e.health.max = const.HEALTH

    new_hp.max = update_stat(new_hp.max, 'health.max', 'add')
    new_hp.max = update_stat(new_hp.max, 'health.max', 'sub')
    new_hp.max = update_stat(new_hp.max, 'health.max', 'mult')

    for _, s in ipairs{'str', 'int', 'agi'} do
        e.stats[s] = update_stat(e.stats[s], 'stats.'..s, 'add')
        e.stats[s] = update_stat(e.stats[s], 'stats.'..s, 'sub')
        e.stats[s] = update_stat(e.stats[s], 'stats.'..s, 'mult')
    end

    for _, s in ipairs{'chance', 'damage'} do
        e.critical[s] = update_stat(e.critical[s], 'critical.'..s, 'add')
        e.critical[s] = update_stat(e.critical[s], 'critical.'..s, 'sub')
        e.critical[s] = update_stat(e.critical[s], 'critical.'..s, 'mult')
    end
    e.critical.chance = min(1, max(0, e.critical.chance))

    -- scale up/down current hp
    new_hp.current = (new_hp.max / e.health.max) * e.health.current
    e.health = new_hp

    log.debug('update stats', {id=e._id,stats=e.stats,health=e.health})
end

---@param entity_id string
function M.all_items(entity_id)
    local e = entity.get(entity_id)
    local i = 0
    local equip_n = e and e.equipped_items and #e.equipped_items or 0
    local inventory_n = e and e.inventory and #e.inventory or 0
    return function ()
        i = i + 1
        if e and i <= equip_n then
            return i, e.equipped_items[i]
        end
        if e and i > equip_n and i <= inventory_n then
            return i, e.inventory[i - equip_n]
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

    local inventory_item = items.get(inventory_data.id)
    if not inventory_item then
        return "inventory item not found"
    end
    if inventory_item.is_ability then
        return "cannot equip ability"
    end

    local hand_l = e.character_sprite and e.character_sprite.renderables.hand_l
    local render_on_character = inventory_item.render_on_character or {}
    if hand_l and inventory_item.render_on_character then
        -- add renderable for newly equipped item
        if e.screen_id then
            render.set_collection(e.screen_id)
        end
        inventory_data.renderable = render.add(
            images.renderable(inventory_item.image, {
                tag = inventory_item.id,
                parent = hand_l,
                x = render_on_character.x or 0,
                y = render_on_character.y or 0,
                z = render_on_character.z or zindex.equipped_item_back
            })
        )
        render.set_collection()
    end

    -- remove previously equipped item renderable
    if equipped_data and equipped_data.renderable then
        -- remove renderable for previously equipped item
        render.remove(equipped_data.renderable)
    end

    -- default data value
    if equipped_data then
        equipped_data.data = equipped_data.data or {}
    end
    inventory_data.data = inventory_data.data or {}
    
    -- swap items
    e.inventory[idx] = equipped_data
    e.equipped_items[swap_idx] = inventory_data

    -- update class
    if inventory_item.class then
        e.class = inventory_item.class
    end

    update_stats(e)
end

---@param entity_id string
---@param item_id string
---@return boolean
function M.has_item_equipped(entity_id, item_id)
    local e = entity.get(entity_id)
    if not e or not e.equipped_items then
        return false
    end
    for _, data in ipairs(e.equipped_items) do
        if data.id == item_id then
            return true
        end
    end
    return false
end

---@param entity_id string
---@param item_id string
---@return boolean
function M.has_item_in_inventory(entity_id, item_id)
    local e = entity.get(entity_id)
    if not e or not e.inventory then
        return false
    end
    for _, data in ipairs(e.inventory) do
        if data.id == item_id then
            return true
        end
    end
    return false
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
    item_data.data = item_data.data or {}
    table.insert(e.inventory, item_data)

    update_stats(e)

    return #e.inventory
end

---@param entity_id string
---@return string? error
function M.kill(entity_id)
    local e = entity.get(entity_id)
    if not e then
        return errors.not_found("entity", entity_id)
    end
    -- check if items will allow it
    for _, data in M.all_items(entity_id) do
        local item = items.get(data.id)
        if item and item.user_will_die and item.user_will_die(data, e) then
            return "death cancelled"
        end
    end
    -- remove sprite
    local ids = e.character_sprite and e.character_sprite.renderables
    if ids then
        render.remove(ids.body)
        render.remove(ids.eyes)
        render.remove(ids.hand_l)
        render.remove(ids.hand_r)
    end
    entity.remove(e._id)
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
        if item and item.damage_scaling and args.stats then
            power = power + stats.apply(item.damage_scaling, args.stats)
            count = count + 1
        elseif item and item.defense then
            power = power + util.diminishing(item.defense)
            count = count + 1
        end
    end

    power = power + stats.apply({agi=1, int=1, str=1, crit=0}, args.stats)

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

        -- character sprite
        local spr = e.character_sprite
        local r = M.sprite.renderables(e._id)
        if r.root then
            -- face direction
            if spr.facing == 'left' then
                r.root.sx = -abs(r.root.sx)
            elseif spr.facing == 'right' then
                r.root.sx = abs(r.root.sx)
            end
            -- position
            r.root.x = e.x
            r.root.y = e.y
        end

        -- held weapons
        if spr and e.equipped_items then
            for _, data in ipairs(e.equipped_items) do
                local item = items.get(data.id)
                local r_item = item and data.renderable and render.get(data.renderable)
                
                if item and r_item and item.render_on_character then
                    -- attach to left hand
                    r_item.parent = spr.renderables.hand_l or spr.renderables.root
                    -- offset
                    if item and item.render_on_character then
                        r_item.x = item.render_on_character.x or 0
                        r_item.y = item.render_on_character.y or 0
                    end
                end
            end
        end

        -- text rendering
        local r_text = e.render_text and render.get(e.render_text)
        if r_text and e.x and e.y then
            r_text.x = e.x
            r_text.y = e.y
        end

        -- rendering for equipped items
        -- position_equipped_items(e)

        -- dead
        if e.health and e.health.current <= 0 then
            M.kill(e._id)
        end
    end
end

return log.log_methods('character', M, {
    exclude={'update', 'get_player', 'all_items'}
})