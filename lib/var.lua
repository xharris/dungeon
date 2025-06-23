local M = {}

---@param v string
function M.is_numeric(v)
    return string.match(v, "^%d+$")
end

return M