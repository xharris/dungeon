extends Node2D
class_name Main

static var TITLE_ROOM:RoomConfig = preload("res://src/rooms/title.tres")
static var STARTING_ZONE:ZoneConfig = preload("res://src/zones/forest/forest.tres")

var logs = Logger.new("main")

@onready var _game:Game = $Game
@onready var pause_controller:PauseController = %PauseController

func _init() -> void:
    #Logger.set_global_level(Logger.Level.DEBUG)
    Util.main_node = self

func _ready() -> void:
    _setup_game()
    _game.start()
    
func _setup_game():
    _game.over.connect(_on_game_over)
    
func _on_game_over(_type:Game.GameOverType):
    # destroy current game
    _game.destroy()
    # create new game
    var new_game = Scenes.GAME.instantiate()
    _game = new_game
    _setup_game()
    add_child(new_game)
    #new_game.start()
