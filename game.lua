local M = {}

M.dt = 0
M.width = 0
M.height = 0
M.mouse_x = 0
M.mouse_y = 0

function M.update(dt)
    M.mouse_x, M.mouse_y = love.mouse.getPosition()
    M.dt = M.dt + dt
end

function M.load()
    M.width, M.height = love.graphics.getWidth(), love.graphics.getHeight()
    M.mouse_x, M.mouse_y = love.mouse.getPosition()
end

return M