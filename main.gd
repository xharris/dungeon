extends Node2D
class_name Main

var logs = Logger.new("main")

@onready var camera:GameCamera = $GameCamera
@onready var environment:GameEnvironment = $Environment
@onready var characters = $Characters
@onready var rooms = $Rooms
@onready var game_ui:GameUI = $GameUI

var ROOM_TEST_COMBAT:RoomConfig = preload("res://rooms/test_combat.tres")
var ZONE_FOREST:ZoneConfig = preload("res://zones/forest/forest.tres")

func _init() -> void:
    Util.main_node = self

func _ready() -> void:    
    Rooms.room_created.connect(_on_create_next_room)
    Rooms.room_finished.connect(_on_room_finished)
    Game.over.connect(_on_game_over)
    Game.start(game_ui)

func _on_game_over(_type:Game.GameOverType):
    Game.reset()
    camera.reset()
    environment.reset()
    Game.start(game_ui)

func _on_room_finished(room:Rooms.Room):
    # disable combat
    for c in Characters.get_all():
        c.disable_combat()
    Rooms.next_room(ZONE_FOREST.rooms.pick_random())

func _on_create_next_room(room:Rooms.Room):
    environment.expand()
    # add characters to tree
    for c in room.characters:
        characters.add_child(c)  
    # add room to tree
    rooms.add_child(room.node)
    # move camera to current room
    camera.move_to(room.node.position + (Game.size / 2))
    
    await Characters.arrange_characters(room)
