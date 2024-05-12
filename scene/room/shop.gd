class_name Shop
extends Node2D

static var l = Logger.create("shop")

class Item:
	var node:Node2D
	var cost:int
	
	func _init(_node:Node2D, _cost:int = 0):
		node = _node
		cost = _cost

signal item_purchased(item:Item)

@export var room:Room
var items:Array[Item] = []

func _ready():
	l.debug("ready")
	room.set_room_name("shop")

	room.repositioned.connect(on_room_repositioned)
	
	global_position = room.room_global_position()

func on_room_repositioned(p:Vector2):
	global_position = p

func reposition_items():
	for item in items:
		if !room.get_bounds().has_point(item.node.global_position):
			l.info(global_position)
			item.node.global_position = global_position

func add_item(item:Item):
	items.append(item)
	add_child(item.node)

func on_item_purchased(item:Item):
	l.info("purchased {item}", {"item":item})
