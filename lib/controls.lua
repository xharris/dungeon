--[[
call `controls:update()` in love.update
]]
local baton = require 'ext.baton'

return baton.new{
    controls = {
        up = {'key:up'},
        down = {'key:down'},
        left = {'key:left'},
        right = {'key:right'},
        select = {'key:space'},
    }
}