local M = {}

---@class PrintcText
---@field text string
---@field color? number[] {r,g,b,a}

---@param texts1 PrintcText[]
---@param texts2 PrintcText[]
function M.equal(texts1, texts2)
    if texts1 == nil and texts2 == nil then
        return true
    end
    if (texts1 == nil) ~= (texts2 == nil) then
        return false
    end
    if #texts1 ~= #texts2 then
        return false
    end
    for i = 1, #texts1 do
        if texts1[i].text ~= texts2[i].text then
            return false
        end
    end
    return true
end

---@param texts PrintcText[]
function M.len(texts)
    local l = 0
    for _, text in ipairs(texts) do
        l = l + string.len(text.text)
    end
    return l
end

---@param texts PrintcText[]
---@param x? number
---@param limit? number
---@param char_limit? number
---@return number
function M.height(texts, x, limit, char_limit)
    local start_x = x
    local y = 0
    x = x or 0
    local font = love.graphics.getFont()
    local font_h = font:getHeight()
    local h = font_h
    local n = 0
    for _, text in ipairs(texts) do
        for i = 1, string.len(text.text) do
            n = n + 1
            if char_limit ~= nil and n > char_limit then
                return h
            end
            local c = text.text:sub(i, i)
            x = x + font:getWidth(c)
            if c == "\n" or x > limit - start_x then
                x = start_x
                y = y + font_h
                h = h + font_h
            end
        end
    end
    return h
end

---@param texts PrintcText[]
---@param x? number
---@param y? number
---@param limit? number
---@param char_limit? number
---@return number
function M.draw(texts, x, y, limit, char_limit)
    x = x or 0
    y = y or 0
    limit = limit or love.graphics.getWidth()
    local start_x = x
    local font = love.graphics.getFont()
    local font_h = font:getHeight()
    local h = font_h
    local n = 0
    for _, text in ipairs(texts) do
        for i = 1, string.len(text.text) do
            n = n + 1
            if char_limit ~= nil and n > char_limit then
                return h
            end
            if text.color then
                love.graphics.setColor(text.color)
            end
            local c = text.text:sub(i, i)
            love.graphics.print(c, x, y)
            x = x + font:getWidth(c)
            -- new line or reached limit
            if c == "\n" or x > limit - start_x then
                x = start_x
                y = y + font_h
                h = h + font_h
            end
        end
    end
    return h
end

return M