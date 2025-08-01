local cos = math.cos
local sin = math.sin
local tan = math.tan
local pi = math.pi

local c1, c3, c4

return {
    linear = function(x)
        return x
    end,
    ease_in_quad = function (x)
        return x * x
    end,
    ease_out_quad = function (x)
        return 1 - (1-x) * (1-x)
    end,
    ease_in_out_sine = function(x)
        return -(cos(pi * x) - 1) / 2
    end,
    ease_out_sine = function (x)
        return sin((x * pi) / 2)
    end,
    aerial_projectile_speed = function (x)
        return (tan(2.2 * (x + 0.95) + 1.9)) / 4
    end,
    ease_in_circ = function (x)
        return 1 - (1 - (x^2))
    end,
    --[[
    const c4 = (2 * Math.PI) / 3;

    return x === 0
    ? 0
    : x === 1
    ? 1
    : Math.pow(2, -10 * x) * Math.sin((x * 10 - 0.75) * c4) + 1
    ]]
    ease_out_elastic = function (x)
        c4 = (2 * pi) / 3
        return
            (x == 0 or x == 1) and x or
            2^(-10 * x) * sin((x * 10 - 0.75) * c4) + 1
    end,
    ease_out_back = function (x)
        c1 = 1.70158
        c3 = c1 + 1
        return 1 + c3 * ((x-1)^3) + c1 * ((x-1)^2)
    end,
    ease_in_out_quint = function (x)
        return x < 0.5 and 16 * x * x * x * x * x or 1 - (-2 * x + 2)^5 / 2
    end,
    ease_in_out_cubic = function (x)
        if x < 0.5 then
            return 4 * x * x * x
        end
        return 1 - ((-2 * x + 2)^3) / 2
    end
}