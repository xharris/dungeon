local M = {}

local entity = require 'lib.entity'
local log = require 'lib.log'
local lume = require 'ext.lume'
local lang = require 'lib.i18n'
local render = require 'render'
local signal = require 'lib.signal'
local zones = require 'zones'

---@class CombatEnemy
---@field id string
---@field health Health
---@field stats Stats
---@field disabled? boolean
---@field items? ItemData[]

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
    enemies[v.id] = v
end

---@param zone_id string?
function M.start(zone_id)
    local gw, gh = love.graphics.getDimensions()

    for i = 1, 1 do -- scale based on difficulty
        local id = M.get_random_enemy()
        if id then
            local enemy = enemies[id]
            local e = entity.add{
                group='enemy',
                name=lang.get(enemy.id),
                items=lume.clone(enemy.items),
                health=lume.clone(enemy.health),
                zone_id=zone_id,
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

---@return string? id
function M.get_random_enemy()
    ---@type string[]
    local possible_enemies = {}
    for key, event in pairs(enemies) do
        if not event.disabled then
            table.insert(possible_enemies, key)
        end
    end
    log.warn_if(#possible_enemies == 0, "no enemies left to pick from randomly")
    return lume.randomchoice(possible_enemies)
end

function M.load()
    IMG.ohmydungeon_v11 = love.graphics.newImage('assets/ohmydungeon_v1.1.png')
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
                for _, data in ipairs(e.items) do
                    -- get target
                    local target --[[@as Entity?]]
                    for _, other in ipairs(combat_entities) do
                        if other._id ~= e._id then
                            target = other
                        end
                    end
                    if e.render_character and target and target.render_character then
                        -- animate attack
                        local r_id, r = render.add{
                            tex = IMG.dk_items,
                            frames = {{x=160, y=128, w=16, h=16}},
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
                        local zone = zones.get(e.zone_id)
                        if zone then
                            r.x = r.x + zone.render.ox
                            r.y = r.y + zone.render.oy
                        end
                    end
                end
            end

        end
    end

    -- combat is over
    if no_enemies_left then
        in_combat = false
        M.signals.emit(M.SIGNALS.on_end)
    end
end

return M