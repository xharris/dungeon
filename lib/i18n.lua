local M = {}

---@alias i18nLanguage 'en'|'es'

---@type i18nLanguage
M.lang = 'en'

---@type table<i18nLanguage, table<string, string>>
local text = {}

---@param lang i18nLanguage
---@param texts table<string, string>
function M.set(lang, texts)
    text[lang] = text[lang] or {}
    for k, v in pairs(texts) do
        text[lang][k] = v
    end
end

function M.get(key)
    local texts = text[M.lang] or {}
    return texts[key] or key
end

---@param ... string
---@return string
function M.join(...)
    local str = ""
    for i = 1, select('#', ...) do
        str = str .. M.get(select(i, ...))
    end
    return str
end

--- TODO parse full string and replace translatable strings
---@param str string
function M.parse(str)
    return str
end

return M