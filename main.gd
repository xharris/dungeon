extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var d = Dungeon.create()
	d.print_grid()
	add_child(d)
