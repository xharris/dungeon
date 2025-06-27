local entity = require 'lib.entity'
local log = require 'lib.log'
local circleui = require 'lib.circleui'
local ctrl = require 'lib.controls'
local lang = require 'lib.i18n'
local lume = require 'ext.lume'
local zone = require 'zones'
local color = require 'lib.color'
local render = require 'render'

lang.set('en', {
    slash = 'Slash',
    basic_armor = 'Basic Armor',
})

local const = {
    INITIAL_PLAYER_HEALTH = 20
}

local DEFAULT_STATE = {
    ---@type Room[]?
    next_room_choices = nil,
    shop_items = nil,
    in_combat = false,
    money = 0,
    ---@type string?
    next_event = nil,
    ---@type string?
    current_event = nil,
    is_game_over = false,
    ---@type 'forest'|'space'|'volcano'
    current_zone = 'forest'
}

local IMG = {}
local ZONES = {}

local state = lume.clone(DEFAULT_STATE)

---@type table<string, Ability>
local abilities = {
    slash = {damage=3, cooldown=1000}
}

---@type table<string, Item>
local items = {
    basic_armor = {
        before_take_damage = function(e, amt)
            log.info("basic armor reduced damage by 1")
            return amt - 1
        end,
    },
}

---@type table<string, RoomEvent>
local events = {
    medic = {
        prompt = 'A wandering medic would like to heal your injuries. Accept the heal for $5?',
        choices = {'yes', 'no'},
        result_choice = 'yes',
        result_type = 'heal',
        cost = 5,
    }
}

local function randomize_next_event()
    state.next_event = lume.randomchoice(lume.keys(events))
end

local function start_combat()
    state.in_combat = true
    entity.add{class='goblin', group='enemy', abilities={'slash'}, cooldowns={}, items={}, health=6}
    randomize_next_event()
end

local function enter_shop()
    state.shop_items = lume.keys(items)
    randomize_next_event()
end

local function enter_event()
    state.current_event = state.next_event
    local event = events[state.current_event] --[[@as RoomEvent?]]
    assert(event, "event not found")
    log.info(event.prompt)
    randomize_next_event()
end

local function end_event()
    state.current_event = nil
end

---@return Entity
local function get_player()
    for _, e in ipairs(entity.find('group')) do
        if e.group == 'player' then
            return e
        end
    end
    error("player not found")
end

local function generate_room_choices()
    state.next_room_choices = {'combat', 'shop', 'rest', 'event'}
end

---@param e Entity
---@param amt number
local function heal(e, amt)
    e.health = math.min(e.health + 5, const.INITIAL_PLAYER_HEALTH)
end

-- clears the current game and starts a new one
local function start_game()
    local gw, gh = love.graphics.getDimensions()

    entity.remove_all()
    render.reset()
    state = lume.clone(DEFAULT_STATE)

    local player = entity.add{class='warrior', group='player', abilities={'slash'}, cooldowns={}, items={}, health=const.INITIAL_PLAYER_HEALTH}
    local zone_id = 'entity-'..tostring(player._id)
    player.zone_id = zone_id
    zone.set{
        {id=zone_id, image=IMG.forest}
    }
    render.set_collection(zone_id)
    render.add{
        text = 'zone1',
        x = gw / 2,
        y = gh / 2,
    }
    render.set_collection()
    
    start_combat()
end

function love.load()
    IMG.forest = love.graphics.newImage('assets/forest.jpg')
    IMG.space = love.graphics.newImage('assets/space.jpg')
    IMG.volcano = love.graphics.newImage('assets/volcano.jpg')
    IMG.tiny_pixel_hero = love.graphics.newImage('assets/tinypixelhero.jpg')
    IMG.ohmydungeon_v11 = love.graphics.newImage('assets/ohmydungeon_v1.1.png')
    IMG.ohmydungeon_v11:setFilter('linear', 'nearest')

    ZONES.forest = {
        id = ''
    } --[[@as ZonesSetValue]]

    render.load()

    start_game()
end

function love.update(dt)
    render.update(dt)
    zone.update(dt)
    ctrl:update()
    entity.update()

    if ctrl:pressed 'zone_1' then
        zone.set{zones[1]}
    elseif ctrl:pressed 'zone_2' then
        zone.set{zones[1], zones[2]}
    elseif ctrl:pressed 'zone_3' then
        zone.set{zones[1], zones[2], zones[3]}
    elseif ctrl:pressed 'zone_4' then
        zone.set{zones[1], zones[2], zones[3], zones[4]}
    elseif ctrl:pressed 'zone_5' then
        zone.set{zones[1]}
    end

    local combat_entities = entity.find('abilities', 'cooldowns', 'health')
    local no_enemies_left = true

    for _, e in ipairs(combat_entities) do
        -- dead
        if e.health <= 0 then
            if e.group == 'player' then
                log.info("player died")
                -- player died
                if not state.is_game_over then
                    log.info("game over. try again?")
                    state.is_game_over = true
                end
            else
                log.info(e.class, "died")
                entity.remove(e._id)
            end
        else
            if e.group == 'enemy' then
                no_enemies_left = false
            end

            -- use abilities that are off cooldown
            for _, ability_name in ipairs(e.abilities) do
                local ability = abilities[ability_name]
                local cooldown = e.cooldowns[ability_name]

                -- on cooldown?
                if cooldown and cooldown > 0 then
                    e.cooldowns[ability_name] = cooldown - (dt * 1000)
                end

                -- ready to use?
                if not cooldown or cooldown <= 0 then
                    local target --[[@as Entity?]]
                    for _, other in ipairs(combat_entities) do
                        if other._id ~= e._id then
                            target = other
                        end
                    end
                    if target then
                        log.info(e.class, 'used', ability_name, 'on', target.class)

                        local damage = ability.damage

                        -- process items
                        if target.items then
                            for _, item_name in ipairs(target.items) do
                                local item = items[item_name]
                                if item.before_take_damage then
                                    damage = item.before_take_damage(target, damage)
                                end
                            end
                        end

                        -- target takes damage
                        target.health = target.health - damage
                        e.cooldowns[ability_name] = ability.cooldown
                    end
                end
            end
        end
    end

    -- combat over
    if no_enemies_left and state.in_combat then
        log.info("player gained $10")
        state.money = state.money + 10
        state.in_combat = false
        generate_room_choices()
    end
end

function love.draw()
    local gw, gh = love.graphics.getDimensions()
    local font = love.graphics.getFont()

    zone.draw(function (_, zone_id)
        render.set_collection(zone_id)
        render.draw()
    end)

    render.set_collection()
    render.draw()

    -- select the next dungeon room to enter
    if state.next_room_choices then
        local choice = circleui.select('next_room_choice', state.next_room_choices)
        if choice then
            log.info("selected", choice)
            state.next_room_choices = nil
            if choice == 'combat' then
                start_combat()
            end
            if choice == 'shop' then
                enter_shop()
            end
            if choice == 'event' then
                enter_event()
            end
            if choice == 'rest' then
                -- heal and move on to next room
                local player = get_player()
                heal(player, 10)
                generate_room_choices()
            end
        end
    end

    -- player is shopping
    if state.shop_items then
        local choice = circleui.select('shop_items', state.shop_items)
        if choice and items[choice] then
            -- buy item
            log.info("player bought", choice)
            local player = get_player()
            table.insert(player.items, choice)
            lume.remove(state.shop_items, choice)
            -- TODO remove
            -- move on to next room after purchasing
            generate_room_choices()
        end
    end

    -- player is in event
    if state.current_event then
        local event = events[state.current_event] --[[@as RoomEvent?]]
        assert(event, "event not found")
        local choice = circleui.select('event', event.choices)
        if choice then
            local player = get_player()
            if choice == event.result_choice then
                if state.money < (event.cost or 0) then
                    -- can't afford it
                    log.info("You didn't have enough money and decided to leave")
                    end_event()
                    generate_room_choices()
                elseif event.result_type == 'heal' then
                    -- receive a heal
                    log.info("You were healed 5 hp for $"..tostring(event.cost))
                    heal(player, 10)
                    state.money = state.money - event.cost
                    end_event()
                    generate_room_choices()
                end
            else
                log.info("You decided to leave")
                end_event()
                generate_room_choices()
            end
        end
    end

    -- game over
    if state.is_game_over then
        local choice = circleui.select('game_over', {'yes', 'no'})
        if choice == 'yes' then
            start_game()
        else
            love.quit()
        end
    end
end