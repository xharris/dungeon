class_name Character
extends CharacterBody2D

enum CombatState {DISABLED, ENABLED}

class MovementState:
    var idle = false
    var move_to_target = false
    var fall = false

signal move_to_finished

@onready var sprite: CharacterSprite = $CharacterSprite
@onready var held_item_l: Node2D = %HeldItemL
@onready var held_item_r: Node2D = %HeldItemR
@onready var _weapon_animation_player: AnimationPlayer = $CharacterSprite/WeaponAnimationPlayer
@onready var _attack_timer: AttackTimer = $AttackTimer
@onready var inspect_node: UICharacterInspect = %UICharacterInspect

var logs = Logger.new("character")#, Logger.Level.DEBUG)
var stats:Stats
var inventory:Inventory

var id:String = "unknown"
var _combat_state:CombatState
var _movement_state = MovementState.new()
var target_position: Vector2
var target_distance: Vector2 = Vector2(20, 20)
var _max_velocity: Vector2 = Vector2(400, 500)
var _weapon: Item

func use_config(config:CharacterConfig):
    id = config.id
    # configure
    stats = config.stats.duplicate()
    inventory = config.inventory.duplicate()
    stats.id = id
    inventory.id = id
    # position depending on group
    match config.group:
        Groups.CHARACTER_PLAYER:
            global_position.x -= (Util.size.x / 2) + (Util.get_rect(self).size.x * 2)
        _:
            global_position.x += (Util.size.x / 2) + (Util.get_rect(self).size.x * 2)
    position.y = 0
    
    add_to_group(config.group)
    add_to_group(Groups.CHARACTER_ANY)

func _ready() -> void:
    name = "char-%s-%d" % [id, get_instance_id()]
    logs.set_id(id)
    _attack_timer.id = id
    
    logs.info("create %s at %.2v" % [id, global_position])
    
    inventory.item_added.connect(_on_item_added)
    inventory.item_removed.connect(_on_item_removed)
    stats.damage_taken.connect(_on_damage_taken)
    stats.death.connect(_on_death)
    _attack_timer.attack_started.connect(_on_attack_timer_started)
    
    # trigger signal for default items
    for item in inventory.items:
        logs.debug("add default item: %s" % item.id)
        _on_item_added(item)
    
    add_to_group(Groups.CHARACTER_ANY)
    Events.character_created.emit(self)

func _on_attack_timer_started():
    if not _weapon:
        logs.warn("missing weapon")
        return
    if not _weapon.attack_config:
        logs.warn("missing weapon.attack_config: %s" % _weapon.id)
        return
    # weapon animation
    if not _weapon_animation_player.has_animation_library(_weapon.id):
        logs.info("add animation library: %s (%s)" % [_weapon.id, _weapon.animation_library.get_animation_list()])
        _weapon_animation_player.add_animation_library(_weapon.id, _weapon.animation_library)
    _attack_timer.set_attack_config(_weapon.attack_config)

    # play attack animation, set animation speed to attack timer speed
    if not logs.warn_if(_weapon.attack_config.animation_name.length() == 0, "missing weapon attack config animation name for '%s' (expecting one of: %s)" % [_weapon.id, _weapon.animation_library.get_animation_list()]):
        var animation_name = "%s/%s" % [_weapon.id, _weapon.attack_config.next_animation()]
        logs.warn_if(not _weapon_animation_player.has_animation(animation_name), "missing weapon animation: %s" % animation_name)
        logs.debug("play animation: %s" % animation_name)
        _weapon_animation_player.stop()
        _weapon_animation_player.play(animation_name)
        _weapon_animation_player.speed_scale = _attack_timer.speed

func _on_death():
    disable_combat()
    stop_moving()

func _on_damage_taken(amount: int):
    var text = Scenes.ACTION_TEXT.instantiate()
    get_tree().root.add_child(text)
    text.global_position = global_position
    text.text = str(-amount)
    text.velocity.y = -700
    var tween = text.create_tween()
    # rise up, get red
    tween.parallel().tween_property(text, "velocity", Vector2.ZERO, 0.5)
    tween.parallel().tween_property(text, "modulate", MUI.RedA400, 0.5).from(MUI.Red200)
    tween = tween.chain()
    # fade out
    tween.tween_property(text, "modulate", Color.TRANSPARENT, 0.25)

func _on_item_added(item: Item):
    if not item.is_weapon:
        return
    var item_node = item.scene.instantiate() if item.scene else null
    # hold in hand?
    var held_item_node = \
        held_item_l if item.hold == Item.Hold.Primary else\
        held_item_r if item.hold == Item.Hold.Secondary else\
        null
    if held_item_node and item_node:
        # clear currently held item
        Util.clear_children(held_item_node)
        # add held item
        held_item_node.add_child(item_node)
    _weapon = item

func _on_item_removed(item: Item, _left: int):
    if inventory.count(item.id) == 0:
        # dont show held in hand anymore
        for held_item in held_item_l.get_children() as Array[Item]:
            if held_item.id == item.id:
                pass

func held_items() -> Array[Item]:
    return []
    
## Returns `true` if successfull
func move_to_x(x: int) -> bool:
    if stats.is_alive():
        logs.info("move to x=%d" % x)
        target_position.x = x
        _movement_state.move_to_target = true
        return true
    return false

func move(relative_pos: Vector2) -> bool:
    if stats.is_alive():
        logs.info("move %.0v + %.0v" % [global_position, relative_pos])
        target_position = global_position + relative_pos
        _movement_state.move_to_target = true
        return true
    return false
    
func stop_moving():
    if _movement_state.move_to_target:
        logs.debug("stop moving")
        _movement_state.move_to_target = false
        velocity.x = 0
        sprite.stand()
        move_to_finished.emit()

func enable_combat() -> bool:
    return set_combat_state(CombatState.ENABLED)

func disable_combat() -> bool:
    return set_combat_state(CombatState.DISABLED)

func get_combat_state() -> CombatState:
    return _combat_state

func set_combat_state(state:CombatState) -> bool:
    logs.info("set combat state: %s" % CombatState.find_key(state))
    
    match state:
        CombatState.DISABLED:
            if stats.is_alive():
                sprite.stand()
            _attack_timer.set_state(AttackTimer.State.DISABLED)

        CombatState.ENABLED:
            if not stats.is_alive():
                logs.info("not alive")
                return false
            sprite.stand()
            _attack_timer.set_state(AttackTimer.State.ENABLED)
 
    _combat_state = state
    return true 

func destroy():
    if Util.destroy(self):
        logs.info("destroyed")

func _physics_process(delta: float) -> void:
    # gravity
    velocity += get_gravity() * delta
    move_and_slide()

    var norm_move_to_target = (target_position - global_position).normalized()
    var arrived = abs(norm_move_to_target.x) < 0.1
    var max_velocity = stats.movespeed * _max_velocity

    # walking animation
    if _movement_state.move_to_target:
        if arrived:
            stop_moving()
        else:
            velocity.x += delta * max_velocity.x * sign(norm_move_to_target.x)
            sprite.walk()
            sprite.speed_scale = lerpf(1, 1.75, abs(norm_move_to_target.x))
        # face left/right
        sprite.scale.x = (-1 if norm_move_to_target.x < 0 else 1) * abs(sprite.scale.x)

    if _movement_state.idle:
        sprite.stand()

    velocity = velocity.clamp(-max_velocity, max_velocity)

    # update _movement_state
    _movement_state.fall = not is_on_floor()
    _movement_state.idle = is_on_floor() and norm_move_to_target.length() == 0
