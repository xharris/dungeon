local dialog = require 'dialog'
local items = require 'items'
local ctrl = require 'lib.controls'
local character = require 'character'
local state = require 'lib.state'
local states = require 'states.index'
local entity = require 'lib.entity'
local const = require 'const'
local render = require 'render'
local log = require 'lib.log'
local images = require 'lib.images'
local color = require 'lib.color'
local assets = require 'assets.index'
local lume = require 'ext.lume'
local easing = require 'lib.easing'
local printc = require 'lib.printc'
local errors = require 'lib.errors'
local lang = require 'lib.i18n'
local game = require 'game'

local lerp = lume.lerp

---@class StarterItem
---@field renderables {root:string,square:string,weapon:string}
---@field item Item

local RECT_SIZE = 32

---@type StarterItem[]
local starting_items = {}

local selected_index = 1

return {

    enter = function ()
        entity.remove_all()
        render.reset()

        -- create player
        character.create()
        
        local starters = items.starters.all()
        starting_items = {}
        for _, item in ipairs(starters) do
            local root = render.add{
                tag='starting_item',
                x=game.width/2, y=game.height/2,
                sx = 2, sy = 2,
            }
            local starter = {
                renderables = {
                    root = root,
                    square = render.add{
                        tag = 'square',
                        parent = root,
                        rect = {mode='fill', w=RECT_SIZE, h=RECT_SIZE},
                        color = color.MUI.GREY_900,
                        opacity = 0.5,
                        ox = RECT_SIZE/2,
                        oy = RECT_SIZE/2,
                    },
                    weapon = render.add(images.renderable(item.image, {
                        tag = 'weapon',
                        parent = root,
                    })),
                },
                item = item,
            } --[[@as StarterItem]]

            table.insert(starting_items, starter)
        end
        log.warn_if(#starting_items == 0, "no starting items added")
    end,

    update = function (dt)
        local player = character.get_player()
        if not player then
            return
        end

        if ctrl:pressed 'right' then
            t = 0
            selected_index = selected_index + 1
            if selected_index > #starting_items then
                selected_index = 1
            end
        end

        if ctrl:pressed 'left' then
            t = 0
            selected_index = selected_index - 1
            if selected_index <= 0 then
                selected_index = #starting_items
            end
        end

        local selected = starting_items[selected_index]
        if ctrl:pressed 'select' then
            local item = items.get(selected.item.id)
            if not log.error_if(not item, errors.not_found('starting_item', selected.item.id)) then
                local idx = character.add_item_to_inventory(player._id, {id=selected.item.id})
                character.equip_item(player._id, idx)
                state.pop()
                state.push(states.game)
            end
        end
    end,

    pre_draw = function ()
        ---@type number, number
        local gw = game.width
        local selected_item = selected_index and starting_items[selected_index]
        if selected_item then
            love.graphics.push('all')
            color.set(color.MUI.GREY_900)
            local w = gw / 3
            printc.draw(items.label(selected_item.item.id), (gw/2) - (w/2), 20, w)
            love.graphics.pop()
        end
    end,

    leave = function ()
        for _, item in ipairs(starting_items) do
            for _, r in pairs(item.renderables) do
                render.remove(r)
            end
        end
        starting_items = {}
    end
    
} --[[@as State]]