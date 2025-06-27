local M = {}

local genid = require 'lib.id'
local lume = require 'ext.lume'
local color = require 'lib.color'
local log = require 'lib.log'

---@class Renderable
---@field id? string
---@field tex? any love.Texture
---@field text? string
---@field frames? {x:number, y:number, w:number,h:number,}[]
---@field current_frame? number
---@field x? number
---@field y? number
---@field r? number
---@field sx? number
---@field sy? number
---@field ox? number
---@field oy? number
---@field _remove? boolean

local DEFAULT_COLLECTION = '_default'

---@type table<string, Renderable[]>
local collection = {}

---@type any
local current_collection = DEFAULT_COLLECTION

---@type table<string, Renderable>
local renderable_map = {}

local quad

---@param id? any
function M.set_collection(id)
    id = id or DEFAULT_COLLECTION
    if not collection[id] then
        collection[id] = {}
    end
    current_collection = id
end

---@param t Renderable
---@return Renderable
function M.add(t)
    t.id = genid()
    
    table.insert(collection[current_collection], t)
    renderable_map[t.id] = t

    return t
end

function M.remove(id)
    if renderable_map[id] then
        renderable_map[id]._remove = true
    end
end

function M.reset()
    collection = {}
    renderable_map = {}
    current_collection = DEFAULT_COLLECTION
    M.set_collection(DEFAULT_COLLECTION)
end

function M.load()
    M.set_collection(DEFAULT_COLLECTION)
    quad = love.graphics.newQuad(0,0,0,0,1,1)
end

---@param dt number
function M.update(dt)
    for _, c in ipairs(collection) do
        for i, r in lume.ripairs(c) do
            ---@cast r Renderable
            if r._remove then
                renderable_map[r.id] = nil
                table.remove(r, i)
            else
                if r.frames and #r.frames > 0 then
                    r.current_frame = 1
                else
                    r.current_frame = nil
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
        elseif r.tex then
            love.graphics.draw(r.tex, r.x or 0, r.y or 0, r.r, r.sx, r.sy, r.ox, r.oy)
        end
        if r.text then
            love.graphics.print(r.text, r.x or 0, r.y or 0, r.r, r.sx, r.sy, r.ox, r.oy)
        end
        love.graphics.pop()
    end
end

return M