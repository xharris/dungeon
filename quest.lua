local M = {}

local datastore = require "lib.datastore"

---@class Quest
---@field id string

---@class QuestData
---@field id string
---@field status 'accepted'|'rejected'|'completed'|'failed'

local storage = datastore.create{
    id = '',
} --[[@as Datastore<Quest>]]

local entity_storage = datastore.create{
    id = '',
    status = 'accepted',
} --[[@as Datastore<QuestData>]]

---@param t Quest
function M.add(t)
    local data = storage(t.id)
    
end

---@param id string
function M.get(id)
    return storage(id)
end

function M.accept(entity_id, quest_id)
    local data = entity_storage(entity_id)
    data.id = quest_id
    data.status = 'accepted'
end

function M.reject(entity_id, quest_id)
    local data = entity_storage(entity_id)
    data.id = quest_id
    data.status = 'accepted'
end

return M