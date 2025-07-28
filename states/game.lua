local M = {}

local events = require 'events'
local log = require 'lib.log'
local combat = require 'combat'
local dungeon = require 'dungeon'
local dialog = require 'dialog'
local entity = require 'lib.entity'
local character = require 'character'
local screens = require 'screens'
local images = require 'lib.images'
local render = require 'render'
local assets = require 'assets.index'
local state = require 'lib.state'
local states = require 'states.index'
local ctrl = require 'lib.controls'
local shop = require 'shop'
local lume = require 'ext.lume'
local items = require 'items'
local signal = require 'lib.signal'
local errors = require 'lib.errors'
local stats  = require 'stats'
local projectiles = require 'projectiles'
local zindex      = require 'zindex'
local animation = require 'lib.animation'
local color = require 'lib.color'
local fonts = require 'lib.fonts'
local const = require 'const'
local game  = require 'game'
local sky = require 'lib.sky'

local max = math.max
local min = math.min

---@type string[]?
local next_zones = nil
local is_game_over = false

---@type fun(room_id:string) string
local enter_room

local function show_rift_choices()
    next_zones = dungeon.get_next_zones()
    ---@type DialogChoice[]
    local choices = {}
    for _, zone in ipairs(next_zones) do
        table.insert(choices, {
            id = zone,
            texts = {{text=zone}},
        } --[[@as DialogChoice]])
    end
    dialog.add{
        texts={{text="A rift has opened"}},
        choices=choices,
    }
end

local function show_room_choices()
    ---@type DialogChoice[]
    local choices = {}
    local next_rooms = dungeon.get_next_rooms()
    local current_room = dungeon.rooms.current()

    local is_current_room_rift = current_room and current_room.rift_room
    local next_room_has_rift = false
    for _, room in ipairs(next_rooms) do
        if room.rift_room then
            next_room_has_rift = true
            break
        end
    end

    -- can move to a new zone
    if is_current_room_rift or next_room_has_rift then
        show_rift_choices()
        return
    end

    -- only one room to go to
    if #next_rooms == 1 then
        enter_room(next_rooms[1].id)
        return
    end
    
    for _, room in ipairs(next_rooms) do
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

---@param entity_id string
---@param change number
---@return string? error
function M.on_change_health(entity_id, change)
    local e = entity.get(entity_id)
    if not e then
        return errors.not_found('entity', entity_id)
    end
    local x, y = e.x, e.y

    -- show text animation
    ---@type Font
    local font = {path=assets.yoster_island, size=20}
    local tw, th = fonts.dimensions(change, font)
    local r_id, text_render = render.add{
        tag = 'health-changed-text',
        x = x, y = y,
        ox = tw / 2, oy = th / 2,
        sx = 0.85, sy = 0.85,
        font = font,
        text = change,
        text_shadow_color = color.MUI.RED_500,
        color = color.MUI.WHITE,
        z = zindex.character_health_changed,
    }
    local duration = 500
    local e = entity.add{
        tag = 'health-changed-text',
        text = text_render,
        color = color.MUI.RED_500,
        x = x,
        y = y,
        -- gravity = 900,
        render_text = r_id,
    }
    e.vx, e.vy = lume.vector(
        lume.lerp(math.rad(-90-45), math.rad(-45), math.random()),
        200
    )
    animation
        .create(text_render.id, text_render)
        .add(
            {to={sx=1, sy=1}, duration=duration*0.9},
            {to={opacity=0}, duration=duration*0.1}
        )
        .on_end(function ()
            render.remove(text_render.id)
        end)
        .start()
    animation
        .create(e._id, e)
        .add(
            {to={vx=0, vy=0}, duration=duration*0.8}
        )
        .on_end(function ()
            entity.remove(e._id)
        end)
        .start()
end

---@param data CombatUseItemData?
local function on_projectile_reached_target(data)
    if data then
        combat.process_attack(data)
    end
end

enter_room = function(room_id)
    local player = character.get_player()
    local room
    if player then
        room = dungeon.move_to_room(room_id, player)
    end
    local room_type = room and dungeon.rooms.get_type(room.id)
    local current_zone = dungeon.current_zone()

    if player and room and room_type then
        if room_type == 'rift' then
            next_zones = dungeon.get_next_zones()
            ---@type DialogChoice[]
            local choices = {}
            for _, zone in ipairs(next_zones) do
                table.insert(choices, {
                    id = zone,
                    texts = {{text=zone}},
                } --[[@as DialogChoice]])
            end
            dialog.add{
                texts={{text="A rift has opened"}},
                choices=choices,
            }
        elseif room_type == 'combat' then
            combat.start(current_zone, nil, player.screen_id)
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

local function on_combat_end()
    for _, e in entity.all() do
        if e.character_sprite then
            character.sprite.hands(e._id)
        end
    end
    show_room_choices()
end

return {

    enter = function ()
        next_zones = nil
        is_game_over = false
        
        sky.add()

        for _, e in entity.all() do
            if e.group ~= 'player' then
                entity.remove(e._id)
            end
        end

        events.signals.on(events.SIGNALS.on_end, show_room_choices)
        combat.signals.on(combat.SIGNALS.ended, on_combat_end)
        dungeon.signals.on(dungeon.SIGNALS.enter_zone, show_room_choices)
        character.signals.on(character.SIGNALS.change_health, M.on_change_health)
        projectiles.signals.on(projectiles.SIGNALS.reached_target, on_projectile_reached_target)

        -- start game
        local player = character.get_player()
        if not player then
            log.error("player entity not created")
            state.pop()
            state.push(states.pick_starter_weapon)
            return
        end

        -- enter a zone
        next_zones = dungeon.get_next_zones()
        local rand_zone = lume.randomchoice(next_zones)
        dungeon.enter_zone(rand_zone, player)
        screens.set{{id=player.screen_id, image=dungeon.get_background_image()}}
    end,

    leave = function ()
        signal.off(show_room_choices, M.on_change_health, on_projectile_reached_target)
    end,
    
    update = function (dt)
        local player = character.get_player()

        if player then
            events.update(dt, player)
        end
        
        if ctrl:pressed 'select' then
            ---@type Room|string|nil
            local choice_id = dialog.selected_choice()

            if choice_id then
                log.debug('selected choice:', choice_id)
            end

            if choice_id == "restart_game" then
                state.pop()
                state.push(states.pick_starter_weapon)
            end

            if choice_id == "quit_game" then
                love.quit()
            end

            -- buy an item and leave the shop
            if player and choice_id and shop.buy_item(player, choice_id) then
                shop.leave()
            end

            -- select next zone
            if player and choice_id and next_zones and lume.find(next_zones, choice_id) then
                dungeon.enter_zone(choice_id, player)
                next_zones = nil
                screens.get(player.screen_id).image = dungeon.get_background_image()
            end

            -- select the next dungeon room to enter
            if choice_id and dungeon.rooms.id(choice_id) then
                enter_room(choice_id)
            end
        end

        -- player died
        if player and player.health.current <= 0 and not is_game_over then
            log.info("player died")
            is_game_over = true

            -- game over
            if is_game_over then
                dialog.add{
                    texts={{text="You died"}},
                    choices={
                        {id="restart_game",texts={{text="restart"}}},
                        {id="quit_game",texts={{text="quit"}}},
                    }
                }
            end
        end
    end,

    pre_draw = function ()
        love.graphics.push('all')
        -- draw sky
        sky.draw()
        -- draw floor
        if const.FLOOR.VISIBLE then
            color.set(color.MUI.BROWN_900)
            love.graphics.rectangle('fill', 0, const.FLOOR.Y, game.width, game.height)
        end
        love.graphics.pop()
    end

} --[[@as State]]