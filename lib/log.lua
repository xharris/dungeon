local M = {}
local lume = require 'ext.lume'

---@type string?
M.error = nil

function M.info(...)
    print("[INFO]", ...)
end

function M.warn(...)
    print("[WARN]", ...)
end

--- returns true if statment is printed
---@param stmt any
---@param ... any
---@return boolean
function M.warn_if(stmt, ...)
    if stmt then
        print("[WARN]", ...)
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
        print("[ERR]", ...)
        M.error = table.concat({...}, " ")
        return true
    end
    return false
end

function M.debug(...)
    local args = {...}
    for i, str in ipairs(args) do
        args[i] = lume.serialize(str)
    end
    local out = table.concat(args, ' ')
    print("[DEBUG]", out)
end

return M