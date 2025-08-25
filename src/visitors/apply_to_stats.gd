extends Visitor
class_name VisitorApplyToStats

# TODO move to seperate file
enum Type {SLOW, STUN}
class StatusEffect extends Resource:
    var type: Type
    ## seconds
    var duration: float

@export var stats: Stats
## positive is heal, negative is damage
@export var health: int
@export var effect: StatusEffect
