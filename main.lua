local entity = require 'lib.entity'
local log = require 'lib.log'
local circleui = require 'lib.circleui'
local ctrl = require 'lib.controls'
local lang = require 'lib.i18n'
local lume = require 'ext.lume'
local color = require 'lib.color'
local render = require 'render'
local screens  = require 'screens'
local dialog = require 'dialog'
local plugin = require 'plugin'
local items = require 'items'
local events = require 'events'
local char = require 'character'
local combat = require 'combat'
local shop = require 'shop'
local dungeon = require 'dungeon'
local assets = require 'assets.index'
local images = require 'lib.images'

render.DEBUG = true

local const = {
    INITIAL_PLAYER_HEALTH = 100
}

local DEFAULT_STATE = {
    ---@type string?
    next_event = nil,
    is_game_over = false,
}

local state = lume.clone(DEFAULT_STATE)

---@return Entity?
local function get_player()
    for _, e in ipairs(entity.find('group')) do
        if e.group == 'player' then
            return e
        end
    end
    log.error("player not found")
end

local function show_room_choices()
    ---@type DialogChoice[]
    local choices = {}
    log.debug(dungeon.get_next_rooms())
    for _, room in ipairs(dungeon.get_next_rooms()) do
        local room_type = dungeon.rooms.get_type(room.id)
        if room_type then
            ---@type DialogChoice
            local choice = {
                id=room.id,
                texts={{text=room_type}}
            }
            table.insert(choices, choice)
        end
    end
    dialog.add{
        texts = {{text="Where will you go next?"}},
        choices = choices
    }
end

-- clears the current game and starts a new one
local function start_game()
    local gw, gh = love.graphics.getDimensions()

    entity.remove_all()
    render.reset()
    state = lume.clone(DEFAULT_STATE)

    local player = entity.add{
        group='player',
        name='Player',
        items={{id='rusty_sword',data={}}},
        health={
            current = const.INITIAL_PLAYER_HEALTH,
            max = const.INITIAL_PLAYER_HEALTH,
        },
        stats = {agi=0, str=5}
    }

    -- add player zone
    local screen_id = 'entity-'..tostring(player._id)
    player.screen_id = screen_id

    -- enter a zone
    local next_zones = dungeon.get_next_zones()
    local rand_zone = lume.randomchoice(next_zones)
    dungeon.enter_zone(rand_zone, player)
    screens.set{{id=screen_id, image=dungeon.get_background_image()}}

    -- add player sprite
    render.set_collection(screen_id)
    player.render_character = render.add{
        tex = images.get{
            path = assets.ohmydungeon_v11,
        },
        frames = {{x=0, y=144, w=16, h=16}},
        current_frame = 1,
        x = gw / 3, y = gh / 2,
        ox = 8, oy = 8,
        sx = 2, sy = 2,
    }
    render.set_collection()
    state.next_event = events.get_random_event()

    combat.start(screen_id)
end

function love.load()
    plugin.add(require 'plugins.basic_events')
    plugin.add(require 'plugins.forest_zone')
    plugin.add(require 'plugins.warrior_class')

    shop.load()
    combat.load()
    plugin.load()
    render.load()

    events.signals.on(events.SIGNALS.on_end, function ()
        log.debug "event ended"
        state.next_event = events.get_random_event()
        show_room_choices()
    end)

    combat.signals.on(combat.SIGNALS.on_end, function ()
        log.debug "combat ended"
        show_room_choices()
    end)

    start_game()
end

function love.update(dt)
    render.update(dt)
    screens.update(dt)
    ctrl:update()
    entity.update()
    dialog.update(dt)
    combat.update(dt)
    

    local player = get_player()
    if player then
        events.update(dt, player)
    end

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

        if choice_id then
            log.debug('selected choice:', choice_id)
        end

        if player and choice_id and shop.buy_item(player, choice_id) then
            shop.leave()
        end

        -- select the next dungeon room to enter
        if choice_id and dungeon.rooms.get_by_id(choice_id) then
            local room = dungeon.move_to_room(choice_id)
            local room_type = room and dungeon.rooms.get_type(room.id)
            if room and room_type then
                log.info("move to room:", room.id, ", type:", room_type)

                if room_type == 'combat' then
                    combat.start()
                elseif room_type == 'shop' then
                    shop.enter()
                elseif room_type == 'event' and player then
                    local zone = dungeon.current_zone()
                    assert(zone, "could not get current zone")
                    local event = events.get_random_event(zone.id)
                    assert(event, "could not pick random event in current zone")
                    events.start_event(event, player)
                end
            end
        end

        -- if room == 'combat' then
        --     combat.start()
        -- elseif room == 'shop' then
        --     shop.enter()
        -- elseif room == 'event' and player then
        --     local zone = dungeon.current_zone()
        --     assert(zone, "could not get current zone")
        --     local event = events.get_random_event(zone.id)
        --     assert(event, "could not pick random event in current zone")
        --     events.start_event(event, player)
        -- end

        dialog.next_dialog()
    end

    -- player died
    if player and player.health.current <= 0 and not state.is_game_over then
        log.info("player died")
        render.remove(player.render_character)
        state.is_game_over = true
    end
end

function love.draw()
    screens.draw(function (_, zone_id)
        render.set_collection(zone_id)
        render.draw()
    end)

    render.set_collection()
    render.draw()
    dialog.draw()

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