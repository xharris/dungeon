local M = {}

local dialog = require 'dialog'
local items = require 'items'
local lang = require 'lib.i18n'
local assets = require 'assets.index'

local IMG = {}
local in_shop = false

---@type ItemData[]
local available_items = {}

function M.enter()
    ---@type DialogChoice[]
    local choices = {}

    for _, item in pairs(items.all()) do
        if not item.shop_disabled then
            ---@type DialogChoice
            local choice = {
                id = item.id,
                image = IMG.dk_items,
                image_frames = {
                    {x=16, y=64, w=16, h=32},
                },
                texts = item.label,
            }
            table.insert(choices, choice)
            table.insert(available_items, {id=item.id})
        end
    end

    dialog.add{texts = {{text="Welcome to my store..."}}}
    dialog.add{choices = choices}
    in_shop = true
end

function M.leave()
    available_items = {}
    in_shop = false
end

function M.is_in_shop()
    return in_shop
end

function M.load()
    IMG.dk_items = love.graphics.newImage(assets.dk_items)
    IMG.dk_items:setFilter('linear', 'nearest')
end

---@param e Entity
---@param item_id string
---@return boolean ok
function M.buy_item(e, item_id)
    if item_id and available_items and #available_items > 0 then
        local found_item = false
        for _, data in ipairs(available_items) do
            if item_id == data.id and items.get_by_id(data.id) then
                found_item = true
                break
            end
        end
        assert(found_item, "item "..tostring(item_id).." not found")
        dialog.add{
            max_time = 2000,
            texts={{text=lang.join("You purchased ", item_id, ".")}}
        }
        table.insert(e.items, {id=item_id})
        return true
    end
    return false
end

return M