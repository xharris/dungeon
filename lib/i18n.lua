local M = {}

---@alias i18nLanguage 'en'|'es'

---@type i18nLanguage
M.lang = 'en'

---@type table<i18nLanguage, table<string, string>>
local text = {}

---@param lang i18nLanguage
---@param texts table<string, string>
function M.set(lang, texts)
    text[lang] = texts
end

function M.get(key)
    local texts = text[M.lang] or {}
    return texts[key] or key
end

--- TODO parse full string and replace translatable strings
---@param str string
function M.parse(str)
    return str
end

return M