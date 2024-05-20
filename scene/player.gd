extends Node2D
class_name Player

static var l = Logger.create("player")
static var Group = "player"

@export var sprite:NPCSprite
@export var movement:RunMovement
@export var hurtbox:CharacterBody2D
@export var health:Health

@export var restrict_velocity_x:bool = false
@export var restrict_velocity_y:bool = false
@export var acceleration:float = 110

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group(Group)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# sprite animation
	sprite.set_animation_speed(4 * movement.velocity.length() * 1.5)
	if movement.velocity != Vector2.ZERO:
		sprite.walk()
	else:
		sprite.stand()
	# face direction
	if movement.direction < Vector2.ZERO:
		sprite.face_left()
	if movement.direction > Vector2.ZERO:
		sprite.face_right()
	# hit something damaging
	hurtbox.position = Vector2.ZERO
	var collision = hurtbox.move_and_collide(Vector2.ZERO)
	if collision:
		var norm = collision.get_normal().round()
		movement.bounce(norm)
		health.take_damage(1)
	var vel = movement.velocity
	if restrict_velocity_x:
		vel.x = 0
	if restrict_velocity_y:
		vel.y = 0
	global_position += vel * delta * acceleration