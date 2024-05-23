@tool
class_name Health
extends Node2D

static var l = Logger.create("health")

signal damaged
signal died

@onready var heart_container:Container = %HeartContainer

@export var heart_texture:Texture2D = preload("res://image/heart.png")
@export var remaining:int = 5:
	set(v):
		remaining = v
		if remaining <= 0:
			l.debug("died")
			died.emit()
		_update_remaining_hearts()
@export var total:int = 5:
	set(v):
		total = v
		_update_total_hearts()

func _ready():
	remaining = total
	_update_total_hearts()

func _update_remaining_hearts():
	if !heart_container:
		return
	var hearts = heart_container.get_children()
	for h in hearts.size():
		if h + 1 > remaining:
			var heart := hearts[h] as TextureRect
			heart.modulate.a = 0.5

func _update_total_hearts():
	if !heart_container:
		return
	for heart in heart_container.get_children():
		heart_container.remove_child(heart)
	for h in total:
		var heart = TextureRect.new()
		heart.texture = heart_texture
		heart_container.add_child(heart)

func reset():
	remaining = total

func take_damage(amt:int):
	l.debug("took damage {amt}",{"amt":-amt})
	remaining -= amt
	var at = Scenes.action_text(self, str(-amt), Palette.Red300)
	at.velocity = Vector2([-1,1].pick_random() * 0.1, -2)
	at.gravity = Vector2(0, 0.1)
	damaged.emit(amt)
