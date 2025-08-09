extends Node2D

var logs = Logger.new("main")

@onready var camera = $GameCamera as GameCamera
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
        logs.warn("player not found")
    Rooms.create_next_room.connect(_on_create_next_room)

enum GroupSide {Left, Right}

# arrange all characters to their designated side of the screen
func arrange_characters():
    var side_size = Game.size.x / 3
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
        
    var move_signals:Array[Signal] = []
    for group in group_sep:
        var side:GroupSide = group_side[group]
        var x = (0.0 if side == GroupSide.Left else side_size)
        x += (side_size / 2)
        x += Rooms.position.x
        for character in get_tree().get_nodes_in_group(group):
            if character is Character:
                move_signals.append(character.move_to_finished)
                character.move_to_x(x)
                x += group_sep[group]
    
    await Async.all(move_signals)

func _on_create_next_room():
    # move camera to current Rooms
    camera.move_to(Rooms.position)
    
    # disable combat
    for character in get_tree().get_nodes_in_group("character") as Array[Character]:
        character.state.combat = false
    environment.expand()
    
    # spawn test enemy
    var enemy = scn_character.instantiate()
    enemy.id = "enemy"
    enemy.add_to_group("enemy")
    enemy.global_position.x = Rooms.position.x + (Game.size.x * 3/5)
    enemy.global_position.y = Game.size.y / 2
    characters.add_child(enemy)
    
    await arrange_characters()
    
    # enable combat
    for character in get_tree().get_nodes_in_group("character") as Array[Character]:
        character.enable_combat()
    
## play game
func _on_button_pressed() -> void:
    logs.info("pressed play")
    Rooms.next_room()
