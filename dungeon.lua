local M = {}

local lume = require 'ext.lume'
local log = require 'lib.log'
local signal = require 'lib.signal'
local const  = require 'const'
local stage = require 'lib.stage'

---@alias DungeonRoomType 'combat'|'shop'|'rest'|'event'|'rift'|'ability'

---@class DungeonRoom
---@field id string
---@field doors? string[] list of room ids
---@field zones? string[] (rift_room) specify which zones this rift can go to
---@field types? DungeonRoomType[] choose a room type from the list
---@field combat_enemy_types? CombatEnemyType[]
---@field _type? DungeonRoomType
---@field spawn_room? boolean allow player to spawn in this room
---@field rift_room? boolean allow player to riftwalk in this room
---@field background_image? Image
---@field only_events? string[]
---@field sky? Sky
---@field floor? Floor

---@class DungeonSetupRoomsCtx
---@field add_room fun(room:DungeonRoom)

---@class DungeonZone
---@field id string
---@field events string[] list of events that can occur
---@field enemies string[] list of enemy ids that can spawn
---@field setup_rooms fun(ctx:DungeonSetupRoomsCtx, e:Entity)
---@field default_background_image? Image
---@field can_return? boolean can choose to return to same room again
---@field sky? Sky
---@field floor? Floor

---@type table<string, DungeonRoom>
local zone_rooms = {}

---@type DungeonZone?
local current_zone

---@type DungeonRoom?
local current_room

---@type table<string, DungeonZone>
local zones = {}

---@class DungeonData
---@field rooms_until_ability number

M.signals = signal.create 'dungeon'
M.SIGNALS = {
    --- DungeonZone, entity_id
    enter_zone = 'enter_zone',
    --- DungeonRoom, entity_id
    enter_room = 'enter_room',
}

M.rooms = {}

---@type DungeonRoom
M.rooms.RIFT = {
    id = '_rift_room',
    _type = 'rift',
}

---@return DungeonRoom?
function M.rooms.id(id)
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

function M.rooms.get_spawn()
    ---@type DungeonRoom[]
    local out = {}
    for _, r in pairs(zone_rooms) do
        if r.spawn_room then
            table.insert(out, r)
        end
    end
    return out
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

    -- setup sky and floor
    stage.floor.set(zone.floor or {})
    stage.sky.set(zone.sky or {})

    M.signals.emit(M.SIGNALS.enter_zone, zone, player)

    return true
end

function M.get_next_zones()
    ---@type table<string, boolean>
    local next_zones = {}
    if current_room and current_room._type == 'rift' and current_room.zones and #current_room.zones > 0 then
        for _, z in ipairs(current_room.zones) do
            next_zones[z] = true
        end
    else
        for _, z in pairs(zones) do
            next_zones[z.id] = true
        end
    end
    -- can redo this zone
    if current_zone and current_zone.can_return then
        next_zones[current_zone.id] = true
    end
    return lume.keys(next_zones)
end

---@return DungeonRoom[]
function M.get_next_rooms()
    if not current_zone then
        return {}
    end
    if not current_room then
        local spawn_rooms = M.rooms.get_spawn()
        return {lume.randomchoice(spawn_rooms)}
    end

    local doors = current_room.doors or {}
    if current_room.rift_room and #doors == 0 then
        -- move to rift next
        return lume.clone(M.rooms.RIFT)
    end
    log.warn_if(current_room.rift_room and #doors > 0, "rift room ignored, room:", current_room.id, ", doors:", #doors)
    ---@type DungeonRoom[]
    local out = {}
    for _, r in ipairs(doors) do
        local room = M.rooms.id(r)
        if room then
            table.insert(out, room)
        end
    end
    log.error_if(#out == 0, "no doors found, room:", current_room.id, ", zone:", current_zone.id)
    return out
end

---@param room_id string
---@param entity Entity
---@return DungeonRoom?
function M.move_to_room(room_id, entity)
    assert(current_zone, "not currently in a zone")

    local room = M.rooms.id(room_id)
    if room and room.spawn_room then
        -- spawn room
        current_room = room
    else
        assert(current_room, "not currently in a room, zone:", current_zone.id)

        -- check if room is connected (TODO remove?)
        local is_connected = false
        for _, id in ipairs(current_room.doors) do
            if id == room_id then
                is_connected = true
            end
        end
        if log.warn_if(not is_connected, "cannot move to disconnected room, from_room:", current_room.id, ", to_room:", room_id) then
            return nil
        end
    end

    if log.warn_if(not room, "could not enter missing room:", room_id, ", zone:", current_zone) then
        return nil
    end

    M.signals.emit(M.SIGNALS.enter_room, room, entity)
    current_room = room
    return room
end

---@return Image?
function M.get_background_image()
    return current_room and current_room.background_image or current_zone and current_zone.default_background_image
end

M.rooms = log.log_methods('dungeon.rooms', M.rooms, {
    exclude={'get_type'}
})

return log.log_methods('dungeon', M, {
    exclude={'get_background_image', 'id', 'get_type', 'current_zone'}
})