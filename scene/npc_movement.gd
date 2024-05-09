class_name NPCMovement
extends Node2D

var l = Logger.create("npc_movement")

signal started_moving
signal move(Vector2)
signal reached_target

var target:Node2D
var target_distance:int:
	set(v):
		target_distance = v
		queue_redraw()

var in_range = false
var paused = false
var velocity:Vector2

func _check_in_range(emit:bool = false):
	if target.global_position.distance_to(global_position) <= target_distance:
		if !in_range || emit:
			l.debug("reached target")
			reached_target.emit()
			move.emit(velocity)
		in_range = true
	else:
		if in_range || emit:
			l.debug('started moving')
			started_moving.emit()
		in_range = false

func set_target(t:Node2D):
	if target != t:
		l.debug("set movement target ", t)
		target = t
		_check_in_range(true)

## Stop movement and clear target
func reset():
	if target:
		l.debug('reset movement')
		target = null
		in_range = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target == null:
		return
	_check_in_range()
	# move towards target
	if !in_range && !paused:
		velocity = (target.global_position - global_position).normalized()
		move.emit(velocity)
	# reached target
	if in_range && velocity != Vector2.ZERO:
		velocity = Vector2.ZERO

func _draw():
	draw_arc(Vector2(0, 0), target_distance, 0, TAU, 180, Color.WHITE, 1)
