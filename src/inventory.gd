extends Resource
class_name Inventory

var logs = Logger.new("inventory")

signal item_added(item:Item)
signal item_removed(item:Item, left:int)

var id:String = "":
    set(v):
        id = v
        logs.set_prefix(id)
@export var capacity:int = 1
@export var items:Array[Item]
@export var lootable:bool = false

func can_add_item(item:Item):
    return count(item.id) < item.max_stack

func add_item(item:Item):
    item = item.duplicate()
    logs.info("add item: %s" % item.id)
    items.append(item)
    item_added.emit(item)

func count(item_id:String = "") -> int:
    if item_id == "":
        return items.size()
    return items.filter(func(item:Item): return item.id == item_id).size()

## Remove [code]n[/code] instances of item [code]item_id[/code]
func remove_item(item_id:String, n:int = 1):
    for i in items.size():
        var item = items[i]
        if item.id == item_id:
            items.remove_at(i)
            n -= 1
            item_removed.emit(item)
        if n <= 0:
            return

func get_item_at(i:int) -> Item:
    if i < items.size():
        return items[i]
    return null
