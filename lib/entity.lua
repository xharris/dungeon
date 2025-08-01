local M = {}

local lume = require 'ext.lume'
local log  = require 'lib.log'
local util = require 'lib.util'

---@type Entity[]
local entities = {}

---@type table<number, Entity>
local entity_map = {}

---@type table<string, boolean>
local deleted = {}

local id = 0

---@param e Entity
function M.add(e)
    id = id + 1
    e.tag = e.tag or 'entity'
    e._id = e.tag..':'..tostring(id)
    table.insert(entities, e)
    entity_map[e._id] = e
    return e
end

---@param id string
---@return Entity?
function M.get(id)
    return entity_map[id]
end

function M.all()
    return util.iterator({
        ---@param i number
        ---@param v Entity
        filter = function (i, v)
            return not deleted[v._id]
        end
    }, entities)
end

---@param ... string
---@return Iterator<Entity>
function M.filter(...)
    local components = {...}
    return util.iterator({
        ---@param i number
        ---@param v Entity
        filter = function (i, v)
            for c = 1, #components do
                if v[components[c]] == nil then
                    return false
                end
            end
            return true
        end
    }, entities)
end

---@param entity_id string
function M.remove(entity_id)
    deleted[entity_id] = true
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

return log.log_methods('entity', M, {
    exclude={'update', 'all', 'filter', 'get'}
})