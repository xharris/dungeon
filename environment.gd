extends Node2D

var floors:Array[Polygon2D]

func _ready() -> void:
	floors.append($Floor)

func expand():
	var last_floor = floors.back() as Polygon2D
	var x = 0
	if last_floor:
		x = last_floor.position.x + Game.size.x
	var new_floor = last_floor.duplicate() as Polygon2D
	new_floor.position.x = x
	floors.append(new_floor)
	add_child(new_floor)
