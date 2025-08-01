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
local errors = require 'lib.errors'
local entity = require 'lib.entity'
local lang = require 'lib.i18n'

local max = math.max

---@alias ItemTransformOperation 'add'|'sub'|'mult'|'set'
---@alias ItemTransformKey 'stats.str'|'stats.int'|'stats.agi'|'stats.crit'|'health.max'|'defense'|'critical.chance'|'critical.damage'

---@class ItemTransform
---@field operation ItemTransformOperation
---@field value number

---@class Item
---@field id string
---@field damage_scaling? Stats ratio of damage item does
---@field transform_stats? table<ItemTransformKey, ItemTransform>
---@field defense? number
---@field shop_disabled? boolean can appear in the shop
---@field image? Image
---@field rarity? RarityLevel
---@field is_ability? boolean TODO does not appear in shop, offered every X combats?
---@field charges_required? number TODO in combat, item activates after X cycles
---@field is_starter? boolean
---@field class? Class replaces class starter item
---@field subclass? string shown when character is inspected
---@field requires_items? string[] TODO can only be accepted/offered if player has item in list
---@field requires_class? Class[] TODO
---@field attack_animation? ItemAttackAnimation
---@field render_on_character? {x?:number, y?:number, z?:number, r?:number}
---@field user_will_die? fun(data:ItemData, e:Entity):boolean? return true to prevent character death

---@class ItemAttackAnimation
---@field swing? {}
---@field shoot? {projectile?:ProjectileAnimation, beam?:ItemBeamAnimation, recoil?:any} TODO recoil
---@field stab? {}
---@field custom? fun(source:Entity, target:Entity, duration:number, data:ItemData)

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
M.DEFAULT_WEAPON = 'fist'

---@type Image
local DEFAULT_IMAGE = {
    path = assets.dk_items,
    frames = {{x=48, y=104, w=16, h=24}},
}

---@type Item[]
local items = {}

local entity_storage = datastore.create{
    gain_ability_cooldown = const.GAIN_ABILITY_COOLDOWN,
} --[[@as Datastore<AbilityData>]]

---@param entity_id string
function M.storage(entity_id)
    return entity_storage(entity_id)
end

function M.load()
    M.add{
        id = M.DEFAULT_WEAPON,
        class = 'adventurer',
        attack_animation = {
            swing = {}
        },
        damage_scaling = {agi=0, int=0, str=0.25},
        transform_stats = {
            ['stats.str'] = {operation='add', value=20}
        },
        is_starter =  true,
    }
end

---@param id string
---@return Item?
function M.get(id)
    for _, item in ipairs(items) do
        if item.id == id then
            return item
        end
    end
end

---@param item_id string
---@param animation_name? 'swing'|'shoot'|'stab'|'custom'
---@return boolean
function M.has_attack_animation(item_id, animation_name)
    local item = M.get(item_id)
    return 
        not item or
        not item.attack_animation or
        not (
            animation_name and
            not item.attack_animation[animation_name]
        )
end

M.starters = {}

---Get starting item for each class
---@return Item[]
function M.starters.all()
    ---@type Item[]
    local out = {}
    for _, item in ipairs(items) do
        if item.is_starter then
            table.insert(out, item)
        end
    end
    return out
end

---@param v Item
function M.add(v)
    v.image = v.image or DEFAULT_IMAGE
    if v.render_on_character and v.damage_scaling and not v.attack_animation then
        v.attack_animation = {
            swing = {}
        }
    end
    table.insert(items, v)
end

function M.all()
    return items
end

---@param entity_id string
---@param item_id any
---@return boolean yes, string? error
function M.can_use(entity_id, item_id)
    local e = entity.get(entity_id)
    if not e then
        return false, errors.not_found('entity', entity_id)
    end
    local item = M.get(item_id) or M.abilities.get(item_id)
    if not item then
        return false, errors.not_found('item', item_id)
    end
    if item.requires_items then
        return lume.all(item.requires_items, function (v)
            return
                lume.any(e.inventory, function (d) return d.id == v end) or
                lume.any(e.equipped_items, function (d) return d.id == v end)
        end)
    end
    return true
end

---@param item_id string
function M.label(item_id)
    return {
        {text=lang.get(item_id)..'\n'},
        {text=lang.get(item_id..'_description')}
    } --[[@as PrintcText[] ]]
end
M.label = lume.memoize(M.label)

M.abilities = {}

---@param v Ability
function M.abilities.add(v)
    v.is_ability = true
    return M.add(v)
end

function M.abilities.all()
    local out = {}
    for _, item in ipairs(items) do
        if item.is_ability then
            table.insert(out, item)
        end
    end
    return out
end

M.abilities.get = M.get

---@param n number
---@param rarity_scale number [0,1], 1 is rarer
---@param entity_id? string
function M.abilities.random(n, rarity_scale, entity_id)
    ---@type string[]
    local out = {}
    ---@type table<string, boolean>
    local exclude = {} -- avoid adding duplicates
    for _ = 1, n do
        local r = rarity.random(rarity_scale)
        local possible = {}
        for _, a in ipairs(items) do
            if
                not exclude[a.id] and
                a.is_ability and
                (not a.rarity or rarity.le(a.rarity, r)) and
                (not entity_id or M.can_use(entity_id, a.id))
            then
                table.insert(possible, a)
            end
        end
        if #possible > 0 then
            local choice = lume.randomchoice(possible)
            exclude[choice.id] = true
            table.insert(out, choice.id)
        end
    end
    return out
end

---@param entity_id string
---@param x? number
---@return number cooldown
function M.abilities.reduce_gain_ability_cooldown(entity_id, x)
    x = x or 1
    local data = entity_storage(entity_id)
    data.gain_ability_cooldown = max(0, data.gain_ability_cooldown - x)
    if data.gain_ability_cooldown < 0 then
        M.signals.emit(M.SIGNALS.gain_ability_ready, entity_id)
    end
    return data.gain_ability_cooldown
end

---@param entity_id string
function M.abilities.show_ability_gain_screen(entity_id)
    if not state.is_active(states.pick_next_ability) then
        state.push(states.pick_next_ability, entity_id)
    end
end

M.abilities = log.log_methods('items.abilities', M.abilities, {
    
})
return log.log_methods('items', M, {
    exclude={'id', 'storage', 'get', 'label'}
})