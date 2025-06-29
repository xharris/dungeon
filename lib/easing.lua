local cos = math.cos
local pi = math.pi

return {
    linear = function(x)
        return x
    end,
    ease_in_out_sine = function(x)
        return -(cos(pi * x) - 1) / 2
    end
}