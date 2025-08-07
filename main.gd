extends Node2D

@onready var camera = $Camera2D
@onready var environment = $Environment
@onready var characters = $Characters

const scn_character = preload("res://character/character.tscn")

func _ready() -> void:
	var player = Game.get_player()
	if player:
		player.move_to_x(200)
	else:
		Logs.warn("player not found")

func _process(delta: float) -> void:
	camera.position.x = lerp(camera.position.x, Room.position.x, delta)

enum GroupSide {Left, Right}

# arrange all characters to their designated side of the screen
func arrange_characters():
	var side_size = Game.size.x / 2
	var group_side = {
		"player": GroupSide.Left,
		"ally": GroupSide.Left,
		"enemy": GroupSide.Right,
	}
	var group_count = {}
	var group_sep = {}
	for group in group_side:
		group_count[group] = get_tree().get_node_count_in_group(group)
	for group in group_count:
		var count = max(1, group_count[group])
		group_sep[group] = side_size / count
	for group in group_sep:
		var side:GroupSide = group_side[group]
		var x = 0.0 if side == GroupSide.Left else Game.size.x / 2
		x += Room.position.x
		for character in get_tree().get_nodes_in_group(group):
			if character is Character:
				character.move_to_x(x)
				x += group_sep[group]

## play
func _on_button_pressed() -> void:
	Logs.info("pressed play")
	Room.next_room()
	
	# expand floor
	environment.expand()
	
	# spawn enemies
	var enemy = scn_character.instantiate()
	enemy.add_to_group("enemy")
	enemy.global_position.x = Room.position.x + Game.size.x
	enemy.global_position.y = Game.size.y / 2
	characters.add_child(enemy)
	Logs.info("enemy spawned at %s" % enemy.global_position)
	
	arrange_characters()
