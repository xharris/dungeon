local rad = math.rad
local easing = require 'lib.easing'

return {
    DEBUG_RENDER = {
        ENABLED = false,
        SHOW_ID = false,
    },
    COMBAT = {
        BASE_ATTACK_DURATION = 800, -- 750,
    },
    DEBUG_PROJECTILES = false,
    LOG = {
        METHODS_LEVEL = 'debug',
        CONSOLE_LEVEL = 'debug',
        ERROR_ROWS = 15,
        WRITE_APPEND = false,
        HEADER = {
            debug       = '[DEBUG]',
            info        = '[INFO]',
            warn        = '[WARN]',
            error       = '[ERROR]',
        }
    },
    STAGE = {
        EASE_DURATION = 3000,
        EASE_FN = easing.ease_in_out_sine
    },
    FLOOR = {
        Y = 300 * (3/5),
        VISIBLE = true,
    },
    SKY = {
        SEGMENTS = 10,
    },
    JUMP_VELOCITY = -300,
    MAX_JUMPS = 0,
    BOUNCE_VY_THRESHOLD = -70,
    CHAR_ARRANGE_SEP = 32,
    GAIN_ABILITY_COOLDOWN = 5,
    RARITY_SCALE_MAX = 1,
    RARITY_SCALE_MIN = 0.5,
    ---@type Stats
    BASE_STATS = {agi=5, int=0, str=5},
    HEALTH = 100,
    CRITICAL_DAMAGE = 1.5,
    MAX_EQUIPPED_ITEMS = 5,
    MAX_INVENTORY_ITEMS = 5,
    PROJECTILE_DURATION = 1000,
    FONT_SIZE = 12,
    ITEM_SWING = {
        UP_ANGLE = rad(-45),
        DOWN_ANGLE = rad(130),
    }
}