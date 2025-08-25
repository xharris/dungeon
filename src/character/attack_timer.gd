extends Node
class_name AttackTimer

enum State {DISABLED, ENABLED}

signal attack_finished(is_sweet_spot:bool)

var logs = Logger.new("combat_ctrl")
@export var speed: float = 1.0

var _state: State
var _weapon: Item
var _timer: float = 0

func set_state(state:State) -> bool:
    match state:
        State.DISABLED:
            _timer = 0
            
        State.ENABLED:
            if not _weapon or _weapon.visitors.size() == 0:
                # cannot attack with this item
                return set_state(State.DISABLED)
            _timer = 0
    
    _state = state
    return true

func set_weapon(item: Item):
    _weapon = item
    set_state(_state)

func _process(delta: float) -> void:
    match _state:
        State.ENABLED:
            _timer += delta * speed
            var spot_range = _weapon.get_sweet_spot_range()
            if _timer >= spot_range[1]:
                _attack_finished(false)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("action"):
        var spot_range = _weapon.get_sweet_spot_range()
        if _timer >= spot_range[0] and _timer <= spot_range[1]:
            _attack_finished(true)

func _attack_finished(sweet:bool = false):
    attack_finished.emit(sweet)
    _timer = 0
