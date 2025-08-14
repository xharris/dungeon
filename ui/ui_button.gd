extends Button
class_name UIButton

enum State {NONE, NORMAL, ELEVATED}

@onready var bg = $BG
@onready var shadow = $Shadow

var logs = Logger.new("ui_button")
var _state:State
var _tween:Tween
var _theme_color:Dictionary = {
    "font_color": Color.WHITE
}

func _ready() -> void:
    mouse_entered.connect(set_state.bind(State.ELEVATED))
    focus_entered.connect(set_state.bind(State.ELEVATED))
    
    mouse_exited.connect(set_state.bind(State.NORMAL))
    focus_exited.connect(set_state.bind(State.NORMAL))
    
    set_state(State.NORMAL)

func _process(delta: float) -> void:
    begin_bulk_theme_override()
    if _theme_color.has("font_color"):
        if _state == State.ELEVATED:
            add_theme_color_override("font_hover_color", _theme_color.get("font_color"))
        if _state == State.NORMAL:
            add_theme_color_override("font_color", _theme_color.get("font_color"))
    end_bulk_theme_override()

func set_state(state:State):
    if state == _state:
        return
    logs.info("set state %s" % State.find_key(state))
    _state = state
    
    # target values
    var font_color = Color.WHITE
    var self_position = Vector2.ZERO
    var bg_color = Color.TRANSPARENT
    var shadow_color = Color.BLACK
    var shadow_position = Vector2.ZERO
    match state:
        State.ELEVATED:
            font_color = Color.BLACK
            self_position = -Vector2.ONE * 2
            bg_color = Color.WHITE
            shadow_color = Color.BLACK
            shadow_color.a = 0.75
            shadow_position = Vector2.ONE * 4
    
    # create tween
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "_theme_color:font_color", font_color, 0.2)
    tween.tween_property(self, "position", self_position, 0.2)
    tween.tween_property(bg, "modulate", bg_color, 0.2)
    tween.tween_property(shadow, "modulate", shadow_color, 0.2)
    tween.tween_property(shadow, "position", shadow_position, 0.2)
    tween.play()
    
