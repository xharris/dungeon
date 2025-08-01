local M = {}

local color = require "lib.color"
local ctrl = require 'lib.controls'
local lume = require 'ext.lume'
local printc = require 'lib.printc'
local easing = require 'lib.easing'
local log = require 'lib.log'
local util= require 'lib.util'
local fonts = require 'lib.fonts'
local animation = require 'lib.animation'
local signal = require 'lib.signal'
local game   = require 'game'

local min = math.min
local max = math.max

M.MARGIN = 4
M.PADDING = 2
M.SEP = 0
---ms
M.EASE_DURATION = 200
M.EASE_FN = easing.ease_in_out_cubic
---@type Font?
M.DEFAULT_FONT = nil

M.signals = signal.create 'cornermenu'
M.SIGNALS = {
    select_item = 'select_item'
}

---@class CornerMenuItem
---@field id string
---@field bg? Color
---@field selected_bg? Color
---@field texts PrintcText[]
---@field selected_texts? PrintcText[]
---@field font? Font TODO
---@field selected_font? Font TODO
---@field rect? number[]

---@class CornerMenuHighlight
---@field rect number[]
---@field color Color

---@type CornerMenuItem[]
local items = {}
---@type table<any, number>
local selected_idx = {}

---@type any?
local current_id

---@type CornerMenuHighlight?
local highlight

local t = 0

---@param texts PrintcText[]
---@param rect RenderableFrame
---@param font Font?
local function draw_texts(texts, rect, font)
    love.graphics.push('all')
    font = font or M.DEFAULT_FONT
    fonts.set(font)
    local x, y, w = rect[1], rect[2], rect[3]
    printc.draw(
        texts,
        x + M.PADDING, y + M.PADDING,
        w - (M.PADDING * 2)
    )
    love.graphics.pop()
end

local function stencil()
    local rect = highlight and highlight.rect
    if rect then
        local x, y, w, h = rect[1], rect[2], rect[3], rect[4]
        color.set(color.MUI.BLACK)
        love.graphics.rectangle('fill', x, y, w, h)
    end
end

---@param id? any
---@param ... CornerMenuItem[]
function M.set(id, ...)
    current_id = id
    items = {...}
    if not id then return end
    if #items > 0 then
        t = 0
        local gw, gh = love.graphics.getDimensions()
        selected_idx[id] = selected_idx[id] or 1
        local x, y = M.MARGIN, gh-M.MARGIN
        for _, item in lume.ripairs(items) do
            item.selected_texts = item.selected_texts or util.deepcopy(item.texts)
            for _, text in ipairs(item.texts) do
                if not text.color then
                    text.color = color.alpha(color.MUI.WHITE, 0.6)
                end
            end
            for _, text in ipairs(item.selected_texts) do
                if not text.color then
                    text.color = color.alpha(color.MUI.WHITE, 0.8)
                end
            end
            item.bg = item.bg or color.alpha(color.MUI.BLACK, 0.4)
            item.selected_bg = item.selected_bg or color.alpha(color.MUI.BLACK, 0.6)

            local font = item.font or M.DEFAULT_FONT
            fonts.set(font)
            
            local tw, th = printc.dimensions(item.selected_texts, x, gw - (M.MARGIN*2))
            local w, h =  tw + (M.PADDING*2), th + (M.PADDING*2)
            y = y - h
            item.rect = {x, y, w, h}
            y = y - M.SEP
        end
        M.select_item(selected_idx[id])
    end
end

function M.clear()
    M.set()
end

---@param idx_or_id number|string
---@return number, CornerMenuItem?
function M.select_item(idx_or_id)
    if type(idx_or_id) == 'number' then
        -- clamp idx to [1, #items]
        while idx_or_id > #items do
            idx_or_id = idx_or_id - #items
        end
        while idx_or_id < 1 do
            idx_or_id = idx_or_id + #items
        end
    end

    -- find item by index/id
    local idx = 1
    ---@type CornerMenuItem?
    local move_to_item
    for i, item in ipairs(items) do
        if i == idx_or_id or i == item.id then
            idx = i
            move_to_item = item
            log.debug('move to', item)
            break
        end
    end

    -- animate highlight moving to item
    if move_to_item and current_id then
        selected_idx[current_id] = idx
        if not highlight then
            highlight = {
                rect = util.deepcopy(move_to_item.rect),
                color = util.deepcopy(move_to_item.selected_bg)
            }
        else
            animation
                .create('cornermenu.rect', highlight.rect)
                .add({to=move_to_item.rect, duration=M.EASE_DURATION, ease_fn=M.EASE_FN})
                .start()
            animation
                .create('cornermenu.color', highlight.color)
                .add({to=move_to_item.selected_bg, duration=M.EASE_DURATION, ease_fn=M.EASE_FN})
                .start()
        end
    end

    return current_id and selected_idx[current_id] or 1, move_to_item
end

---@param dt number
function M.update(dt)
    if current_id then
        local idx = selected_idx[current_id]
        if ctrl:pressed 'down' then
            M.select_item(idx + 1)
        end
        if ctrl:pressed 'up' then
            M.select_item(idx - 1)
        end
        if ctrl:pressed 'select' then
            local selected = items[idx]
            if selected then
                M.signals.emit(M.SIGNALS.select_item, selected.id)
            end
        end
    end
end

function M.draw()
    if #items > 0 then
        love.graphics.push('all')
        -- draw all items
        for _, item in ipairs(items) do
            draw_texts(item.texts, item.rect)
            if item.rect then
                color.set(item.bg)
                love.graphics.rectangle("fill", item.rect[1], item.rect[2], item.rect[3], item.rect[4])
            end
        end
        -- draw highlight rect and masked texts
        if highlight then
            love.graphics.stencil(stencil, "replace", 1)
            love.graphics.setStencilTest("greater", 0)
            -- draw rect
            color.set(highlight.color)
            love.graphics.rectangle("fill", 0, 0, game.width, game.height)
            -- draw text
            for _, item in ipairs(items) do
                draw_texts(item.selected_texts, item.rect)
            end

            love.graphics.setStencilTest()
        end
        love.graphics.pop()
    end
end

return log.log_methods('cornermenu', M, {
    exclude={'update', 'draw', 'EASE_FN'}
})