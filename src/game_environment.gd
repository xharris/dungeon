extends Node2D
class_name GameEnvironment

@onready var _floor:Polygon2D = $Floor
#var floors:Array[Polygon2D]
#
func _ready() -> void:
    _floor.position.x -= Util.size.x * 2
    _floor.scale.x *= 3

func expand():
    _floor.position.x += Util.size.x
    
func reset():
    _floor.position.x = -Util.size.x * 2
