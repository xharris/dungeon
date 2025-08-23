extends Visitor
class_name VisitorReplayRoom

func run():
    var rooms = GameUtil.rooms()
    var last_room = rooms.last_room()
    logs.error(not last_room, "no previous room to replay")
    rooms.push_room(last_room)
    finished.emit()
