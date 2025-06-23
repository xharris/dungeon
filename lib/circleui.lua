local M = {}

---@class CircleUiSelectData
---@field page number
---@field selected_item any

---@class CircleUiItemData
---@field is_hovered boolean
---@field hover_t number

---@class CircleUiPageData
---@field is_selected boolean
---@field hover_t number

local lume = require 'ext.lume'
local color = require 'lib.color'
local log   = require 'lib.log'
local ctrl = require 'lib.controls'
local ds = require 'lib.datastore'

local ROWS = 2
local COLS = 4
local RADIUS = 20
local HOVER_RADIUS = 30
local HOVER_DURATION = 200
local PAGE_SEP = 4
local PAGE_HEIGHT = 2
local PAGE_SELECTED_HEIGHT = 4

local ds_item_data = ds.new(
    { hover_t = 0, is_hovered = false } --[[@as CircleUiItemData]]
)

local ds_page_data = ds.new(
    { is_selected=false, hover_t=0 } --[[@as CircleUiPageData]]
)

local ds_select = ds.new(
    { page=1 } --[[@as CircleUiSelectData]]
)

function M.update(dt)
    local mx, my = love.mouse.getPosition()
    for _, data in pairs(ds_item_data.storage()) do
        if data.is_hovered then
            data.hover_t = math.min(data.hover_t + (dt * 1000), HOVER_DURATION)
        else
            data.hover_t = math.max(data.hover_t - (dt * 1000), 0)
        end
    end
    for _, data in pairs(ds_page_data.storage()) do
        if data.is_selected then
            data.hover_t = math.min(data.hover_t + (dt * 1000), HOVER_DURATION)
        else
            data.hover_t = math.max(data.hover_t - (dt * 1000), 0)
        end
    end
end

---@generic C
---@param id string
---@param items C[]
---@return C|nil
function M.select(id, items)
    local i, x, y, r, h = 0, 0, 0, 0, 0
    local w, h = love.graphics.getDimensions()
    local cols = COLS + 1
    local rows = ROWS + 1
    local wsect = w / cols
    local vsect = h / rows
    local mx, my = love.mouse.getPosition()
    local dist = 0
    local pages = math.ceil(#items / (ROWS * COLS))
    local data = ds_select.get(id)
    local item_data --[[@as CircleUiItemData]]
    local page_data --[[@as CircleUiPageData]]
    local item
    local font = love.graphics.getFont()
    local text_offy = -font:getHeight() / 2

    -- reset selected item
    data.selected_item = nil

    color.set(color.MUI.WHITE, 1)
    for j = 1, (ROWS * COLS) do
        i = j + (ROWS * COLS * (data.page - 1))
        item = items[i]
        if item then
            item_data = ds_item_data.get(item)

            x = (j - 1) % COLS + 1
            y = (j - x) / COLS + 1
            if y <= ROWS then
                -- expand/shrink circle
                r = lume.smooth(RADIUS, HOVER_RADIUS, item_data.hover_t / HOVER_DURATION)
                -- mouse hovering
                dist = lume.distance(mx, my, x * wsect, y * vsect)
                item_data.is_hovered = dist < r
                if item_data.is_hovered then
                    love.graphics.printf(item, font, 0, vsect / 2 - RADIUS, w, 'center')
                    if ctrl:pressed 'ui_select' then
                        data.selected_item = item
                    end
                end
                -- item circle
                love.graphics.circle('fill', x * wsect, y * vsect, r)
            end
        end
    end
    local marginx = (w / cols) - RADIUS

    -- prev page
    y = (ROWS * vsect) + RADIUS + (vsect / 2)
    color.set(color.MUI.WHITE, 0.4)
    if pages > 1 then
        if data.page > 1 and mx > 0 and mx < marginx then
            color.set(color.MUI.WHITE, 1)
            if ctrl:pressed 'ui_select' then
                data.page = math.max(1, data.page - 1)
            end
        end
        love.graphics.printf('<', font, 0, (h/2) + text_offy, marginx, 'center')
        
        -- next page
        if data.page < pages and mx > w - marginx and mx < w then
            color.set(color.MUI.WHITE, 1)
            if ctrl:pressed 'ui_select' then
                data.page = math.min(pages, data.page + 1)
            end
        end
        love.graphics.printf('>', font, w - marginx, (h/2) + text_offy, marginx, 'center')

        local rectw = (w - (marginx * 2)) / pages
        for i = 1, pages do
            page_data = ds_page_data.get(id..tostring(i))
            page_data.is_selected = data.page == i

            -- page indicator
            x = (i - 1) * rectw + (marginx)
            color.set(color.MUI.WHITE, 0.4)
            if page_data.is_selected then
                color.set(color.MUI.WHITE, 1)
            end
            h = lume.smooth(PAGE_HEIGHT, PAGE_SELECTED_HEIGHT, page_data.hover_t / HOVER_DURATION)
            love.graphics.rectangle('fill', x, y - (h / 2), rectw - PAGE_SEP, h)
        end
    end

    return data.selected_item
end

return M