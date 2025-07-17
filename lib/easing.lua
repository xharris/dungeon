local cos = math.cos
local sin = math.sin
local pi = math.pi

return {
    linear = function(x)
        return x
    end,
    ease_in_quad = function (x)
        return x * x
    end,
    ease_in_out_sine = function(x)
        return -(cos(pi * x) - 1) / 2
    end,
    ease_out_sine = function (x)
        return sin((x * pi) / 2)
    end
}