extends Node2D
class_name RunMovement

static var l = Logger.create("run_movement")

var direction:Vector2
var velocity:Vector2
var speed_scale:float = 1.0
var target_velocity:Vector2

signal changed_direction

func _ready():
	direction = Vector2(1, 0)

## after hitting something, bounce away and then continue moving
func bounce(normal:Vector2):
	velocity = normal
		
func flip_horizontal():
	direction.x = -direction.x

func _process(delta):
	target_velocity = direction * speed_scale
	velocity = velocity.lerp(target_velocity, delta * 3)
	# change direction
	if Input.is_action_just_pressed("reverse_direction"):
		changed_direction.emit()
		flip_horizontal()
	if Input.is_action_just_pressed("turn_right"):
		changed_direction.emit()
		direction.x = 1
	if Input.is_action_just_pressed("turn_left"):
		changed_direction.emit()
		direction.x = -1
	direction.y = 0
	if Input.is_action_pressed("steer_up"):
		direction.y = -1
	if Input.is_action_pressed("steer_down"):
		direction.y = 1
