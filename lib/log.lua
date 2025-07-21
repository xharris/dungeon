local M = {}
local lume = require 'ext.lume'
local const = require 'const'

local count = lume.count

io.stdout:setvbuf("no")

---@alias LogLevel 'debug'|'info'|'warn'|'error'

---@type LogLevel
M.LOG_METHODS_LEVEL = 'info'
M.LOG_CONSOLE_LEVEL = 'info'

---@type string?
M.error = nil

---@type table<LogLevel, number>
local levels = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4,
}

-- indentation strings
local depth = {}
for i = 1, 20 do
    local str = ""
    for _ = 1, i-1 do
        str = str .. "| "
    end
    table.insert(depth, str)
end
local d = 0
local indent = ""

---@type string[]
local logs = {}

---comment
---@param a LogLevel level in question
---@param b LogLevel level allowed
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
    -- print(header, indent..out)
    table.insert(logs, header.." "..indent..out)
    return header.." "..indent..out
end

function M.add_line(str)
    table.insert(logs, str)
end

function M.info(...)
    if cmp_level('info', M.LOG_CONSOLE_LEVEL) then
        _print(const.LOG_HEADER.info, ...)
    end
end

function M.warn(...)
    if cmp_level('warn', M.LOG_CONSOLE_LEVEL) then
        _print(const.LOG_HEADER.warn, ...)
    end
end

--- returns true if statment is printed
---@param stmt any
---@param ... any
---@return boolean
function M.warn_if(stmt, ...)
    if stmt then
        if cmp_level('warn', M.LOG_CONSOLE_LEVEL) then
            M.warn(...)
        end
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
        if cmp_level('error', M.LOG_CONSOLE_LEVEL) then
            M.error = _print(const.LOG_HEADER.error, ...)
        end
        return true
    end
    return false
end

function M.debug(...)
    if cmp_level('debug', M.LOG_CONSOLE_LEVEL) then
        _print(const.LOG_HEADER.debug, ...)
    end
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
                if not cmp_level(l, M.LOG_METHODS_LEVEL) then
                    -- not correct log level
                    return v(...)
                end
                -- indentation
                d = d + 1
                indent = depth[d]
                -- print fn name + arguments
                _print(const.LOG_HEADER[l], '('..name..'.'..k..')', ...)
                local ret = {v(...)}
                d = d - 1
                -- print return values
                if count(ret) > 0 then
                    for _, r in ipairs(ret) do
                        _print(const.LOG_HEADER[l], '|->', r)
                    end
                end
                ---@diagnostic disable-next-line: deprecated
                return unpack(ret)
            end
            t[k] = wrapper
        end
    end
    return t
end

---@param path string
---@param append? boolean
---@return string? error
function M.write_to_file(path, append)
    append = append == nil and true or append
    -- concat lines
    local str = string.format('=== START %s ===\n\n', os.date())
    for _, line in ipairs(logs) do
        str = str .. line .. "\n"
    end
    str = str .. "\n=== END ===\n\n"
    -- write to file
    local fp = io.open(path, append and "a" or "w+")
    if not fp then
        return "could not write logs to file"
    end
    fp:write(str)
    fp:flush()
    fp:close()
end

return M