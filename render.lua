local M = {}

local genid = require 'lib.id'
local lume = require 'ext.lume'
local color = require 'lib.color'
local log = require 'lib.log'
local signal = require 'lib.signal'
local easing = require 'lib.easing'

---@alias RenderableEaseFn 'linear'|'ease_in_out_sine'

---@class RenderableEasing
---@field a number
---@field b number
---@field ease_fn RenderableEaseFn
---@field duration number ms
---@field _t number ms
---@field _vertices? number[]

---@class Renderable
---@field id? string
---@field data? table arbitrary value that does nothing
---@field tex? any love.Texture
---@field text? string
---@field frames? {x:number, y:number, w:number, h:number}[]
---@field current_frame? number
---@field copy_transform? any id of renderable with transform that should be copied
---@field x? number
---@field y? number
---@field r? number
---@field sx? number
---@field sy? number
---@field ox? number
---@field oy? number
---@field _remove? boolean
---@field _easing? table<string, RenderableEasing>

local cos = math.cos
local pi = math.pi
local max = math.max
local min = math.min

local DEFAULT_COLLECTION = '_default'
M.DEBUG = false

---@type table<string, Renderable[]>
local collection = {}

---@type any
local current_collection = DEFAULT_COLLECTION

---@type table<string, Renderable>
local renderable_map = {}

local quad
local curve

M.signals = signal.create('render')

M.SIGNALS = {
    -- id, Renderable
    easing_done = 'render_ease_done'
}

---@param id? any
function M.set_collection(id)
    id = id or DEFAULT_COLLECTION
    if not collection[id] then
        collection[id] = {}
    end
    current_collection = id
end

---@param t Renderable
---@return any, Renderable
function M.add(t)
    t.id = genid()
    table.insert(collection[current_collection], t)
    renderable_map[t.id] = t
    -- copy transform?
    if t.copy_transform then
        local x, y, r = M.transform_point(t.copy_transform, 0, 0)
        t.x = x
        t.y = y
        t.sx = t.sx or r.sx
        t.sy = t.sy or r.sx
        t.r = t.r or r.r
        t.ox = t.ox or r.ox
        t.oy = t.oy or r.ox
    end
    return t.id, t
end

function M.get(id)
    return id and renderable_map[id] or nil
end

function M.remove(id)
    if renderable_map[id] then
        renderable_map[id]._remove = true
    end
end

local transform

---@param id any
---@param x number
---@param y number
---@return number, number, Renderable
function M.transform_point(id, x, y)
    local r = renderable_map[id]
    assert(r, 'renderable not found')
    transform:setTransformation(r.x or 0, r.y or 0, r.r, r.sx, r.sy, r.ox, r.oy)
    local x, y = transform:transformPoint(x, y)
    return x, y, r
end

function M.reset()
    collection = {}
    renderable_map = {}
    current_collection = DEFAULT_COLLECTION
    M.set_collection(DEFAULT_COLLECTION)
end

---@param id any
---@param property string
---@param to number
---@param opts? {duration?:number, ease_fn?:RenderableEaseFn}
function M.ease(id, property, to, opts)
    opts = opts or {}
    opts.duration = opts.duration or 1000
    opts.ease_fn = opts.ease_fn or 'linear'

    local r = M.get(id)
    r._easing = r._easing or {}
    if not r._easing[property] then
        local start = r[property] or to
        r._easing[property] = {
            a = start,
            b = to,
            ease_fn = opts.ease_fn,
            duration = opts.duration,
            _t = 0,
        }
    end
end

---@param id any renderable to ease
---@param source any renderable id
---@param target any renderable id
---@param opts? {duration?:number, ease_fn?:RenderableEaseFn}
function M.move_to(id, source, target, opts)
    local r = M.get(id)
    local r_source = M.get(source)
    local r_target = M.get(target)
    assert(r and r_source and r_target, 'invalid renderable id')

    r.x = r_source.x
    r.y = r_source.y
    local target_x, target_y = M.transform_point(target, r.ox, r.oy)
    M.ease(id, 'x', target_x, opts)
    M.ease(id, 'y', target_y, opts)
end

function M.load()
    curve = love.math.newBezierCurve(0, 0, 0, 0, 0, 0)
    transform = love.math.newTransform()
    M.set_collection(DEFAULT_COLLECTION)
    quad = love.graphics.newQuad(0,0,0,0,1,1)
end

---@param dt number
function M.update(dt)
    for _, c in pairs(collection) do
        for i, r in lume.ripairs(c) do
            ---@cast r Renderable
            if r._remove then
                renderable_map[r.id] = nil
                table.remove(c, i)
            else
                if r.frames and #r.frames > 0 then
                    r.current_frame = 1
                else
                    r.current_frame = nil
                end

                -- easing
                if r._easing then
                    for property, ease in pairs(r._easing) do
                        local fn = easing[ease.ease_fn]
                        ease._t = ease._t + (dt * 1000)
                        local ratio = min(1, max(0, fn(ease._t / ease.duration)))
                        r[property] = ease.a + ((ease.b - ease.a) * ratio)

                        if ratio >= 1 then
                            r._easing[property] = nil
                            M.signals.emit(M.SIGNALS.easing_done, r.id, r)
                        end
                    end
                end
            end
        end
    end
end

function M.draw()
    for _, r in ipairs(collection[current_collection]) do
        love.graphics.push('all')
        color.reset()
        local frame = r.current_frame and r.frames and r.frames[r.current_frame]
        if frame and r.tex then
            local sw, sh = r.tex:getDimensions()
            quad:setViewport(frame.x, frame.y, frame.w, frame.h, sw, sh)
            love.graphics.draw(r.tex, quad, r.x or 0, r.y or 0, r.r, r.sx, r.sy, r.ox, r.oy)

            if M.DEBUG then
                -- draw rectangle around texture
                local x, y = M.transform_point(r.id, 0, 0)
                local centerx, centery = M.transform_point(r.id, r.ox, r.oy)
                love.graphics.push('all')
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.circle('fill', centerx, centery, 4)
                love.graphics.rectangle('line', x, y, frame.w * (r.sx or 1), frame.h * (r.sy or r.sx or 1))
                love.graphics.pop()
            end

        elseif r.tex then
            love.graphics.draw(r.tex, r.x or 0, r.y or 0, r.r, r.sx, r.sy, r.ox, r.oy)

            if M.DEBUG then
                -- draw rectangle around texture
                local x, y = M.transform_point(r.id, 0, 0)
                local centerx, centery = M.transform_point(r.id, r.ox, r.oy)
                local sw, sh = r.tex:getDimensions()
                love.graphics.push('all')
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.circle('fill', centerx, centery, 4)
                love.graphics.rectangle('line', x, y, sw * (r.sx or 1), sh * (r.sy or r.sx or 1))
                love.graphics.pop()
            end
        end
        
        if r.text then
            love.graphics.print(r.text, r.x or 0, r.y or 0, r.r, r.sx, r.sy, r.ox, r.oy)
        end

        if M.DEBUG and r._easing then
            -- draw position transition
            local x, y = r._easing['x'], r._easing['y']
            if x and y then
                love.graphics.push('all')
                love.graphics.setColor(0, 1, 0, 1)
                love.graphics.line(x.a, y.a, x.b, y.b)
                love.graphics.pop()
            end
        end

        love.graphics.pop()
    end
end

return M