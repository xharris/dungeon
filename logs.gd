extends Resource
class_name Logger

static var max_prefix_length = 0

@export var _prefix:String = ""
var _prev_msg:String

func _init(prefix:String) -> void:
    set_prefix(prefix)

func set_prefix(prefix:String) -> Logger:
    _prefix = prefix
    if _prefix.length() > max_prefix_length:
        max_prefix_length = _prefix.length()
    return self

func _print(color:Color, level:String, msg:String) -> bool:
    var pad = max(0, max_prefix_length - _prefix.length())
    var formatted = "[color=%s][b]%s[/b][/color] \t%s %s %s" % [
        color.to_html(), level, 
        _prefix, " ".repeat(pad),
        msg
    ]
    if formatted == _prev_msg:
        return false # avoid printing same message twice
    _prev_msg = formatted
    print_rich(formatted)
    return true

func info(msg:String):
    _print(Color.SKY_BLUE, "INFO", msg)
    
func warn(msg:String):
    if _print(Color.YELLOW, "WARN", msg):
        push_warning(msg)	

func debug(msg:String):
    _print(Color.GREEN_YELLOW, "DEBUG", msg)
