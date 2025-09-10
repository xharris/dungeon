extends Visitor
class_name PushRoom

@export var room: RoomConfig

func visit_rooms(v: Rooms):
    v.push_room(room)