local M = {}
local enet = require "enet"
local id = require 'lib.id'
local lume = require 'ext.lume'

local EVENT_TYPE = {
    receive     = '#',
    connect     = 'o',
    disconnect  = '-',
}

local EVENT_KEY = {
    assign_id = 'server.assign_id',
    connect = 'server.connect',
}

local client = {}
local peers = {}
local rooms = {}

function M.move_to_room(clientid, roomid)
    if not rooms[roomid] then
        rooms[roomid] = {}
    end
    table.insert(rooms[roomid], clientid)
end

function M.server(address)
    client = {
        id = 'server'..id(),
        host = enet.host_create(address),
    }
end

function M.client(address)
    local host = enet.host_create()
    
    client = {
        id = nil,
        host = host,
        connection = host:connect(address),
    }
end

function M.disconnect(v)
    if not v.connection then return end
    v.connection:disconnect_now()
end

function M.update(v)
    local event = v.host:service(100)

    if event then
        print('['..EVENT_TYPE[event.type]..'] '..tostring(event.peer)..' '..event.data)
        if event.type == 'connect' then
            -- assign id to client and send it to them
            local clientid = id()
            ---@type NetPayload
            local data = {
                event = EVENT_KEY.assign_id,
                data = clientid,
            }
            peers[clientid] = event.peer
            event.peer:send(lume.serialize(data))
        elseif event.type == 'receive' then
            ---@type NetPayload
            local data = lume.deserialize(event.data)

            -- received client id from server
            if data.event == EVENT_KEY.assign_id then
                v.id = data.data
            end

            if M.on_data then
                M.on_data(data)
            end
        end
    end
end

---@param data NetPayload
function M.send(data)
    if not client.connection or not client.id then return print('missing client info',client.connection,client.id) end
    data.from = client.id
    client.host:service(100)
    print("net send", lume.serialize(data))
    if data.roomid and rooms[data.roomid] then
        -- send data to one room
        for _, clientid in ipairs(rooms[data.roomid]) do
            peers[clientid]:send(lume.serialize(data), 0, 'reliable')
        end
    else
        -- send data to everyone
        client.connection:send(lume.serialize(data), 0, 'reliable')
    end
end

return M