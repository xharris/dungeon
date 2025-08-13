extends Node

enum GameOverType {PLAYER_DEATH}

signal over(type:GameOverType)

var ROOM_MAIN:RoomConfig = preload("res://rooms/title/title.tres")
var logs = Logger.new("game")
var size:Vector2:
    get:
        return get_viewport().get_visible_rect().size

func _ready() -> void:
    Characters.character_created.connect(_on_character_created)

# BUG not being called
func _on_character_created(c:Character):
    c.stats.death.connect(_on_character_death, CONNECT_ONE_SHOT)
    
func _on_character_death(c:Character):
    if c.is_in_group(Groups.CHARACTER_PLAYER):
        logs.info("game over: player death")
        over.emit(GameOverType.PLAYER_DEATH)

func start():
    logs.info("game start")
    # create first room
    var room = Rooms.next_room(ROOM_MAIN)
    
func reset():
    logs.info("game reset")
    Characters.destroy_all()
    Rooms.destroy_all()

func is_over() -> bool:
    var player = Characters.get_player()
    return player and not player.stats.is_alive()
