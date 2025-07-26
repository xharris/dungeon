local dungeon = require 'dungeon'
local items = require 'items'
local combat = require 'combat'
local events = require 'events'
local dialog = require 'dialog'
local ctrl = require 'lib.controls'
local char = require 'character'
local assets = require 'assets.index'
local theme = require 'theme'

local REST_HEAL_AMOuNT = 20

return {
    on_load = function ()
        items.add{
            id = 'big_stick',
            type = 'weapon',
            description = {
                {text='Big Stick\n'},
                {text='Found somewhere in the forest'}
            },
            image = {
                path = assets.dk_items,
                frames = {{x=160, y=128, w=16, h=16}},
            },
            shop_disabled = true,
            damage_scaling = {agi=0, int=0, str=0.2},
        }

        items.add{
            id = 'slime_shot',
            type = 'weapon',
            shop_disabled = true,
            damage_scaling = {agi=0, int=0, str=1},
        }

        combat.enemy.add{
            id = 'goblin',
            inventory = {{id='big_stick'}},
            equipped_items = {1},
            stats = {agi=100, str=10, int=0},
            image = {
                path = assets.dk_items,
                frames = {{x=160, y=128, w=16, h=16}},
            },
            character_sprite = {
                default_expression = 'angry',
            }
        }

        combat.enemy.add{
            id = 'slime',
            health = {current=40, max=40},
            stats = {agi=1, str=1, int=0},
        }

        events.add{
            id = 'cozy_cabin',
            rarity = "rare",
            on_start = function (e)
                dialog.add{
                    texts={{text="You see a cozy looking cabin in the distance."}},
                    choices={
                        {id="rest",texts={{text="Go inside and rest."}}},
                        {id="pass",texts={{text="Ignore it."}}},
                    }
                }
            end,
            on_update = function (dt, e)
                if ctrl:pressed 'select' then
                    local choice_id = dialog.selected_choice()
                    if choice_id == "rest" then
                        char.add_health(e._id, REST_HEAL_AMOuNT)
                        dialog.add{texts={{text="You healed "..tostring(REST_HEAL_AMOuNT).." hp."}}}
                    
                    elseif choice_id == "pass" then
                        dialog.add{texts={{text="You ignore it and walk past."}}}
                    end
                end
                if not dialog.is_in_progress() then
                    events.end_event()
                end
            end
        }

        events.add{
            id = 'collect_sticks',
            on_start = function (e)
                local data = events.storage(e._id)
                if data.visits == 0 then
                    -- propose quest to collect sticks
                    dialog.add{
                        texts = {
                            {text="Oh noes!! Where did my stick pile go?! Did the wind blow them away?"},
                        }
                    }
                    dialog.add{
                        texts = {
                            {text="You there! Please help me! I'll starve in the winter without at least "},
                            {text="10 sticks", color=theme.color.quest_goal},
                            {text="!"}
                        },
                        choices = {
                            {id='accept', }
                        }
                    }
                    events.end_event()
                end
            end
        }

        -- events.add{
        --     id = 'lost_kid',
        --     on_start = function (e)
                
        --     end
        -- }

        -- events.add{
        --     id = 'combat_assist',
        --     on_start = function (e)

        --     end
        -- }

        dungeon.add_zone{
            id = 'forest',
            enemies = {'goblin'},
            events = {'cozy_cabin', 'collect_sticks', 'lost_kid', 'combat_assist'},
            can_return = true,
            setup_rooms = function (ctx, e)
                ctx.add_room{
                    id = 'rm_first_fight',
                    types = {'combat'},
                    doors = {'rm_event'},
                    spawn_room = true,
                }
                ctx.add_room{
                    id = 'rm_event',
                    types = {'event'},
                    doors = {'rm_fight_or_event'},
                }
                ctx.add_room{
                    id = 'rm_fight_or_event',
                    types = {'combat', 'event'},
                    doors = {'rm_boss'},
                }
                ctx.add_room{
                    id = 'rm_boss',
                    types = {'combat'},
                    combat_enemy_types = {'boss'},
                    rift_room = true,
                }
            end
        }
    end
} --[[@as PluginOptions]]