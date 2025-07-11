local dialog = require 'dialog'
local items = require 'items'
local ctrl = require 'lib.controls'
local char = require 'character'
local state = require 'lib.state'
local states = require 'states.index'
local entity = require 'lib.entity'
local const = require 'const'
local render = require 'render'
local log = require 'lib.log'

local show_starting_items = false

return {

    enter = function ()
        show_starting_items = false
        entity.remove_all()
        render.reset()

        -- create player
        char.create{
            max_jumps = 2,
            floor_behavior = 'bounce'
        }
        char.create{
            group = 'ally',
            name = 'some kid'
        }

        -- get starting items
        ---@type DialogChoice[]
        local choices = {}
        local starters = items.get_all_starters()
        for _, item in ipairs(starters) do
            table.insert(choices, {
                id = item.id,
                image = item.image,
                texts = item.label,
            } --[[@as DialogChoice]])
        end
        log.warn_if(#starters == 0, "no starting items added")
        dialog.add{
            texts={{text="Pick your starting weapon"}},
            choices=choices,
        }
        show_starting_items = true
    end,

    update = function (dt)
        local player = char.get_player()

        if ctrl:pressed 'select' then
            local choice_id = dialog.selected_choice()
            if player and show_starting_items then
                local item = items.get_by_id(choice_id)
                if item then
                    char.add_item(player, {id=item.id})
                    state.pop()
                    state.push(states.game)
                end
            end
            if choice_id then
                dialog.next_dialog()
            end
        end
    end
    
} --[[@as State]]