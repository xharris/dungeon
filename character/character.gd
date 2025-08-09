class_name Character
extends CharacterBody2D

var logs = Logger.new()

class Group:
    static var Ally = "ally"
    static var Enemy = "enemy"
    static var Player = "player"

class State:
    var idle = false
    var move_to_target = false
    var fall = false
    var combat = false

signal move_to_finished

@onready var sprite: CharacterSprite = $CharacterSprite
@onready var held_item_l: Node2D = %HeldItemL
@onready var held_item_r: Node2D = %HeldItemR
@onready var attack_start_timer: Timer = $AttackStart
@onready var attack_landed_timer: Timer = $AttackLanded

@export var stats:Stats
@export var id = "unknown":
    set(v):
        id = v
        stats.id = id
        inventory.id = id
        logs.set_prefix(id)
@export var inventory:Inventory = Inventory.new()

var state = State.new()
var target_position: Vector2
var target_distance: Vector2 = Vector2(20, 20)

func _ready() -> void:
    inventory.item_added.connect(_on_item_added)
    inventory.item_removed.connect(_on_item_removed)

func _enter_tree() -> void:
    logs.info("spawned at %.2v" % global_position)

func _on_item_added(item: Item):
    # trigger item visitors
    for i in inventory.items:
        for v in i.visitors:
            v.ctx = ItemVisitor.Context.new()
            v.ctx.source = self
            v.ctx.item = i
            v.on_equip()
    var item_node = item.scene.instantiate() if item.scene else null
    # hold in hand?
    var held_item_node = \
        held_item_l if item.hold == Item.Hold.Primary else\
        held_item_r if item.hold == Item.Hold.Secondary else\
        null
    if held_item_node and item_node:
        # clear currently held item
        held_item_node.get_children().map(func(c:Node): remove_child(c))
        # add held item
        held_item_node.add_child(item_node)

func _on_item_removed(item: Item, left: int):
    if inventory.count(item.item_id) == 0:
        # dont show held in hand anymore
        for held_item in held_item_l.get_children() as Array[Item]:
            if held_item.item_id == item.item_id:
                pass

func _on_attack_start_timeout() -> void:
    # iter items
    for item in inventory.items:
        var ctx = ItemVisitor.Context.new()
        ctx.item = item
        ctx.source = self
        ctx.target = self
        
        if item.attack_animation == Item.AttackAnimation.Swing:
            logs.info("swing %s" % item.item_id)
            ctx.trigger_item = item
            # actual attack landing timer
            var attack_landed_timer = Timer.new()
            attack_landed_timer.one_shot = true
            attack_landed_timer.wait_time = attack_start_timer.wait_time / 2
            attack_landed_timer.timeout.connect(_on_attack_landed_timeout.bind(ctx))
            add_child(attack_landed_timer)
            attack_landed_timer.start()
            # start animation
            sprite.swing()

func _on_attack_landed_timeout(ctx: ItemVisitor.Context) -> void:
    # calculate damage
    var damage = 0
    for item in inventory.items:
        for v in item.visitors: 
            v.ctx = ctx
            v.ctx.item = item
            damage += v.on_apply_damage()
    # apply damage
    if ctx.target:
        ctx.target.stats.take_damage(damage)
        
func held_items() -> Array[Item]:
    return []
    
func move_to_x(x: int):
    logs.debug("move to x=%d" % x)
    target_position.x = x
    state.move_to_target = true

func enable_combat():
    await sprite.swing_up()
    state.combat = true

func _physics_process(delta: float) -> void:
    # gravity
    velocity += get_gravity() * delta
    move_and_slide()

    var norm_move_to_target = (target_position - global_position).normalized()
    var arrived = abs(norm_move_to_target.x) < 0.1

    # walking animation
    if state.move_to_target:
        if arrived:
            logs.debug("stop moving")
            state.move_to_target = false
            velocity.x = 0
            sprite.stand()
            move_to_finished.emit()
        else:
            velocity.x += delta * stats.max_velocity.x * sign(norm_move_to_target.x)
            sprite.walk()
            sprite.speed_scale = lerpf(1, 1.75, norm_move_to_target.x)
        # face left/right
        sprite.scale.x = (-1 if norm_move_to_target.x < 0 else 1) * abs(sprite.scale.x)

    if state.idle:
        sprite.stand()

    # combat: attack enemy
    if not state.combat and not attack_start_timer.is_stopped():
        logs.debug("stop combat")
        attack_start_timer.stop()
    if state.combat and attack_start_timer.is_stopped():
        logs.debug("start combat")
        attack_start_timer.start()

    velocity = velocity.clamp(-stats.max_velocity, stats.max_velocity)

    # update state
    state.fall = not is_on_floor()
    state.idle = is_on_floor() and norm_move_to_target.length() == 0
