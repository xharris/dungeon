extends Resource
class_name Inventory

signal item_added(item:Item)
signal item_removed(item:Item, left:int)

@export var capacity:int = 2
var items:Array[Item]

func add_item(item:Item):
	items.append(item)

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
