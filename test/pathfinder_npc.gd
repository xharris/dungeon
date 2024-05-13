extends Node2D

@export var pathfinder:Pathfinder

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position += pathfinder.velocity * 0.5
