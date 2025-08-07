class_name Character
extends CharacterBody2D

@onready var sprite:CharacterSprite = $CharacterSprite

class State:
	var idle = false
	var move_to_target = false
	var fall = false

var target_position:Vector2
var state = State.new()

func move_to_x(x:int):
	Logs.debug("move to x=%d" % x)
	target_position.x = x
	state.move_to_target = true

func _physics_process(delta: float) -> void:
	# gravity
	velocity += get_gravity() * delta
	move_and_slide()
	
	var norm_move_to_target = (target_position - global_position).normalized()
		
	if state.move_to_target and not state.fall:
		global_position.x = lerp(global_position.x, target_position.x, delta)
		# face left/right
		sprite.scale.x = (-1 if norm_move_to_target.x < 0 else 1) * abs(sprite.scale.x)
		
	# walking animation
	if state.move_to_target:
		if norm_move_to_target.x > 0.3:
			sprite.walk()
			sprite.speed_scale = lerpf(0.2, 2, norm_move_to_target.x)
		else:
			sprite.stand()
	
	if state.idle:
		sprite.stand()
	
	# update state
	state.fall = not is_on_floor()
	state.move_to_target = \
		is_on_floor() and \
		abs(target_position.x - global_position.x) >= 10
	state.idle = not (state.fall or state.move_to_target)
