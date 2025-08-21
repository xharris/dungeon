extends Resource
class_name ZoneConfig

signal finished

var logs = Logger.new("zone")
@export var id:String = "unknown":
    set(v):
        id = v
        logs.set_prefix(id)
@export var rooms:Array[RoomConfig]

func start():
    logs.info("start")
    Rooms.next_room(rooms.pick_random())
