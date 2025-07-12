local M = {}
local lume = require 'ext.lume'
local const = require 'const'

local count = lume.count

---@alias LogLevel 'debug'|'info'|'warn'|'error'

---@type LogLevel
M.LOG_METHODS_LEVEL = 'info'

---@type string?
M.error = nil

---@type table<LogLevel, number>
local levels = {
    debug = 1, 
    info = 2, 
    warn = 3, 
    error = 4,
}

---comment
---@param a LogLevel level in question
---@param b LogLevel current_set_level
---@return boolean enabled 
local function cmp_level(a, b)
    return levels[a] >= levels[b]
end

---@param header string?
---@param ... string|number
local function _print(header, ...)
    header = header or ""
    local args = {...}
    for i, str in ipairs(args) do
        args[i] = lume.serialize(str)
    end
    local out = table.concat(args, ' ')
    print(header, out)
    return header.." "..out
end

function M.info(...)
    _print(const.LOG_HEADER.info, ...)
end

function M.warn(...)
    _print(const.LOG_HEADER.warn, ...)
end

--- returns true if statment is printed
---@param stmt any
---@param ... any
---@return boolean
function M.warn_if(stmt, ...)
    if stmt then
        M.warn(...)
        return true
    end
    return false
end

--- returns true if statment is printed
---@param stmt any
---@param ... string|number
---@return boolean
function M.error_if(stmt, ...)
    if stmt then
        M.error = _print(const.LOG_HEADER.error, ...)
        return true
    end
    return false
end

function M.debug(...)
    _print(const.LOG_HEADER.debug, ...)
end

---@generic T
---@param name string
---@param t T
---@param keys? {include?:string[], exclude?:string[]}
---@param level? LogLevel
---@return T
function M.log_methods(name, t, keys, level)
    keys = keys or {}
    for k, v in pairs(t) do
        if
            type(v) == 'function' and 
            (not keys.exclude or not lume.find(keys.exclude, k)) and
            (not keys.include or lume.find(keys.include, k))
        then
            ---@type LogLevel
            local l
            local wrapper = function (...)
                l = level or M.LOG_METHODS_LEVEL
                if cmp_level(l, M.LOG_METHODS_LEVEL) then
                    _print(const.LOG_HEADER[l], '('..name..'.'..k..')', ...)
                end
                local ret = {v(...)}
                if cmp_level(l, M.LOG_METHODS_LEVEL) and count(ret) > 0 then
                    _print(const.LOG_HEADER[l], '->', ret)
                end
                ---@diagnostic disable-next-line: deprecated
                return unpack(ret)
            end
            t[k] = wrapper
        end
    end
    return t
end

return M