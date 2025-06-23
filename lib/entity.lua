local M = {}

local lume = require 'ext.lume'

---@type Entity[]
local entities = {}

---@type table<string, boolean>
local deleted = {}

local id = 0

---@param e Entity
function M.add(e)
    id = id + 1
    e._id = id
    table.insert(entities, e)
end

function M.all()
    return entities
end

---@param ... string
function M.find(...)
    local components = {...}
    ---@type Entity[]
    local found = {}
    for _, e in ipairs(entities) do
        for _, c in ipairs(components) do
            if e[c] == nil then
                break
            end
        end
        table.insert(found, e)
    end
    return found
end

---@param id number
function M.remove(id)
    deleted[id] = true
end

function M.remove_all()
    entities = {}
    deleted = {}
    id = 0
end

function M.update()
    for i, e in lume.ripairs(entities) do
        if deleted[e._id] then
            table.remove(entities, i)
        end
    end
    deleted = {}
end

return M