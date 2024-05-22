extends Node2D

@export var parent:Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var vr = get_viewport_rect()
	var m = 192
	if global_position.x > vr.size.x + m:
		parent.global_position.x = -m
	if global_position.x < -m:
		parent.global_position.x = vr.size.x + m
	if global_position.y > vr.size.y + m:
		parent.global_position.y = -m
	if global_position.y < -m:
		parent.global_position.y = vr.size.y + m
