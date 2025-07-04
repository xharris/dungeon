---@class Entity
---@field _id? number
---@field health? number
---@field class? string
---@field group? 'player'|'enemy'
---@field items? ItemData[]
---@field zone_id? any id of the zone this entity is in
---@field render_character? any id of character sprite renderable
---@field stats? Stats
---@field attack_timer? number

---@class Stats
---@field str number strength
----@field int number intelligence
---@field agi number agility

---@alias Room 'combat'|'shop'|'rest'|'event'

---@class RoomEvent
---@field is_unknown? boolean
---@field prompt string
---@field choices DialogChoice[]
---@field result_choice string which choice will give the player the `result`
---@field result_type 'gain_item'|'lose_item'|'combat'|'heal'
---@field result_data any
---@field cost? number