local M = {}

local lume = require 'ext.lume'
local log = require 'lib.log'
local images = require 'lib.images'
local screens = require 'screens'

---@alias DungeonRoomType 'combat'|'shop'|'rest'|'event'

---@class DungeonRoom
---@field id string
---@field doors? string[] list of room ids
---@field types? DungeonRoomType[] choose a room type from the list
---@field combat_enemy_types? CombatEnemyType[]
---@field _type? DungeonRoomType
---@field spawn_room? boolean allow player to spawn in this room
---@field rift_room? boolean allow player to riftwalk in this room
---@field background_image? Image

---@class DungeonSetupRoomsCtx
---@field add_room fun(room:DungeonRoom)

---@class DungeonZone
---@field id string
---@field enemies string[] list of enemy ids that can spawn
---@field setup_rooms fun(ctx:DungeonSetupRoomsCtx, e:Entity)
---@field default_background_image? Image

---@type table<string, DungeonRoom>
local zone_rooms = {}

---@type DungeonZone?
local current_zone

---@type DungeonRoom?
local current_room

---@type table<string, DungeonZone>
local zones = {}

M.rooms = {}

---@return DungeonRoom?
function M.rooms.get_by_id(id)
    return zone_rooms[id]
end

---@return DungeonRoom?
function M.rooms.current()
    return current_room
end

---@return DungeonRoomType?
function M.rooms.get_type(room_id)
    return zone_rooms[room_id] and zone_rooms[room_id]._type
end

---y distance from bottom of screen where ground edge is
M.GROUND_LEVEL = 50

---@param t DungeonZone
function M.add_zone(t)
    zones[t.id] = t
end

---@return DungeonZone?
function M.current_zone()
    return current_zone
end

---@param zone_id string
---@param player Entity
---@return boolean ok
function M.enter_zone(zone_id, player)
    local zone = zones[zone_id]
    if log.warn_if(not zone, "could not enter missing zone:", zone_id) then
        return false
    end
    zone_rooms = {}
    current_room = nil
    
    -- setup rooms
    local spawn_rooms = {}
    ---@type DungeonSetupRoomsCtx
    local ctx = {
        add_room = function(room)
            room = lume.clone(room)
            zone_rooms[room.id] = room
            if room.spawn_room then
                table.insert(spawn_rooms, zone_rooms[room.id])
            end
            if room.types then
                room._type = lume.randomchoice(room.types)
            end
        end
    }
    current_zone = zone
    zone.setup_rooms(ctx, player)
    if log.warn_if(#spawn_rooms == 0, "no spawn rooms set, zone:", zone.id) then
        return false
    end

    -- set starting room
    current_room = lume.randomchoice(spawn_rooms)

    return true
end

function M.get_next_zones()
    return lume.keys(zones)
end

---@return DungeonRoom[]
function M.get_next_rooms()
    if not current_zone then
        return {}
    end
    if not current_room then
        return {}
    end
    local doors = current_room.doors or {}
    if current_room.rift_room and #doors == 0 then
        -- move to rift next
        return {} -- TODO add 'rift' room type?
    end
    ---@type DungeonRoom[]
    local out = {}
    for _, r in ipairs(doors) do
        local room = M.rooms.get_by_id(r)
        if room then
            table.insert(out, room)
        end
    end
    log.error("no doors found, room:", current_room.id, ", zone:", current_zone.id)
    return out
end

---@param room_id string
---@return DungeonRoom?
function M.move_to_room(room_id)
    assert(current_zone, "not currently in a zone")
    assert(current_room, "not currently in a room, zone:", current_zone.id)

    local is_connected = false
    for _, id in ipairs(current_room.doors) do
        if id == room_id then
            is_connected = true
        end
    end
    if log.warn_if(not is_connected, "cannot move to disconnected room, from_room:", current_room.id, ", to_room:", room_id) then
        return nil
    end
    local room = M.rooms.get_by_id(room_id)
    if log.warn_if(not room, "could not enter missing room:", room_id, ", zone:", current_zone) then
        return nil
    end
    current_room = room
    return room
end

---@return Image?
function M.get_background_image()
    return current_room and current_room.background_image or current_zone and current_zone.default_background_image
end

return M