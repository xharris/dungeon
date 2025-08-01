local M = {}

local game = require "game"
local color= require "lib.color"
local fonts= require "lib.fonts"
local assets = require 'assets.index'
local cornermenu = require 'cornermenu'
local log = require 'lib.log'
local signal = require 'lib.signal'
local states = require 'states.index'
local state = require 'lib.state'
local character = require 'character'
local stage = require 'lib.stage'
local dungeon = require 'dungeon'
local lume = require 'ext.lume'
local entity = require 'lib.entity'
local render = require 'render'

---@type Font
local title_font = {
    path = assets.yoster_island,
    size = 48
}

---@param id string
function M.on_select_item(id)
    if id == 'start_solo' then
        state.pop().push(states.game)
        cornermenu.clear()
    end
    if id == 'main_menu' then
        M.main_menu()
    end
    if id == 'settings' then
        cornermenu.set(
            'settings',
            {
                id='change_character',
                texts={{text="Change Character"}},
            },
            {
                id='main_menu',
                texts={{text='<'}},
            }
        )
    end
    if id == "quit_game" then
        love.event.quit()
    end
end

function M.main_menu()
    cornermenu.set(
        'main_menu',
        {
            id='start_solo',
            texts={{text="Solo Run"}},
        },
        {
            id='settings',
            texts={{text="Settings"}},
        },
        {
            id='help',
            texts={{text="Help"}},
        },
        {
            id='quit_game',
            texts={{text="Quit"}}
        }
    )
end

log.log_methods('states.title', M)

return {

    leave = function ()
        signal.offt(M)
    end,

    enter = function ()
        render.reset()
        entity.remove_all()

        cornermenu.signals.on(cornermenu.SIGNALS.select_item, M.on_select_item)

        M.main_menu()

        -- clear all characters
        -- for _, e in entity.all() do
        --     if character.is(e._id) then
        --         entity.remove(e._id)
        --     end
        -- end

        -- create player
        local player = character.get_player()
        if player then
            entity.remove(player._id)
        else
            player = character.create()
        end

        -- enter a zone
        local next_zones = dungeon.get_next_zones()
        local rand_zone = lume.randomchoice(next_zones)
        dungeon.enter_zone(rand_zone, player)
    end,

    draw = function ()
        love.graphics.push('all')
        color.set(color.MUI.BLACK)
        fonts.set(title_font)
        local _, h = fonts.dimensions('GAME TITLE', title_font)
        love.graphics.printf('GAME TITLE', 0, (game.height - h)/5, game.width, 'center')
        love.graphics.pop()
    end
} --[[@as State]]