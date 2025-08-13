extends Node2D

var logs = Logger.new("main")

@onready var camera:GameCamera = $GameCamera
@onready var environment = $Environment
@onready var characters = $Characters
@onready var rooms = $Rooms

func _ready() -> void:
    Rooms.room_created.connect(_on_create_next_room)
    Rooms.room_finished.connect(_on_room_finished)
    Game.over.connect(_on_game_over)

    Game.start()

func _on_game_over():
    Game.reset()
    Game.start()

func _on_room_finished(room:Rooms.Room):
    # disable combat
    for c in Characters.get_all():
        c.disable_combat()

func _on_create_next_room(room:Rooms.Room):
    environment.expand()

    # add characters to tree
    for c in room.characters:
        characters.add_child(c)  

    # add room to tree
    rooms.add_child(room.node)
    
    # move camera to current Rooms
    camera.move_to(room.node.position + (Game.size / 2))
    
    await Characters.arrange_characters(room)
