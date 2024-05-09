class_name NPCSprite
extends Node2D

signal attack_climaxed

var animations:Dictionary = {}

func _attack_climaxed():
	attack_climaxed.emit()

func face_right():
	scale.x = 1
	
func face_left():
	scale.x = -1

func attack():
	var player := %AnimationPlayer as AnimationPlayer
	player.stop(true)
	player.play("attack")

func walk():
	var player := %AnimationPlayer as AnimationPlayer
	player.play("walk")

func stand():
	var player := %AnimationPlayer as AnimationPlayer
	player.play("stand")
