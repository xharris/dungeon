extends Node

var _prev_msg:String

func _print(color:Color, level:String, msg:String) -> bool:
    var caller = get_stack()[2]
    var formatted = "[color=%s][b]%s[/b][/color] \t%s (%s:%d)" % [color.to_html(), level, msg, caller["source"], caller["line"]]
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
