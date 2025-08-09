extends Resource
class_name Stats

var logs = Logger.new("stats")

@export var id:String = "":
    set(v):
        id = v
        logs.set_prefix(id)
@export var max_hp:int = 10:
    set(x):
        # scale up current hp
        hp = (hp / max_hp) * x
        max_hp = x
@export var hp: int = 10
@export var max_velocity: Vector2 = Vector2(100, 200)

func _init() -> void:
    resource_local_to_scene = true

func take_damage(v:int) -> Stats:
    logs.debug("take damage: %d" % v)
    hp -= v
    return self
    
func heal(v:int) -> Stats:
    logs.debug("heal: %d" % v)
    hp += v
    return self
