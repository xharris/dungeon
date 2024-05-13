extends Node2D

var l = Logger.create("pathfinder_region", Logger.Level.Debug)

var margin = 32
var region:NavigationRegion2D
var _need_update = false

func _to_packed_vec_array(shape:Shape2D, pos:Vector2) -> PackedVector2Array:
	if shape is CircleShape2D:
		var r = shape.radius
		var d = r * 2
		return PackedVector2Array([
			Vector2(0, 0) - Vector2(r, r) + pos,
			Vector2(0, d) - Vector2(r, r) + pos,
			Vector2(d, d) - Vector2(r, r) + pos,
			Vector2(d, 0) - Vector2(r, r) + pos,
		])
	if shape is RectangleShape2D:
		var s = shape.size
		return PackedVector2Array([
			Vector2(0, 0) - (s/2) + pos,
			Vector2(0, s.y) - (s/2) + pos,
			Vector2(s.x, s.y) - (s/2) + pos,
			Vector2(s.x, 0) - (s/2) + pos,
		])
	return PackedVector2Array()

func update_mesh():
	_need_update = true

# Called when the node enters the scene tree for the first time.
func _ready():
	region = NavigationRegion2D.new()
	add_child(region)

func _process(delta):
	if _need_update:
		_need_update = false
		# clear shapes
		for child in region.get_children():
			region.remove_child(child)
		var mesh = NavigationPolygon.new()
		var bounds:Rect2
		# get shapes
		var shapes:Array[Shape2D] = []
		for node in get_tree().get_nodes_in_group(Pathfinder.Group):
			node = node as Pathfinder
			if !node.is_solid:
				continue
			# expand nav region
			var shape = node.shape
			var rect = shape.get_rect()
			rect.position += node.global_position
			bounds = bounds.merge(rect.grow(margin))
			# add shape to region
			var polygon = Polygon2D.new()
			polygon.visible = false
			polygon.polygon = _to_packed_vec_array(shape, node.global_position)
			region.add_child(polygon)
		mesh.add_outline(PackedVector2Array([
			bounds.position,
			bounds.position + Vector2(0, bounds.size.y),
			bounds.position + bounds.size,
			bounds.position + Vector2(bounds.size.x, 0),
		]))
		region.navigation_polygon = mesh
		region.bake_navigation_polygon()
