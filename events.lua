local M = {}

local log = require 'lib.log'
local entity = require 'lib.entity'
local lume = require 'ext.lume'
local signal = require 'lib.signal'

---@class EventLegacy
---@field id string
---@field is_unknown? boolean
---@field prompt PrintcText[]
---@field choices DialogChoice[]
---@field result_choice string which choice will give the player the `result`
---@field result_type 'gain_item'|'lose_item'|'combat'|'heal'
---@field result_data any
---@field cost? number

---@class Event
---@field id string
---@field on_start fun(e:Entity)
---@field on_update? fun(dt:number, e:Entity)

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
    table.insert(events, t)
end

function M.get_random_event()
    local event_keys = lume.keys(events)
    local rand = lume.randomchoice(event_keys)
    return rand
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
    state.current_event.on_start(e)
    return true
end

function M.end_event()
    if state.current_event then
        M.signals.emit(M.SIGNALS.on_end)
    end
end

---@param dt number
---@param e Entity
function M.update(dt, e)
    if state.current_event then
        state.current_event.on_update(dt, e)
    end
end

return M