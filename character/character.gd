class_name Character
extends CharacterBody2D

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

var logs = Logger.new("character")#, Logger.Level.DEBUG)
var stats:Stats
var inventory:Inventory

var id = "unknown"
var state = State.new()
var target_position: Vector2
var target_distance: Vector2 = Vector2(20, 20)

func _ready() -> void:
    name = "char-%s-%d" % [id, get_instance_id()]
    logs.set_id(id)
    logs.info("create %s at %.2v" % [id, global_position])
    
    inventory.item_added.connect(_on_item_added)
    inventory.item_removed.connect(_on_item_removed)
    stats.damage_taken.connect(_on_damage_taken)
    stats.death.connect(_on_death)
    
    # trigger signal for default items
    for item in inventory.items:
        logs.debug("add default item: %s" % item.id)
        _on_item_added(item)
    
    add_to_group(Groups.CHARACTER_ANY)
    Characters.character_created.emit(self)

func _on_death():
    disable_combat()
    stop_moving()

func _on_damage_taken(amount: int):
    var text = ActionText.create()
    get_tree().root.add_child(text)
    text.global_position = global_position
    text.text = str(-amount)
    text.velocity.y = -200
    var tween = text.create_tween()
    # rise up, get red
    tween.parallel().tween_property(text, "velocity", Vector2.ZERO, 0.5)
    tween.parallel().tween_property(text, "modulate", MUI.RedA400, 0.5).from(MUI.Red200)
    tween = tween.chain()
    # fade out
    tween.tween_property(text, "modulate", Color.TRANSPARENT, 0.25)

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

func _on_item_removed(item: Item, _left: int):
    if inventory.count(item.id) == 0:
        # dont show held in hand anymore
        for held_item in held_item_l.get_children() as Array[Item]:
            if held_item.id == item.id:
                pass
                
var _attack_ctx: ItemVisitor.Context
func _on_attack_start_timeout() -> void:
    # iter items
    for item in inventory.items:        
        var ctx = ItemVisitor.Context.new()
        ctx.item = item
        ctx.source = self
        
        if item.attack_animation == Item.AttackAnimation.Swing:
            logs.debug("swing %s" % item.id)
            ctx.trigger_item = item
            _attack_ctx = ctx
            # start animation
            sprite.swing()

func _on_attack_landed() -> void:
    var ctx = _attack_ctx
    _attack_ctx = null
    if ctx == null:
        logs.warn("attack landed, missing context")
        return
    # calculate damage
    var damage = 0
    for item in inventory.items:        
        for v in item.visitors: 
            # get possible targets
            var possible_targets = v.on_get_possible_targets()
            var targets = []
            for t in possible_targets:
                var groups:Array[String]
                if t is int: # specific character
                    var instance = instance_from_id(t)
                    if instance is Character:
                        targets.append(instance)
                        
                elif t == ItemVisitor.TARGET.SELF: # target self
                    targets.append(self)
                    
                elif t == ItemVisitor.TARGET.ALLY: # target same team
                    if is_in_group(ItemVisitor.TARGET.ENEMY):
                        groups.append(Groups.CHARACTER_ENEMY)
                    elif is_in_group(Groups.CHARACTER_PLAYER):
                        groups.append(Groups.CHARACTER_ALLY)
                    elif is_in_group(ItemVisitor.TARGET.ALLY):
                        groups.append(Groups.CHARACTER_PLAYER)
                        
                elif t == ItemVisitor.TARGET.ENEMY: # target opposite team
                    if is_in_group(ItemVisitor.TARGET.ENEMY):
                        groups.append(Groups.CHARACTER_ALLY)
                        groups.append(Groups.CHARACTER_PLAYER)
                    elif is_in_group(Groups.CHARACTER_PLAYER) or is_in_group(ItemVisitor.TARGET.ALLY):
                        groups.append(Groups.CHARACTER_ENEMY)
                        
                # get characters in groups
                for group in groups:
                    targets.append_array(get_tree().get_nodes_in_group(group))

            v.ctx = ctx
            v.ctx.item = item
            # pick target
            targets = targets.filter(func(t:Character): return t.stats.is_alive())
            v.ctx.target = targets.pick_random()
            if v.ctx.target:
                damage += v.on_apply_damage()
            # apply damage
            if ctx.target:
                ctx.target.stats.take_damage(damage)
            else:
                logs.warn("no targets found: %s" % ctx.stringify())
        
func is_in_character_group(group:String):
    return is_in_group(group)
        
func held_items() -> Array[Item]:
    return []
    
## Returns `true` if successfull
func move_to_x(x: int) -> bool:
    if stats.is_alive():
        logs.info("move to x=%d" % x)
        target_position.x = x
        state.move_to_target = true
        return true
    return false

func stop_moving():
    if state.move_to_target:
        logs.debug("stop moving")
        state.move_to_target = false
        velocity.x = 0
        sprite.stand()
        move_to_finished.emit()

func enable_combat():
    if state.combat or not stats.is_alive():
        return
    logs.info("enable combat")
    sprite.stand()
    state.combat = true
    attack_start_timer.start()

func disable_combat():
    if not state.combat:
        return
    logs.info("disable combat")
    sprite.stand()
    state.combat = false
    attack_start_timer.stop()

func destroy():
    if Util.destroy(self):
        logs.info("destroyed")

func _physics_process(delta: float) -> void:
    # gravity
    velocity += get_gravity() * delta
    move_and_slide()

    var norm_move_to_target = (target_position - global_position).normalized()
    var arrived = abs(norm_move_to_target.x) < 0.1

    # walking animation
    if state.move_to_target:
        if arrived:
            stop_moving()
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

    velocity = velocity.clamp(-stats.max_velocity, stats.max_velocity)

    # update state
    state.fall = not is_on_floor()
    state.idle = is_on_floor() and norm_move_to_target.length() == 0
