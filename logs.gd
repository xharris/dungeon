extends Resource
class_name Logger

enum Level {NONE, ERROR, WARN, INFO, DEBUG}
static var max_prefix_length = 0
static var _global_level:Level = Level.NONE

static func set_global_level(level:Level):
    print("[color=%s][b]set global log level %s[/b][/color]" % [Color.WHITE, Level.find_key(level)])
    _global_level = level

@export var ignore_repeats = false
var _level:Level = Level.INFO
var _prefix:String = "":
    set(v):
        v = v if v != null else ""
        _prefix = v.strip_edges()
        _update_full_prefix()
var _id:String = "":
    set(v):
        v = v if v != null else ""
        _id = v.strip_edges()
        _update_full_prefix()
var _full_prefix:String = ""
var _prev_msg:String

func _init(id:String = "", level:Level = Level.INFO) -> void:
    _id = id
    _level = level

func _update_full_prefix():
    var parts:Array[String] = []
    if _prefix.length() > 0:
        parts.append(_prefix)
    if _id.length() > 0:
        parts.append(_id)
    _full_prefix = ".".join(parts)
    if _full_prefix.length() > max_prefix_length:
        max_prefix_length = _full_prefix.length()

func set_level(level:Level) -> Logger:
    _level = level
    return self

func set_prefix(prefix:String) -> Logger:
    _prefix = prefix
    return self

func set_id(id:String) -> Logger:
    _id = id
    return self

func _print(color:Color, level:String, msg:String) -> bool:
    var pad = max(0, max_prefix_length - _full_prefix.length())
    var formatted = "[color=%s][b]%s[/b][/color] \t%s %s %s" % [
        color.to_html(), level, 
        _full_prefix, " ".repeat(pad),
        msg
    ]
    if formatted == _prev_msg and ignore_repeats:
        return false # avoid printing same message twice
    _prev_msg = formatted
    print_rich(formatted)
    return true

func _is_level_enabled(level:Level) -> bool:
    if Logger._global_level != Level.NONE:
        return Logger._global_level >= level
    return _level >= level

func info(msg:String):
    if not _is_level_enabled(Level.INFO): return
    _print(Color.SKY_BLUE, "INFO", msg)
    
func warn(msg:String):
    if not _is_level_enabled(Level.WARN): return
    if _print(Color.YELLOW, "WARN", msg):
        push_warning(msg)	

## prints warning if [code]cond[/code] is [code]true[/code]
##
## Returns: [code]cond[/code]
func warn_if(cond:bool, msg:String) -> bool:
    if cond:
        warn(msg)
    return cond

func debug(msg:String):
    if not _is_level_enabled(Level.DEBUG): return
    _print(Color.GREEN_YELLOW, "DEBUG", msg)

## prints debug msg if [code]cond[/code] is [code]true[/code]
##
## Returns: [code]cond[/code]
func debug_if(cond:bool, msg:String) -> bool:
    if cond:
        debug(msg)
    return cond

## raises error if [code]cond[/code] is [code]true[/code]
##
## Returns: [code]cond[/code]
func error(cond:bool, msg:String) -> bool:
    if _is_level_enabled(Level.ERROR) and cond:
        _print(Color.RED, "ERROR", msg)
    assert(not cond, msg)
    return cond
