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

---@alias CombatEnemyType 'boss'

---@class CombatEnemy
---@field id string
---@field health? Health
---@field stats? Stats
---@field disabled? boolean
---@field items? ItemData[]
---@field type? CombatEnemyType
---@field only_zones? string[] only allow this enemy to spawn in specified zones

local IMG = {}

---@type table<string, CombatEnemy>
local enemies = {}

local in_combat = false

M.signals = signal.create 'combat'
M.SIGNALS = {
    on_start = 'on_start',
    on_end = 'on_end'
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
    log.info("start combat", {screen_id=screen_id})

    for i = 1, 1 do -- TODO scale based on difficulty or whatever
        local id = M.get_random_enemy(zone, enemy_types)
        local enemy = id and enemies[id]
        if enemy then
            log.info("add enemy", enemy.id)
            local e = char.create(
                {
                    group='enemy',
                    name=lang.get(enemy.id),
                    items=enemy.items and lume.clone(enemy.items) or nil,
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
function M.attack(source_id, target_id, item_data)
    local source = entity.get(source_id)
    local target = entity.get(target_id)
    local item = items.get_by_id(item_data.id)

    if not source then return errors.not_found("source entity", source_id) end
    if not target then return errors.not_found("target entity", target_id) end
    if not item then return errors.not_found("item", item_data.id) end

    if not (item.image and source.render_character and target.render_character) then
        return "missing visuals"
    end

    -- animate attack
    local r_id, r = render.add{
        tex = images.get(item.image),
        frames = item.image.frames,
        current_frame = 1,
        copy_transform = source.render_character,
        data = {
            type = 'attack',
            source = source._id,
            target = target._id,
            item = item_data,
            stats = lume.clone(source.stats),
        }
    }
    local e_render_x, e_render_y = render.transform_point(source.render_character, 0, 0)
    local e_screen_ox, e_screen_oy = screens.rect(source.screen_id)
    r.x = e_render_x + e_screen_ox
    r.y = e_render_y + e_screen_oy
    -- ease towards target
    render.move_to(r_id, target.render_character, {
        duration = 500,
        transform_target = function (_, x, y)
            if target.screen_id then
                local target_screen_ox, target_screen_oy = screens.rect(source.screen_id)
                return x + target_screen_ox, y + target_screen_oy
            end
            return x, y
        end
    })
    -- screen drawing offset
    if source.screen_id then
        local screen = screens.get(source.screen_id)
        if screen then
            r.x = r.x + screen.ox
            r.y = r.y + screen.oy
        end
    end
end

function M.load()
    IMG.ohmydungeon_v11 = love.graphics.newImage(assets.ohmydungeon_v11)
    IMG.ohmydungeon_v11:setFilter('linear', 'nearest')

    render.signals.on(render.SIGNALS.easing_done,
        ---@param id any
        ---@param r Renderable
        function (id, r)
            local data = r.data
            if data and data.source then
                local source = entity.get(data.source)
                if not source then
                    log.warn("attack source not found, data:", data)
                    return
                end

                -- attack animation
                if source and data.type == 'attack' then
                    local target = entity.get(data.target)
                    if not target then
                        log.warn('attack target not found, target-data:', data.target)
                        return
                    end

                    -- get modified character stats
                    local stats = data.stats --[[@as Stats]]
                    for _, data in ipairs(source.items) do
                        local item = items.get_by_id(data.id)
                        if item and item.stats_ratio then
                            stats.agi = stats.agi * item.stats_ratio.agi
                            stats.int = stats.int * item.stats_ratio.int
                            stats.str = stats.str * item.stats_ratio.str
                        end
                    end

                    -- calculate damage the attack will do
                    local damage = stats.str + stats.agi + stats.int
                    for _, data in ipairs(target.items) do
                        local item = items.get_by_id(data.id)
                        if item and item.mitigate_damage then
                            damage = item.mitigate_damage(target, damage)
                        end
                    end
 
                    if not char.add_health(target, -damage) then
                        log.warn("attack failed, could not change target hp, damage:", -damage, ", hp:", target.health.current, target.health.max)
                    end
                    render.remove(id)
                end
            end
        end
    )
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
                for _, data in ipairs(e.items) do
                    -- get target
                    local target --[[@as Entity?]]
                    for _, other in ipairs(combat_entities) do
                        if other._id ~= e._id then
                            target = other
                        end
                    end

                    M.attack(e._id, target._id, data)
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

return M