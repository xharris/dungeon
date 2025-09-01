class_name CharacterSprite
extends Node2D

@onready var animation_player:AnimationPlayer = $AnimationPlayer
@onready var weapon_animation_player:AnimationPlayer = $WeaponAnimationPlayer

@export var speed_scale = 1.0

class MovementState:
    var idle = false
    var walk = false

var _speed_scale = 1.0

func stand():
    animation_player.play("RESET")
    animation_player.advance(0)
    animation_player.play("character_movement/idle")
    _speed_scale = 1.0

func walk():
    animation_player.play("character_movement/walk")
    _speed_scale = 6.0

func swing():
    var animations = weapon_animation_player.get_animation_list()
    weapon_animation_player.play(animations[randi() % animations.size()])
    await animation_player.animation_finished

func reset_speed_scale():
    speed_scale = 1.0

func _process(_delta: float) -> void:
    animation_player.speed_scale = _speed_scale * speed_scale
