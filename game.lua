local M = {}

M.dt = 0
M.width = 0
M.height = 0

function M.update(dt)
    M.dt = M.dt + dt
end

function M.load()
    M.width, M.height = love.graphics.getWidth(), love.graphics.getHeight()
end

return M