extends Resource
class_name ZoneConfig

var logs = Logger.new("zone")
@export var id:String:
    set(v):
        id = v
        logs.set_prefix(id)
@export var rooms:Array[RoomConfig]

func get_rooms() -> Array[RoomConfig]:
    logs.error(rooms.size() == 0, "no rooms")
    var out:Array[RoomConfig]
    for _i in 4:
        out.append(rooms.pick_random())
    return out

func get_starting_room() -> RoomConfig:
    logs.error(rooms.size() == 0, "no rooms")
    var room:RoomConfig = rooms.pick_random()
    logs.info("first room: %s" % room.id)
    return room
