extends Visitor
class_name WeaponVisitor

#- swing_seconds `float` sweet spot seconds offset, also determines when the attack actually lands
#- sweet_spot_difficulty `enum {EASY, MEDIUM, HARD}`
#- sweet_spot_offset `{START, MID, END} default=MID`
#- on_success `Array[Visitor]`

# TODO move sweet spot stuff to encapsulated Resource class

## how large the sweet spot is
@export_enum("EASY", "MEDIUM", "HARD") var difficulty:int
## where the sweet spot is in the attack animation
@export_range(0, 1, 0.1, "suffix:percent") var ratio:float = 0
@export var on_success:Array[Visitor]

var _stats: Stats

func set_stats(stats: Stats):
    _stats = stats

func get_sweet_spot_size() -> float:
    return [0.2, 0.3, 0.5][difficulty]

func get_sweet_spot_range() -> Array[float]:
    var size = [0.2, 0.3, 0.5][difficulty]
    return [0, 0]

func run():
    pass
