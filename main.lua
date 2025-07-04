local entity = require 'lib.entity'
local log = require 'lib.log'
local circleui = require 'lib.circleui'
local ctrl = require 'lib.controls'
local lang = require 'lib.i18n'
local lume = require 'ext.lume'
local color = require 'lib.color'
local render = require 'render'
local zones  = require 'zones'
local dialog = require 'dialog'
local plugin = require 'plugin'
local itemlib = require 'item'

-- render.DEBUG = true

lang.set('en', {
    slash = 'Slash',
    basic_armor_title = 'Basic Armor',
    basic_armor_description = 'It does damage',
})

local const = {
    INITIAL_PLAYER_HEALTH = 20
}

local DEFAULT_STATE = {
    ---@type string[]?
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

local state = lume.clone(DEFAULT_STATE)

---@type table<string, RoomEvent>
local events = {
    medic = {
        prompt = 'A wandering medic would like to heal your injuries. Accept the heal for $5?',
        choices = {
            {id='yes', text='Sure'},
            {id='no', text='No thanks'}
        },
        result_choice = 'yes',
        result_type = 'heal',
        cost = 5,
    }
}

local function randomize_next_event()
    state.next_event = lume.randomchoice(lume.keys(events))
end

---@param zone_id? any
local function start_combat(zone_id)
    local gw, gh = love.graphics.getDimensions()
    state.in_combat = true
    
    local enemy = entity.add{
        class='goblin',
        group='enemy',
        cooldowns={},
        items={{id='rusty_sword',data={}}},
        health=6,
        zone_id = zone_id,
        stats = {agi=0, str=3},
    }
    
    if zone_id then
        render.set_collection(zone_id)
    end
    enemy.render_character = render.add{
        tex = IMG.ohmydungeon_v11,
        frames = {{x=48, y=144, w=16, h=16}},
        current_frame = 1,
        x = gw * 2/3, y = gh / 2,
        ox = 8, oy = 8,
        sx = -2, sy = 2,
    }
    render.set_collection()
    
    randomize_next_event()
end

local function enter_shop()
    ---@type DialogChoice[]
    local choices = {}
    state.shop_items = {}
    for _, item in pairs(itemlib.all()) do
        ---@type DialogChoice
        local choice = {
            id = item.id,
            image = IMG.dk_items,
            image_frames = {
                {x=16, y=64, w=16, h=32},
            },
            texts = item.label,
        }
        table.insert(choices, choice)
        table.insert(state.shop_items, item.id)
    end
    dialog.add{texts = {{text="Welcome to my store..."}}}
    dialog.add{choices = choices}
    randomize_next_event()
end

local function enter_event()
    state.current_event = state.next_event
    local event = events[state.current_event] --[[@as RoomEvent?]]
    assert(event, "event not found")

    dialog.add{
        texts = {{text=event.prompt}},
        choices = event.choices,
    }

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
    dialog.add{
        texts = {{text="Where will you go next?"}},
        choices = {
            {id='event', texts={{text='Enter the mysterious door'}}},
            {id='shop', texts={{text='Approach the nearby shop'}}},
            {id='combat', texts={{text='Enter the open door'}}},
        }
    }
end

---@param e Entity
---@param amt number
local function heal(e, amt)
    e.health = math.min(e.health + amt, const.INITIAL_PLAYER_HEALTH)
end

-- clears the current game and starts a new one
local function start_game()
    local gw, gh = love.graphics.getDimensions()

    entity.remove_all()
    render.reset()
    state = lume.clone(DEFAULT_STATE)

    local player = entity.add{
        class='warrior',
        group='player',
        abilities={'slash'},
        cooldowns={},
        items={{id='rusty_sword',data={}}},
        health=const.INITIAL_PLAYER_HEALTH,
        stats = {agi=0, str=5}
    }

    -- add player zone
    local zone_id = 'entity-'..tostring(player._id)
    player.zone_id = zone_id
    zones.set{{id=zone_id, image=IMG.forest}}

    -- add player sprite
    render.set_collection(zone_id)
    player.render_character = render.add{
        tex = IMG.ohmydungeon_v11,
        frames = {{x=0, y=144, w=16, h=16}},
        current_frame = 1,
        x = gw / 3, y = gh / 2,
        ox = 8, oy = 8,
        sx = 2, sy = 2,
    }
    render.set_collection()

    start_combat(zone_id)
end

function love.load()
    IMG.forest = love.graphics.newImage('assets/forest.jpg')
    IMG.space = love.graphics.newImage('assets/space.jpg')
    IMG.volcano = love.graphics.newImage('assets/volcano.jpg')
    IMG.tiny_pixel_hero = love.graphics.newImage('assets/tinypixelhero.jpg')
    IMG.ohmydungeon_v11 = love.graphics.newImage('assets/ohmydungeon_v1.1.png')
    IMG.ohmydungeon_v11:setFilter('linear', 'nearest')
    IMG.dk_items = love.graphics.newImage('assets/( D&K ) Items V.2.png')
    IMG.dk_items:setFilter('linear', 'nearest')

    plugin.add(require 'plugins.warrior')

    plugin.load()
    render.load()
    render.signals.on(render.SIGNALS.easing_done,
        ---@param id any
        ---@param r Renderable
        function (id, r)
            local data = r.data
            if data then
                if data.type == 'attack' then
                    local source = entity.get(data.source)
                    local target = entity.get(data.target)
                    assert(target, 'attack source not found')
                    assert(target, 'attack target not found')

                    local stats = data.stats --[[@as Stats]]
                    for _, data in ipairs(source.items) do
                        local item = itemlib.get_by_id(data.id)
                        if item and item.modify_stats then
                            item.modify_stats(stats)
                        end
                    end

                    local damage = stats.str
                    for _, data in ipairs(target.items) do
                        local item = itemlib.get_by_id(data.id)
                        if item and item.mitigate_damage then
                            damage = item.mitigate_damage(target, damage)
                        end
                    end

                    target.health = target.health - damage
                    render.remove(id)
                end
            end
        end
    )

    start_game()
end

function love.update(dt)
    render.update(dt)
    zones.update(dt)
    ctrl:update()
    entity.update()
    dialog.update(dt)

    -- dialog controls
    if dialog.has_image_choices() then
        if ctrl:pressed 'left' then
            dialog.prev_choice()
        end
        if ctrl:pressed 'right' then
            dialog.next_choice()
        end
    elseif dialog.has_choices() then
        if ctrl:pressed 'up' then
            dialog.prev_choice()
        end
        if ctrl:pressed 'down' then
            dialog.next_choice()
        end
    end

    if ctrl:pressed 'select' then
        ---@type Room|string|nil
        local choice_id = dialog.selected_choice()

        if choice_id and state.shop_items and #state.shop_items > 0 then
            local found_item = false
            for _, id in ipairs(state.shop_items) do
                if choice_id == id and plugin.item_by_id(id) then
                    found_item = true
                    break
                end
            end
            assert(found_item, "item "..tostring(choice_id).." not found")
            dialog.add{
                max_time = 2000,
                texts={{text=lang.join("You purchased ", choice_id, ".")}}
            }
            local player = get_player()
            table.insert(player.items, {id=choice_id})
        end

        -- select the next dungeon room to enter
        if choice_id == 'combat' then
            start_combat()
        elseif choice_id == 'shop' then
            enter_shop()
        elseif choice_id == 'event' then
            enter_event()
        elseif choice_id == 'rest' then
            -- heal and move on to next room
            local player = get_player()
            heal(player, 10)
            generate_room_choices()
        end

        -- event choice
        if state.current_event and events[state.current_event] then
            local event = events[state.current_event] --[[@as RoomEvent]]
            for _, choice in ipairs(event.choices) do
                if event.result_choice == choice.id and choice_id == event.result_choice then
                    if state.money < (event.cost or 0) then
                        -- can't afford it
                        dialog.add{
                            texts={
                                {text="You didn't have enough money and decided to leave"},
                            },
                        }
                    elseif event.result_type == 'heal' then
                        -- receive a heal
                        dialog.add{
                            texts={
                                {text="You were healed 5 hp for $"..tostring(event.cost)},
                            },
                        }
                        local player = get_player()
                        heal(player, 10)
                        state.money = state.money - event.cost
                    end
                else
                    dialog.add{
                        texts={
                            text="You decided to leave",
                        },
                    }
                end
                end_event()
                generate_room_choices()
            end
        end

        dialog.next_dialog()
    end

    local combat_entities = entity.find('abilities', 'cooldowns', 'health')
    local no_enemies_left = true

    for _, e in ipairs(combat_entities) do
        -- dead
        if e.health <= 0 then
            -- remove sprite
            render.remove(e.render_character)
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

    -- combat over
    if no_enemies_left and state.in_combat then
        log.info("player gained $10")
        state.money = state.money + 10
        state.in_combat = false
        generate_room_choices()
    end
end

function love.draw()
    zones.draw(function (_, zone_id)
        render.set_collection(zone_id)
        render.draw()
    end)

    render.set_collection()
    render.draw()
    dialog.draw()

    -- player is shopping
    -- if state.shop_items then
    --     local choice = circleui.select('shop_items', state.shop_items)
    --     if choice and items[choice] then
    --         -- buy item
    --         log.info("player bought", choice)
    --         local player = get_player()
    --         table.insert(player.items, choice)
    --         lume.remove(state.shop_items, choice)
    --         -- TODO remove
    --         -- move on to next room after purchasing
    --         generate_room_choices()
    --     end
    -- end

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