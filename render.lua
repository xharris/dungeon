local M = {}

local genid = require 'lib.id'
local lume = require 'ext.lume'
local color = require 'lib.color'
local log = require 'lib.log'
local signal = require 'lib.signal'
local easing = require 'lib.easing'
local const  = require 'const'
local fonts  = require 'lib.fonts'
local errors = require 'lib.errors'
local util   = require 'lib.util'

local abs = math.abs

---@alias RenderableEaseFn 'linear'|'ease_in_out_sine'

---@class Renderable
---@field id? string
---@field created_at? number
---@field parent? string 'attach' to another renderable
---@field tag? string
---@field collection_id? string
---@field data? table arbitrary value that does nothing
---@field tex? any love.Texture
---@field font? Font
---@field text? any
---@field text_shadow_color? Color
---@field text_shadow_size? number
---@field frames? RenderableFrame[]
---@field current_frame? number
---@field color? Color
---@field opacity? number
---@field copy_transform? string id of renderable with transform that should be copied
---@field x? number
---@field y? number
---@field r? number radians
---@field r2? number radians (rotate around r2_radius position)
---@field r2_radius? number distance from origin to rotate around
---@field sx? number
---@field sy? number
---@field ox? number
---@field oy? number
---@field _remove? boolean
---@field w? number
---@field h? number
---@field z? number
---@field _last_z? number
---@field _last_x? number
---@field _last_y? number
---@field _debug_color? Color
---@field angle? number direction of renderable movement (radians)
---@field face_direction? boolean
---@field rect? {mode?:'line'|'fill', w:number, h:number}
---@field disabled? boolean do not render
---@field debug? {enabled?:boolean, show_id?:boolean}
---@field _is_new? boolean wait a frame to allow renderable to be transformed before drawing it

---@class RenderableFrame
---@field x number
---@field y number
---@field w number
---@field h number

local cos = math.cos
local pi = math.pi
local max = math.max
local min = math.min
local floor = math.floor

local DEFAULT_COLLECTION = '_default'

M.DEBUG = false
M.DEBUG_SHOW_ID = false
M.ROUND_POSITION = true

---@type table<string, Renderable[]>
local collection = {}

---@type any
local current_collection = DEFAULT_COLLECTION

---@type table<string, Renderable>
local renderable_map = {}

local quad
local debug_canvas
local transform -- love.math.Transform

M.signals = signal.create('render')

M.SIGNALS = {
    -- id, Renderable
    easing_done = 'easing_done'
}

---@param x number
local function round(x)
    return floor(x + 0.5)
end

---@param t Renderable[]
local function z_sort(t)
    table.sort(t, function (a, b)
        if a.z == b.z then
            return (a.created_at or 0) < (b.created_at or 0)
        end
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

---@param t? Renderable
---@return string, Renderable
function M.add(t)
    local id = genid()
    t = t or {}
    t.tag = t.tag or 'renderable'
    t.id = t.tag..':'..tostring(id)

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
        t.r2 = t.r2 or r.r2
        t.r2_radius = t.r2_radius or r.r2_radius
        t.ox = t.ox or r.ox
        t.oy = t.oy or r.ox
    end
    t.opacity = t.opacity or 1
    t.x = t.x or 0
    t.y = t.y or 0
    t.w = 0
    t.h = 0
    t.r = t.r or 0
    t.r2 = t.r2 or 0
    t.r2_radius = t.r2_radius or 0
    t.ox = t.ox or 0
    t.oy = t.oy or 0
    t.sx = t.sx or 1
    t.sy = t.sy or t.sx
    t.current_frame = t.current_frame or 1
    t.collection_id = current_collection
    t.angle = 0
    t._last_x = t.x
    t._last_y = t.y
    t.created_at = os.time()
    t._debug_color = t._debug_color or {math.random(20, 80)/100, 0, 0, 1}
    t._is_new = true
    z_sort(collection[current_collection])

    -- negative offsets
    local w, h = M.dimensions(t, true)
    if t.ox < 0 then
        t.ox = w + t.ox
    end
    if t.oy < 0 then
        t.oy = h + t.oy
    end

    if current_collection then
        log.debug('collection:', current_collection)
    end
    return t.id, t
end

---@param id? string
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


---@param id string
---@param x? number
---@param y? number
---@return number, number, Renderable
function M.transform_point(id, x, y)
    local r = renderable_map[id]
    assert(r, errors.not_found('renderable', id))
    x = x or 0
    y = y or 0
    local tf = M.get_transform(id)
    x, y = tf:transformPoint(x, y)
    return x, y, r
end

---@type Renderable[]
local nodes = {}
---@type table<string, boolean>
local ids = {} -- keep track of renderables encountered

---love.math.Transform
---@type table<string, any>
local memo_get_transform = {}

---@param id string
---@return any transform
function M.get_transform(id)
    if memo_get_transform[id] then
        return memo_get_transform[id]
    end
    local r = M.get(id)
    local depth = 0
    local x, y, ox, oy = 0, 0, 0, 0
    ids = {}
    ---@type Renderable[]
    nodes = {}
    transform:reset()
    while r and not ids[r.id] do
        table.insert(nodes, r)
        ids[r.id] = true
        depth = depth + 1
        r = r.parent and M.get(r.parent) or nil
    end
    for _, n in lume.ripairs(nodes) do
        x, y = n.x or 0, n.y or 0
        ox, oy = n.ox or 0, n.oy or 0
        if M.ROUND_POSITION then
            x = round(x)
            y = round(y)
            ox = round(ox)
            oy = round(oy)
        end

        -- draw at parent's origin
        if n.parent then
            local p = M.get(n.parent)
            if p then
                x = x + p.ox
                y = y + p.oy
            end
        end

        local rx, ry = 0, 0
        if n.r2_radius then
            rx, ry = lume.vector(n.r2 or 0, n.r2_radius)
        end
        
        transform:translate(x, y)

        transform:translate(rx, ry)
        transform:rotate(n.r2 or 0)

        transform:rotate(n.r or 0)
        transform:scale(n.sx, n.sy)
        transform:translate(-ox, -oy)

    end
    memo_get_transform[id] = transform:clone()
    if depth > 1 and r and ids[r.id] then
        log.error("parent cycle for", id, "("..table.concat(lume.keys(ids), ', ')..")")
        return memo_get_transform[id]
    end
    return memo_get_transform[id]
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
    elseif r.rect then
        r.w = r.rect.w * sx
        r.h = r.rect.h * sy
    end
    return r.w, r.h
end

function M.reset()
    collection = {}
    renderable_map = {}
    current_collection = DEFAULT_COLLECTION
    M.set_collection(DEFAULT_COLLECTION)
end

function M.load()
    transform = love.math.newTransform()
    M.set_collection(DEFAULT_COLLECTION)
    quad = love.graphics.newQuad(0,0,0,0,1,1)
end

---@param dt number
function M.update(dt)
    for _, c in pairs(collection) do
        local need_z_sort = false
        for i, r in lume.ripairs(c) do
            r._is_new = false
            ---@cast r Renderable
            if r._remove then
                renderable_map[r.id] = nil
                table.remove(c, i)
            else
                -- need sorting?
                if r.z ~= r._last_z then
                    r.z = floor(r.z + 0.5)
                    r._last_z = r.z
                    need_z_sort = true
                end

                -- calculate movement
                if r._last_x and r._last_y then
                    r.angle = lume.angle(r._last_x, r._last_y, r.x, r.y)
                end
                if r.face_direction and r.angle then
                    r.r = r.angle
                end
                r._last_x = r.x
                r._last_y = r.y

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
    memo_get_transform = {}
    if not debug_canvas then
        debug_canvas = love.graphics.newCanvas()
    end
    debug_canvas:renderTo(function()
        love.graphics.clear()
    end)
    for _, r in ipairs(collection[current_collection]) do
        if not r.disabled and not r._is_new then
            love.graphics.push('all')
            color.reset()
            local tf = M.get_transform(r.id)

            if r.font then
                fonts.set(r.font)
            end

            local frame = r.frames and r.frames[r.current_frame or 1]

            love.graphics.replaceTransform(tf)

            -- set color
            color.set(r.color or color.MUI.WHITE, r.opacity or 1)

            if frame and r.tex then
                -- draw frame of texture
                local sw, sh = r.tex:getDimensions()
                quad:setViewport(frame.x, frame.y, frame.w, frame.h, sw, sh)
                love.graphics.draw(r.tex, quad)
            elseif r.tex then
                -- draw texture
                love.graphics.draw(r.tex)
            end

            -- draw rect
            local rect = r.rect
            if rect then
                love.graphics.rectangle(rect.mode or 'line', 0, 0, max(1, rect.w), max(1, rect.h))
            end

            local text = r.text and tostring(r.text)
            if text then
                if r.text_shadow_color then
                    -- draw text shadow
                    love.graphics.push('all')
                    color.set(r.text_shadow_color, r.opacity or 1)
                    for i = 1, r.text_shadow_size or 1 do
                        love.graphics.print(text, i, i)
                    end
                    love.graphics.pop()
                end
                -- draw text
                love.graphics.print(text)
            end
            
            local debug = r.debug
            if M.DEBUG or (debug and debug.enabled) then
                -- TODO update for new transform stuff
                debug_canvas:renderTo(function()
                    love.graphics.push('all')
                    fonts.set()
                    local w, h = M.dimensions(r, true)
                    local px, py = M.transform_point(r.id, r.ox, r.oy)

                    -- draw rectangle around texture with origin point
                    love.graphics.setColor(r._debug_color)
                    love.graphics.rectangle('line', 0, 0, w, h)

                    love.graphics.push('all')
                    love.graphics.origin()
                    local pox, poy = M.transform_point(r.id, r.ox, r.oy)
                        love.graphics.circle('fill', pox, poy, 3)
                    if not r.tex or rect or text then
                        -- root node probably
                        love.graphics.circle('line', pox, poy, 5)
                    end
                    love.graphics.pop()
            
                    -- transform:setTransformation(x, y, rot, 1, 1, ox, oy)
                    -- love.graphics.replaceTransform(transform)
                    if M.DEBUG_SHOW_ID or (debug and debug.show_id) then
                        love.graphics.origin()
                        love.graphics.print(r.id, px, py)
                        love.graphics.scale(r.sx, r.sy)
                    end

                    love.graphics.pop()
                end)
            end

            love.graphics.pop()
        end
    end

    love.graphics.draw(debug_canvas)
end

return log.log_methods('render', M, {
    exclude={'draw', 'update', 'get', 'transform_point', 'get_transform', 'set_collection', 'dimensions'}
})