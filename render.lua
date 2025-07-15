local M = {}

local genid = require 'lib.id'
local lume = require 'ext.lume'
local color = require 'lib.color'
local log = require 'lib.log'
local signal = require 'lib.signal'
local easing = require 'lib.easing'
local const  = require 'const'

local abs = math.abs

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
---@field collection_id? string
---@field data? table arbitrary value that does nothing
---@field tex? any love.Texture
---@field text? string
---@field frames? RenderableFrame[]
---@field current_frame? number
---@field copy_transform? string id of renderable with transform that should be copied
---@field x? number
---@field y? number
---@field r? number radians
---@field sx? number
---@field sy? number
---@field ox? number
---@field oy? number
---@field _remove? boolean
---@field _easing? table<string, RenderableEasing>
---@field w? number
---@field h? number
---@field z? number
---@field _last_z? number

---@class RenderableFrame
---@field x number
---@field y number
---@field w number
---@field h number

local cos = math.cos
local pi = math.pi
local max = math.max
local min = math.min

local DEFAULT_COLLECTION = '_default'
M.DEBUG = const.DEBUG_RENDER

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
    easing_done = 'easing_done'
}

---@param t Renderable[]
local function z_sort(t)
    table.sort(t, function (a, b)
        return (a.z or 0) < (b.z or 0)
    end)
end

---All new renderables will be added to the specified collection. 
---When calling draw or other methods, only renderables in the 
---currently set collection will be used.
---@param id? any
function M.set_collection(id)
    id = id or DEFAULT_COLLECTION
    if not collection[id] then
        collection[id] = {}
    end
    current_collection = id
end

---@param render_id string
---@param collection_id string
---@return boolean ok
function M.move_to_collection(render_id, collection_id)
    local r = M.get(render_id)
    if not r then
        log.warn('(move_to_collection) renderable not found, id:', render_id)
        return false
    end
    local from_c = collection[r.collection_id]
    if from_c then
        -- remove from old collection
        for i, r2 in lume.ripairs(from_c) do
            ---@cast r2 Renderable
            if r2.id == r.id then
                table.remove(from_c, i)
                break
            end
        end
    end
    -- add to new collection
    M.set_collection(collection_id)
    r.collection_id = collection_id
    table.insert(collection[collection_id], r)
    z_sort(collection[collection_id])
    M.set_collection()
    return true
end

---@param t Renderable
---@return string, Renderable
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
    t.w = 0
    t.h = 0
    t.ox = t.ox or 0
    t.oy = t.oy or 0
    t.sx = t.sx or 1
    t.sy = t.sy or t.sx
    t.current_frame = t.current_frame or 1
    t.collection_id = current_collection
    z_sort(collection[current_collection])

    -- negative offsets
    local w, h = M.dimensions(t, true)
    if t.ox < 0 then
        t.ox = w + t.ox
    end
    if t.oy < 0 then
        t.oy = h + t.oy
    end

    return t.id, t
end

function M.get(id)
    return id and renderable_map[id] or nil
end

---@param id string
---@return string? error
function M.remove(id)
    if renderable_map[id] then
        renderable_map[id]._remove = true
        return
    end
    return "renderable not found"
end

local transform

---@param id any
---@param x? number
---@param y? number
---@return number, number, Renderable
function M.transform_point(id, x, y)
    local r = renderable_map[id]
    assert(r, 'renderable not found, id:', id)
    x = x or 0
    y = y or 0
    transform:setTransformation(r.x or 0, r.y or 0, r.r, r.sx, r.sy, r.ox, r.oy)
    x, y = transform:transformPoint(x, y)
    return x, y, r
end

---@param r Renderable
---@param ignore_scaling? boolean
---@return number,number
function M.dimensions(r, ignore_scaling)
    local frame = r.current_frame and r.frames and r.frames[r.current_frame]
    local sx = ignore_scaling and 1 or r.sx or 1
    local sy = ignore_scaling and 1 or r.sy or r.sx or 1
    if frame and r.tex then
        r.w = abs(frame.w * sx)
        r.h = abs(frame.h * sy)
    elseif r.tex then
        local sw, sh = r.tex:getDimensions()
        r.w = abs(sw * sx)
        r.h = abs(sh * sy)
    end
    return r.w, r.h
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
---@param target any renderable id
---@param opts? {duration?:number, ease_fn?:RenderableEaseFn, transform_target?:fun(r:Renderable, x:number,y:number):number,number}
function M.move_to(id, target, opts)
    local r = M.get(id)
    local r_target = M.get(target)
    assert(r and r_target, 'invalid renderable id')

    local target_x, target_y = M.transform_point(target, 0, 0)
    if opts and opts.transform_target then
        target_x, target_y = opts.transform_target(r, target_x, target_y)
    end
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
        local need_z_sort = false
        for i, r in lume.ripairs(c) do
            ---@cast r Renderable
            if r._remove then
                renderable_map[r.id] = nil
                table.remove(c, i)
            else
                if r.z ~= r._last_z then
                    r._last_z = r.z
                    need_z_sort = true
                end

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

                -- calculate size
                M.dimensions(r)
            end
        end

        -- sort?
        if need_z_sort then
            z_sort(c)
        end
    end
end

function M.draw()
    for _, r in ipairs(collection[current_collection]) do
        love.graphics.push('all')
        color.reset()

        -- draw image
        local frame = r.frames and r.frames[r.current_frame or 1]
        local x, y = 0, 0
        local ox, oy = r.ox or 1, r.oy or 1

        if frame and r.tex then
            local sw, sh = r.tex:getDimensions()
            x, y = M.transform_point(r.id, ox, oy)
            quad:setViewport(frame.x, frame.y, frame.w, frame.h, sw, sh)
            love.graphics.draw(r.tex, quad, x, y, r.r, r.sx, r.sy, r.ox, r.oy)
        elseif r.tex then
            x, y = M.transform_point(r.id, ox, oy)
            love.graphics.draw(r.tex, x, y, r.r, r.sx, r.sy, r.ox, r.oy)
        end

        if M.DEBUG then
            local w, h = M.dimensions(r, true)

            -- draw rectangle around texture with origin point
            local x2, y2 = x - (r.ox * abs(r.sx)), y - (r.oy * abs(r.sy))
            love.graphics.push('all')
            love.graphics.setColor(1, 0, 0, 1)

            transform:setTransformation(r.x or 0, r.y or 0, r.r, r.sx, r.sy, r.ox, r.oy)
            love.graphics.replaceTransform(transform)

            love.graphics.print(r.id, 0, 0)
            love.graphics.circle('fill', r.ox, r.oy, 2)
            love.graphics.rectangle('line', 0, 0, w, h)
            love.graphics.pop()
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

return log.log_methods('render', M, {
    exclude={'draw', 'update', 'get', 'transform_point', 'set_collection', 'dimensions'}
})