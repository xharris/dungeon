extends Node2D
class_name ActionText

@onready var _label = $CenterContainer/RichTextLabel

@export var text:String = "":
    set(v):
        text = v
        _label.text = text

var velocity:Vector2

func _process(delta: float) -> void:
    global_position += velocity * delta
