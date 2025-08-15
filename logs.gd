extends Resource
class_name Logger

enum Level {NONE, ERROR, WARN, INFO, DEBUG}
static var max_prefix_length = 0

@export var _level:Level = Level.INFO
@export var _prefix:String = "":
    set(v):
        v = v if v != null else ""
        _prefix = v.strip_edges()
        _update_full_prefix()
@export var _id:String = "":
    set(v):
        v = v if v != null else ""
        _id = v.strip_edges()
        _update_full_prefix()
@export var ignore_repeats = false

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

func info(msg:String):
    if _level < Level.INFO: return
    _print(Color.SKY_BLUE, "INFO", msg)
    
func warn(msg:String):
    if _level < Level.WARN: return
    if _print(Color.YELLOW, "WARN", msg):
        push_warning(msg)	

func debug(msg:String):
    if _level < Level.DEBUG: return
    _print(Color.GREEN_YELLOW, "DEBUG", msg)

func error(cond:bool, msg:String) -> bool:
    if _level < Level.ERROR and not cond:
        _print(Color.RED, "ERROR", msg)
    assert(cond, msg)
    return not cond
