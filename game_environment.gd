extends Node2D
class_name GameEnvironment

@onready var floor:Polygon2D = $Floor
#var floors:Array[Polygon2D]
#
func _ready() -> void:
    floor.position.x -= Game.size.x * 2
    floor.scale.x *= 3

func expand():
    floor.position.x += Game.size.x
    
func reset():
    floor.position.x = -Game.size.x * 2
