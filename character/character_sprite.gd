class_name CharacterSprite
extends Node2D

@onready var animation_player:AnimationPlayer = $AnimationPlayer

@export var speed_scale = 1.0

var _speed_scale = 1.0
var _swing_up = false

func stand():
    #await animation_player.animation_finished
    animation_player.play("stand")
    _speed_scale = 1.0

func walk():
    animation_player.play("walk")
    _speed_scale = 6.0

func swing():
    animation_player.play("swing_up" if _swing_up else "swing_down")
    _swing_up = !_swing_up

func reset_speed_scale():
    speed_scale = 1.0

func _process(_delta: float) -> void:
    animation_player.speed_scale = _speed_scale * speed_scale
