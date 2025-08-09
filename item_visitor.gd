extends Resource
class_name ItemVisitor

class Context:
    var source: Character
    var target: Character
    var item: Item
    var trigger_item: Item
    
var ctx:Context

# helper funcs

## add [code]amount[/code] charge to all given items
func add_charge_all(items:Array[Item], amount:int = 1):
    for item in items:
        item.add_charge(amount)

# visitor callbacks

func on_equip():
    pass

func on_get_possible_targets() -> Array[String]:
    return []

func on_use() -> void:
    pass

func on_apply_damage() -> int:
    return ctx.item.base_damage

func on_attack_landed():
    if ctx.source:
        add_charge_all(ctx.source.inventory.items)
