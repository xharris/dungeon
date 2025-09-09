# Test.gd
extends Node

var item: Item = preload("res://src/items/sword/sword.tres")
#var fist: Item = preload("res://src/items/fist.tres")

func _ready():
    print("=== TEST_ITEM ===")
    print("class: %s" % item.get_class())
    print("item is Item: %s" % item is Item)
    print("id: %s" % item.id)
#
    #print()
    #print("=== FIST ===")
    #print("class: %s" % fist.get_class())
    #print("item is Item: %s" % fist is Item)
    #print("id: %s" % fist.id)
