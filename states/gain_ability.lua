local entity = require 'lib.entity'
local log    = require 'lib.log'
local state = require 'lib.state'
local color = require 'lib.color'
local items = require 'items'

---@type Ability[]
local abilities = {}

return {

    ---@param entity_id string
    enter = function (entity_id)
        -- check args
        local e = entity.get(entity_id)
        if not e then
            log.warn('(gain_ability.enter) could not find entity:', entity_id)
            state.pop()
        end
        abilities = items.ability.random(3, 0)
    end,
    
    draw = function ()
        local gw, gh = love.graphics.getDimensions()
        color.set(color.MUI.BLACK, 0.75)
        love.graphics.rectangle('fill', 0, 0, gw, gh)
        -- TODO draw ability choices
    end

} --[[@as State]]