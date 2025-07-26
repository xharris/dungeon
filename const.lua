return {
    DEBUG_RENDER = {
        ENABLED = false,
        SHOW_ID = false,
    },
    COMBAT = {
        BASE_ATTACK_DURATION = 750,
    },
    DEBUG_PROJECTILES = false,
    ---@type LogLevel
    LOG_METHODS_LEVEL = 'debug',
    ---@type LogLevel
    LOG_CONSOLE_LEVEL = 'debug',
    WRITE_LOGS_APPEND = false,
    FLOOR_Y = 160,
    JUMP_VELOCITY = -300,
    MAX_JUMPS = 0,
    BOUNCE_VY_THRESHOLD = -70,
    CHAR_ARRANGE_SEP = 32,
    GAIN_ABILITY_COOLDOWN = 5,
    LOG_HEADER = {
        debug       = '[DEBUG]',
        info        = '[INFO]',
        warn        = '[WARN]',
        error       = '[ERROR]',
    },
    RARITY_SCALE_MAX = 1,
    RARITY_SCALE_MIN = 0.5,
    ---@type Stats
    BASE_STATS = {agi=0, int=0, str=0},
    HEALTH = 100,
    CRITICAL_DAMAGE = 1.5,
    MAX_EQUIPPED_ITEMS = 5,
    MAX_INVENTORY_ITEMS = 5,
    PROJECTILE_DURATION = 1000,
    FONT_SIZE = 12,
}