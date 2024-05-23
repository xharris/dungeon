@tool
extends Node2D
class_name ChaseMovement

@export var target_group:String = "player"
@export var detect_radius:int = 80:
	set(v):
		detect_radius = v
		queue_redraw()
@export var acceleration:float = 1.0
var velocity:Vector2
var target_velocity:Vector2
@export var enabled = false
var _found_target:Node2D

signal target_detected
signal target_lost

func _process(delta):
	# detect target in range
	var targets:Array[Node2D] = []
	targets.assign(get_tree().get_nodes_in_group(target_group))
	targets = targets.filter(func(n:Node2D):return n.global_position.distance_to(global_position) <= detect_radius)
	if targets.size() > 0 && !_found_target:
		_found_target = targets.front()
		target_detected.emit()
	# move towards target
	if _found_target:
		target_velocity = (_found_target.global_position - global_position).normalized()
		# out of range
		if _found_target.global_position.distance_to(global_position) > detect_radius:
			_found_target = null
			target_lost.emit()
	if targets.size() == 0 or !enabled:
		target_velocity = Vector2.ZERO
	velocity = velocity.lerp(target_velocity, delta * acceleration)
	
func _draw():
	draw_arc(Vector2.ZERO, detect_radius, 0, deg_to_rad(360), 32, Color.RED, 1)
