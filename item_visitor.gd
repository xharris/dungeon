extends Resource
class_name ItemVisitor

class Context:
    var source: Character
    var target: Character
    var item: Item
    var attack_item: Item
    
var ctx:Context

func on_get_possible_targets() -> Array[String]:
    return []

func on_use() -> void:
    pass

func on_apply_damage() -> int:
    return ctx.item.base_damage

func on_attack_landed():
    if ctx.attack_item:
        ctx.attack_item.add_charge()
