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
local items = require 'items'
local events = require 'events'
local char = require 'character'
local combat = require 'combat'

-- render.DEBUG = true

local const = {
    INITIAL_PLAYER_HEALTH = 20
}

local DEFAULT_STATE = {
    ---@type string[]?
    shop_items = nil,
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

local function enter_shop()
    ---@type DialogChoice[]
    local choices = {}
    state.shop_items = {}
    for _, item in pairs(items.all()) do
        if not item.shop_disabled then
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
    end
    dialog.add{texts = {{text="Welcome to my store..."}}}
    dialog.add{choices = choices}
end

---@return Entity?
local function get_player()
    for _, e in ipairs(entity.find('group')) do
        if e.group == 'player' then
            return e
        end
    end
    log.error("player not found")
end

local function generate_room_choices()
    dialog.add{
        texts = {{text="Where will you go next?"}},
        choices = {
            {id='event', texts={{text='Enter the mysterious door'}}},
            {id='shop', texts={{text='Approach the nearby shop'}}},
            {id='combat', texts={{text='Enter the ominous door'}}},
        }
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
    state.next_event = events.get_random_event()

    combat.start(zone_id)
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

    plugin.add(require 'plugins.basic')
    plugin.add(require 'plugins.warrior')

    combat.load()
    plugin.load()
    render.load()

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

                    char.add_health(target, -damage)
                    render.remove(id)
                end
            end
        end
    )

    events.signals.on(events.SIGNALS.on_end, function ()
        log.debug "event ended"
        state.next_event = events.get_random_event()
        generate_room_choices()
    end)

    combat.signals.on(combat.SIGNALS.on_end, function ()
        log.debug "combat ended"
        generate_room_choices()
    end)

    start_game()
end

function love.update(dt)
    render.update(dt)
    zones.update(dt)
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

        if player and choice_id and state.shop_items and #state.shop_items > 0 then
            local found_item = false
            for _, id in ipairs(state.shop_items) do
                if choice_id == id and items.get_by_id(id) then
                    found_item = true
                    break
                end
            end
            assert(found_item, "item "..tostring(choice_id).." not found")
            dialog.add{
                max_time = 2000,
                texts={{text=lang.join("You purchased ", choice_id, ".")}}
            }
            table.insert(player.items, {id=choice_id})
        end

        -- select the next dungeon room to enter
        if choice_id == 'combat' then
            combat.start()
        elseif choice_id == 'shop' then
            enter_shop()
        elseif choice_id == 'event' and player then
            events.start_event(state.next_event, player)
        end

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
    zones.draw(function (_, zone_id)
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