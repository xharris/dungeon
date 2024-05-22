class_name NPCSprite
extends Node2D

signal attack_climaxed
signal animation_started(animation_name:String)
signal animation_finished(animation_name:String)

var l = Logger.create("npc_sprite", Logger.Level.Debug)
var animations:Dictionary = {}
@export var weapon_texture:Texture2D

func _ready():
	var player := %AnimationPlayer as AnimationPlayer
	player.animation_started.connect(_on_animation_started)
	player.animation_finished.connect(_on_animation_finished)

func _on_animation_started(anim:String):
	animation_started.emit()
	
func _on_animation_finished(anim:String):
	animation_finished.emit()

func _process(delta):
	var images := %Images as Node2D
	images.modulate = images.modulate.lerp(Color.WHITE, delta * 10)
	var weapon := %Weapon as Sprite2D
	weapon.texture = weapon_texture

func play(animation_name:String):
	var player := %AnimationPlayer as AnimationPlayer
	player.play(animation_name)

func knocked_back():
	var player := %AnimationPlayer as AnimationPlayer
	player.play("knocked_back")

func happy_jump():
	var player := %AnimationPlayer as AnimationPlayer
	player.play("happy_jump")

func eyes_default():
	var eyes := %Eyes
	eyes.animation = "default"

func arm_down():
	var arm := %Arm
	arm.animation = "down"

func eyes_happy():
	var eyes := %Eyes
	eyes.animation = "happy"
	
func set_animation_speed(speed:float):
	var player := %AnimationPlayer as AnimationPlayer
	player.speed_scale = speed

func damage():
	var images := %Images as Node2D
	images.modulate = Color.hex(0xF44336FF)

## Called when animation is at the right frame to inflict ability
func _attack_climaxed():
	attack_climaxed.emit()

func face_right():
	scale.x = 1
	
func face_left():
	scale.x = -1

func melee_attack():
	var player := %AnimationPlayer as AnimationPlayer
	player.stop(true)
	player.play("melee_attack")

func ranged_attack():
	var player := %AnimationPlayer as AnimationPlayer
	player.stop(true)
	player.play("ranged_attack")

func walk():
	var player := %AnimationPlayer as AnimationPlayer
	player.play("walk")

func stand():
	var player := %AnimationPlayer as AnimationPlayer
	player.play("stand")

