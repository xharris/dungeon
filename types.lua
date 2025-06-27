---@class Entity
---@field _id? number
---@field health? number
---@field abilities? table<string>
---@field cooldowns? table<string, number>
---@field class? string
---@field group? 'player'|'enemy'
---@field items? string[]
---@field zone_id? any id of the zone this entity 'owns'

---@class Ability
---@field damage number
---@field cooldown number

---@alias Room 'combat'|'shop'|'rest'|'event'

---@class Item
---@field before_take_damage? fun(e:Entity, amt:number): number

---@class RoomEvent
---@field is_unknown? boolean
---@field prompt string
---@field choices string[]
---@field result_choice string which choice will give the player the `result`
---@field result_type 'gain_item'|'lose_item'|'combat'|'heal'
---@field result_data any
---@field cost? number