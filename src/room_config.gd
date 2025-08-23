extends Resource
class_name RoomConfig

signal events_finished

var logs = Logger.new("room")

@export var id:String = "unknown":
    set(v):
        id = v
        logs.set_prefix(id)
@export var events:Array[Visitor]

func run_events():
    logs.info("run events")
    _run_event(0)

func _run_event(idx:int):
    if idx >= events.size():
        logs.info("all events finished")
        events_finished.emit()
        return
    var event = events[idx]
    event.finished.connect(_run_event.bind(idx + 1))
    event.visit()
