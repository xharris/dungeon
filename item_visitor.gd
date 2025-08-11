extends Resource
class_name ItemVisitor

static var logs = Logger.new("item_visitor")

class TARGET:
    static var SELF = "self"
    static var ALLY = "ally"
    static var ENEMY = "enemy"

class Context:
    var source: Character
    var target: Character
    var item: Item
    var trigger_item: Item
    
    func stringify() -> String:
        return JSON.stringify({
            "source": source.id if source else null,
            "target": target.id if target else null,
            "item": item.id if item else null,
            "trigger_item": item.id if item else null,
        })
    
var ctx:Context

# helper funcs

## add [code]amount[/code] charge to all given items
func add_charge_all(items:Array[Item], amount:int = 1):
    for item in items:
        item.add_charge(amount)

# visitor callbacks

func on_equip():
    pass

## Return Array["self"|"ally"|"enemy"|instance_id]
func on_get_possible_targets() -> Array:
    return []

func on_use() -> void:
    pass

func on_apply_damage() -> int:
    return ctx.item.base_damage

func on_attack_landed():
    if ctx.source:
        add_charge_all(ctx.source.inventory.items)
