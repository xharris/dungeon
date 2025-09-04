extends Node2D
class_name Room

static var static_logs = Logger.new("room")
static var grid: Grid
static var _SCENE = preload("res://src/room/room.tscn")

static func _static_init() -> void:
    grid = Grid.new()

static func create(config: RoomConfig, continue_to: Vector2i) -> Room:
    var me = _SCENE.instantiate() as Room
    me._config = config
    me._position = grid.continue_to(continue_to)
    if config.scene:
        var scene = config.scene.instantiate()
        me.add_child(scene)
    return me

var logs = Logger.new("room")
var _position: Grid.Position
var _config: RoomConfig

func _ready() -> void:
    add_to_group(Groups.ROOM)
    if not _position:
        logs.warn("grid position not set")
        return
    var _name_suffix:String = "%dx%d-%s" % [_position.position.x, _position.position.y, _config.id]
    logs.set_id(_name_suffix)
    name = "room-%s" % [_name_suffix]
    position = _position.top_left()
    _config.run_events()
    logs.info("created")
    Events.room_created.emit(_config, self)

func center():
    return _position.center()

func get_rect() -> Rect2:
    return _position.get_rect()
