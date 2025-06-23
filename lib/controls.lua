--[[
call `controls:update()` in love.update
]]
local baton = require 'ext.baton'

return baton.new{
    controls = {
        textui_next_row = {'key:tab'},
        textui_prev_choice = {'key:up'},
        textui_next_choice = {'key:down'},
        textui_select = {'key:space'},
        ui_select = {'key:space','mouse:1'},
        death_return_to_menu = {'key:space'},
    }
}