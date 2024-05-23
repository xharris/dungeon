extends Node2D
class_name Player

static var l = Logger.create("player")
static var Group = "player"

@export var sprite:NPCSprite
@export var movement:RunMovement
@export var hurtbox:Hitbox
@export var health:Health
@export var radial_light:Light2D
@export var knockback:KnockbackTimer

@export var restrict_velocity_x:bool = false
@export var restrict_velocity_y:bool = false
@export var acceleration:float = Game.PLAYER_SPEED
@export var bounce_factor:float = 4
@export var disable_restart_on_death = false

# Called when the node enters the scene tree for the first time.
func _ready():
	health.died.connect(_on_health_died)
	knockback.hit.connect(_on_knockback_hit)
	knockback.finished.connect(_on_knockback_finished)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# sprite animation
	sprite.set_animation_speed(4 * movement.velocity.length() * 1.5)
	if !knockback.stunned:
		if movement.velocity != Vector2.ZERO:
			sprite.walk()
		else:
			sprite.stand()
		# face direction
		if movement.direction.x < 0:
			sprite.face_left()
		if movement.direction.x > 0:
			sprite.face_right()
	var vel = movement.velocity
	if restrict_velocity_x:
		vel.x = 0
	if restrict_velocity_y:
		vel.y = 0
	if knockback.stunned:
		global_position += knockback.velocity * delta
	else:
		global_position += vel * delta * acceleration

func _on_knockback_hit():
	if !knockback.stunned:
		health.take_damage(1)
	sprite.knocked_back()

func _on_knockback_finished():
	sprite.eyes_default()
	sprite.arm_down()

func _on_health_died():
	if disable_restart_on_death:
		return
	Game.restart()
