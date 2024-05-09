class_name ActionText
extends Node2D

static var scn_action_text = preload("res://scene/action_text.tscn")
enum AnimationType {Fly, Slow}

static func create(source:Node2D, direction:int = 1, animation_type:AnimationType = AnimationType.Fly) -> ActionText:
	var at := scn_action_text.instantiate() as ActionText
	at.global_position = source.global_position
	at.z_index = 10
	# animation type
	match animation_type:
		AnimationType.Fly:
			at.velocity = Vector2(randi_range(1,2) * direction, -3)
			at.gravity = Vector2(0, 0.25)
			at._disappear_timer.wait_time = 0.25
	source.get_tree().root.add_child(at)
	return at

var l = Logger.create("action_text")
var gravity = Vector2.ZERO
var velocity = Vector2.ZERO
var _disappear_timer = Timer.new()

func _ready():
	add_child(_disappear_timer)
	_disappear_timer.one_shot = true
	_disappear_timer.start()

func set_text(v:Variant):
	var text := %Label as Label
	text.text = str(v)

func set_color(v:Color):
	var text := %Label as Label
	text.add_theme_color_override("font_color", v)

func _process(delta):
	velocity += gravity
	global_position += velocity
	# disappear
	if _disappear_timer.time_left <= 0:
		modulate = modulate.lerp(Color.TRANSPARENT, delta * 20)
	# destroy
	if modulate.a <= 0:
		get_parent().remove_child(self)
