class_name Character
extends CharacterBody2D

class Group:
    static var Ally = "ally"
    static var Enemy = "enemy"
    static var Player = "player"

class State:
    var idle = false
    var move_to_target = false
    var fall = false
    var combat = false

@onready var sprite: CharacterSprite = $CharacterSprite
@onready var held_item_l: Node2D = %HeldItemL
@onready var held_item_r: Node2D = %HeldItemR
@onready var attack_start_timer: Timer = $AttackStart
@onready var attack_landed_timer: Timer = $AttackLanded

@export var stats:Stats

var state = State.new()
var inventory:Inventory = Inventory.new()
var target_position: Vector2

func _ready() -> void:
    inventory.item_added.connect(_on_item_added)
    inventory.item_removed.connect(_on_item_removed)

func _on_item_added(item: Item):
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
    Logs.debug("start attack")
    # TODO get target
    
    # TODO start attack animation
    attack_landed_timer.start()
    
    # TODO start attack landed timer
    pass

func _on_attack_landed_timeout() -> void:
    # calculate damage
    var damage = 0
    for item in inventory.items:
        var data = Item.Data.new()
        data.item = item
        data.source = self
        data.target = self
        damage += item.apply_damage(data)
        
func held_items() -> Array[Item]:
    return []
    
func move_to_x(x: int):
    Logs.debug("move to x=%d" % x)
    target_position.x = x
    state.move_to_target = true

func _physics_process(delta: float) -> void:
    # gravity
    velocity += get_gravity() * delta
    move_and_slide()

    var norm_move_to_target = (target_position - global_position).normalized()

    if state.move_to_target and not state.fall:
        global_position.x = lerp(global_position.x, target_position.x, delta)
        # face left/right
        sprite.scale.x = (-1 if norm_move_to_target.x < 0 else 1) * abs(sprite.scale.x)

    # walking animation
    if state.move_to_target:
        if norm_move_to_target.x > 0.3:
            sprite.walk()
            sprite.speed_scale = lerpf(0.2, 2, norm_move_to_target.x)
        else:
            sprite.stand()

    if state.idle:
        sprite.stand()

    # combat: attack enemy
    if not state.combat and not attack_start_timer.is_stopped():
        Logs.debug("stop combat")
        attack_start_timer.stop()
    if state.combat and attack_start_timer.is_stopped():
        Logs.debug("start combat")
        attack_start_timer.start()

    # update state
    state.fall = not is_on_floor()
    state.move_to_target = \
        is_on_floor() and \
        abs(target_position.x - global_position.x) >= 10
    state.idle = is_on_floor() and norm_move_to_target.length() == 0
