extends Node2D
class_name Room

## TODO update the code in this file

var logs = Logger.new("room")

var grid_position: GridPosition:
    set(v):
        global_position = v.center()
        grid_position = v

func _ready() -> void:
    add_to_group(Groups.ROOM)
    grid_position = GridPosition.new()
    logs.debug("created at grid=%s" % [grid_position.position])

func center():
    return global_position + (Util.size / 2)

func get_rect() -> Rect2:
    var rect = Rect2(
        global_position,
        global_position + Util.size
    )
    rect.position.y = 0
    rect.size.y = 0
    return rect
