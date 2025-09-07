extends Resource
class_name AttackStrategy

enum TARGET {SELF, ALLY, ENEMY}

@export var id:String
@export var target:TARGET
@export var modify_stats:Stats
@export_group("Damage")
@export var deal_damage:bool = true
@export var strength_ratio:float = 1.0

var _source_node: Node2D
var _target_node: Node2D

var logs = Logger.new("attack_strategy")

func setup(source_node: Node2D, target_node: Node2D):
    _source_node = source_node
    _target_node = target_node

func run(stats:Stats):
    if deal_damage:
        stats.take_damage(stats.strength * strength_ratio)
    if modify_stats:
        modify_stats.apply_to(stats)
