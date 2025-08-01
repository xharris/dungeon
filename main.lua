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
local items= require 'items'
local dungeon = require 'dungeon'
local log     = require 'lib.log'
local const   = require 'const'
local animation = require 'lib.animation'
local projectiles = require 'projectiles'
local game        = require 'game'
local fonts = require 'lib.fonts'
local assets= require 'assets.index'
local timer = require 'lib.timer'
local cornermenu = require 'cornermenu'
local stage = require 'lib.stage'
local easing= require 'lib.easing'

---@diagnostic disable-next-line: deprecated
table.unpack = unpack

log.LOG_METHODS_LEVEL = const.LOG.METHODS_LEVEL
log.LOG_CONSOLE_LEVEL = const.LOG.CONSOLE_LEVEL
log.LOG_ERROR_ROWS = const.LOG.ERROR_ROWS
log.LOG_HEADER = const.LOG.HEADER

render.DEBUG = const.DEBUG_RENDER.ENABLED
render.DEBUG_SHOW_ID = const.DEBUG_RENDER.SHOW_ID
projectiles.DEBUG = const.DEBUG_PROJECTILES
projectiles.DURATION = const.PROJECTILE_DURATION
fonts.FONT_SIZE = const.FONT_SIZE
combat.BASE_ATTACK_DURATION = const.COMBAT.BASE_ATTACK_DURATION

stage.EASE_DURATION = const.STAGE.EASE_DURATION
stage.EASE_FN = const.STAGE.EASE_FN

stage.SKY.SEGMENTS = const.SKY.SEGMENTS

stage.FLOOR.VISIBLE = const.FLOOR.VISIBLE
stage.FLOOR.Y = const.FLOOR.Y

cornermenu.DEFAULT_FONT = {
    path = assets.yoster_island,
    size = 20,
}

function love.load()
    game.load()
    fonts.set{path=assets.yoster_island}

    plugin.add(require 'plugins.global_events')
    plugin.add(require 'plugins.classes')
    plugin.add(require 'plugins.forest')

    items.load()
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
    dungeon.signals.on(dungeon.SIGNALS.enter_room,
    ---@param _ DungeonRoom
    ---@param entity Entity
    function (_, entity)
        items.abilities.reduce_gain_ability_cooldown(entity._id)
    end)
    items.signals.on(items.SIGNALS.gain_ability_ready,
    ---@param entity_id string
    function (entity_id)
        items.abilities.show_ability_gain_screen(entity_id)
    end)

    state.push(states.title)
end

function love.update(dt)
    game.update(dt)
    render.update(dt)
    screens.update(dt)
    ctrl:update()
    entity.update()
    dialog.update(dt)
    combat.update(dt)
    char.update(dt)
    animation.update(dt)
    projectiles.update(dt)
    stage.update(dt)
    timer.update(dt)
    cornermenu.update(dt)

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
    
    if ctrl:pressed 'select' then
        dialog.next_dialog()
    end
end

function love.draw()
    -- game
    state.pre_draw()
    stage.draw()
    render.draw()
    state.draw()
    -- debug
    animation.draw()
    projectiles.debug_draw()
    -- ui
    dialog.draw()
    cornermenu.draw()
end

function love.quit()
    local err = log.write_to_file('logs.txt', const.LOG.WRITE_APPEND)
    if err then print('could not write logs:', err) end
end

local function error_printer(msg, layer)
    return (debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", ""))
end

local old_errorhandler = love.errorhandler or love.errhand

function love.errorhandler(msg)
    log.add_line(error_printer(msg, 2))
    local err = log.write_to_file('logs.txt', const.LOG.WRITE_APPEND)
    if err then print('could not write logs:', err) end
    return old_errorhandler(msg)
end

love = log.log_methods('love', love, {
    include={'load', 'quit'}
})
love.event = log.log_methods('love.event', love.event, {
    include={'quit'}
})