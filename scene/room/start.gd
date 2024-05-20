extends Node2D

static var l = Logger.create("start")

@export var player:Player
@export var modes:Array[ModeChoice]
@export var room:Room

var _mode_chosen = false
var _mode:String = ""
var _player_x_start = 0

func _ready():
	_player_x_start = player.global_position.x
	player.movement.direction.x = -1
	player.movement.changed_direction.connect(_on_changed_direction)
	for mode in modes:
		mode.entered_area.connect(_on_mode_entered_area)
		mode.exited_area.connect(_on_mode_exited_area)
	room.exited.connect(_on_room_exited, CONNECT_ONE_SHOT)

func _process(delta):
	if _mode_chosen:
		player.movement.direction.x = 1
		var camera = %Camera2D
		camera.global_position.x = lerp(camera.global_position.x, player.global_position.x, delta)
	else:
		player.movement.direction.x = -1
		# prevent player from moving but still loop background
		if abs(_player_x_start - player.global_position.x) > 32:
			player.global_position.x = _player_x_start
		# camera follow player exact position
		var camera = %Camera2D
		camera.global_position.x = player.global_position.x
		
func _on_room_exited():
	l.info("unlock player")
	player.restrict_velocity_x = false
	player.restrict_velocity_y = false

func _on_mode_entered_area(mode_name:String):
	l.info("selecting {mode}",{"mode":mode_name})
	_mode = mode_name

func _on_mode_exited_area():
	l.info("cleared selection")
	_mode = ""

func _on_changed_direction():
	if _mode == "":
		return
	l.info("confirm mode")
	Game.mode = _mode.to_lower()
	player.movement.changed_direction.disconnect(_on_changed_direction)
	_mode_chosen = true
	player.restrict_velocity_x = false
	player.restrict_velocity_y = true

