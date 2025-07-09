local M = {}
local lume = require 'ext.lume'

---@type string?
M.error = nil

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
    _print("[INFO]", ...)
end

function M.warn(...)
    _print("[WARN]", ...)
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
        M.error = _print("[ERR]", ...)
        return true
    end
    return false
end

function M.debug(...)
    _print("[DEBUG]", ...)
end

return M