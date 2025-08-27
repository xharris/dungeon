extends Resource
class_name ZoneConfig

var logs = Logger.new("zone")
@export var id:String:
    set(v):
        id = v
        logs.set_prefix(id)
@export var rooms:Array[RoomConfig]

func get_starting_room() -> RoomConfig:
    logs.error(rooms.size() == 0, "no rooms")
    var room:RoomConfig = rooms.pick_random()
    logs.info("first room: %s" % room.id)
    return room
