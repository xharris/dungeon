local M = {}

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

return M