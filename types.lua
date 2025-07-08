---@class Entity
---@field _id? string
---@field health? Health
---@field name? string
---@field group? 'player'|'enemy'
---@field items? ItemData[]
---@field screen_id? any id of the screen this entity is in
---@field render_character? any id of character sprite renderable
---@field stats? Stats
---@field attack_timer? number
---@field money? number

---@class Health
---@field current number
---@field max number

---@class Stats
---@field str number strength
----@field int number intelligence
---@field agi number agility

---@alias Room 'combat'|'shop'|'rest'|'event'
