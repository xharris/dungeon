extends Node
class_name Game

enum State {NONE, TITLE, PLAY}
enum GameOverType {PLAYER_DEATH}

signal over(type:GameOverType)

@onready var camera:GameCamera = $GameCamera
@onready var environment:GameEnvironment = $Environment
@onready var characters:Characters = $Characters
@onready var rooms:Rooms = $Rooms

@export var starting_zone:ZoneConfig = preload("res://src/zones/forest/forest.tres")
## call reset on given visitors (should reset static variables and stuff)
@export var reset_visitors:Array[Visitor] = [VisitorAddCharacter.new()]

var logs = Logger.new("game")
var _current_zone: ZoneConfig

func _ready() -> void:
    _current_zone = starting_zone
    Events.room_created.connect(_on_room_created)
    Events.character_created.connect(_on_character_created)
    
func _on_room_created(config:RoomConfig, node:Node2D):
    if config.id != Scenes.ROOM_TITLE.id:
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
    logs.info("start")
    rooms.push_room(Scenes.ROOM_TITLE)
    enter_zone(_current_zone)

func destroy():
    logs.info("destroy")
    for v in reset_visitors:
        logs.info("reset visitor: %s" % v.id)
        v.reset()
    UIInspectNode.reset()
    Util.destroy(self)
    
func enter_zone(config:ZoneConfig):
    for r in config.get_rooms():
        rooms.push_room(r)
    rooms.next()

func _on_character_death(c:Character):
    if c.is_in_group(Groups.CHARACTER_PLAYER):
        logs.info("game over: player death")
        over.emit(GameOverType.PLAYER_DEATH)

func is_over() -> bool:
    var player = characters.get_player()
    return player and not player.stats.is_alive()
