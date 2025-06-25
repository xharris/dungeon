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
        zone_1 = {'key:1'},
        zone_2 = {'key:2'},
        zone_3 = {'key:3'},
        zone_4 = {'key:4'},
        zone_5 = {'key:5'},
    }
}