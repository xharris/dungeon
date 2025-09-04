extends Node2D
class_name Rooms

@export var title_room_id:String = "title"

var logs = Logger.new("rooms")
var _last_room:RoomConfig
var _next_rooms:Array[RoomConfig]

func _ready() -> void:
    add_to_group(Groups.ROOMS)
    Events.trigger_rooms_next.connect(_on_trigger_rooms_next)
    
    Room.grid = Grid.new()
    
func _on_room_events_finished():
    var ok = next()
    if not ok:
        pass # TODO show next zone roullette
        
func _on_trigger_rooms_next():
    next()

func last_room() -> RoomConfig:
    return _last_room

func push_room(config:RoomConfig) -> Rooms:
    logs.info("push room: %s" % config.id)
    _next_rooms.append(config)
    return self

func center() -> Vector2:
    var last_room = Util.get_last_node_in_group(Groups.ROOM) as Room
    if not last_room:
        return Vector2.ZERO
    return last_room.center()

## returns false if a room is not loaded
func next() -> bool:   
    var config = _next_rooms.pop_front() as RoomConfig
    if not config:
        logs.info("no rooms left in queue")
        return false
    logs.info("next: %s" % config.id)
    if not config.halt:
        config.events_finished.connect(_on_room_events_finished, CONNECT_ONE_SHOT)
    else:
        logs.info("halt (%s)" % config.id)

    var room = Room.create(config, Vector2i(1, 0))
    add_child(room)

    return true
