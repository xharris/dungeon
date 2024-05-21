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
@export var acceleration:float = 120
@export var bounce_factor:float = 4

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group(Group)
	health.died.connect(_on_health_died)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# sprite animation
	sprite.set_animation_speed(4 * movement.velocity.length() * 1.5)
	if movement.velocity != Vector2.ZERO:
		sprite.walk()
	else:
		sprite.stand()
	# face direction
	if movement.direction.x < 0:
		sprite.face_left()
	if movement.direction.x > 0:
		sprite.face_right()
	# hit something damaging
	var collision = hurtbox.move_and_collide(Vector2.ZERO, true)
	if collision:
		var norm = collision.get_normal().round()
		movement.knockback(norm * bounce_factor)
		health.take_damage(1)
	var vel = movement.velocity
	if restrict_velocity_x:
		vel.x = 0
	if restrict_velocity_y:
		vel.y = 0
	global_position += vel * delta * acceleration

func _on_health_died():
	Game.restart()
