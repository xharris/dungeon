extends Node2D
class_name Game

enum State {NONE, TITLE, PLAY}
enum GameOverType {PLAYER_DEATH}

signal over(type:GameOverType)

@onready var camera:GameCamera = $GameCamera
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
    Events.trigger_game_restart.connect(_on_trigger_game_restart)

func _on_trigger_game_restart():
    Events.game_restart.emit()
    restart()

func _on_room_created(config:RoomConfig, room:Room):
    # move camera to current room
    camera.move_to(room.center())
    var all_chars:Array[Character] = []
    all_chars.assign(Util.get_nodes_in_group(Groups.CHARACTER_ANY))
    await _characters.arrange(all_chars, room.get_rect())

func _on_character_created(c:Character):
    var last_room = Util.get_last_node_in_group(Groups.ROOM) as Room
    if not last_room:
        logs.warn("no rooms created")
        return
    var room_center = last_room.center()
    var offset_x = (Util.size.x / 2) + (Util.get_rect(c).size.x * 2)
    if c.is_in_group(Groups.CHARACTER_ENEMY):
        c.global_position.x = room_center.x + offset_x
    else:
        c.global_position.x = room_center.x - offset_x
    c.position.y = 0
    c.stats.death.connect(_on_character_death.bind(c), CONNECT_ONE_SHOT)
    # arrange
    await _characters.arrange([c], last_room.get_rect())

func start():
    logs.info("start")
    rooms.push_room(title_room)
    enter_zone(_current_zone)

func restart():
    logs.info("restart")
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
