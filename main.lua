local entity = require 'lib.entity'
local ctrl = require 'lib.controls'
local render = require 'render'
local screens  = require 'screens'
local dialog = require 'dialog'
local plugin = require 'plugin'
local events = require 'events'
local char = require 'character'
local combat = require 'combat'
local shop = require 'shop'
local state = require 'lib.state'
local states = require 'states.index'

render.DEBUG = true

function love.load()
    plugin.add(require 'plugins.basic_events')
    plugin.add(require 'plugins.forest_zone')
    plugin.add(require 'plugins.warrior_class')

    shop.load()
    combat.load()
    plugin.load()
    render.load()

    state.push(states.game)
end

function love.update(dt)
    render.update(dt)
    screens.update(dt)
    ctrl:update()
    entity.update()
    dialog.update(dt)
    combat.update(dt)

    local player = char.get_player()
    if player then
        events.update(dt, player)
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