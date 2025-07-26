local M = {}

---@alias Iterator<V> fun(o?:{filter?: fun(i:number, v:V)}, ...:V[]): fun(table: V[], i?: integer):integer, V

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
    return function()
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

return M