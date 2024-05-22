@tool
extends Node2D
class_name CircleShadow

@export var radius:float = 16:
	set(v):
		radius = v
		queue_redraw()

func _draw():
	var color = Color.hex(0x212121FF)
	color.a = 0.85
	draw_circle(Vector2.ZERO, radius, color)
