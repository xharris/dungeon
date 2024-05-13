@tool
class_name Pathfinder
extends Node2D

static var l = Logger.create("pathfinder", Logger.Level.Debug)

const Group = "pathfinder"

@export var debug_draw = false
@export var shape:Shape2D:
	set(v):
		shape = v
		notify_property_list_changed()
@export var is_static = false
@export var is_solid = false
@export var target:Node2D:
	set(v):
		target = v
		var nav_agent := %NavigationAgent2D as NavigationAgent2D
		nav_agent.target_position = v.global_position
@export var target_position:Vector2
@export_flags_2d_navigation var avoidance_layer:int = 0
@export_flags_2d_navigation var avoidance_mask:int = 0

var velocity = Vector2.ZERO
var _target_velocity = Vector2.ZERO
var _safe_velocity = Vector2.ZERO
var _tool_collision_shape:CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group(Group)
	var nav_agent := %NavigationAgent2D as NavigationAgent2D
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	if Engine.is_editor_hint():
		_tool_collision_shape = CollisionShape2D.new()
		add_child(_tool_collision_shape)
		return
	PathfinderRegion.update_mesh()

func _exit_tree():
	if Engine.is_editor_hint():
		return
	PathfinderRegion.update_mesh()

func _on_velocity_computed(safe:Vector2):
	_safe_velocity = safe

func get_radius() -> int:
	return 32

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint() && _tool_collision_shape && shape:
		_tool_collision_shape.shape = shape
		return
	# update flags
	var nav_agent := %NavigationAgent2D as NavigationAgent2D
	var nav_avoid := %NavigationObstacle2D as NavigationObstacle2D
	nav_avoid.avoidance_layers = avoidance_layer
	nav_avoid.radius = get_radius() * 2
	nav_agent.avoidance_mask = avoidance_mask
	if is_static:
		return
	# move to target
	if target:
		target_position = target.global_position
	if target_position == Vector2.ZERO && target == null:
		l.debug("no target")
		target_position = global_position
	nav_agent.target_position = target_position
	# try to move around avoided stuff
	var to_target = (target_position - global_position).normalized()
	var to_safety = _safe_velocity
	if !nav_agent.is_navigation_finished() && abs(_safe_velocity.dot(to_target)) < 0.5:
		to_safety = to_safety.rotated(deg_to_rad(90))
	velocity = velocity.lerp((to_target + to_safety) / 2.0, delta * 10)
	queue_redraw()

func _physics_process(delta):
	if is_static:
		return
	var nav_agent := %NavigationAgent2D as NavigationAgent2D
	var nav_avoid := %NavigationObstacle2D as NavigationObstacle2D
	if !nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		_target_velocity = (next_pos - global_position).normalized()
	else:
		_target_velocity = Vector2.ZERO
	nav_agent.velocity = _target_velocity
	nav_avoid.velocity = _target_velocity

func _draw():
	if !debug_draw:
		return
	var to_target = (target_position - global_position).normalized()
	var radius = get_radius()
	draw_line(Vector2.ZERO, _safe_velocity * radius * 1.4, Color.RED, 1)
	draw_line(Vector2.ZERO, to_target * radius * 1.2, Color.YELLOW, 1)
	draw_line(Vector2.ZERO, velocity * radius, Color.GREEN, 1)
