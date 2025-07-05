local events = require 'events'
local dialog = require 'dialog'
local log = require 'lib.log'
local ctrl = require 'lib.controls'
local color = require 'lib.color'
local char = require 'character'
local lume = require 'ext.lume'
local combat = require 'combat'
local items = require 'items'

local REST_HEAL_AMOuNT = 20
local MEDIC_HEAL_AMOUNT = 20
local MEDIC_TIP_AMOUNT = 12
local MEDIC_TIPS = {
    "Plant your corn early next year!",
    "Buy low, sell high!",
    "Never play leap frog with a unicorn!",
}

return {
    -- related_plugins = {'warrior'}, -- TODO ?
    on_load = function()
        items.add{
            id = 'big_stick',
            type = 'weapon',
            label = {
                {text='Big Stick\n'},
                {text='Found somewhere in the forest'}
            },
            shop_disabled = true,
            modify_stats = function (stats)
                stats.str = stats.str + 3
            end
        }

        combat.add_enemy{
            id = 'goblin',
            items = {{id='big_stick'}},
            health = {current=6, max=6},
            stats = {agi=0, str=3}
        }

        events.add{
            id = 'cozy_cabin',
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
                        char.add_health(e, REST_HEAL_AMOuNT)
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
            id = 'medic',
            on_start = function(e)
                if e.health.current >= e.health.max then
                    -- doesn't need healing
                    dialog.add{
                        texts={{text="How do you do?"}},
                        choices={
                            {id="good", texts={{text="I'm fine"}}},
                            {id="food", texts={{text="Do you have any food?"}}}
                        }
                    }
                else
                    -- offer to heal
                    dialog.add{texts={{text="You don't looks so good..."}}}
                    dialog.add{
                        texts={{text="I can try to heal your injuries."}},
                        choices={
                            {id="accept_heal",texts={{text="Sure."}}},
                            {id="decline_heal",texts={{text="No thanks..."}}}
                        }
                    }
                end
            end,
            on_update = function(dt, e)
                if ctrl:pressed 'select' then
                    local choice_id = dialog.selected_choice()
                    
                    if choice_id == "good" then
                        dialog.add{texts={{text="That's nice."}}}

                    elseif choice_id == "food" then
                        dialog.add{texts={{text="I have lots of food!"}}}
                        dialog.add{texts={{text="Bye."}}}

                    elseif choice_id == "accept_heal" then
                        char.add_health(e, MEDIC_HEAL_AMOUNT)
                        dialog.add{
                            texts={{text="There you go! That should help."}},
                            choices={
                                {id="tip",texts={{text="Leave a tip."}}},
                                {id="leave",texts={{text="Leave."}}}
                            }
                        }

                    elseif choice_id == "decline_heal" then
                        dialog.add{texts={{text="Okay, well good luck out there."}}}

                    elseif choice_id == "tip" then
                        local tip = math.min(e.money, MEDIC_TIP_AMOUNT)
                        if tip > 0 and char.add_money(e, -tip) then
                            -- give money
                            dialog.add{texts={
                                {text="You tip the kind medic "},
                                {text="$"..tostring(tip), color=color.MUI.GREEN_500},
                                {text="."}
                            }}
                            dialog.add{texts={{text="Thanks! Be seeing you..."}}}
                        else
                            -- no money to give, no more medic
                            dialog.add{texts={{text=lume.randomchoice(MEDIC_TIPS)}}}
                            dialog.add{texts={{text="..."}}}
                            events.disable("medic")
                        end
                    end
                end

                if not dialog.is_in_progress() then
                    events.end_event()
                end
            end
        }
    end,
} --[[@as PluginOptions]]