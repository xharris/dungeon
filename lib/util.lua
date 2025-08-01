local M = {}

local lume = require 'ext.lume'

local lerp = lume.lerp

---@alias Iterator<V> fun(start?: integer):integer, V

---create an iterator from given tables
---@generic V : table
---@param o? {filter?: fun(i:number, v:V):boolean?}
---@param ... V[]
---@return Iterator<V>
function M.iterator(o, ...)
    local tables = {...}
    local i = 0
    local table_i = 1
    local table = tables[table_i]
    local len = #table
    local total_len = 0
    return function(start)
        if start and i < start then
            i = start
        end
        if o and o.filter then
            repeat
                i = i + 1
            until (i - total_len) > len or o.filter(i, table[i - total_len])
        else
            i = i + 1
        end
        if i > len then
            -- move to next table
            table_i = table_i + 1
            if table_i > #tables then
                return -- stop iterating
            end
            table = tables[table_i]
            total_len = total_len + len
            len = #table
        end
        return i, table[i - total_len]
    end
end

---@param x number
---@param max? number
---@return number [0, 1]
function M.diminishing(x, max)
    return x / (x + (max or 100)) + 1
end

---https://gist.github.com/revolucas/184aec7998a6be5d2f61b984fac1d7f7
---@generic V : table
---@param into V
---@param from V
---@return V
function M.merge(into, from)
	local stack = {}
	local node1 = into
	local node2 = from
	while (true) do
		for k,v in pairs(node2) do
			if (type(v) == "table" and type(node1[k]) == "table") then
				table.insert(stack,{node1[k],node2[k]})
			else
				node1[k] = v
			end
		end
		if (#stack > 0) then
			local t = stack[#stack]
			node1,node2 = t[1],t[2]
			stack[#stack] = nil
		else
			break
		end
	end
	return into
end

---@param direction 'horizontal'|'vertical'
---@param ... Color[]
function M.gradient(direction, ...)
    local colors = {...}
    local horizontal = direction == "horizontal"
    local result = love.image.newImageData(horizontal and 1 or #colors, horizontal and #colors or 1)
    for i, color in ipairs(colors) do
        local x, y
        if horizontal then
            x, y = 0, i - 1
        else
            x, y = i - 1, 0
        end
        result:setPixel(x, y, color[1], color[2], color[3], color[4] or 255)
    end
    result = love.graphics.newImage(result)
    result:setFilter('linear', 'linear')
    return result
end

---@generic T
---@param orig T
---@param copies? table<T, T>
---@return T
local function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---@generic T : table
---@param t T
---@return T
function M.deepcopy(t)
    return deepcopy(t)
end

local lerpt_cache = {}

---@generic T : table
---@param from T
---@param to T
---@param p number
---@return T
function M.lerpt(from, to, p)
    local out = lerpt_cache[from]
    if not out then
        out = {}
        lerpt_cache[from] = out
    end
    for k, v in pairs(from) do
        if to[k] ~= nil then
            out[k] = lerp(v, to[k], p)
        end
    end
    return out
end

return M