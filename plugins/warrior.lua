local items = require 'items'

return {
    on_load = function ()
        items.add{
            id = 'rusty_sword',
            type = 'weapon',
            label = {
                {text='Rusty Sword\n'},
                {text='Worn out, but can deal damage'}
            },
            modify_stats = function (stats)
                stats.str = stats.str + 3
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