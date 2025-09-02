extends Node2D
class_name GameEnvironment

@onready var _floor:Polygon2D = $Floor
@onready var _duplicates:Node2D = $Duplicates
var logs = Logger.new("game_environment")
#var floors:Array[Polygon2D]
#
func _ready() -> void:
    Events.trigger_game_restart.connect(_on_trigger_game_restart)
    
    _floor.position.x -= Util.size.x * 2
    _floor.scale.x *= 3

func _on_trigger_game_restart():
    Util.clear_children(_duplicates)

func expand():
    # get last floor created
    var last_floor = _floor
    var dupes = _duplicates.get_children()
    if dupes.size() > 0:
        last_floor = dupes.back()
    # duplicate it
    var new_floor = last_floor.duplicate() as Polygon2D
    _duplicates.add_child(new_floor)
    # move it to new position
    var xoff = Util.size.x
    new_floor.position.x += xoff
    logs.info("expand, xoff=%d, position=%.0v" % [xoff, new_floor.position])
