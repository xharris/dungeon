extends Visitable
class_name Stats

const MIN_ATTACK_SPEED = 0.2
const MAX_ATTACK_SPEED = 3.0

var logs = Logger.new("stats")

signal death
signal damage_taken(amount:int)
signal modified(amount:Stats)

var id:String = "":
    set(v):
        id = v
        logs.set_prefix(id)
@export var ignore_limits:bool = false
@export var max_hp:int:
    set(x):
        # scale up current hp
        hp = int((1.0 * hp / max_hp) * x)
        max_hp = x
@export var hp: int
@export var movespeed: Vector2
@export var strength: int
@export var attack_speed: float:
    set(v):
        if ignore_limits:
            attack_speed = v
        else:
            attack_speed = max(MIN_ATTACK_SPEED, min(MAX_ATTACK_SPEED, v))
@export var invincible: bool = false

func accept(visitor: Visitor):
    visitor.visit_stats(self)

func take_damage(v:int) -> Stats:
    logs.info("take damage: %d" % v)
    if invincible:
        logs.debug("invincible")
        return self
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

func apply_to(stats:Stats):
    stats.attack_speed += attack_speed
    stats.strength += strength
    stats.max_hp += max_hp
    stats.movespeed += movespeed
    stats.modified.emit(self)
