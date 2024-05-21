extends Node2D

static var l = Logger.create("start")

@export var player:Player
@export var room:Room
@export var easy_door:Door
@export var hard_door:Door

var _mode_chosen = false
var _mode:String = ""

func _ready():
	#player.movement.changed_direction.connect(_on_changed_direction)
	easy_door.opened.connect(_on_mode_change.bind(Game.Easy))
	hard_door.opened.connect(_on_mode_change.bind(Game.Hard))
	easy_door.player_entered.connect(_on_room_exited)
	hard_door.player_entered.connect(_on_room_exited)

func _process(delta):
	# wrap player
	var vr = get_viewport_rect()
	var m = 32
	if player.global_position.x > vr.size.x + m:
		player.global_position.x = -m
	if player.global_position.x < -m:
		player.global_position.x = vr.size.x + m
	if player.global_position.y > vr.size.y + m:
		player.global_position.y = -m
	if player.global_position.y < -m:
		player.global_position.y = vr.size.y + m
	var camera = %Camera2D
	camera.global_position = player.global_position # lerp(camera.global_position, player.global_position, delta)
		
func _on_room_exited(mode:String):
	l.info("unlock player")
	_mode = mode
	player.restrict_velocity_x = false
	player.restrict_velocity_y = false

func _on_mode_change(mode_name:String):
	l.info("selecting {mode}",{"mode":mode_name})
	Game.mode = mode_name.to_lower()

func _on_mode_exited_area():
	l.info("cleared selection")
	_mode = ""
