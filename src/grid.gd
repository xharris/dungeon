extends Resource
class_name Grid

static var logs = Logger.new("grid", Logger.Level.DEBUG)

class Position extends Resource:
    var position:Vector2i

    func center() -> Vector2:
        return (Vector2(position) * Util.size) + (Util.size / 2)
        
    func top_left() -> Vector2:
        return (Vector2(position) * Util.size)
        
    func get_rect() -> Rect2:
        var r: Rect2
        r.position = top_left()
        r.size = Util.size
        return r

var _positions: Array[Position]

func _get_at(pos:Vector2i) -> Position:
    for p in _positions:
        if p.position == pos:
            return p
    return null

# [code]to[/code] should be in range of [code][-1, 1][/code]
func continue_to(to:Vector2i) -> Position:
    to.clampi(-1, 1)
    var next = Position.new()
    if _positions.size() > 0:
        var last = _positions.back() as Position
        next.position = last.position + to
    else:
        # first position, stay at 0, 0
        logs.debug("first position")
    _positions.append(next)
    return next

func last() -> Position:
    if _positions.size() > 0:
        return _positions.back()
    return null
