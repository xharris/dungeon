extends Node2D
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

@export var animation_player: AnimationPlayer
@export var character: Character
## node that will display sweet spot indication
@export var particle_node: Node2D:
    set(v):
        particle_node = v
        update_particles()

@onready var _particles: Node2D = $Particles
@onready var _p_sweet_spot: GPUParticles2D = $Particles/ParticlesSweetSpot
@onready var _p_ability_triggered: GPUParticles2D = $Particles/ParticlesAbilityTriggered

var logs = Logger.new("attack_timer", Logger.Level.DEBUG)
var id:String:
    set(v):
        logs.set_prefix(v)
        id = v
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
    update_particles()

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
    logs.debug("attack start")
    if _state != State.ENABLED:
        logs.warn("not enabled")
        return
    _timer = 0
    _p_ability_triggered.amount_ratio = 0
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
    logs.info("update particles")
    if not _p_ability_triggered:
        logs.debug("not ready")
        return
    var rect = Util.get_rect(particle_node)
    if rect.size.length() == 0:
        return
    for p in _particles.get_children():
        if p is GPUParticles2D:
            p = p as GPUParticles2D
            var mat:ParticleProcessMaterial = p.process_material
            logs.info("weapon rect: %s" % rect)
            # update particle emission area to cover weapon node
            mat.emission_box_extents.x = rect.size.x / 2
            mat.emission_box_extents.y = rect.size.y / 2
            # draw particles behind weapon
            #_particles.z_as_relative = false
            #_particles.z_index = particle_node.z_index - 1
    
func _sweet_spot_enter():
    if _sweet_spot_entered:
        return
    if not _attack_config:
        logs.debug("_attack_config not set")
        return
    logs.debug("sweet spot enter")
    _sweet_spot_entered = true
    # show visual
    _emit(_p_sweet_spot, _attack_config.get_sweet_spot_size())
    sweet_spot_entered.emit()

func _sweet_spot_exit():
    if _sweet_spot_done:
        return
    _sweet_spot_done = true
    sweet_spot_exited.emit()

func _sweet_spot_trigger():
    sweet_spot_triggered.emit()
    _p_ability_triggered.amount_ratio = 1
    logs.debug("sweet spot triggered")
    if animation_player.current_animation:
        var t = create_tween()
        var time_left = animation_player.current_animation_length - animation_player.current_animation_position
        logs.debug("attack animation time left=%0.3f" % time_left)
        #t.tween_property(_p_ability_triggered, "amount_ratio", 0, time_left)
        #t.play()
    else:
        logs.debug("no current animation")

func _emit(emitter: GPUParticles2D, lifetime: float = 1.0):
    emitter.lifetime = lifetime
    emitter.emitting = true
    emitter.amount_ratio = 1
    emitter.emit_particle( 
        particle_node.global_transform, 
        Vector2.ZERO, Color.WHITE, 
        Color(0, 0, 0, emitter.lifetime), 
        GPUParticles2D.EmitFlags.EMIT_FLAG_POSITION
    )
    logs.debug("emit %s lifetime=%f" % [emitter.name, emitter.lifetime])
    
func _process(delta: float) -> void:
    if particle_node and  _last_weapon_node != particle_node:
        update_particles()
        _last_weapon_node = particle_node
    if particle_node:
        for p in _particles.get_children():
            if p is GPUParticles2D:
                p = p as GPUParticles2D
                p.global_position = particle_node.global_position
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
    if event.is_action_pressed("debug_action") and character.is_in_group(Groups.CHARACTER_PLAYER):
        _emit(_p_sweet_spot)
    if _attack_config and _state == State.ENABLED and \
    character.is_in_group(Groups.CHARACTER_PLAYER) and event.is_action_pressed("action"):
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
