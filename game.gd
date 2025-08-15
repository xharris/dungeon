extends Node

enum GameOverType {PLAYER_DEATH}

signal over(type:GameOverType)

var ROOM_MAIN:RoomConfig = preload("res://rooms/title/title.tres")
var logs = Logger.new("game")
var size:Vector2:
    get:
        return get_viewport().get_visible_rect().size
var _game_ui:GameUI
var _paused = false

func _ready() -> void:
    Characters.character_created.connect(_on_character_created)

func _on_character_created(c:Character):
    c.stats.death.connect(_on_character_death.bind(c), CONNECT_ONE_SHOT)

func _on_character_death(c:Character):
    if c.is_in_group(Groups.CHARACTER_PLAYER):
        logs.info("game over: player death")
        over.emit(GameOverType.PLAYER_DEATH)

func _on_state_popped(state:GameUI.State):
    if state == GameUI.State.PAUSE:
        resume()

func start(game_ui:GameUI):
    logs.info("game start")
    _game_ui = game_ui
    if not _game_ui.state_popped.is_connected(_on_state_popped):
        _game_ui.state_popped.connect(_on_state_popped)
    # create first room
    var room = Rooms.next_room(ROOM_MAIN)
    
func reset():
    logs.info("game reset")
    Characters.destroy_all()
    Rooms.destroy_all()

func is_over() -> bool:
    var player = Characters.get_player()
    return player and not player.stats.is_alive()

func get_ui() -> GameUI:
    return _game_ui # get_tree().get_first_node_in_group(Groups.GAME_UI) as GameUI

func toggle_pause():
    if _paused:
        resume()
    else:
        pause()

func pause() -> bool:
    if _paused:
        return true
    var ui_layer = _game_ui.push_state(GameUI.State.PAUSE)
    if not ui_layer:
        logs.warn("could not push pause state to game ui")
        return false
    # set up pause ui
    var label = Label.new()
    label.text = "PAUSED"
    ui_layer.add_to_top_row(label)
    # pause
    get_tree().paused = true
    _paused = true
    logs.info("pause")
    _game_ui.enable_inspect()
    return true

func resume():
    if not _paused:
        return
    # pop ui state if still on pause screen
    var current = _game_ui.current_state()
    if current == GameUI.State.PAUSE:
        _game_ui.pop_state()
    # resume game
    get_tree().paused = false
    _paused = false
    logs.info("resume")
