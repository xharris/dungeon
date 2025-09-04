extends Resource
class_name GridPosition

## Dictionary[String, Array[GridPosition]]
static var _instances:Dictionary

static func _get_instances(group:String) -> Array[GridPosition]:
    return _instances.get(group, [])

# [code]to[/code] should be in range of [code][-1, 1][/code]
static func continue_to(group:String, to:Vector2i) -> GridPosition:
    to.clampi(-1, 1)
    var next = GridPosition.new()
    # get last position
    var last = GridPosition.new()
    var instances = _get_instances(group)
    if instances.size() > 0:
        last = instances.back()
    # set next position
    next.position = last.position + to
    return next
    
var position:Vector2i

func center() -> Vector2:
    return (Vector2(position) * Util.size)
