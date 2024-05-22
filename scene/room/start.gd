extends Node2D

static var l = Logger.create("start")

@export var room:Room
@export var normal_door:Door
@export var random_door:Door

var _mode_chosen = false
var _mode:Game.Mode

func _ready():
	normal_door.opened.connect(_on_mode_change.bind(Game.Mode.Normal))
	random_door.opened.connect(_on_mode_change.bind(Game.Mode.Random))
	room.exited.connect(_on_room_exited)
	for p in get_tree().get_nodes_in_group(Player.Group):
		(p as Player).radial_light.enabled = true
	
func _process(delta):
	# wrap player
	var camera = %Camera2D
	#camera.global_position = player.global_position # lerp(camera.global_position, player.global_position, delta)

func _on_room_exited(p:Player):
	l.debug("turn off player light")
	p.radial_light.enabled = false

func _on_mode_change(new_mode:Game.Mode):
	l.debug("selecting {mode}",{"mode":Game.Mode.find_key(new_mode)})
	Game.mode = new_mode
