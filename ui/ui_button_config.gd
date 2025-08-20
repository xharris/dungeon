extends Resource
class_name UIButtonConfig

static var logs = Logger.new("ui_button_config")

signal pressed

@export var id:String
@export var text:String:
    get:
        if text.length() == 0:
            logs.error(id.length() == 0, "button is missing id")                
            return id.capitalize()
        return text
@export var auto_focus:bool = false
@export var shadow_size:int = 10
@export var disabled:bool = false
@export var close_on_pressed:bool = false

func _init(_id:String = "") -> void:
    id = _id

func _to_string() -> String:
    return str(to_dict())

func to_dict() -> Dictionary:
    return {
        "id": id,
        "text": text,
        "auto_focus": auto_focus,
        "shadow_size": shadow_size,
        "disabled": disabled
    }
