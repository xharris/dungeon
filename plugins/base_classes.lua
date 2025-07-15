local items = require 'items'
local assets = require 'assets.index'
local zindex = require 'zindex'
local render = require 'render'
local easing = require 'lib.easing'
local stats  = require 'stats'

local WPN_STATS_RATIO = 0.25
local WPN_SCALE = 2

return {
    on_load = function ()
        -- warrior
        items.add{
            id = "starter_sword",
            type = "weapon",
            class_starter = 'warrior',
            label = {
                {text='Beginner\'s Sword\n'},
                {text='Rusty, but gets the job done'},
            },
            image = {
                path = assets.dk_items,
                frames = {{x=48, y=104, w=16, h=24}},
                sx = WPN_SCALE,
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
            label = {
                {text='Beginner\'s Bow\n'},
                {text='May your aim be true'}
            },
            image = {
                path = assets.dk_items,
                frames = {{x=144, y=106, w=16, h=22}},
                sx = WPN_SCALE,
                ox = 8, oy = 11,
            },
            render_on_character = {x=16, y=0, z=zindex.equipped_item_back},
            attack_animation = {
                shoot = {
                    projectile = {
                        image = {
                            path = assets.dk_items,
                            frames = {{x=161, y=128, w=14, h=16}},
                            sx = WPN_SCALE,
                            ox = 7, oy = 8,
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
            id = 'starter_tome',
            type = 'weapon',
            class_starter = 'mage',
            stats_ratio = items.stats{int=WPN_STATS_RATIO},
            label = {
                {text='Beginner\'s Tome\n'},
                -- TODO event
                -- A fallen lord hides his name among twisted words.
                --
                -- Im truly old 
                -- - Bad Tom
                {text="A strange quote is written on the first page"}
            },
            render_on_character = {x=15, y=4, z=zindex.equipped_item_front},
            image = {
                path = assets.dk_items,
                frames = {{x=208, y=128, w=13, h=16}},
                sx = 1.25,
                ox = 6.5, oy = 8,
                r = 45/2,
            },
            attack_animation = {
                shoot = {
                    projectile = {
                        image = {
                            path = assets.dk_items,
                            frames = {{x=226, y=67, w=11, h=11}},
                            ox = 5.5, oy = 5.5,
                        }
                    }
                }
            }
        }

        -- rogue
        items.add{
            id = 'starter_knife',
            type = 'weapon',
            class_starter = 'rogue',
            stats_ratio = items.stats{str=WPN_STATS_RATIO},
            label = {
                {text='Beginner\'s Knife\n'},
                {text='Sharpens as you use it!'}
            },
            render_on_character = {x=0, y=0, z=zindex.equipped_item_back},
            image = {
                path = assets.dk_items,
                frames = {{x=48, y=144, w=16, h=16}},
                sx = WPN_SCALE,
                ox = 8, oy = -3,
            },
            attack_animation = {
                shoot = {
                    projectile = {
                        image = {
                            path = assets.dk_items,
                            frames = {{x=48, y=144, w=16, h=16}},
                            sx = WPN_SCALE,
                            ox = 8, oy = -3,
                        },
                    }
                }
            }
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