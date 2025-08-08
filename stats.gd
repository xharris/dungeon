extends Resource
class_name Stats

@export var max_hp:int = 10:
	set(x):
		# scale up current hp
		hp = (hp / max_hp) * x
		max_hp = x
@export var hp: int = 10

func _init() -> void:
	resource_local_to_scene = true
