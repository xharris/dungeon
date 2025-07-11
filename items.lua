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
---@field rarity? Rarity
---@field is_augment? boolean TODO does not appear in shop, offered every X combats?
---@field charges_required? number TODO in combat, item activates after X cycles

---@class ItemData
---@field id string
---@field data? table<string, any>

---@type Item[]
local items = {}
---@type Item[]
local augments = {}

---@param id string
---@return Item?
function M.get_by_id(id)
    for _, item in ipairs(items) do
        if item.id == id then
            return item
        end
    end
end

---@return Item[]
function M.get_all_starters()
    ---@type Item[]
    local out = {}
    for _, item in ipairs(items) do
        if item.starter_item then
            table.insert(out, item)
        end
    end
    return out
end

---@param v Item
function M.add(v)
    if v.is_augment then
        table.insert(augments, v)
    else
        table.insert(items, v)
    end
end

function M.all()
    return items
end

function M.augments()
    return augments
end

return M