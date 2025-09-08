# Test.gd
extends Node

var inventory: Inventory
var item: Item = preload("res://src/items/test_item.tres")
var fist: Item = preload("res://src/items/fist.tres")

func _ready():
    inventory = Inventory.new()
    inventory.capacity = 1
    inventory.add_item(item)
    
    print("=== TEST_ITEM ===")
    print("class: %s" % item.get_class())
    print("item is Item: %s" % item is Item)
    print("id: %s" % item.id)

    print()
    print("=== FIST ===")
    print("class: %s" % fist.get_class())
    print("item is Item: %s" % fist is Item)
    print("id: %s" % fist.id)
