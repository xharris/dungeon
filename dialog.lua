local M = {}

local log = require "lib.log"
local easing = require 'lib.easing'

local min = math.min
local max = math.max
local ceil = math.ceil
local str_len = string.len

local MARGIN = 10
local PADDING = 10
local SEP = 2

---@class DialogChoice
---@field id string
---@field text string

---@class DialogOptions
---@field text string
---@field duration? number
---@field choices? DialogChoice[]
---@field clear_on_choice? boolean
---@field _choice_index? number
---@field _char_index? number
---@field _text? string
---@field _t? number

---@type table<string, string[]>
local text_characters = {}

---@type DialogOptions[]
local instances = {}

---@param text string
---@param y number
---@param opts {margin?:number, padding?:number, selected?:boolean}
local function draw_box_with_text(text, y, opts)
    opts = opts or {}
    local margin = opts.margin or 0
    local padding = opts.padding or 0

    local font = love.graphics.getFont()
    local gw = love.graphics.getPixelWidth()
    local w = gw - (2 * margin) - (2 * padding)
    local h = math.ceil(font:getWidth(text) / w) * font:getHeight()

    -- box
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('fill', margin, y, w + (2 * padding), h + (2 * padding))
    
    -- text
    love.graphics.setColor(1, 1, 1, 1.0)
    love.graphics.printf(text, margin + padding, y + padding, w)

    -- selected?
    if opts.selected then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.rectangle('line', margin, y, w + (2 * padding), h + (2 * padding))
    end

    return h + (2 * padding) + SEP
end

---@param v DialogOptions
function M.add(v)
    v._t = 0
    v._char_index = 0
    v._text = ''
    v.duration = v.duration or 1000
    v.text = v.text or ''
    v._choice_index = 1
    v.clear_on_choice = v.clear_on_choice ~= nil and v.clear_on_choice or true
    table.insert(instances, v)
end

function M.prev_choice()
    local first = instances[1]
    if first and first.choices then
        first._choice_index = first._choice_index - 1
    end
    if first._choice_index <= 0 then
        first._choice_index = #first.choices
    end
end

function M.next_choice()
    local first = instances[1]
    if first and first.choices then
        first._choice_index = first._choice_index + 1
    end
    if first._choice_index > #first.choices then
        first._choice_index = 1
    end
end

function M.selected_choice()
    local first = instances[1]
    if first.choices and first._choice_index then
        local choice = first.choices[first._choice_index]
        if choice then
            return choice.id
        end
    end
end

function M.next_dialog()
    if #instances > 0 then
        table.remove(instances, 1)
    end
end

---@param dt number
function M.update(dt)
    for _, instance in ipairs(instances) do
        if instance._char_index < str_len(instance.text) then
            local ratio = easing.ease_in_out_sine(instance._t / instance.duration)
            local idx = ceil(min(str_len(instance.text), str_len(instance.text) * ratio))
            if instance._t < instance.duration then
                instance._t = instance._t + (dt * 1000)
                instance._text = instance.text:sub(1, idx)
            end
        end
    end
end

function M.draw()
    local first = instances[1]
    if first and str_len(first._text) > 0 then
        local y = MARGIN

        -- dialog
        y = y + draw_box_with_text(first._text, y, {margin=MARGIN, padding=PADDING * 2})

        -- choices
        if first._t >= first.duration and first.choices and #first.choices > 0 then
            for i, choice in ipairs(first.choices) do
                y = y + draw_box_with_text(
                    choice.text,
                    y,
                    {margin=MARGIN, padding=PADDING, selected=i == first._choice_index}
                )
            end
        end
    end
end

return M