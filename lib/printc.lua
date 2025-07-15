local M = {}

local floor = math.floor

---@class PrintcText
---@field text string
---@field color? number[] {r,g,b,a}

M.ROUND_POSITION = true

---@param x number
local function round(x)
    return floor(x + 0.5)
end

---@param x number
---@param start_x number
---@param limit number
---@param c string
local function should_break(x, start_x, limit, c)
    return
        c == "\n" or
        ((x - start_x) > limit and c == " ")
end

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
---@return number, number
function M.dimensions(texts, x, limit, char_limit)
    x = x or 0
    local y = 0
    if M.ROUND_POSITION then
        x, y = round(x), round(y)
    end
    local start_x = x
    limit = limit or love.graphics.getWidth()
    local font = love.graphics.getFont()
    local font_h = font:getHeight()
    local w = 0
    local h = font_h
    local n = 0
    for _, text in ipairs(texts) do
        for i = 1, string.len(text.text) do
            n = n + 1
            if char_limit ~= nil and n > char_limit then
                return w, h
            end
            local c = text.text:sub(i, i)
            x = x + font:getWidth(c)
            if x > w then
                w = x
            end
            if should_break(x, start_x, limit, c) then
                x = start_x
                y = y + font_h
                h = h + font_h
            end
        end
    end
    return w, h
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
    if M.ROUND_POSITION then
        x, y = round(x), round(y)
    end
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
            if should_break(x, start_x, limit, c) then
                x = start_x
                y = y + font_h
                h = h + font_h
            end
        end
    end
    return h
end

return M