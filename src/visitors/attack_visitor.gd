extends Visitor
class_name VisitorModifyStats

# TODO move to seperate file
enum Type {SLOW, STUN}
class StatusEffect extends Resource:
    var type: Type
    ## seconds
    var duration: float

enum TARGET {SELF=0, ALLY=1, ENEMY=2}

var _stats: Array[Stats]
## positive is heal, negative is damage
@export var health: int
@export var effect: StatusEffect
@export_enum("SELF", "ALLY", "ENEMY") var possible_targets: Array[int]

func setup(stats:Array[Stats]):
    _stats = stats

func targets_self() -> bool:
    return TARGET.SELF in possible_targets

func get_target_groups(my_group:StringName) -> Array[StringName]:
    var out:Array[StringName]
    
    if TARGET.SELF in possible_targets:
        return out
    
    var allies:Array[StringName]
    var enemies:Array[StringName]
    match my_group:
        Groups.CHARACTER_PLAYER, Groups.CHARACTER_ALLY:
            allies = [Groups.CHARACTER_PLAYER, Groups.CHARACTER_ALLY]
            enemies = [Groups.CHARACTER_ENEMY]
        Groups.CHARACTER_ENEMY:
            allies = [Groups.CHARACTER_ENEMY]
            enemies = [Groups.CHARACTER_PLAYER, Groups.CHARACTER_ALLY]
            
    return out

func run():
    for s in _stats:
        s.take_damage(health)
        # TODO status effects
