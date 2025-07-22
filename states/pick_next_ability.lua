local entity = require 'lib.entity'
local log    = require 'lib.log'
local state = require 'lib.state'
local color = require 'lib.color'
local items = require 'items'
local printc= require 'lib.printc'
local theme = require 'theme'
local errors= require 'lib.errors'
local ctrl = require 'lib.controls'
local character = require 'character'
local states = require 'states.index'

---@class NextAbility
---@field id string
---@field label PrintcText[]
---@field border_color Color
---@field x number
---@field y number
---@field t number
---@field w number
---@field h number
---@field ox number
---@field oy number

---@type NextAbility[]
local next_abilities = {}

local selected_index = 1

return {

    ---@param entity_id string
    enter = function (entity_id)
        -- check args
        local abilities = items.abilities.random(3, 0, entity_id)
        if #abilities == 0 then
            log.error('no abilities to pick')
            state.pop()
        end
        next_abilities = {}
        selected_index = 1

        -- add to next ability
        local y = 0
        local gw, gh = love.graphics.getDimensions()
        for _, id in ipairs(abilities) do
            local a = items.abilities.get(id)
            if a then
                local _, h = printc.dimensions(a.label or {{text=a.id}})
                ---@type NextAbility
                local next_ability = {
                    id = a.id,
                    label = a.label,
                    border_color = theme.color.dialog_selected_outline,
                    x = 0,
                    y = y,
                    t = 0,
                    w = gw,
                    h = h,
                    ox = 0,
                    oy = 0,
                }
                y = y + h
                table.insert(next_abilities, next_ability)
            end
        end
    end,

    update = function (dt)
        if ctrl:pressed 'down' then
            selected_index = selected_index + 1
        end
        if ctrl:pressed 'up' then
            selected_index = selected_index - 1
        end
        if ctrl:pressed 'select' then
            local id = next_abilities[selected_index].id
            local ability = items.abilities.get(id)
            local player = character.get_player()
            log.error_if(not ability, errors.not_found('ability', id))
            log.error_if(not player, errors.not_found('player'))
            if ability and player then
                character.add_item_to_inventory(player._id, {id=ability.id})
                state.pop()
                state.push(states.game)
            else
                -- TODO restart game?
            end
        end

        for i, a in ipairs(next_abilities) do
            local is_selected = i == selected_index
            a.border_color = color.alpha(theme.color.dialog_selected_outline, is_selected and 1 or 0)
        end
    end,

    draw = function ()
        local gw, gh = love.graphics.getDimensions()
        color.set(color.MUI.BLACK, 0.75)
        love.graphics.rectangle('fill', 0, 0, gw, gh)
        local y = 0
        -- draw ability choices
        for i, a in ipairs(next_abilities) do
            love.graphics.push('all')
            -- border
            color.set(a.border_color)
            love.graphics.rectangle('line', a.x, a.y, a.w, a.h)
            -- text
            color.set(theme.color.dialog_text)
            printc.draw(a.label, a.x, a.y)
            love.graphics.pop()
        end
    end

} --[[@as State]]