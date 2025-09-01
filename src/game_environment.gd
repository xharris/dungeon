extends Node2D
class_name GameEnvironment

@onready var _floor:Polygon2D = $Floor
var logs = Logger.new("game_environment")
var _initial_position:Vector2
#var floors:Array[Polygon2D]
#
func _ready() -> void:
    _floor.position.x -= Util.size.x * 2
    _floor.scale.x *= 3
    _initial_position = _floor.position

func expand():
    _floor.position.x += Util.size.x
    
func reset():
    logs.info("reset, initial position=%.1v" % [_initial_position])
    _floor.position = _initial_position
