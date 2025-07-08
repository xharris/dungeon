local items = require 'items'
local assets = require 'assets.index'

return {
    on_load = function ()
        items.add{
            id = "rusty_sword",
            type = "weapon",
            starter_item = true,
            label = {
                {text='Rusty Sword\n'},
                {text='It does a little damage'},
            },
            image = {
                path = assets.dk_items,
                frames = {{x=160, y=128, w=16, h=16}},
            },
            modify_stats = function (stats)
                stats.str = stats.str + 10
            end
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