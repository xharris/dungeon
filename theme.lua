local c = require 'lib.color'

return {
    color = {
        quest_goal = c.MUI.ORANGE_500,
        dialog_bg = c.alpha(c.MUI.BLACK, 0.8),
        dialog_selected_outline = c.alpha(c.MUI.WHITE, 0.9),
        dialog_text = c.MUI.WHITE,
    },
    space = {
        dialog_pad = 10,
    }
}