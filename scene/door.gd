extends Node2D
class_name Door

static var l = Logger.create("door")

signal player_entered(player:Player)
signal opened
signal closed

@export var is_open = false
## Open when the player get nearby
@export var proximity_open = false

var _player_entered = false

func _process(delta):
	if proximity_open:
		var players:Array[Player] = []
		players.assign(get_tree().get_nodes_in_group(Player.Group))
		var nearby = false
		for player in players:
			if player.global_position.distance_to(global_position) < 64:
				nearby = true
		if nearby:
			open()
		else:
			close()
		
func open():
	if !is_open:
		var sprite = %Sprite2D as AnimatedSprite2D
		sprite.play("open")
		opened.emit()
	is_open = true
	
func close():
	if is_open:
		var sprite = %Sprite2D as AnimatedSprite2D
		sprite.play("closed")
		closed.emit()
	is_open = false

func _on_area_2d_body_entered(body):
	var parent = body.get_parent() as Player
	if parent != null && is_open && !_player_entered:
		_player_entered = true
		player_entered.emit(parent)
	
