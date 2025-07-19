local M = {}

local entity = require 'lib.entity'
local log = require 'lib.log'
local lume = require 'ext.lume'
local lang = require 'lib.i18n'
local render = require 'render'
local signal = require 'lib.signal'
local items = require 'items'
local character = require 'character'
local screens= require 'screens'
local errors = require 'lib.errors'
local animation = require 'lib.animation'
local stats = require 'stats'
local projectiles = require 'projectiles'
local const       = require 'const'

local rad = math.rad
local deg = math.deg
local max = math.max
local min = math.min

---@alias CombatEnemyType 'boss'

---@class CombatEnemy
---@field id string
---@field health? Health
---@field stats? Stats
---@field disabled? boolean
---@field inventory? ItemData[]
---@field equipped_items? number[]
---@field type? CombatEnemyType
---@field only_zones? string[] only allow this enemy to spawn in specified zones

---@class CombatUseItemData
---@field type 'attack'
---@field source string
---@field target string
---@field item ItemData
---@field stats Stats
---@field damage? number
---@field mitigation? number

M.signals = signal.create 'combat'
M.SIGNALS = {
    on_start = 'on_start',
    ended = 'ended',
    attack_landed = 'attack_landed', -- CombatUseItemData
}

---@type table<string, CombatEnemy>
local enemies = {}

local in_combat = false

M.enemy = {}

---@param v CombatEnemy
function M.enemy.add(v)
    v.inventory = v.inventory or {}
    v.only_zones = v.only_zones or {}
    enemies[v.id] = v
end

---@param id string
function M.enemy.get(id)
    return enemies[id]
end

---@param id string
---@param screen_id? string
---@return string id, string? error
function M.enemy.spawn(id, screen_id)
    local enemy = id and enemies[id]
    if not enemy then
        return '', errors.not_found('enemy', id)
    end
    local e = character.create(
        {
            group='enemy',
            name=lang.get(enemy.id),
            inventory = enemy.inventory,
            equipped_items = {},
            health=enemy.health and lume.clone(enemy.health) or {current=const.HEALTH, max=const.HEALTH} --[[@as Health]],
            screen_id=screen_id,
            stats=enemy.stats and lume.clone(enemy.stats) or const.CLASS_STATS,
        },
        {
            frames = {{x=48, y=144, w=16, h=16}},
            sx = 2, sy = 2,
        }
    )
    for i in ipairs(e.inventory) do
        character.equip_item(e._id, i)
    end
    character.arrange()
    return e._id
end

---@param zone DungeonZone?
---@param enemy_types CombatEnemyType[]?
---@return string? id
function M.enemy.random(zone, enemy_types)
    enemy_types = enemy_types or {}
    local enemy_type = #enemy_types > 0 and lume.randomchoice(enemy_types) or nil
    
    ---@type string[]
    local possible_enemies = {}
    for key, enemy in pairs(enemies) do
        local correct_zone =
            not zone or
            not zone.enemies or
            lume.find(zone.enemies, enemy.id)
        if not enemy.disabled and correct_zone and (not enemy_type or enemy.type == enemy_type) then
            table.insert(possible_enemies, key)
        end
    end
    if log.warn_if(#possible_enemies == 0, "no possible enemies to pick from randomly, zone:", zone, ", type:", enemy_type) then
        if enemy_type then
            -- try to pick a random enemy without that type
            enemy_types = lume.remove(enemy_types, enemy_type)
            return M.enemy.random(zone, enemy_types)
        end
    end
    return lume.randomchoice(possible_enemies)
end

---@param zone DungeonZone?
---@param enemy_types CombatEnemyType[]?
---@param screen_id string?
---@return string? error
function M.start(zone, enemy_types, screen_id)
    local player = character.get_player()
    if not player then
        return errors.not_found('player')
    end

    local player_level = character.power_level(player)
    local enemy_power = 0
    local max_iter = 30
    while enemy_power < player_level and max_iter > 0 do
        local id = M.enemy.random(zone, enemy_types)
        if id then
            local e_id = M.enemy.spawn(id, screen_id)
            local e = entity.get(e_id)

            if e then
                enemy_power = enemy_power + character.power_level(e)
            end
        else
            log.error(errors.not_found('enemy', id))
        end
        max_iter = max_iter - 1
    end

    in_combat = true
    M.signals.emit(M.SIGNALS.on_start)
end

function M.is_in_progress()
    return in_combat
end

---@param data CombatUseItemData
---@return string? error
function M.process_attack(data)
    local source = entity.get(data.source)
    local target = entity.get(data.target)
    local item = items.get(data.item.id)

    if not source or not target then return end
    if not item then
        return errors.not_found('item', data.item.id)
    end

    if data.type == 'attack' then
        -- take damage from attack
        local damage = stats.apply(item.stats_ratio, source.stats)
        local mitigation = 0
        for _, e in ipairs(target.equipped_items or {}) do
            local target_item = items.get(e.id)
            if target_item and target_item.defense then
                mitigation = mitigation + stats.defense(target_item.defense)
            end
        end
        character.add_health(target._id, min(0, -(damage - mitigation)))
        data.damage = damage
        data.mitigation = mitigation
        
        log.debug('data after', data)
        M.signals.emit(M.SIGNALS.attack_landed, data)
    end
end

---@param source_id string entity id
---@param target_id string entity id
---@param item_data ItemData item used
---@return string? error
function M.use_item(source_id, target_id, item_data)
    local source = entity.get(source_id)
    local target = entity.get(target_id)
    local item = items.get(item_data.id)

    if not source then return errors.not_found("source entity", source_id) end
    local src_stats = source.stats

    if not src_stats then return errors.missing_field("source.stats") end
    if not target then return errors.not_found("target entity", target_id) end
    if not item then return errors.not_found("item", item_data.id) end
    if not item.image then return errors.missing_field("item.image") end
    if not source.render_character then return errors.missing_field("source.render_character") end
    if not target.render_character then return errors.missing_field("target.render_character") end

    -- animate attack
    if item.attack_animation then
        local r_weapon = item_data.renderable and render.get(item_data.renderable)
        local swing = item.attack_animation.swing
        local shoot = item.attack_animation.shoot
        local projectile = shoot and shoot.projectile
        local custom = item.attack_animation.custom
        
        if (swing or shoot) and not r_weapon then
            return errors.missing_field("item_data.renderable", item_data)
        end

        ---@type CombatUseItemData
        local data = {
            type = 'attack',
            source = source._id,
            target = target._id,
            item = item_data,
            stats = lume.clone(src_stats),
        }

        if custom then
            custom(source, target, item_data)
        end

        if swing and r_weapon and source.render_character then
            local r = r_weapon
            r.r = r.r or 0

            local err = M.process_attack(data)
            if err then return err end

            -- swing weapon
            animation
                .create(r.id, r)
                .add(
                    {to={r=deg(r.r) >= (45+135)/2 and rad(45) or rad(135)}, duration=1000, data=data}
                )
                .on_end(function ()
                    if item.attack_landed then
                        item.attack_landed(target, {})
                    end
                    M.signals.emit(M.SIGNALS.attack_landed, data)
                end)
                .start()
        end

        if shoot and r_weapon then
            local r = r_weapon
            -- TODO recoil
            -- animation
            --     .create(r.id, r)
            --     .add()
            
            if projectile then
                local from = {render.transform_point(r_weapon.id, r_weapon.ox, r_weapon.oy)}
                local target_screen_ox, target_screen_oy = screens.rect(target.screen_id)

                projectiles.create(
                    {x=from[1], y=from[2]},
                    {x=target.x + target_screen_ox, y=target.y + target_screen_oy},
                    projectile,
                    {data=data, target=target}
                )

                -- animation
                --     .create(r_projectile.id, r_projectile)
                --     .add({to={x=target_x, y=target_y}, duration=1000, data=data, ease_fn=projectile.ease_fn})
                --     .on_end(function ()
                --         if item.attack_landed then
                --             item.attack_landed(target, {r_projectile})
                --         end
                --         M.signals.emit(M.SIGNALS.attack_landed, data)
                --     end)
                --     .start()
            end
        end
    end
end

function M.load()
    projectiles.signals.on(projectiles.SIGNALS.reached_target, function (data)
        ---@cast data CombatUseItemData
        if data and data.type == 'attack' then
            M.signals.emit(M.SIGNALS.attack_landed, data)
        end
    end)
end

function M.update(dt)
    local combat_entities = entity.find('health', 'group')
    local no_enemies_left = true

    for _, e in ipairs(combat_entities) do
        -- dead
        if e.health and e.health.current <= 0 and e.group ~= 'player' then
            -- remove sprite
            log.info(e.name or e._id, "died")
            render.remove(e.render_character)
            entity.remove(e._id)
        end
        if e.health and e.health.current > 0 and e.stats then
            if e.group == 'enemy' then
                no_enemies_left = false
            end

            if not e.attack_timer then
                e.attack_timer = 0
            end
            e.attack_timer = e.attack_timer + (dt * 1000 * stats.attack_speed(e.stats))

            -- attack
            if e.stats and e.attack_timer >= 1000 then
                e.attack_timer = 0
            
                -- process items
                for _, data in ipairs(e.equipped_items) do
                    -- get target
                    local target --[[@as Entity?]]
                    for _, other in ipairs(combat_entities) do
                        if other._id ~= e._id then
                            target = other
                        end
                    end
                    if target then
                        M.use_item(e._id, target._id, data)
                    end
                end
            end

        end
    end

    -- combat is over
    if no_enemies_left and in_combat then
        in_combat = false
        M.signals.emit(M.SIGNALS.ended)
    end
end

return log.log_methods('combat', M, {
    exclude={'is_in_progress', 'update'}
})