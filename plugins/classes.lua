local items = require 'items'
local assets = require 'assets.index'
local zindex = require 'zindex'
local stats  = require 'stats'
local game = require 'game'
local lang = require 'lib.i18n'
local const= require 'const'

local WPN_STATS_RATIO = 0.25

---@class CursedSwordData
---@field no_death_time_left? number

--[[
CLASS_STATS = {
    warrior     = {agi=0,  int=0,     str=75},
    archer      = {agi=0,  int=25,    str=50},
    mage        = {agi=0,  int=75,    str=0},
    rogue       = {agi=10, int=25,    str=50},
}
]]

return {
    on_load = function ()
        lang.set('en', {
            -- adventurer
            ---- warrior
            warrior_starter = 'Wooden Sword',
            warrior_starter_description = 'Capable of dealing some damage',
            ------ fighter
            fighter = 'Fighter Training',
            fighter_description = 'Crit Chance + 15%',
            fighter_2 = 'Fast Fighter',
            fighter_2_description = 'Critical strikes deal no bonus damage, but grant +1 AGI',
            fighter_3 = 'Brutal Fighter',
            fighter_3_description = 'Critical strikes deal no bonus damage, but grant +1 STR',
            ------ shield
            shield = 'Hero Shield',
        })

        -- warrior
        items.add{
            id = "warrior_starter",
            is_starter = true,
            class = 'adventurer',
            image = {
                path = assets.dk_items,
                frames = {{x=48, y=104, w=16, h=24}},
                ox = 8, oy = -2,
            },
            transform_stats = {
                ['stats.str'] = {operation='add', value=75},
            },
            damage_scaling = stats.create{str=WPN_STATS_RATIO},
            render_on_character = {},
            attack_animation = {
                swing = {}
            },
        }
        -- warrior subclasses
        items.abilities.add{
            id = 'fighter',
            class = "warrior",
            requires_items = {'warrior_starter'},
            requires_class = {'adventurer'},
            transform_stats = {
                ['stats.str'] = {operation='add', value=120},
            },
            rarity = 'rare',
            user_will_die = function (data, e)
                ---@cast data CursedSwordData
                if data.no_death_time_left == nil then
                    data.no_death_time_left = 3000
                    return true
                end
                if data.no_death_time_left <= 0 then
                    return false -- times up
                end
                data.no_death_time_left = data.no_death_time_left - (game.dt * 1000)
                e.health.current = 1
            end
        }
        items.abilities.add{
            id = "shield",
            class = "warrior",
            requires_items = {'warrior_starter'},
            requires_class = {'adventurer'},
        }
        

        -- archer
        -- items.add{
        --     id = "starter_bow",
        --     class_starter = 'archer',
        --     stats_ratio = items.stats{str=WPN_STATS_RATIO},
        --     label = {
        --         {text='Beginner\'s Bow\n'},
        --         {text='May your aim be true'}
        --     },
        --     image = {
        --         path = assets.dk_items,
        --         frames = {{x=144, y=106, w=16, h=22}},
        --         sx = WPN_SCALE,
        --         ox = 8, oy = 11,
        --     },
        --     render_on_character = {x=16, y=0, z=zindex.equipped_item_back},
        --     attack_animation = {
        --         shoot = {
        --             projectile = {
        --                 image = {
        --                     path = assets.dk_items,
        --                     frames = {{x=161, y=128, w=14, h=16}},
        --                     sx = WPN_SCALE,
        --                     ox = 7, oy = 8,
        --                 },
        --                 ease_fn = easing.ease_in_quad,
        --                 face_direction = true,
        --                 curve = {
        --                     0,      0,
        --                     0.5, -0.5,
        --                     1,      0,
        --                 },
        --                 curve_sy = 200,
        --             },
        --         },
        --     },
        -- }

        -- mage
        -- items.add{
        --     id = 'starter_tome',
        --     class_starter = 'mage',
        --     stats_ratio = items.stats{int=WPN_STATS_RATIO},
        --     label = {
        --         {text='Beginner\'s Tome\n'},
        --         -- TODO event
        --         -- A fallen lord hides his name among twisted words.
        --         --
        --         -- Im truly old 
        --         -- - Bad Tom
        --         {text="A strange quote is written on the first page"}
        --     },
        --     render_on_character = {x=15, y=4, z=zindex.equipped_item_front},
        --     image = {
        --         path = assets.dk_items,
        --         frames = {{x=208, y=128, w=13, h=16}},
        --         sx = 1.25,
        --         ox = 6.5, oy = 8,
        --         r = 45/2,
        --     },
        --     attack_animation = {
        --         shoot = {
        --             projectile = {
        --                 image = {
        --                     path = assets.dk_items,
        --                     frames = {{x=226, y=67, w=11, h=11}},
        --                     ox = 5.5, oy = 5.5,
        --                 }
        --             }
        --         }
        --     }
        -- }

        -- -- rogue
        -- items.add{
        --     id = 'starter_knife',
        --     class_starter = 'rogue',
        --     stats_ratio = items.stats{str=WPN_STATS_RATIO},
        --     label = {
        --         {text='Beginner\'s Knife\n'},
        --         {text='Sharpens as you use it!'}
        --     },
        --     render_on_character = {x=0, y=0, z=zindex.equipped_item_back},
        --     image = {
        --         path = assets.dk_items,
        --         frames = {{x=48, y=144, w=16, h=16}},
        --         sx = WPN_SCALE,
        --         ox = 8, oy = -3,
        --     },
        --     attack_animation = {
        --         shoot = {
        --             projectile = {
        --                 image = {
        --                     path = assets.dk_items,
        --                     frames = {{x=48, y=144, w=16, h=16}},
        --                     sx = WPN_SCALE,
        --                     ox = 8, oy = -3,
        --                 },
        --             }
        --         }
        --     }
        -- }
    end
} --[[@as PluginOptions]]