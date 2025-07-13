local items = require 'items'
local assets = require 'assets.index'

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
                frames = {{x=160, y=128, w=16, h=16}},
            },
            stats_ratio = items.stats{str=WPN_STATS_RATIO},
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
        }

        -- mage
        items.add{
            id = 'starter_wand',
            type = 'weapon',
            class_starter = 'mage',
            stats_ratio = items.stats{int=WPN_STATS_RATIO},
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