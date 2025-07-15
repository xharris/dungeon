local M = {}

local entity = require 'lib.entity'
local log = require 'lib.log'
local lume = require 'ext.lume'
local lang = require 'lib.i18n'
local render = require 'render'
local signal = require 'lib.signal'
local zones = require 'screens'
local items = require 'items'
local char = require 'character'
local images = require 'lib.images'
local assets = require 'assets.index'
local screens= require 'screens'
local errors = require 'lib.errors'
local animation = require 'lib.animation'
local easing    = require 'lib.easing'

local rad = math.rad
local deg = math.deg

---@alias CombatEnemyType 'boss'

---@class CombatEnemy
---@field id string
---@field health? Health
---@field stats? Stats
---@field disabled? boolean
---@field items? ItemData[]
---@field type? CombatEnemyType
---@field only_zones? string[] only allow this enemy to spawn in specified zones

---@class CombatUseItemData
---@field type 'attack'
---@field source string
---@field target string
---@field item ItemData
---@field stats Stats

local IMG = {}

---@type table<string, CombatEnemy>
local enemies = {}

local in_combat = false

M.signals = signal.create 'combat'
M.SIGNALS = {
    on_start = 'on_start',
    on_end = 'on_end',
    attack_landed = 'attack_landed', -- CombatUseItemData
}

---@param v CombatEnemy
function M.add_enemy(v)
    v.items = v.items or {}
    v.only_zones = v.only_zones or {}
    enemies[v.id] = v
end

---@param zone DungeonZone?
---@param enemy_types CombatEnemyType[]?
---@param screen_id string?
function M.start(zone, enemy_types, screen_id)
    for i = 1, 1 do -- TODO scale based on difficulty or whatever
        local id = M.get_random_enemy(zone, enemy_types)
        local enemy = id and enemies[id]
        if enemy then
            log.info("add enemy", enemy.id)
            local e = char.create(
                {
                    group='enemy',
                    name=lang.get(enemy.id),
                    equipped_items=enemy.items and lume.clone(enemy.items) or nil,
                    health=enemy.health and lume.clone(enemy.health) or nil,
                    screen_id=screen_id,
                    stats=enemy.stats and lume.clone(enemy.stats) or nil,
                },
                {
                    frames = {{x=48, y=144, w=16, h=16}},
                    sx = 2, sy = 2,
                }
            )
        end
    end

    in_combat = true
    M.signals.emit(M.SIGNALS.on_start)
end

function M.is_in_progress()
    return in_combat
end

---@param zone DungeonZone?
---@param enemy_types CombatEnemyType[]?
---@return string? id
function M.get_random_enemy(zone, enemy_types)
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
            return M.get_random_enemy(zone, enemy_types)
        end
    end
    return lume.randomchoice(possible_enemies)
end

---@param source_id string entity id
---@param target_id string entity id
---@param item_data ItemData item used
---@return string? error
function M.use_item(source_id, target_id, item_data)
    local source = entity.get(source_id)
    local target = entity.get(target_id)
    local item = items.get_by_id(item_data.id)

    if not source then return errors.not_found("source entity", source_id) end
    local stats = source.stats
    if not stats then return errors.missing_field("source.stats") end
    if not target then return errors.not_found("target entity", target_id) end
    if not item then return errors.not_found("item", item_data.id) end

    if not (item.image and source.render_character and target.render_character) then
        return "missing visuals"
    end

    -- animate attack
    if item.attack_animation then
        local r_weapon = item_data.renderable and render.get(item_data.renderable)
        local swing = item.attack_animation.swing
        local shoot = item.attack_animation.shoot
        log.warn_if((swing or shoot) and not r_weapon, "missing weapon renderable")

        ---@type CombatUseItemData
        local data = {
            type = 'attack',
            source = source._id,
            target = target._id,
            item = item_data,
            stats = lume.clone(stats),
        }

        if swing and r_weapon and source.render_character then
            local r = r_weapon
            r.r = r.r or 0
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
            
            -- shoot projectile
            local _, r_projectile = render.add(images.renderable(shoot.projectile.image))
            r_projectile.x, r_projectile.y = render.transform_point(r_weapon.id, r_weapon.ox, r_weapon.oy)

            local target_screen_ox, target_screen_oy = screens.rect(source.screen_id)
            local target_x = target.x + target_screen_ox
            local target_y = target.y + target_screen_oy

            animation
                .create(r_projectile.id, r_projectile)
                .add(
                    {to={x=target_x, y=target_y}, duration=1000, data=data, ease_fn=shoot.projectile.ease_fn}
                )
                .on_end(function ()
                    if item.attack_landed then
                        item.attack_landed(target, {r_projectile})
                    end
                    M.signals.emit(M.SIGNALS.attack_landed, data)
                end)
                .start()
        end
    end
end

function M.load()
    IMG.ohmydungeon_v11 = love.graphics.newImage(assets.ohmydungeon_v11)
    IMG.ohmydungeon_v11:setFilter('linear', 'nearest')
end

function M.update(dt)
    local combat_entities = entity.find('abilities', 'cooldowns', 'health')
    local no_enemies_left = true

    for _, e in ipairs(combat_entities) do
        -- dead
        if e.health.current <= 0 and e.group ~= 'player' then
            -- remove sprite
            log.info(e.name or e._id, "died")
            render.remove(e.render_character)
            entity.remove(e._id)
        end
        if e.health.current > 0 then
            if e.group == 'enemy' then
                no_enemies_left = false
            end

            local stats = e.stats and lume.clone(e.stats)
            if not e.attack_timer then
                e.attack_timer = 0
            end
            e.attack_timer = e.attack_timer + (dt * 1000)

            -- attack
            if stats and e.attack_timer >= 1000 then -- TODO stats.agi modifier
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
        M.signals.emit(M.SIGNALS.on_end)
    end
end

return log.log_methods('combat', M, {
    exclude={'is_in_progress', 'update'}
})