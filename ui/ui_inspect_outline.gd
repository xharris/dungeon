extends Node2D
class_name UIInspectOutline

enum State {HIDDEN, VISIBLE, SELECTED}

var logs = Logger.new("ui_inspect_outline")
var _tween:Tween
var _rect:Rect2

func _ready() -> void:
    set_state(State.HIDDEN, true)

func set_rect(rect:Rect2):
    _rect = rect
    queue_redraw()

func set_state(state:State, immediate = false):
    logs.info("set state %s" % State.find_key(state))
    if _tween:
        _tween.stop()
    _tween = create_tween()
    
    var t = 0.2
    match state:
        State.VISIBLE:
            _tween.tween_property(self, "modulate", Color(1, 1, 1, 0.25), t)
        State.SELECTED:
            _tween.tween_property(self, "modulate", Color(1, 1, 1, 1), t)
        State.HIDDEN:
            _tween.tween_property(self, "modulate", Color(1, 1, 1, 0), t)

    if immediate:
        _tween.pause()
        _tween.custom_step(t)
    else:
        _tween.play()

func _process(_delta: float) -> void:
    if _tween and _tween.is_running():
        queue_redraw()
    
func _draw():
    draw_circle(Vector2.ZERO, _rect.size.length(), Color.WHITE)
