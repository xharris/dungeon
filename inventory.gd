extends Resource
class_name Inventory

signal item_added(item:Item)
signal item_removed(item:Item, left:int)

@export var capacity:int = 2
var items:Array[Item]

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
