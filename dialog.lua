local M = {}

local log = require "lib.log"
local easing = require 'lib.easing'
local lume = require 'ext.lume'
local printc = require 'lib.printc'

local min = math.min
local max = math.max
local ceil = math.ceil

local MARGIN = 10
local PADDING = 10

M.NEXT_DIALOG_COOLDOWN = 1000
M.IMAGE_ONLY_CHOICES = 7

M.margin = {0, 0, 0, 0} -- TODO?
M.sep = {10, 10}
M.padding = {0, 0, 0, 0}

---@class DialogChoice
---@field id string
---@field texts? PrintcText[]
---@field image? any love.Image TODO
---@field image_frames? {x:number, y:number, w:number, h:number}[] TODO

---@class DialogOptions
---@field texts? PrintcText[]
---@field duration? number (ms) animation duration
---@field choices? DialogChoice[]
---@field clear_on_choice? boolean
---@field max_time? number (ms) max time to show dialog before calling next_dialog
---@field _choices_have_images? boolean TODO 1 row of squares with left/right arrows for overflow, up/down to skip to next 'section'
---@field _choice_index? number
---@field _text_len? number
---@field _char_limit? number
---@field _t? number

---@type DialogOptions[]
local instances = {}
local quad
local next_dialog_cooldown = M.NEXT_DIALOG_COOLDOWN

---@param texts PrintcText[]
---@param y number
---@param limit number
---@param opts {margin?:number, padding?:number, selected?:boolean, char_limit?:number}
local function draw_box_with_text(texts, y, limit, opts)
    texts = texts or {{text=' '}}
    opts = opts or {}
    local margin = opts.margin or 0
    local padding = opts.padding or 0

    -- local font = love.graphics.getFont()
    local gw = love.graphics.getPixelWidth()
    local w = gw - (2 * margin) - (2 * padding)
    local h = printc.height(texts, margin + padding, limit) + (2 * padding)

    -- box
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('fill', margin, y, w + (2 * padding), h)

    -- text
    love.graphics.setColor(1, 1, 1, 1.0)
    printc.draw(texts, margin + padding, y + padding, w, opts.char_limit)

    -- selected?
    if opts.selected then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.rectangle('line', margin, y, w + (2 * padding), h)
    end

    return h
end

---@param text_changed boolean?
local function reset_first(text_changed)
    local v = instances[1]
    if v then
        v._t = v._t or 0
        v.duration = v.duration or 1000
        v.texts = v.texts or {}
        v._text_len = printc.len(v.texts)
        v._choice_index = v._choice_index or 1
        v.clear_on_choice = v.clear_on_choice ~= nil and v.clear_on_choice or true
        v._choices_have_images = false
        v.duration = v.duration or 0
        v._char_limit = v._char_limit or 0

        if v.max_time and v.max_time <= v.duration then
            v.max_time = v.duration + 500
        end

        if v.choices then
            for _, choice in ipairs(v.choices) do
                if choice.image then
                    v._choices_have_images = true
                    break
                end
            end

            local choice = v._choice_index and v.choices[v._choice_index]
            if v._choices_have_images and choice and choice.texts then
                v.texts = choice.texts or {}
                v._text_len = printc.len(v.texts)
            end
        end

        if text_changed then
            v._t = 0
            v._char_limit = 0
        end

        if v._text_len == 0 then
            v._t = v.duration
        end

        if v.duration <= 0 then
            v._char_limit = v._text_len
        end
    end
end

---@param v DialogOptions
function M.add(v)
    if not quad then
        quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1)
    end
    table.insert(instances, v)
    M.set(v, #instances)
end

---@param v DialogOptions
---@param i? number
function M.set(v, i)
    i = i or 1
    local found = instances[i]
    if found then
        instances[i] = lume.merge(found, v)
        instances[i].texts = v.texts or found.texts
        reset_first(not printc.equal(found.texts, v.texts))
    end
end

function M.prev_choice()
    local first = instances[1]
    if not first then
        return
    end
    first._choice_index = first._choice_index - 1
    if first._choice_index <= 0 then
        first._choice_index = #first.choices
    end
    local choice = first.choices[first._choice_index]
    if choice and first._choices_have_images and choice.texts then
        M.set({texts=choice.texts})
    end
end

function M.next_choice()
    local first = instances[1]
    if not first then
        return
    end
    first._choice_index = first._choice_index + 1
    if first._choice_index > #first.choices then
        first._choice_index = 1
    end
    local choice = first.choices[first._choice_index]
    if choice and first._choices_have_images and choice.texts then
        M.set({texts=choice.texts})
    end
end

function M.selected_choice()
    local first = instances[1]
    if first and first.choices and first._choice_index then
        local choice = first.choices[first._choice_index]
        if choice then
            return choice.id
        end
    end
end

---@param force? boolean
function M.next_dialog(force)
    if not force and next_dialog_cooldown > 0 then
        return
    end
    if #instances > 0 then
        ---@type DialogOptions?
        local removed = table.remove(instances, 1)
        local first = instances[1]
        next_dialog_cooldown = M.NEXT_DIALOG_COOLDOWN
        if removed and first then
            reset_first(not printc.equal(removed.texts, first.texts))
        end
    end
end

function M.has_choices()
    local first = instances[1]
    return first and first.choices and #first.choices > 0
end

function M.has_image_choices()
    local first = instances[1]
    return first and first._choices_have_images
end

---@param dt number
function M.update(dt)
    if next_dialog_cooldown > 0 then
        next_dialog_cooldown = next_dialog_cooldown - (dt * 1000)
    end
    local first = instances[1]
    local len = first and first._text_len
    -- show more characters
    if first and len and first._char_limit < len then
        local ratio = easing.ease_in_out_sine(first._t / first.duration)
        first._char_limit = ceil(min(len, len * ratio))
    end
    -- auto-move to next dialog
    if first and first.max_time and first._t >= first.max_time then
        M.next_dialog(true)
    end
    if first and (first._t <= max(first.duration, first.max_time or 0)) then
        first._t = first._t + (dt * 1000)
    end
end

function M.draw()
    local first = instances[1]
    if first then
        local x = MARGIN
        local y = MARGIN
        local limit = love.graphics.getWidth() - (2 * MARGIN) - (2 * PADDING)

        -- dialog
        y = y + draw_box_with_text(first.texts, y, limit, {
            margin=MARGIN,
            padding=PADDING,
            char_limit=first._char_limit
        }) + M.sep[2]

        -- choices
        if first.choices and #first.choices > 0 then
            if first._choices_have_images then
                local choice_size = (love.graphics.getWidth() - MARGIN - (M.sep[1] * M.IMAGE_ONLY_CHOICES)) / M.IMAGE_ONLY_CHOICES
                -- draw choices
                for i = 1, M.IMAGE_ONLY_CHOICES do
                    -- box
                    love.graphics.setColor(0, 0, 0, 0.8)
                    love.graphics.rectangle('fill', x, y, choice_size, choice_size)

                    -- selected?
                    if i == (first._choice_index % M.IMAGE_ONLY_CHOICES) then
                        love.graphics.setLineWidth(2)
                        love.graphics.setColor(1, 1, 1, 0.9)
                        love.graphics.rectangle('line', x, y, choice_size, choice_size)
                    end

                    x = x + choice_size + M.sep[1]
                end
            elseif first._t >= first.duration then
                -- draw choices
                for i, choice in ipairs(first.choices) do
                    y = y + M.sep[2] + draw_box_with_text(
                        choice.texts, y, limit,
                        {margin=MARGIN, padding=PADDING, selected=i == first._choice_index}
                    )
                end
            end
        end
    end
end

return M