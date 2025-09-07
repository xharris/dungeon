# Test.gd
extends Node

@onready var item = preload("res://src/items/fist.tres")

func _ready():
    print(item.get_class())
    print(item.id)
