local M = {}

local screens = require 'screens'
local lume = require 'ext.lume'
local render = require 'render'
local images = require 'lib.images'
local signal = require 'lib.signal'
local color  = require 'lib.color'

local max = math.max
local min = math.min
local distance = lume.distance
local vector = lume.vector
local lerp = lume.lerp
---@diagnostic disable-next-line: deprecated
local atan = math.atan2 or math.atan
local angle = function (x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = -(y2 - y1)
    local rad = atan(dy, dx)
    return rad < 0 and rad + math.pi*2 or rad
end

---@class ProjectileAnimation
---@field image Image
---@field ease_fn? function
---@field face_direction? boolean
---@field speed? 'slow'|'normal'|'fast'
---@field target_distance? number distance where projectile is considered to have hit the target
---@field keep? boolean do not destroy after hitting target
---@field on_reached_target? fun(data:any)
---@field curve? number[]
---@field curve_sy? number

---@class Projectile
---@field target Entity
---@field animation ProjectileAnimation
---@field data any
---@field renderable Renderable
---@field from Vector2
---@field to Vector2
---@field t number
---@field _bezier any love.BezierCurve

M.DEBUG = false

M.signals = signal.create 'projectiles'
M.SIGNALS = {
    reached_target = 'reached_target' -- data:any
}

---@type Projectile[]
local projectiles = {}

---@param from Vector2
---@param to Vector2
---@param v ProjectileAnimation
---@param extra? {data?:any, target?:Entity}
function M.create(from, to, v, extra)
    extra = extra or {}
    v.curve_sy = v.curve_sy or 0

    -- shoot projectile
    local _, r = render.add(
        images.renderable(v.image, {
            face_direction = v.face_direction
        })
    )
    r.x = from.x
    r.y = from.y

    ---@type Projectile
    local p = {
        animation = v,
        data = extra.data,
        renderable = r,
        target = extra.target,
        _bezier = love.math.newBezierCurve(v.curve or {
            0, 0,
            0.5, 0,
            1, 0,
        }),
        from = from,
        to = to,
        t = 0,
    }

    table.insert(projectiles, p)
end

function M.update(dt)
    -- move projectiles
    for i, p in lume.ripairs(projectiles) do
        ---@cast p Projectile
        -- get current target position
        local target = p.target
        local target_screen_ox, target_screen_oy = screens.rect(target.screen_id)
        local r_x, r_y = p.renderable.x, p.renderable.y
        local target_x = target.x + target_screen_ox
        local target_y = target.y + target_screen_oy

        local dist = distance(r_x, r_y, target_x, target_y)
        if dist <= (p.animation.target_distance or 10) then
            -- close enough to target
            M.signals.emit(M.SIGNALS.reached_target, p.data)
            if not p.animation.keep then
                -- destroy projectile
                render.remove(p.renderable.id)
                table.remove(projectiles, i)
            end
        elseif p.t <= 2000 then
            -- move along curve
            p.t = p.t + 1000 * dt
            local amt = max(0, min(1, p.animation.ease_fn(p.t / 2000)))
            local x, y = p._bezier:evaluate(amt)
            
            local x_scale = p.to.x - p.from.x

            p.renderable.x = (x * x_scale) + p.from.x
            p.renderable.y = (y * p.animation.curve_sy) + p.from.y
        end
    end
end

function M.draw()
    if M.DEBUG then
        love.graphics.push('all')
        for _, p in ipairs(projectiles) do
            color.set(color.MUI.GREEN_500)
            love.graphics.line(p._bezier:render())
        end
        love.graphics.pop()
    end
end

return M