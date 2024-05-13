@tool
class_name Pathfinder
extends Node2D

const Group = "pathfinding"
const DefaultLayer = "_"
const GridUpdateCooldown = 3 # seconds
const GridSize = 16
static var l = Logger.create("pathfinder")

signal velocity_changed(Vector2)
signal target_reached

@export var draw_debug = false
@export var is_static:bool = false
@export var layer:String = DefaultLayer
@export var avoid:Array[String] = []
@export var turn_speed:float = 15
@export var radius = 32:
	set(v):
		radius = v
		var collision = %CollisionShape2D as CollisionShape2D
		(collision.shape as CircleShape2D).radius = radius
@export var search_radius:int = 200:
	set(v):
		search_radius = v
		_update_rays()
@export var rays:int = 32:
	set(v):
		rays = v
		_update_rays()
@export var target_distance:int = 15
@export var target:Node2D
var velocity:Vector2
var norm_vectors:Array[Vector2] = []
var target_position:Vector2:
	set(v):
		target_position = v
		is_pathing = true
var is_pathing = false
var _grid = AStarGrid2D.new()
var _update_grid_timer = GridUpdateCooldown

func _snap(v:Vector2) -> Vector2i:
	return snapped(v + Vector2(GridSize, GridSize) / 2.0, Vector2(GridSize, GridSize))

func _update_grid():
	_grid.clear()
	if is_static:
		return
	var nodes:Array[Pathfinder] = []
	nodes.assign(get_tree().get_nodes_in_group(Group))
	# calculate region
	var region = Rect2i()
	for node in nodes:
		region = region.expand(node.global_position)
		var node_radius = Vector2(node.radius + radius, node.radius + radius) * 2
		region = region.expand(_snap(node.global_position - node_radius))
		region = region.expand(_snap(node.global_position + node_radius))
	_grid.region = region
	_grid.update()
	# mark obstacles in grid
	for node in nodes:
		var node_radius = Vector2(node.radius + radius, node.radius + radius)
		if node != self && avoid.has(node.layer):
			var snapped_top_left = _snap(node.global_position - node_radius)
			var snapped_bot_right = _snap(node.global_position + node_radius)
			for x in range(snapped_top_left.x, snapped_bot_right.x, GridSize):
				for y in range(snapped_top_left.y, snapped_bot_right.y, GridSize):
					if !_grid.is_in_boundsv(Vector2i(x, y)):
						continue
					_grid.set_point_solid(Vector2i(x, y))
	queue_redraw()

func set_target(t:Node2D):
	target_position = t.global_position
	is_pathing = true

func _update_rays():
	if is_static:
		return
	var rays_container = %Area2D as Area2D
	# remove previous rays
	for child in _get_rays():
		if child is RayCast2D:
			Game.delete_node(child)
	norm_vectors = []
	# add new rays
	for i in rays:
		var norm = Vector2.from_angle(deg_to_rad(360.0 * i/rays))
		norm_vectors.append(norm)
		var ray = RayCast2D.new()
		ray.set_collision_mask_value(1, true)
		ray.target_position = norm * search_radius
		ray.collide_with_areas = true
		ray.hit_from_inside = true
		ray.exclude_parent = true
		rays_container.add_child(ray)

func _get_rays() -> Array[RayCast2D]:
	var raycasts:Array[RayCast2D] = []
	var ray_container = %Area2D as Area2D
	raycasts.assign(ray_container.get_children().filter(func(c): return c is RayCast2D))
	return raycasts

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group(Group)
	_update_rays()
	_update_grid()
	if target:
		set_target(target)
		target = null
	if !Engine.is_editor_hint():
		Game.pathfinder_added.emit()
		Game.pathfinder_added.connect(_update_grid)
		Game.pathfinder_removed.connect(_update_grid)

func _exit_tree():
	Game.pathfinder_removed.emit()

var context_map:Array[float] = [] 
func _get_steering_vector() -> Vector2:
	# get target vector
	var target_vector = global_position.direction_to(target_position).normalized()
	var interest:Array[float] = []
	var danger:Array[float] = []
	var all_rays = _get_rays()
	danger.resize(norm_vectors.size())
	for c in norm_vectors.size():
		var norm = norm_vectors[c]
		var ray = all_rays[c]
		# get interest based on target position
		interest.append(norm.dot(target_vector))
		# check if ray found avoid nodes
		if ray.is_colliding():
			var parent = ray.get_collider() as Area2D
			if !parent:
				continue
			parent = parent.get_parent() as Pathfinder
			if !parent || parent == self || !avoid.has(parent.layer):
				continue
			var danger_amt = 3
			danger[c] = max(danger[c], ray.target_position.length() / parent.global_position.distance_to(global_position))
	context_map = []
	for c in norm_vectors.size():
		context_map.append(max(-1, interest[c] - danger[c]))
	queue_redraw()
	# calculate final velocity
	var final_vector = Vector2.ZERO
	for c in context_map.size():
		final_vector += norm_vectors[c] * context_map[c]
	return final_vector


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_static || (!is_pathing && !(Engine.is_editor_hint() && draw_debug)):
		return
	_update_grid_timer -= delta
	if _update_grid_timer <= 0:
		_update_grid_timer = GridUpdateCooldown
		_update_grid()
	if target_position.distance_to(global_position) <= target_distance:
		velocity = Vector2.ZERO
		velocity_changed.emit(velocity)
		target_reached.emit()
		is_pathing = false
		context_map = []
		queue_redraw()
		return
	var steer = _get_steering_vector()
	velocity = velocity.lerp(steer.normalized(), delta * turn_speed)
	velocity_changed.emit(velocity)

func _draw():
	if !draw_debug:
		return
	# draw steeing/avoidance
	for v in norm_vectors.size():
		var ctx = 1.0
		if v < context_map.size():
			ctx = context_map[v]
		var newv = (norm_vectors[v] as Vector2) * ctx
		draw_dashed_line(Vector2.ZERO, newv * 60, Color.GREEN, 3, 6)
	draw_line(Vector2.ZERO, velocity * 60, Color.YELLOW, 2)
	# draw astar
	draw_set_transform_matrix(global_transform.inverse())
	draw_rect(_grid.region, Color.WHITE, false)
	for x in range(_grid.region.position.x, _grid.region.size.x, GridSize):
		for y in range(_grid.region.position.y, _grid.region.size.y, GridSize):
			var snap_pos := _snap(Vector2(x, y))
			if !_grid.is_in_boundsv(snap_pos):
				continue
			draw_circle(snap_pos, 3, Color.RED if _grid.is_point_solid(snap_pos) else Color.DARK_GRAY)
