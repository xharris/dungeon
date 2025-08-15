extends Button
class_name UIButton

enum State {NONE, NORMAL, ELEVATED, PRESSED}

@onready var bg = $BG
@onready var shadow = $BGShadow

@export var auto_focus = false

var logs = Logger.new("ui_button")
var _state:State
var _tween:Tween
var _theme_color:Dictionary = {
    "font_color": Color.WHITE
}
var _prev_state:State

func _ready() -> void:
    resized.connect(_on_resize)
    focus_entered.connect(set_state.bind(State.ELEVATED))
    focus_exited.connect(set_state.bind(State.NORMAL))
    button_down.connect(set_state.bind(State.PRESSED))
    pressed.connect(Util.chain_call.bind([
        set_state.bind(State.PRESSED),
        set_state.bind(State.ELEVATED)
    ]))
    set_state(State.NORMAL)
    if auto_focus:
        call_deferred("grab_focus")
    pivot_offset = size / 2

func _on_resize():
    pivot_offset = size / 2

func _process(delta: float) -> void:
    begin_bulk_theme_override()
    add_theme_color_override("font_color", _theme_color.get("font_color"))
    add_theme_color_override("font_focus_color", _theme_color.get("font_color"))
    end_bulk_theme_override()

func set_state(state:State):
    if state == null:
        state = State.NORMAL
    if state == _state:
        return
    logs.debug("set state %s" % State.find_key(state))
    _prev_state = _state
    _state = state
    
    # target values
    var font_color = Color.WHITE
    var bg_color = Color.TRANSPARENT
    var shadow_color = Color.BLACK
    var shadow_position = Vector2.ZERO
    var self_scale = Vector2.ONE
    var self_z_index = 0
    match state:
        State.PRESSED, State.ELEVATED:
            font_color = Color.BLACK
            bg_color = Color.WHITE
            shadow_color = Color.BLACK
            shadow_color.a = 0.75
            shadow_position = Vector2.ONE * 4
            match state:
                State.PRESSED:
                    var off = 0.2
                    self_scale = Vector2(1 + off, 1 - off) * 1.1
                    self_z_index = 1
    
    # create tween
    var tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "_theme_color:font_color", font_color, 0.2)
    tween.tween_property(bg, "modulate", bg_color, 0.2)
    tween.tween_property(shadow, "modulate", shadow_color, 0.2)
    tween.tween_property(shadow, "position", shadow_position, 0.2)
    tween.tween_property(self, "scale", self_scale, 0.2)
    tween.tween_property(self, "z_index", self_z_index, 0.2)
    tween.play()
    
