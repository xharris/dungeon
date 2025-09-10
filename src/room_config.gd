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

@export_group("Order")
@export var event_order: Order.Type = Order.Type.LINEAR
@export var event_wrap: bool = false

var _order: Order

func run_events():
    logs.info("run events")
    _order = Order.new()
    _order.set_items(events)
    _order.set_type(event_order)
    _order.set_wrap(event_wrap)
    _run_event()

func _run_event():
    var event = _order.next() as Visitor
    if not event:
        logs.info("all events finished")
        events_finished.emit()
        return
    event.visit()
