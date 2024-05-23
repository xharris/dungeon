class_name ActionText
extends Node2D

enum AnimationType {Fly, Slow}

var l = Logger.create("action_text")
var gravity = Vector2.ZERO
var velocity = Vector2.ZERO
var duration = 0.5
var _t = 0

func set_text(v:Variant):
	var text := %Label as Label
	text.text = str(v)

func set_color(v:Color):
	var text := %Label as Label
	text.add_theme_color_override("font_color", v)

func _process(delta):
	_t += delta
	velocity += gravity
	global_position += velocity
	# disappear
	if _t > duration:
		modulate = modulate.lerp(Color.TRANSPARENT, delta * 20)
	# destroy
	if modulate.a <= 0:
		get_parent().remove_child(self)
