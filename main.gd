extends Node2D
class_name Main

static var TITLE_ROOM:RoomConfig = preload("res://src/rooms/title.tres")
static var STARTING_ZONE:ZoneConfig = preload("res://src/zones/forest/forest.tres")

var logs = Logger.new("main")

@onready var _game:Game = $Game
@onready var pause_controller:PauseController = %PauseController

func _ready() -> void:
    Util.main_node = self
    _game.over.connect(_on_game_over)
    _game.start()
    
func _on_game_over(_type:Game.GameOverType):
    _game.restart()
