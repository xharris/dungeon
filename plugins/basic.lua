local events = require 'events'
local dialog = require 'dialog'
local log = require 'lib.log'
local ctrl = require 'lib.controls'

return {
    on_load = function()
        events.add{
            id = 'medic',
            on_start = function(e)
                if e.health.current >= e.health.max then
                    dialog.add{
                        texts={{text="How do you do?"}},
                        choices={
                            {id="good", texts={{text="I'm fine"}}},
                            {id="food", texts={{text="Do you have any food?"}}}
                        }
                    }
                else
                    dialog.add{texts={{text="You don't looks so good..."}}}
                    dialog.add{
                        texts={{text="I can try to heal your injuries."}},
                        choices={
                            {id="accept_heal",texts={{text="Sure."}}},
                            {id="decline_heal",texts={{text="No thanks..."}}}
                        }
                    }
                    -- TODO offer to heal for money
                end
            end,
            on_update = function(dt, e)
                if ctrl:pressed 'select' then
                    local choice_id = dialog.selected_choice()
                    if choice_id == "good" then
                        dialog.add{texts={{text="That's nice."}}}
                        events.end_event()
                    elseif choice_id == "food" then
                        dialog.add{texts={{text="I have lots of food!"}}}
                        dialog.add{texts={{text="Bye."}}}
                        events.end_event()
                    elseif choice_id == "accept_heal" then
                        events.end_event()
                    elseif choice_id == "decline_heal" then
                        events.end_event()
                    end
                end
            end
        }
    end,
} --[[@as PluginOptions]]