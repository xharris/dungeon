return {
    DEBUG_RENDER = true,
    ---@type LogLevel
    LOG_METHODS_LEVEL = 'debug',
    ---@type LogLevel
    LOG_CONSOLE_LEVEL = 'info',
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
        warrior     = {agi=50,  int=25,     str=75},
        archer      = {agi=50,  int=25,     str=50},
        mage        = {agi=25,  int=75,     str=25},
        rogue       = {agi=75,  int=25,     str=50},
    },
    MAX_EQUIPPED_ITEMS = 5,
    MAX_INVENTORY_ITEMS = 5,
}