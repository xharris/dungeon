local M = {}

local log = require 'lib.log'
local lume = require 'ext.lume'
local signal = require 'lib.signal'

---@class Event
---@field id string
---@field rarity? Rarity
---@field disabled? boolean
---@field only_zones? string[] only allow this event to happen in specified zones
---@field on_start fun(e:Entity)
---@field on_update? fun(dt:number, e:Entity)
---@field cooldown? number TODO how many events until this event can appear again?

M.signals = signal.create 'events'
M.SIGNALS = {
    on_end = 'on_end'
}

---@type table<string, Event>
local events = {}

local state = {
    ---@type Event?
    current_event = nil,
    ---@type string?
    entity = nil,
}

---@param t Event
function M.add(t)
    if log.warn_if(events[t.id], "duplicate event ids:", t.id) then
        return
    end
    events[t.id] = t
end

function M.disable(id)
    if log.warn_if(not events[id], "event not found:", id) then
        return
    end
    events[id].disabled = true
end

---@param zone_id? string
---@return string? id
function M.get_random_event(zone_id)
    ---@type string[]
    local possible_events = {}
    for key, event in pairs(events) do
        local correct_zone =
            (zone_id and not event.only_zones) or
            (not zone_id and not event.only_zones) or
            (zone_id and event.only_zones and lume.find(event.only_zones, zone_id))
        if not event.disabled and correct_zone then
            table.insert(possible_events, key)
        end
    end
    log.warn_if(#possible_events == 0, "no events left to pick from randomly")
    return lume.randomchoice(possible_events)
end

---@param id string
---@param e Entity
---@return boolean ok false if no event has been started
function M.start_event(id, e)
    if state.current_event then
        return true -- event already running
    end
    state.current_event = events[id]
    if log.error_if(state.current_event == nil, "event not found:", id) then
        return false
    end
    log.info("start event", id)
    if state.current_event.on_start then
        state.current_event.on_start(e)
    end
    return true
end

function M.end_event()
    if state.current_event then
        state.current_event = nil
        M.signals.emit(M.SIGNALS.on_end)
    end
end

---@param dt number
---@param e Entity
function M.update(dt, e)
    if state.current_event and state.current_event.on_update then
        state.current_event.on_update(dt, e)
    end
end

return M