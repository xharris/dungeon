extends Node2D
class_name RunMovement

static var l = Logger.create("run_movement")

var direction:Vector2
var velocity:Vector2
var speed_scale:float = 1.0
var target_velocity:Vector2
@export var acceleration:float = 3
var _knockback_timer:Timer = Timer.new()
var _stunned = false

signal changed_direction

func _ready():
	_knockback_timer.autostart = false
	_knockback_timer.one_shot = true
	_knockback_timer.wait_time = 1
	_knockback_timer.timeout.connect(_on_knockback_done)
	add_child(_knockback_timer)
	direction = Vector2(1, 0)

func _on_knockback_done():
	_stunned = false

## after hitting something, bounce away and then continue moving
func bounce(normal:Vector2):
	velocity = normal

func knockback(normal:Vector2):
	_knockback_timer.start()
	velocity = normal
	_stunned = true

func flip_horizontal():
	direction.x = -direction.x

func _process(delta):
	target_velocity = direction * speed_scale
	if _stunned:
		target_velocity = Vector2.ZERO
	velocity = velocity.lerp(target_velocity, delta * acceleration)
	# change direction
	#if Input.is_action_just_pressed("reverse_direction"):
		#changed_direction.emit()
		#flip_horizontal()
	#if Input.is_action_just_pressed("turn_right"):
		#changed_direction.emit()
		#direction.x = 1
	#if Input.is_action_just_pressed("turn_left"):
		#changed_direction.emit()
		#direction.x = -1
	#direction.y = 0
	if Input.is_action_pressed("left"):
		direction.x = -1
		direction.y = 0
	if Input.is_action_pressed("right"):
		direction.x = 1
		direction.y = 0
	if Input.is_action_pressed("up"):
		direction.x = 0
		direction.y = -1
	if Input.is_action_pressed("down"):
		direction.x = 0
		direction.y = 1
