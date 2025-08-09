extends Resource
class_name Inventory

var logs = Logger.new("inventory")

signal item_added(item:Item)
signal item_removed(item:Item, left:int)

@export var id = "":
    set(v):
        id = v
        logs.set_prefix(v)
@export var capacity:int = 2
@export var default_items:Array[Item]

var items:Array[Item]

func _init() -> void:
    for item in default_items:
        if can_add_item(item):
            add_item(item)

func can_add_item(item:Item):
    return count(item.item_id) < item.max_stack

func add_item(item:Item):
    items.append(item)
    item_added.emit(item)

func count(item_id:String = "") -> int:
    if item_id == "":
        return items.size()
    return items.filter(func(item:Item): return item.item_id == item_id).size()

func remove_item(item_id:String, count:int = 1):
    for i in items.size():
        if items[i].item_id == item_id:
            items.remove_at(i)
            count -= 1
            item_removed.emit(items[i])
        if count <= 0:
            return
