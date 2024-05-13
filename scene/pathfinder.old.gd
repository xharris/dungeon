#@tool
class_name Pathfinder
extends Node2D

const Group = "pathfinding"
const DefaultLayer = "_"
const GridUpdateCooldown = 1 # seconds
const GridSize = 16
static var l = Logger.create("pathfinder", Logger.Level.Debug)

signal velocity_changed(Vector2)
signal target_reached

@export var draw_debug = false
@export var is_static:bool = false
@export var layer:String = DefaultLayer
@export var avoid:Array[String] = []
@export var turn_speed:float = 15
@export var radius = 32
@export var search_radius:int = 200:
	set(v):
		search_radius = v
		_update_rays()
@export var rays:int = 8:
	set(v):
		rays = v
		_update_rays()
@export var target_distance:int = 15
@export var target:Node2D
var velocity:Vector2
var norm_vectors:Array[Vector2] = []
var target_position:Vector2:
	set(v):
		if v != target_position:
			target_position = v
			is_pathing = true
			l.debug("target {v}",{"v":v})
			_update_path()
			if _path.size():
				_next_path_position = _path.pop_front()
var is_pathing:bool
var _grid = AStarGrid2D.new()
var _update_grid_timer = GridUpdateCooldown
var _path:Array[Vector2] = []
var _next_path_position:Vector2
var _movement_vectors:Array[Vector2] = []

func _snap(v:Vector2) -> Vector2i:
	return snapped(v, Vector2(GridSize, GridSize)) / Vector2(GridSize, GridSize)

func _update_path():
	if !is_pathing:
		return
	if _grid.is_point_solid(_snap(target_position)):
		l.warn("trying to path to solid point")
		stop()
		return
	var points = _grid.get_id_path(_snap(global_position), _snap(target_position))
	l.debug("path {from} to {to}", {"from":_snap(global_position), "to":_snap(target_position)})
	_path = []
	for pt in points:
		_path.append(Vector2(pt) * GridSize)
	if _path.size() == 0:
		l.debug("empty path")
		return
	l.debug("update path pos={pos} size={size} path={path}", {"pos":global_position,"size":_path.size(),"path":_path})

var _node_regions:Dictionary = {} # Dict[Pathfinder]Rect2i
func _add_to_grid(node:Pathfinder):
	# skip if this is self or not an obstacle
	if node == self || !avoid.has(node.layer):
		return
		
	# get region this node occupies
	var node_radius = Vector2(node.radius, node.radius)
	var node_region = Rect2i(
		_snap(node.global_position - node_radius),
		_snap(node_radius * 2)
	)#.grow_individual(0, 0, 1, 1)
	_node_regions[node] = node_region
	_grid.region = _grid.region.merge(node_region)
	_grid.update()		
	l.debug(["add", _snap(node.global_position), node_region])
	
func _remove_from_grid(node:Pathfinder):
	if !_node_regions.has(node):
		return
	_node_regions.erase(node)
	l.debug(["remove", node])

func _update_grid():
	_grid.fill_solid_region(_grid.region, false)
	for node in _node_regions:
		if node.is_static:
			_grid.fill_solid_region(_node_regions[node].grow_individual(0, 0, 1, 1))

func _create_grid():
	if is_static:
		return
	l.debug("create grid")
	# grid settings
	_grid.cell_size = Vector2(GridSize, GridSize)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	_grid.jumping_enabled = true
	_grid.region = Rect2i(_snap(global_position), Vector2i(0, 0))
	# get other pathfinders
	var nodes:Array[Pathfinder] = []
	if get_tree():
		nodes.assign(get_tree().get_nodes_in_group(Group))
	# mark obstacles in grid
	for node in nodes:
		_add_to_grid(node)
	_grid.update()

func _update_rays():
	if is_static:
		return
	var rays_container = %Area2D as Area2D
	# remove previous rays
	for child in _get_rays():
		if child is RayCast2D:
			child.get_parent().remove_child(child)
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
	_create_grid()
	_update_grid()
	if !is_static:
		l.debug(["region", _grid.region])
	if !Engine.is_editor_hint():
		Game.pathfinder_added.emit(self)
		Game.pathfinder_added.connect(_add_to_grid)
		Game.pathfinder_removed.connect(_remove_from_grid)

func _exit_tree():
	if !Engine.is_editor_hint():
		Game.pathfinder_removed.emit(self)

var context_map:Array[float] = [] 
func _get_steering_vector(to:Vector2) -> Vector2:
	# get target vector
	var target_vector = Vector2.ZERO
	if is_pathing:
		target_vector = global_position.direction_to(to).normalized()
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
			danger[c] = max(interest[c], ray.target_position.length() / parent.global_position.distance_to(global_position))
	context_map = []
	#l.debug(["danger", danger])
	for c in norm_vectors.size():
		context_map.append(interest[c] - danger[c])
	# calculate final velocity
	var final_vector = Vector2.ZERO
	for c in context_map.size():
		final_vector += norm_vectors[c] * context_map[c]
	return final_vector.normalized()

func stop():
	if is_pathing:
		l.debug("done pathing")
		is_pathing = false
		target_reached.emit()
		context_map = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# update shape radius
	var shape = (%CollisionShape2D as CollisionShape2D).shape as CircleShape2D
	shape.radius = radius
	if is_static:
		return
	# update grid every once in a while
	_update_grid_timer -= delta
	#if _update_grid_timer <= 0 && target:
	_update_grid()
	# update target_position
	if target:
		target_position = target.global_position
	var close_to_next_position = _next_path_position.distance_to(global_position) <= target_distance
	var is_path_empty = _path.size() == 0
	# done pathing
	if is_pathing && is_path_empty && close_to_next_position:
		stop()
	# move to next point in path
	if !is_path_empty && close_to_next_position:
		_next_path_position = _path.pop_front()
		l.debug("next path point {pt}",{"pt":_next_path_position})
	
	_movement_vectors = [_get_steering_vector(target_position)]
	if is_pathing:
		_movement_vectors.append(global_position.direction_to(_next_path_position).normalized())
	var target_velocity = Vector2.ZERO
	for m in _movement_vectors:
		target_velocity += m
	velocity.lerp(target_velocity, delta * turn_speed)
	velocity_changed.emit(velocity)
	queue_redraw()

func _draw():
	if !draw_debug:
		return
	# draw steeing/avoidance
	for v in norm_vectors.size():
		var ctx = 1.0
		if v < context_map.size():
			ctx = context_map[v]
		var newv = (norm_vectors[v] as Vector2) * ctx
		draw_dashed_line(Vector2.ZERO, newv * 60, Color.GREEN, 1, 6)
	#draw_line(Vector2.ZERO, velocity * 60, Color.YELLOW, 2)
	for m in _movement_vectors:
		draw_line(Vector2.ZERO, m * 60, Color.YELLOW, 2)
	# draw astar
	draw_set_transform_matrix(global_transform.inverse())
	draw_rect(Rect2i(_grid.region.position * GridSize, _grid.region.size * GridSize), Color.WHITE, false)
	for x in range(_grid.region.position.x, _grid.region.size.x):
		for y in range(_grid.region.position.y, _grid.region.size.y):
			var snap_pos = Vector2i(x, y)
			if !_grid.is_in_boundsv(snap_pos):
				continue
			draw_circle(snap_pos * GridSize, 3, Color.RED if _grid.is_point_solid(snap_pos) else Color.DARK_GRAY)
	# draw path
	if is_pathing:
		draw_polyline(_path, Color.BLUE, 2)
	# draw regions
	for region in _node_regions.values():
		draw_rect(Rect2i(region.position * GridSize, region.size * GridSize), Color.PURPLE, false, 1)
