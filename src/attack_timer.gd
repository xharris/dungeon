extends Node
## - Weapon attack timer
## - Sweet spot activation
class_name AttackTimer

enum State {DISABLED, ENABLED}

signal attack_started

var logs = Logger.new("attack_timer")#, Logger.Level.DEBUG)
@export var speed: float = 1.0
@export var animation_player:AnimationPlayer
@export var character: Character

var id:String:
    set(v):
        logs.set_prefix(v)
var _state: State
var _attack_config: ItemAttackConfig
var _timer: float = 0
var _sweet_spot_done = false
var _attack_done = false
var _animation_length:float = 0

func set_state(state:State) -> bool:
    logs.info("set state: %s" % State.find_key(state))
    match state:
        State.DISABLED:
            _timer = 0
            
        State.ENABLED:
            _state = state
            start()
            
    _state = state
    return true

func start():
    if _state != State.ENABLED:
        return
    logs.debug("start")
    _timer = 0
    _attack_done = false
    _sweet_spot_done = false
    attack_started.emit()
    if animation_player.current_animation == "":
        logs.warn("animation not playing")
        _animation_length = 1.0
    else:
        _animation_length = animation_player.current_animation_length
    logs.warn_if(not _attack_config, "need attack config")

func set_attack_config(config: ItemAttackConfig):
    _attack_config = config

func _process(delta: float) -> void:
    match _state:
        State.ENABLED:
            _timer += delta * speed
            if _attack_config and not _attack_done and _attack_config.is_past_sweet_spot(_timer):
                    # attack landed
                    logs.info("attack landed")
                    for s in _attack_config.attack_strategy:
                        s.run(character)
                    _attack_done = true
            if _timer >= _animation_length:
                # attack finished
                logs.debug("attack finished")
                start()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("action"):
        if _attack_config:
            if not _sweet_spot_done and _attack_config.is_in_sweet_spot(_timer):
                # sweet spot triggered
                logs.debug("sweet spot!")
                for s in _attack_config.sweet_spot_strategy:
                    s.run(character)
                _sweet_spot_done = true
