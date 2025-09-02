extends Resource
class_name RoomConfig

signal events_finished

var logs = Logger.new("room")

@export var id:String = "unknown":
    set(v):
        id = v
        logs.set_prefix(id)
@export var scene:PackedScene
## stop advancing to the next room automatically
@export var halt:bool = true
@export var events:Array[Visitor]
@export var event_order: Order.Type = Order.Type.LINEAR

var _order: Order

func run_events():
    logs.info("run events")
    _order = Order.new()
    _order.set_items(events)
    _order.set_type(event_order)
    _run_event()

func _run_event():
    var event = _order.next() as Visitor
    if not event:
        logs.info("all events finished")
        events_finished.emit()
        return
    if not event.finished.is_connected(_run_event):
        event.finished.connect(_run_event, CONNECT_ONE_SHOT)
    event.visit()
