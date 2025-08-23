extends Node2D
class_name Rooms

var logs = Logger.new("rooms")
## index of current room
var _index = -1
var _last_room_node:Node2D
var _last_room:RoomConfig
var _next_rooms:Array[RoomConfig]

func _ready() -> void:
    Events.trigger_rooms_next.connect(_on_trigger_rooms_next)

func _on_trigger_rooms_next():
    next()

func last_room() -> RoomConfig:
    return _last_room

func push_room(config:RoomConfig) -> Rooms:
    logs.info("push room: %s" % config.id)
    _next_rooms.append(config)
    return self

func reset():
    logs.info("reset")
    Util.clear_children(self)

func center() -> Vector2:
    if _last_room_node:
        return _last_room_node.global_position
    return Vector2.ZERO

func next() -> bool:   
    var config = _next_rooms.pop_front()
    if not config:
        logs.info("no rooms left in queue")
        return false
    _index += 1
    var node = Node2D.new()    
    # position room node
    node.name = "room-%d-%s" % [_index, config.id]
    if _last_room_node:
        node.position += \
            _last_room_node.position + \
            Vector2(Util.size.x, 0)
    _last_room_node = node
    logs.info("next: %s position=%.0v" % [config.id, node.global_position])
    add_child(node)
    
    config.run_events()
    Events.room_created.emit(config, node)
    return true
