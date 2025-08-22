extends Node

enum State {NONE, TITLE, PLAY,}
enum GameOverType {PLAYER_DEATH}
static var STARTING_ROOM:RoomConfig = preload("res://src/rooms/title.tres")

signal over(type:GameOverType)
signal paused
signal resumed

var logs = Logger.new("game")
var size:Vector2:
    get:
        return get_viewport().get_visible_rect().size
var _paused = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    Characters.character_created.connect(_on_character_created)

func _on_character_created(c:Character):
    c.stats.death.connect(_on_character_death.bind(c), CONNECT_ONE_SHOT)

func start():
    logs.info("game start")
    # create first room
    Rooms.next_room(STARTING_ROOM)

func _on_character_death(c:Character):
    if c.is_in_group(Groups.CHARACTER_PLAYER):
        logs.info("game over: player death")
        over.emit(GameOverType.PLAYER_DEATH)

func reset():
    logs.info("game reset")
    Characters.destroy_all()
    Rooms.destroy_all()

func is_over() -> bool:
    var player = Characters.get_player()
    return player and not player.stats.is_alive()

func is_paused() -> bool:
    return _paused

func toggle_pause() -> bool:
    if _paused:
        return resume()
    return pause()

func pause() -> bool:
    logs.info("pause")
    if logs.warn_if(_paused, "game already paused"):
        return false

    # pause
    _paused = true
    paused.emit()
    get_tree().paused = true
    return true

func resume() -> bool:
    logs.info("resume")
    if logs.warn_if(not _paused, "game not paused"):
        return false
        
    # resume game
    _paused = false
    get_tree().paused = false
    resumed.emit()
    return true
