extends Node2D

#@onready var _rooms: Rooms = $Rooms
@onready var _characters: Characters = $Characters

@export var room_config: RoomConfig
var logs = Logger.new("dev-example")

func _ready() -> void:
    Events.character_created.connect(_on_character_created)
    
    var room = Room.create(room_config, Vector2i(0, 0))
    add_child(room)

func _on_character_created(c: Character):
    add_child(c)

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
    # arrange
    await _characters.arrange([c], last_room.get_rect())
