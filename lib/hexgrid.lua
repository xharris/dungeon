local M = {}
local lume = require 'ext.lume'

function M.local_position(size, x, y)
    local px, py = x + (y * 0.5), y * 0.5
    local lower_limit = math.ceil(size / 2)
    if (x <= lower_limit - y) or (size - x < lower_limit - (size - y) - 1) then
        -- return nil, nil
    end
    return px, py
end

function M.create(size, cell_size)
    local cells = {}
    local lower_limit = math.ceil(size / 2)
    local ids = {}

    -- add cells
    for y = 1, size do
        for x = 1, size do
            local px, py = M.local_position(size, x, y)
            if px ~= nil then
                local index_x, index_y = x - lower_limit, y - lower_limit
                local id = index_x..','..index_y
                ids[id] = true
                table.insert(cells, {
                    id = id,
                    index_x = index_x,
                    index_y = index_y,
                    position_x = px * cell_size,
                    position_y = py * 1.75 * cell_size,
                })
            end
        end
    end

    -- add neighbors
    for _, cell in ipairs(cells) do
        cell.neighbors = {}
        for x = -1, 1 do
            for y = -1, 1 do
                local id = (cell.index_x+x)..','..(cell.index_y+y)
                if ids[id] and x ~= y then
                    table.insert(cell.neighbors, id)
                end
            end
        end
    end

    return cells
end

function M.cell_at_position(grid, cell_size, x, y)
    for _, cell in ipairs(grid) do
        if lume.distance(x, y, cell.position_x, cell.position_y) <= cell_size / 1.75 then
            return cell
        end
    end
end

return M