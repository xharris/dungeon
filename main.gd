extends Node2D

var logs = Logger.new("main")

@onready var camera:GameCamera = $GameCamera
@onready var environment = $Environment
@onready var characters = $Characters

const main_config:RoomConfig = preload("res://rooms/main/main.tres")

func _ready() -> void:
    Rooms.create_next_room.connect(_on_create_next_room)
    Rooms.next_room(main_config)

func _on_create_next_room(room:Rooms.Room):
    # add characters to tree
    for c in room.characters:
        characters.add_child(c)  
        
    # add room to tree
    add_child(room.node)
    
    # move camera to current Rooms
    camera.move_to(room.node.position + (Game.size / 2))
    
    # disable combat
    for character in get_tree().get_nodes_in_group("character") as Array[Character]:
        character.state.combat = false
    environment.expand()
    
    await Characters.arrange_characters(room)
