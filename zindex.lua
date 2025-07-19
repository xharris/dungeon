local M = {
    player = 0,
    equipped_item_back = 0,
    equipped_item_front = 0,
    character_health_changed = 0
}

local i = 0
for k in pairs(M) do
    M[k] = i
    i = i + 1
end

return M