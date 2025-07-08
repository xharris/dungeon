local M = {}

---@class Item
---@field id string
---@field type 'weapon'|'armor'|'ring'|'passive'
---@field label? PrintcText[]
---@field modify_stats? fun(stats:Stats) modify stats of the user
---@field mitigate_damage? fun(src:Entity, damage:number): number mitigate damage before an attack lands
---@field shop_disabled? boolean can appear in the shop
---@field starter_item? boolean player can start the game with this item
---@field image? Image

---@class ItemData
---@field id string
---@field data? table<string, any>

---@type Item[]
local items = {}

---@param id string
---@return Item?
M.get_by_id = function(id)
    for _, item in ipairs(items) do
        if item.id == id then
            return item
        end
    end
end

---@param v Item
function M.add(v)
    table.insert(items, v)
end

function M.all()
    return items
end

return M