class_name NPC
extends Node2D

static var GROUP = "npc"

enum TargetStrategy {Closest, Farthest, HighestAttack, LowestAttack, HighestHealth, LowestHealth, Random}
enum NPCType {Ally, Enemy}

var l = Logger.create("npc")

@export var target_strategy:TargetStrategy
@export var ability:Ability
@export var type:NPCType
@export var body_radius:int
@export var sprite:NPCSprite
@export var movement:NPCMovement
@export var health:Health

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group(GROUP)
	ability.activated.connect(on_ability_activated)
	sprite.attack_climaxed.connect(on_sprite_attack_climaxed)
	movement.started_moving.connect(on_started_moving)
	movement.reached_target.connect(on_reached_target)
	movement.move.connect(on_move)

func on_ability_activated():
	sprite.attack()

func on_sprite_attack_climaxed():
	ability.inflict()

func on_move(velocity:Vector2):
	global_position += velocity
	if velocity.x > 0:
		sprite.face_right()
	if velocity.x < 0:
		sprite.face_left()

func on_started_moving():
	sprite.walk()
	ability.stop()

func on_reached_target():
	sprite.stand()
	ability.start()

func sort_closest(a:NPC, b:NPC):
	return a.global_position.distance_to(global_position) > b.global_position.distance_to(global_position)

func find_target():
	if ability.target_type == Ability.TargetType.Self:
		movement.reset()
		ability.reset()
		return
	var npcs:Array[NPC]
	npcs.assign(get_tree().get_nodes_in_group(GROUP))
	npcs = npcs.filter(func(npc:NPC):
		return npc != self && \
			(
				(ability.target_type == Ability.TargetType.Ally && type == npc.type) || 
				(ability.target_type == Ability.TargetType.Enemy && type != npc.type)
			)
	)
	if npcs.size() == 0:
		l.debug("no npcs to target")
		movement.reset()
		ability.reset()
		return
	match target_strategy:
		TargetStrategy.Closest:
			npcs.sort_custom(sort_closest)
	movement.set_target(npcs.front())
	ability.set_target(npcs.front())

func get_range() -> int:
	return ability.get_range() + body_radius

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	find_target()
	movement.target_distance = get_range()

