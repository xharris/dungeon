extends Node2D
class_name Game

enum State {NONE, TITLE, PLAY}
enum GameOverType {PLAYER_DEATH}

signal over(type:GameOverType)

@onready var camera:GameCamera = $GameCamera
@onready var _environment:GameEnvironment = $GameEnvironment
@onready var _characters:Characters = $Characters
@onready var rooms:Rooms = $Rooms

@export var title_room:RoomConfig = preload("res://src/rooms/title.tres")
@export var starting_zone:ZoneConfig = preload("res://src/zones/forest/forest.tres")

var logs = Logger.new("game")
var _current_zone: ZoneConfig

func _ready() -> void:
    name = "Game"
    _current_zone = starting_zone
    Events.room_created.connect(_on_room_created)
    Events.character_created.connect(_on_character_created)
    Events.trigger_game_restart.connect(_on_trigger_game_reset, CONNECT_DEFERRED)

func _on_trigger_game_reset():
    restart()    

func _on_room_created(config:RoomConfig, node:Node2D):
    _environment.expand()
    # move camera to current room
    camera.move_to(node.position)
    var all_chars = _characters.get_all()
    await _characters.arrange(all_chars, node.global_position)

func _on_character_created(c:Character):
    var room_center = rooms.center()
    var offset_x = (Util.size.x / 2) + (Util.get_rect(c).size.x * 2)
    if c.is_in_group(Groups.CHARACTER_ENEMY):
        c.global_position.x = room_center.x + offset_x
    else:
        c.global_position.x = room_center.x - offset_x
    c.position.y = 0
    c.stats.death.connect(_on_character_death.bind(c), CONNECT_ONE_SHOT)
    # arrange
    await _characters.arrange([c], room_center)

func start():
    logs.info("start")
    rooms.push_room(title_room)
    enter_zone(_current_zone)

func restart():
    get_tree().reload_current_scene()
    
func enter_zone(config:ZoneConfig):
    for r in config.get_rooms():
        rooms.push_room(r)
    Events.trigger_rooms_next.emit()

func _on_character_death(c:Character):
    if c.is_in_group(Groups.CHARACTER_PLAYER):
        logs.info("game over: player death")
        over.emit(GameOverType.PLAYER_DEATH)

func is_over() -> bool:
    var player = _characters.get_player()
    return player and not player.stats.is_alive()
