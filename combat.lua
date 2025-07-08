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

---@alias CombatEnemyType 'boss'

---@class CombatEnemy
---@field id string
---@field health Health
---@field stats Stats
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
    on_end = 'on_end'
}

---@param v CombatEnemy
function M.add_enemy(v)
    v.items = v.items or {}
    v.only_zones = v.only_zones or {}
    enemies[v.id] = v
end

---@param zone_id string?
---@param enemy_types CombatEnemyType[]?
function M.start(zone_id, enemy_types)
    log.info("start combat")
    local gw, gh = love.graphics.getDimensions()

    for i = 1, 1 do -- scale based on difficulty
        local id = M.get_random_enemy(zone_id, enemy_types)
        local enemy = id and enemies[id]
        if enemy then
            local e = entity.add{
                group='enemy',
                name=lang.get(enemy.id),
                items=lume.clone(enemy.items),
                health=lume.clone(enemy.health),
                screen_id=zone_id,
                stats=lume.clone(enemy.stats),
            }
            if zone_id then
                render.set_collection(zone_id)
            end
            e.render_character = render.add{
                tex = IMG.ohmydungeon_v11,
                frames = {{x=48, y=144, w=16, h=16}},
                current_frame = 1,
                x = gw * 2/3, y = gh / 2,
                ox = 8, oy = 8,
                sx = -2, sy = 2,
            }
            render.set_collection()
        end
    end

    in_combat = true
end

function M.is_in_progress()
    return in_combat
end

---@param zone_id string?
---@param enemy_types CombatEnemyType[]?
---@return string? id
function M.get_random_enemy(zone_id, enemy_types)
    enemy_types = enemy_types or {}
    local enemy_type = #enemy_types > 0 and lume.randomchoice(enemy_types) or nil
    
    ---@type string[]
    local possible_enemies = {}
    for key, enemy in pairs(enemies) do
        local correct_zone = not zone_id or not enemy.only_zones or lume.find(enemy.only_zones, zone_id)
        if not enemy.disabled and correct_zone and (not enemy_type or enemy.type == enemy_type) then
            table.insert(possible_enemies, key)
        end
    end
    if log.warn_if(#possible_enemies == 0, "no possible enemies to pick from randomly, zone:", zone_id, ", type:", enemy_type) then
        if enemy_type then
            -- try to pick a random enemy without that type
            enemy_types = lume.remove(enemy_types, enemy_type)
            return M.get_random_enemy(zone_id, enemy_types)
        end
    end
    return lume.randomchoice(possible_enemies)
end

function M.load()
    IMG.ohmydungeon_v11 = love.graphics.newImage(assets.ohmydungeon_v11)
    IMG.ohmydungeon_v11:setFilter('linear', 'nearest')

    render.signals.on(render.SIGNALS.easing_done,
        ---@param id any
        ---@param r Renderable
        function (id, r)
            local data = r.data
            if data then
                -- attack animation
                if data.type == 'attack' then
                    local source = entity.get(data.source)
                    local target = entity.get(data.target)
                    assert(target, 'attack source not found')
                    assert(target, 'attack target not found')

                    -- get modified character stats
                    local stats = data.stats --[[@as Stats]]
                    for _, data in ipairs(source.items) do
                        local item = items.get_by_id(data.id)
                        if item and item.modify_stats then
                            item.modify_stats(stats)
                        end
                    end

                    -- calculate damage the attack will do
                    local damage = stats.str
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
                    local item = items.get_by_id(data.id)
                    if item and item.image and e.render_character and target and target.render_character then
                        log.debug('combat attack item:', data.id, ', target:', target.name)
                        -- animate attack
                        local r_id, r = render.add{
                            tex = images.get(item.image),
                            frames = item.image.frames,
                            current_frame = 1,
                            copy_transform = e.render_character,
                            data = {
                                type = 'attack',
                                source = e._id,
                                target = target._id,
                                item = data,
                                stats = lume.clone(e.stats),
                            }
                        }
                        -- ease towards target
                        render.move_to(r_id, e.render_character, target.render_character, {
                            duration = 500
                        })
                        -- zone drawing offset
                        if e.screen_id then
                            local zone = zones.get(e.screen_id)
                            if zone then
                                r.x = r.x + zone.render.ox
                                r.y = r.y + zone.render.oy
                            end    
                        end
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

return M