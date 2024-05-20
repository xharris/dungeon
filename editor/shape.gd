## TODO Allows previewing a shape in the editor if a shape property is exported
class_name EditorShape
extends Node2D

static func use(parent:Node2D, properties:Array[String]):
	if !Engine.is_editor_hint():
		return

static func notify_changed(parent:Node2D):
	if !Engine.is_editor_hint():
		return

var properties:Array[String] = []
var _tool_collision_shape:CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready():
	_tool_collision_shape = CollisionShape2D.new()
	add_child(_tool_collision_shape)
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
