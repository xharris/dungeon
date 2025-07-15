local items = require 'items'
local assets = require 'assets.index'
local zindex = require 'zindex'
local render = require 'render'
local easing = require 'lib.easing'

local WPN_STATS_RATIO = 0.25

return {
    on_load = function ()
        -- warrior
        items.add{
            id = "starter_sword",
            type = "weapon",
            class_starter = 'warrior',
            label = {
                {text='Rusty Sword\n'},
                {text='It does a little damage'},
            },
            image = {
                path = assets.dk_items,
                frames = {{x=48, y=104, w=16, h=24}},
                sx = 2,
                ox = 8, oy = -4,
            },
            stats_ratio = items.stats{str=WPN_STATS_RATIO},
            render_on_character = {x=16, y=0, z=zindex.equipped_item_back},
            attack_animation = {
                swing = {}
            },
        }
        -- warrior abilities
        --
        -- [crit|hp|agi] * 2
        -- 5% parry chance (reflect 50% damage)
        -- cannot die for 2 sec
        -- weapon mastery: every 5 seconds switch to a special random sword (super_rare)
        -- double edged

        -- archer
        items.add{
            id = "starter_bow",
            type = 'weapon',
            class_starter = 'archer',
            stats_ratio = items.stats{str=WPN_STATS_RATIO},
            image = {
                path = assets.dk_items,
                frames = {{x=144, y=106, w=16, h=22}},
                sx = 2,
                ox = 8, oy = 11,
            },
            render_on_character = {x=16, y=0, z=zindex.equipped_item_back},
            attack_animation = {
                shoot = {
                    projectile = {
                        image = {
                            path = assets.dk_items,
                            frames = {{x=161, y=128, w=14, h=16}},
                            sx = 2,
                            ox = 7,
                            oy = 8,
                        },
                        ease_fn = easing.ease_in_quad
                    }
                },
            },
            attack_landed = function (_, projectiles)
                for _, r in ipairs(projectiles) do
                    render.remove(r.id)
                end
            end
        }

        -- mage
        items.add{
            id = 'starter_wand',
            type = 'weapon',
            class_starter = 'mage',
            stats_ratio = items.stats{int=WPN_STATS_RATIO},
            render_on_character = {x=0, y=0, z=zindex.equipped_item_back},
        }

        -- rogue
        items.add{
            id = 'starter_knife',
            type = 'weapon',
            class_starter = 'rogue',
            stats_ratio = items.stats{str=WPN_STATS_RATIO},
            label = {
                {text='Starter Knife\n'},
                {text='Sharpens as you use it!'}
            },
            render_on_character = {x=0, y=0, z=zindex.equipped_item_back},
        }
 
        items.add{
            id = 'chain_vest',
            type = 'armor',
            label = {
                {text='Chain Vest\n'},
                {text='Blocks some damage'}
            },
            mitigate_damage = function (_, damage)
                return damage - 2
            end
        }
    end
} --[[@as PluginOptions]]