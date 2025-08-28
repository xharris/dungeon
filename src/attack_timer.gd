extends Node
## - Weapon attack timer
## - Sweet spot activation
class_name AttackTimer

enum State {DISABLED, ENABLED}

signal attack_started
signal sweet_spot_entered
signal sweet_spot_exited
signal sweet_spot_triggered
signal sweet_spot_missed
signal state_changed(state:State)

var logs = Logger.new("attack_timer", Logger.Level.DEBUG)
@export var animation_player:AnimationPlayer
@export var character: Character

var id:String:
    set(v):
        logs.set_prefix(v)
var speed: float = 1.0
var _state: State
var _attack_config: ItemAttackConfig
var _timer: float = 0
var _sweet_spot_done = false
var _attack_done = false
var _sweet_spot_entered = false
var _sweet_spot_missed = false

func set_state(state:State) -> bool:
    logs.info("set state: %s" % State.find_key(state))
    match state:
        State.DISABLED:
            _timer = 0
            
        State.ENABLED:
            _state = state
            start()
            
    _state = state
    state_changed.emit(_state)
    return true

func start():
    logs.debug("start")
    if _state != State.ENABLED:
        logs.warn("not enabled")
        return
    _timer = 0
    _attack_done = false
    _sweet_spot_done = false
    _sweet_spot_entered = false
    _sweet_spot_missed = false
    attack_started.emit()
    if animation_player.current_animation == "":
        logs.warn("animation not playing")
        animation_player.speed_scale = 1.0
    else:
        animation_player.speed_scale = (1.0 / animation_player.current_animation_length) * speed
    logs.warn_if(not _attack_config, "need attack config")

func set_attack_config(config: ItemAttackConfig):
    _attack_config = config

func _process(delta: float) -> void:
    match _state:
        State.ENABLED:
            _timer += delta * speed
            # animation should take one second * attack speed
            if _attack_config:
                if not _sweet_spot_entered and not _sweet_spot_missed and _attack_config.is_in_sweet_spot(_timer):
                    # start of sweet spot
                    _sweet_spot_entered = true
                    sweet_spot_entered.emit()
                    
                if _sweet_spot_entered and not _sweet_spot_done and not _sweet_spot_missed and not _attack_config.is_in_sweet_spot(_timer):
                    # end of sweet spot
                    _sweet_spot_done = true
                    sweet_spot_exited.emit()
                    
                if not _attack_done and _attack_config.is_past_sweet_spot(_timer):
                    # attack landed
                    logs.info("attack landed")
                    for s in _attack_config.attack_strategy:
                        s.run(character)
                    _attack_done = true
                    # also the end of sweet spot technically
                    if _sweet_spot_entered and not _sweet_spot_done:
                        _sweet_spot_done = true
                        sweet_spot_exited.emit()
                    
            if _timer >= 1.0:
                # attack finished
                logs.debug("attack finished")
                start()

func _unhandled_input(event: InputEvent) -> void:
    if character.is_in_group(Groups.CHARACTER_PLAYER) and event.is_action_pressed("action"):
        if _attack_config:
            var is_in_sweet_spot = _sweet_spot_entered and not _sweet_spot_done
            if is_in_sweet_spot:
                # sweet spot triggered
                logs.info("sweet spot triggered!")
                for s in _attack_config.sweet_spot_strategy:
                    s.run(character)
                _sweet_spot_done = true
                sweet_spot_triggered.emit()
                sweet_spot_exited.emit()
            elif not _sweet_spot_missed:
                # sweet spot missed
                logs.info("sweet spot missed")
                for s in _attack_config.sweet_spot_missed_strategy:
                    s.run(character)
                _sweet_spot_done = true
                _sweet_spot_missed = true
                sweet_spot_missed.emit()
                sweet_spot_exited.emit()
