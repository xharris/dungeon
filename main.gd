extends Node2D

@onready var camera = $Camera2D
@onready var environment = $Environment
@onready var characters = $Characters

const scn_character = preload("res://character/character.tscn")

const items:Array[Item] = [
    preload("res://items/sword/sword.tres")
]

func _ready() -> void:
    var player = Game.get_player()
    if player:
        player.inventory.add_item(items[0])
        player.move_to_x(200)
    else:
        Logs.warn("player not found")
    Rooms.create_next_room.connect(_on_create_next_room)

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
        x += Rooms.position.x
        for character in get_tree().get_nodes_in_group(group):
            if character is Character:
                character.move_to_x(x)
                x += group_sep[group]

func _on_camera_tween_finished():
    # enable combat
    for character in get_tree().get_nodes_in_group("character") as Array[Character]:
        character.state.combat = true

func _on_create_next_room():
    # move camera to current Rooms
    var tween = camera.create_tween()
    var prop = tween.tween_property(camera, "position", Rooms.position, 3)
    prop.set_trans(Tween.TransitionType.TRANS_QUAD)
    prop.set_ease(Tween.EaseType.EASE_IN_OUT)
    tween.finished.connect(_on_camera_tween_finished)
    tween.play()
    
    # disable combat
    for character in get_tree().get_nodes_in_group("character") as Array[Character]:
        character.state.combat = false
    environment.expand()
    
    # spawn enemies
    var enemy = scn_character.instantiate()
    enemy.add_to_group("enemy")
    enemy.global_position.x = Rooms.position.x + Game.size.x
    enemy.global_position.y = Game.size.y / 2
    characters.add_child(enemy)
    Logs.info("enemy spawned at %s" % enemy.global_position)
    
    arrange_characters()
    
## play game
func _on_button_pressed() -> void:
    Logs.info("pressed play")
    Rooms.next_room()
