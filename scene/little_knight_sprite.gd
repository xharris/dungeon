extends Node2D
class_name LittleKnightSprite

@onready var animation_player = %AnimationPlayer as AnimationPlayer

func _ready():
	stand()

func stand():
	animation_player.speed_scale = 1
	animation_player.play("idle")
	
func walk():
	animation_player.play("walk")

func jump():
	animation_player.speed_scale = 2.5
	animation_player.play("jump")
