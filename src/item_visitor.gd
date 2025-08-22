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
        var data:Dictionary
        if source: data.set("source", source.id)
        if target: data.set("target", target.id)
        if item: data.set("item", item.id)
        if trigger_item: data.set("trigger_item", trigger_item.id)
        return JSON.stringify(data)
    
var ctx:Context

# helper funcs

## add [code]amount[/code] charge to all given items
func add_charge_all(items:Array[Item], amount:int = 1):
    for item in items:
        item.add_charge(amount)

# visitor callbacks

func get_description() -> String:
    return ""

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
