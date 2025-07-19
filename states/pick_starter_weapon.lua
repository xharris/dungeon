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

local lerp = lume.lerp

---@class StarterItem
---@field item Item
---@field r_weapon string
---@field x number
---@field y number
---@field scale number
---@field sx number
---@field sy number
---@field shadow_offset number

local RECT_SIZE = 32
local SEP_SCALE = 0.6

local SCALE = 1
local SELECTED_SCALE = 2

local SHADOW_OFFSET = 0
local SELECTED_SHADOW_OFFSET = 10

---@type StarterItem[]
local starting_items = {}

local selected_index = 1

local x_offset = {
    current = 0,
    target = 0,
}

local t = 0
local ease_duration = 1000

return {

    enter = function ()
        entity.remove_all()
        render.reset()

        -- create player
        character.create()
        
        local starters = items.get_all_starters()
        starting_items = {}
        for _, item in ipairs(starters) do
            local r = images.renderable(item.image)
            r.sx = r.sx * SCALE
            r.sy = r.sy * SCALE
            table.insert(starting_items, {
                item = item,
                x = 0,
                y = 0,
                sx = r.sx,
                sy = r.sy,
                scale = SCALE,
                shadow_offset = SHADOW_OFFSET,
                r_weapon = render.add(r),
            } --[[@as StarterItem]])
        end
        log.warn_if(#starting_items == 0, "no starting items added")
    end,

    update = function (dt)
        local player = character.get_player()
        if not player then
            return
        end
        if t < ease_duration then
            t = t + (dt * 1000)
        end
        local gw, gh = love.graphics.getDimensions()
        local sep = gw * SEP_SCALE

        -- animate offset
        local selected_index0 = selected_index - 1
        x_offset.target = -(selected_index0 * (RECT_SIZE + sep))
        x_offset.current = lerp(x_offset.current, x_offset.target, t / ease_duration)

        for i, item in ipairs(starting_items) do
            local i0 = i - 1
            item.x = gw/2 + (i0 * (RECT_SIZE + sep))
            item.y = gh/2

            local r = render.get(item.r_weapon)
            if r then
                r.x = item.x + x_offset.current
                r.y = item.y
                local target_scale = i == selected_index and SELECTED_SCALE or SCALE
                item.scale = lerp(item.scale, target_scale, easing.ease_in_out_sine(t / ease_duration))
                r.sx = item.sx * item.scale
                r.sy = item.sy * item.scale
            end
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
        local gw, gh = love.graphics.getDimensions()
        for i, item in ipairs(starting_items) do
            love.graphics.push('all')
            love.graphics.translate(item.x + x_offset.current, item.y)
            local size = RECT_SIZE * item.scale
            local pos = -size / 2
            item.shadow_offset = lerp(
                item.shadow_offset,
                selected_index == i and SELECTED_SHADOW_OFFSET or SHADOW_OFFSET,
                easing.ease_in_out_sine(t / ease_duration)
            )
            -- draw box shadow
            color.set(color.MUI.GREY_900, 0.5)
            love.graphics.rectangle('fill', pos + item.shadow_offset, pos + item.shadow_offset, size, size)
            -- draw box
            color.set(color.MUI.GREY_900)
            love.graphics.rectangle('fill', pos, pos, size, size)
            love.graphics.pop()
        end
        local selected_item = selected_index and starting_items[selected_index]
        if selected_item then
            love.graphics.push('all')
            color.set(color.MUI.GREY_900)
            local w = gw / 3
            printc.draw(selected_item.item.label, (gw/2) - (w/2), 20, w)
            love.graphics.pop()
        end
    end,

    leave = function ()
        for _, item in ipairs(starting_items) do
            render.remove(item.r_weapon)
        end
        starting_items = {}
    end
    
} --[[@as State]]