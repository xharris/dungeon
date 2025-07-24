local M = {}

M.dt = 0

function M.update(dt)
    M.dt = M.dt + dt
end

return M