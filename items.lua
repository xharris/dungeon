local M = {}

local datastore = require "lib.datastore"
local const     = require "const"
local signal = require 'lib.signal'
local state = require 'lib.state'
local states = require 'states.index'
local log = require 'lib.log'
local rarity = require 'lib.rarity'
local lume = require 'ext.lume'
local images = require 'lib.images'
local assets = require 'assets.index'
local render = require 'render'

local max = math.max

---@class Item
---@field id string
---@field type 'weapon'|'armor'|'ring'|'passive'
---@field label? PrintcText[]
---@field stats_ratio? Stats
---@field mitigate_damage? fun(src:Entity, damage:number): number mitigate damage before an attack lands
---@field shop_disabled? boolean can appear in the shop
---@field image? Image
---@field rarity? Rarity
---@field is_ability? boolean TODO does not appear in shop, offered every X combats?
---@field charges_required? number TODO in combat, item activates after X cycles
---@field class_starter? Class starter item for class
---@field subclass? string replaces class starter item
---@field upgrade_from? string[] TODO can only be accepted/offered if player has item in list
---@field attack_animation? ItemAttackAnimation
---@field render_on_character? Vector3
---@field attack_landed? fun(target:Entity, projectiles:Renderable[])

---@class ItemAttackAnimation
---@field swing? {}
---@field shoot? {projectile?:ProjectileAnimation, beam?:ItemBeamAnimation}
---@field stab? {}
---@field custom? fun(source:Entity, target:Entity, data:ItemData)

---NOTE stops at target, does not pass through
---@class ItemBeamAnimation

---@class ItemData
---@field id string
---@field data? table<string, any>
---@field renderable? string

---@alias Ability Item

---@class AbilityData
---@field gain_ability_cooldown number

M.signals = signal.create 'items'
M.SIGNALS = {
    -- entity_id
    gain_ability_ready = 'gain_ability_ready'
}

---@type Image
local DEFAULT_IMAGE = {
    path = assets.dk_items,
    frames = {{x=48, y=104, w=16, h=24}},
}

---@type Item[]
local items = {}

---@type Ability[]
local abilities = {}

local entity_storage = datastore.create{
    gain_ability_cooldown = const.GAIN_ABILITY_COOLDOWN,
} --[[@as Datastore<AbilityData>]]

---@param entity_id string
function M.storage(entity_id)
    return entity_storage(entity_id)
end

---@param id string
---@return Item?
function M.get_by_id(id)
    for _, item in ipairs(items) do
        if item.id == id then
            return item
        end
    end
end

---Get starting item for each class
---@return Item[]
function M.get_all_starters()
    ---@type table<Class, Item>
    local class_items = {}
    for _, item in ipairs(items) do
        if item.class_starter then
            class_items[item.class_starter] = item
        end
    end
    ---@type Item[]
    local out = {}
    for _, item in pairs(class_items) do
        table.insert(out, item)
    end
    return out
end

---@param v Item
function M.add(v)
    v.label = v.label or {{text=v.id}} --[[@as PrintcText[] ]]
    v.image = v.image or DEFAULT_IMAGE
    if v.is_ability then
        table.insert(abilities, v)
    else
        table.insert(items, v)
    end
end

function M.all()
    return items
end

function M.abilities()
    return abilities
end

---shortcut to create Stats object
---@param v {agi?:number, str?:number, int?:number}
---@return Stats
function M.stats(v)
    v.agi = v.agi or 0
    v.int = v.int or 0
    v.str = v.str or 0
    return v
end

M.ability = {}

---@param n number
---@param rarity_scale number [0,1]
function M.ability.random(n, rarity_scale)
    ---@type Ability[]
    local out = {}
    for _ = 1, n do
        local r = rarity.random(rarity_scale)
        local possible_items = {}
        for _, a in ipairs(abilities) do
            if a.rarity == r then
                table.insert(out, lume.randomchoice(possible_items))
            end
        end
    end
    return out
end

---@param entity_id string
---@param x? number
---@return number cooldown
function M.ability.reduce_gain_ability_cooldown(entity_id, x)
    x = x or 1
    local data = entity_storage(entity_id)
    log.debug('ability cooldown', data.gain_ability_cooldown)
    data.gain_ability_cooldown = max(0, data.gain_ability_cooldown - x)
    if data.gain_ability_cooldown < 0 then
        M.signals.emit(M.SIGNALS.gain_ability_ready, entity_id)
    end
    return data.gain_ability_cooldown
end

---@param entity_id string
function M.ability.show_ability_gain_screen(entity_id)
    if not state.is_active(states.gain_ability) then
        state.push(states.gain_ability, entity_id)
    end
end

M.ability = log.log_methods('items.ability', M.ability, {
    
})
return log.log_methods('items', M, {
    exclude={'get_by_id', 'storage'}
})