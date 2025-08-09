extends Resource
class_name Stats

@export var max_hp:int = 10:
    set(x):
        # scale up current hp
        hp = (hp / max_hp) * x
        max_hp = x
@export var hp: int = 10
@export var max_velocity: Vector2 = Vector2(100, 200)

func _init() -> void:
    resource_local_to_scene = true
