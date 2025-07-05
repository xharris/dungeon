---@class Entity
---@field _id? string
---@field health? {current:number, max:number}
---@field name? string
---@field group? 'player'|'enemy'
---@field items? ItemData[]
---@field zone_id? any id of the zone this entity is in
---@field render_character? any id of character sprite renderable
---@field stats? Stats
---@field attack_timer? number
---@field money? number

---@class Stats
---@field str number strength
----@field int number intelligence
---@field agi number agility

---@alias Room 'combat'|'shop'|'rest'|'event'
