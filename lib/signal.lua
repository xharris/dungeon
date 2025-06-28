local M = {}

local signals = {}

function M.create(prefix)
    return {
        ---@param name string
        ---@param fn function
        on = function(name, fn)
            local key = prefix.."."..name
            if not signals[key] then
                signals[key] = {}
            end
            table.insert(signals[key], fn)
        end,
        ---@param name string
        ---@param ... any
        emit = function (name, ...)
            local key = prefix.."."..name
            if not signals[key] then
                signals[key] = {}
            end
            local keep_fns = {}
            for _, fn in ipairs(signals[key]) do
                local ret = fn(...)
                if not ret then
                    table.insert(keep_fns, fn)
                end
            end
            signals[key] = keep_fns
        end,
    }
end

return M