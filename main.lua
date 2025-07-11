local entity = require 'lib.entity'
local ctrl = require 'lib.controls'
local render = require 'render'
local screens  = require 'screens'
local dialog = require 'dialog'
local plugin = require 'plugin'
local combat = require 'combat'
local shop = require 'shop'
local state = require 'lib.state'
local states = require 'states.index'
local color = require 'lib.color'
local char = require 'character'

render.DEBUG = true

function love.load()
    plugin.add(require 'plugins.global_events')
    plugin.add(require 'plugins.forest')
    plugin.add(require 'plugins.warrior_class')

    shop.load()
    combat.load()
    plugin.load()
    render.load()

    love.graphics.setBackgroundColor(color.MUI.WHITE)
    screens.signals.on(screens.SIGNALS.on_change, function ()
        char.arrange()
    end)
    combat.signals.on(combat.SIGNALS.on_start, function ()
        char.arrange()
    end)

    state.push(states.lobby)
end

function love.update(dt)
    render.update(dt)
    screens.update(dt)
    ctrl:update()
    entity.update()
    dialog.update(dt)
    combat.update(dt)
    char.update(dt)

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
    
    state.update(dt)
end

function love.draw()
    screens.draw(function (_, zone_id)
        render.set_collection(zone_id)
        render.draw()
    end)
    render.set_collection()

    render.draw()
    dialog.draw()
end