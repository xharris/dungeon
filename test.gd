# Test.gd
extends Node

var fist: Item = preload("res://src/items/fist.tres")

func _ready():
    print("--- ORIGINAL ---")
    print("class:", fist.get_class())
    print("script:", fist.get_script())

    var shallow = fist.duplicate(false)
    var deep = fist.duplicate(true)

    print("--- SHALLOW ---")
    print("class:", shallow.get_class())
    print("script:", shallow.get_script())

    print("--- DEEP ---")
    print("class:", deep.get_class())
    print("script:", deep.get_script())
