local M = {}

local log = require 'lib.log'
local lume = require 'ext.lume'

---@type table<string, function[]>
local signals = {}

function M.off(...)
    for _, fn in ipairs({...}) do
        for k, fns in pairs(signals) do
            for i, signal_fn in lume.ripairs(fns) do
                if fn == signal_fn then
                    table.remove(fns, i)
                end
            end
        end
    end
end

---@param t table
function M.offt(t)
    local fns = {}
    for _, v in pairs(t) do
        if type(v) == 'function' then
            table.insert(fns, v)
        end
    end
    M.off(table.unpack(fns))
end

---@param prefix string
function M.create(prefix)
    local N
    N = {
        ---@param name string
        ---@param fn function
        on = function(name, fn)
            local key = prefix.."."..name
            if not signals[key] then
                signals[key] = {}
            end
            table.insert(signals[key], fn)
        end,
        ---@param ... function]
        off = function(...)
            for _, fn in ipairs({...}) do
                for k, fns in pairs(signals) do
                    if string.find(k, "^"..prefix..".") then
                        for i, signal_fn in lume.ripairs(fns) do
                            if fn == signal_fn then
                                table.remove(fns, i)
                            end
                        end
                    end
                end
            end
        end,
        ---@param name string
        ---@param ... any
        emit = function (name, ...)
            local key = prefix.."."..name
            if not signals[key] then
                signals[key] = {}
            end
            local keep_fns = {}
            for _, fn in ipairs(signals[key]) do
                local ret = fn(...)
                if not ret then
                    table.insert(keep_fns, fn)
                end
            end
            signals[key] = keep_fns
        end,
    }
    return log.log_methods('signal.'..tostring(prefix), N, {
        exclude={'on'}
    })
end

return log.log_methods('signal', M)