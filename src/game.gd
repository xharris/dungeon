extends Node
class_name Game

enum State {NONE, TITLE, PLAY,}
enum GameOverType {PLAYER_DEATH}

signal over(type:GameOverType)
signal started
signal resetted

@onready var camera:GameCamera = $GameCamera
@onready var environment:GameEnvironment = $Environment
@onready var characters:Characters = $Characters
@onready var rooms:Rooms = $Rooms

@export var title_room:RoomConfig = preload("res://src/rooms/title.tres")
@export var starting_zone:ZoneConfig = preload("res://src/zones/forest/forest.tres")

var logs = Logger.new("game")

func _ready() -> void:
    Events.room_created.connect(_on_room_created)
    Events.character_created.connect(_on_character_created)
    
func _on_room_created(_config:RoomConfig, node:Node2D):
    environment.expand()
    # move camera to current room
    camera.move_to(node.position)
    var all_chars = characters.get_all()
    await characters.arrange(all_chars, node.global_position)

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
    await characters.arrange([c], room_center)

func start():
    logs.info("game start")
    
    rooms.push_room(title_room)
    rooms.push_room(starting_zone.get_starting_room())
    rooms.next()
    
    started.emit()

func _on_character_death(c:Character):
    if c.is_in_group(Groups.CHARACTER_PLAYER):
        logs.info("game over: player death")
        over.emit(GameOverType.PLAYER_DEATH)

func reset():
    logs.info("game reset")
    
    camera.reset()
    environment.reset()
    rooms.reset()
    for c in characters.get_all():
        Util.destroy(c)
    
    resetted.emit()

## BUG not working as expected
func restart():
    reset()
    start()

func is_over() -> bool:
    var player = characters.get_player()
    return player and not player.stats.is_alive()
