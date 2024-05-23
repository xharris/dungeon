extends Node2D
class_name KnockbackTimer

static var l = Logger.create("knockback_timer")

@export var bounce_factor:float = 300
@export var duration:float = 1
@export var body:Hitbox:
	set(v):
		if v:
			v.collision.connect(_on_body_collision)
		elif body:
			body.collision.disconnect(_on_body_collision)
		body = v
@export var decceleration:float = 15
var velocity:Vector2
var stunned = false
var _t = 0

signal hit
signal finished

func _ready():
	if body:
		body.collision.connect(_on_body_collision)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	if stunned:
		_t += delta
		if _t > duration:
			stunned = false
			l.debug("finished")
			finished.emit()
	velocity = velocity.lerp(Vector2.ZERO, delta * decceleration)

func _on_body_collision(normal:Vector2):
	knockback(normal)

func knockback(normal:Vector2):
	hit.emit()
	if !stunned:
		l.debug("stunned")
	_t = 0
	velocity = normal * bounce_factor
	stunned = true
