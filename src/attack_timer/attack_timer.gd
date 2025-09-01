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

var logs = Logger.new("attack_timer")#, Logger.Level.DEBUG)
@export var animation_player: AnimationPlayer
@export var character: Character
## node that will display sweet spot indication
@export var particle_node: Node2D:
    set(v):
        particle_node = v
        update_particles()

@onready var _particles: GPUParticles2D = $GPUParticles2D
@onready var _remote_transform: RemoteTransform2D = $RemoteTransform2D

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
var _last_weapon_node: Node2D

func _ready() -> void:
    _particles.amount_ratio = 0
    _remote_transform.tree_exiting.connect(_on_remote_transform_tree_exited)

func _on_remote_transform_tree_exited():
    _remote_transform.reparent(self)

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

func update_particles():
    if not _particles:
        logs.warn("particles not ready")
        return
    var mat:ParticleProcessMaterial = _particles.process_material
    var rect = Util.get_rect(particle_node)
    if rect.size.length() == 0:
        return
    logs.info("update particles")
    logs.info("weapon rect: %s" % rect)
    # update particle emission area to cover weapon node
    mat.emission_box_extents.x = rect.size.x / 2
    mat.emission_box_extents.y = rect.size.y / 2
    # draw particles behind weapon
    _particles.z_index = particle_node.z_index - 1
    _remote_transform.reparent(particle_node)

func _sweet_spot_enter():
    if _sweet_spot_entered:
        return
    _sweet_spot_entered = true
    # show visual
    _particles.emit_particle(
        Transform2D.IDENTITY, Vector2.ZERO, 
        Color.WHITE, Color.WHITE,
        0
    )
    sweet_spot_entered.emit()

func _sweet_spot_exit():
    if _sweet_spot_done:
        return
    _sweet_spot_done = true
    sweet_spot_exited.emit()

func _sweet_spot_trigger():
    sweet_spot_triggered.emit()
    _particles.amount_ratio = 1
    var t = _particles.create_tween()
    t.tween_property(_particles, "amount_ratio", 0, 0.5)
    t.play()

func _process(delta: float) -> void:
    if particle_node and  _last_weapon_node != particle_node:
        update_particles()
        _last_weapon_node = particle_node
    
    match _state:
        State.ENABLED:
            _timer += delta * speed
            # animation should take one second * attack speed
            if _attack_config:
                if not _sweet_spot_entered and not _sweet_spot_missed and _attack_config.is_in_sweet_spot(_timer):
                    # start of sweet spot
                    _sweet_spot_enter()
                    
                if _sweet_spot_entered and not _sweet_spot_done and not _sweet_spot_missed and not _attack_config.is_in_sweet_spot(_timer):
                    # end of sweet spot
                    _sweet_spot_exit()
                    
                if not _attack_done and _attack_config.is_past_sweet_spot(_timer):
                    # attack landed
                    logs.info("attack landed")
                    for s in _attack_config.attack_strategy:
                        s.run(character)
                    _attack_done = true
                    # also the end of sweet spot technically
                    if _sweet_spot_entered and not _sweet_spot_done:
                        _sweet_spot_exit()
                    
            if _timer >= 1.0:
                # attack finished
                logs.debug("attack finished")
                start()

func _unhandled_input(event: InputEvent) -> void:
    if _state == State.ENABLED and character.is_in_group(Groups.CHARACTER_PLAYER) and event.is_action_pressed("action"):
        if _attack_config:
            var is_in_sweet_spot = _sweet_spot_entered and not _sweet_spot_done
            if is_in_sweet_spot:
                # sweet spot triggered
                logs.info("sweet spot triggered!")
                for s in _attack_config.sweet_spot_strategy:
                    s.run(character)
                _sweet_spot_exit()
                _sweet_spot_trigger()
            elif not _sweet_spot_missed:
                # sweet spot missed
                logs.info("sweet spot missed")
                for s in _attack_config.sweet_spot_missed_strategy:
                    s.run(character)
                _sweet_spot_missed = true
                _sweet_spot_exit()
                sweet_spot_missed.emit()
