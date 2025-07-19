local cos = math.cos
local sin = math.sin
local tan = math.tan
local pi = math.pi

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
    end
}