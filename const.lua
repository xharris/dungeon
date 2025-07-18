return {
    DEBUG_RENDER = false,
    DEBUG_PROJECTILES = true,
    ---@type LogLevel
    LOG_METHODS_LEVEL = 'debug',
    ---@type LogLevel
    LOG_CONSOLE_LEVEL = 'debug',
    WRITE_LOGS_APPEND = false,
    HEALTH = 100,
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
        error       = '[ERR]',
    },
    RARITY_SCALE_MAX = 1,
    RARITY_SCALE_MIN = 0.5,
    ---@type table<Class, Stats>
    CLASS_STATS = {
        warrior     = {agi=0,  int=0,     str=75},
        archer      = {agi=0,  int=25,    str=50},
        mage        = {agi=0,  int=75,    str=0},
        rogue       = {agi=10, int=25,    str=50},
    },
    MAX_EQUIPPED_ITEMS = 5,
    MAX_INVENTORY_ITEMS = 5,
    PROJECTILE_DURATION = 1000,
}