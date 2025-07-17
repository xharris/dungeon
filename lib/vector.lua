local M = {}

local sqrt = math.sqrt

---@class Vector2
---@field x number
---@field y number

---@class Vector3
---@field x number
---@field y number
---@field z number

---||v||
---@param v Vector2|Vector3
function M.magnitude(v)
    local z = v.z or 0
    return sqrt((v.x * v.x) + (v.y * v.y) + (z * z))
end

---v / ||v||
---@generic V : Vector2
---@param v V
---@return V
function M.normalize(v)
    local mag = M.magnitude(v)
    ---@cast v Vector3
    if v.z then
        return {x=v.x / mag, y=v.y / mag, z=v.z / mag}
    end
    return {x=v.x / mag, y=v.y / mag}
end

return M