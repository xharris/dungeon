extends Node2D
class_name Room

static var l = Logger.create("room")

signal exited

@export var top_entrance:Door
@export var mid_entrance:Door
@export var bot_entrance:Door
@export var top_exit:Door
@export var mid_exit:Door
@export var bot_exit:Door
@export var start_direction:Vector2i = Vector2i(1, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	var entrances:Array[Door] = get_entrances()
	# put player at entrance
	var player := get_tree().get_first_node_in_group(Player.Group) as Player
	if player && entrances.size():
		var player_entrance := entrances.pick_random() as Door
		player.global_position = player_entrance.global_position
	# initial player direction
	if player:
		l.info(start_direction)
		player.movement.direction = start_direction
	# close entrances
	for entrance in entrances:
		if entrance == null:
			continue
		entrance.close()
	# connect exit
	var exits:Array[Door] = [top_exit, mid_exit, bot_exit]
	for exit in exits:
		if exit == null:
			continue
		exit.player_entered.connect(_on_door_player_entered, CONNECT_ONE_SHOT)
		
func _on_door_player_entered(player:Player):
	exited.emit()
	Game.go_to_next_room()

func get_entrances() -> Array[Door]:
	var doors:Array[Door] = []
	doors.assign([top_entrance, mid_entrance, bot_entrance].filter(func(r): return r != null))
	return doors

func get_exits() -> Array[Door]:
	var doors:Array[Door] = []
	doors.assign([top_exit, mid_exit, bot_exit].filter(func(r): return r != null))
	return doors
