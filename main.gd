extends Node2D
class_name Main

static var TITLE_ROOM:RoomConfig = preload("res://src/rooms/title.tres")
static var STARTING_ZONE:ZoneConfig = preload("res://src/zones/forest/forest.tres")

var logs = Logger.new("main")

@onready var game:Game = $Game
@onready var pause_controller:PauseController = %PauseController

func _init() -> void:
    #Logger.set_global_level(Logger.Level.DEBUG)
    Util.main_node = self

func _ready() -> void:
    game.over.connect(_on_game_over)
    game.start()
    
func _on_game_over(_type:Game.GameOverType):
    game.restart()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        pause_controller.toggle_pause()
