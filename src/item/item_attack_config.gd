extends Resource
class_name ItemAttackConfig

enum AnimationOrder {LINEAR, RANDOM}

## how large the sweet spot is
@export_enum("EASY", "MEDIUM", "HARD") var difficulty:int
## where the sweet spot is in the attack animation
@export_custom(PROPERTY_HINT_NONE, "suffix:seconds") var midpoint:float = 0
## comma separated animation names
@export var animation_name:String = "swing_up,swing_down":
    set(v):
        animation_name = v
        _animation_names.assign(v.split(",", false))
        logs.info("set animation names: %s -> %s" % [v, _animation_names])
@export var animation_order:AnimationOrder
## if the sweet spot is triggered, ignore the normal attack strategy
@export var sweet_spot_skip_attack:bool = false
@export var attack_strategy:Array[AttackStrategy]
@export var sweet_spot_strategy:Array[AttackStrategy]

var logs = Logger.new("item_attack_config")

var _animation_names:Array[String]
var _animation_index:int = -1

func next_animation() -> String:
    if _animation_index > _animation_names.size():
        return ""
    match animation_order:
        AnimationOrder.LINEAR:
            _animation_index += 1
        AnimationOrder.RANDOM:
            _animation_index = randi() * _animation_names.size()
    _animation_index = wrapi(_animation_index, 0, _animation_names.size())
    return _animation_names[_animation_index]

func get_sweet_spot_size() -> float:
    return [0.025, 0.03, 0.05][difficulty]

func is_in_sweet_spot(elapsed:float) -> bool:
    var size = get_sweet_spot_size()
    return elapsed >= midpoint - size and elapsed <= midpoint + size

func is_past_sweet_spot(elapsed:float) -> bool:
    var size = get_sweet_spot_size()
    return elapsed > midpoint + size

## apply damage, shoot projectile, etc
func run(character:Character, sweet_spot:bool = false):
    for s in attack_strategy:
        s.run(character)
