extends Node2D
class_name Room

static var l = Logger.create("room")
const Group = "room"

signal exited(player:Player)

# Called when the node enters the scene tree for the first time.
func _ready():
	# close entrances
	for entrance in get_doors(Door.Type.Entrance):
		if entrance == null:
			continue
		entrance.close()
	for door in get_doors(Door.Type.Exit):
		door.player_entered.connect(_on_exit_player_entered)
	
func _on_exit_player_entered(player:Player):
	exited.emit(player)

func get_all_doors() -> Array[Door]:
	var doors:Array[Door] = []
	doors.assign(get_parent().get_tree().get_nodes_in_group(Door.Group))
	return doors

func get_doors(type:Door.Type) -> Array[Door]:
	var doors:Array[Door] = []
	doors.assign(
		get_parent().get_tree().get_nodes_in_group(Door.Group).filter(func(d:Door): return d.type == type)
	)
	return doors
