extends Resource
class_name Stats

var logs = Logger.new("stats")

signal death
signal damage_taken(amount:int)

var id:String = "":
    set(v):
        id = v
        logs.set_prefix(id)
@export var max_hp:int = 10:
    set(x):
        # scale up current hp
        hp = int((1.0 * hp / max_hp) * x)
        max_hp = x
@export var hp: int = 10
@export var movespeed: Vector2 = Vector2(1.0, 1.0)
@export var strength: int = 4

func take_damage(v:int) -> Stats:
    logs.info("take damage: %d" % v)
    hp -= v
    damage_taken.emit(v)
    if not is_alive():
        logs.info("died")
        death.emit()
    return self
    
func heal(v:int) -> Stats:
    logs.debug("heal: %d" % v)
    hp += v
    return self

func is_alive() -> bool:
    return hp > 0
