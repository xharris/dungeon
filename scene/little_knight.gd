extends Node2D

static var l = Logger.create("little_knight")

@export var chase:ChaseMovement
@export var sprite:LittleKnightSprite
@export var knockback:KnockbackTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	chase.target_detected.connect(_on_target_detected)
	sprite.stand()
	
func _on_target_detected():
	chase.enabled = false
	sprite.jump()
	sprite.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
	var at = Scenes.action_text(self, "!", Palette.Yellow700)
	at.global_position.y -= 24
	at.velocity = Vector2(0, -0.05)

func _on_animation_finished(anim_name:String):
	chase.enabled = true
	sprite.stand()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# chase
	if knockback.stunned:
		global_position += knockback.velocity * delta
	else:
		global_position += chase.velocity * delta * Game.LITTLE_KNIGHT_SPEED
	if chase.enabled:
		# face direction
		if chase.target_velocity.x > 0:
			scale.x = -1
		if chase.target_velocity.x < 0:
			scale.x = 1
		# animation
		if chase.velocity.length() > 0:
			sprite.walk()
			sprite.animation_player.speed_scale = 3 * chase.velocity.length()
		else:
			sprite.stand()
