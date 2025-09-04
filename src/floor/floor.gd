extends Polygon2D
class_name Floor

func _ready() -> void:
    add_to_group(Groups.FLOOR)

func get_rect() -> Rect2:
    var pos = Vector2(global_position.x, 0)
    var size = Vector2(Util.size.x, 0)
    return Rect2(pos, pos + size)
