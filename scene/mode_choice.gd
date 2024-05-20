extends Area2D
class_name ModeChoice

static var l = Logger.create("mode_choice")

signal entered_area(mode_name:String)
signal exited_area()

@export var label_text:String:
	set(v):
		var label := %Label as Label
		label.text = v
var _contains_player = false

func _process(delta):
	var control := %Control as Control
	control.position.y = global_position.y

func _on_body_entered(body):
	l.info(body.get_parent())
	if body.get_parent() is Player:
		_contains_player = true
		entered_area.emit(name)

func _on_body_exited(body):
	if body.get_parent() is Player:
		_contains_player = false
		exited_area.emit()
