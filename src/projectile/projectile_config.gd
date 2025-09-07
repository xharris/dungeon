extends Resource
class_name ProjectileConfig

signal reached_target

@export var speed_curve: Curve
@export var distance_curve: Curve
@export var angle_curve: Curve
@export var rotation_curve: Curve
@export var on_reached_target: Array[AttackStrategy]
@export var destroy_on_reached: bool = true
