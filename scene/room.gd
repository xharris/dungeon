class_name Room
extends Node2D

static var l = Logger.create("room")
const Group = "room"

enum RoomType {Normal, Entrance, Exit}

static func get_by_type(room_type:Room.RoomType) -> Array[Room]:
	var rooms:Array[Room] = []
	rooms.assign(Game.get_tree().get_nodes_in_group(Group).filter(func(r:Room): return r.room_type == room_type))
	return rooms

static func get_at_position(pos:Vector2i) -> Room:
	for room in Game.get_tree().get_nodes_in_group(Group):
		room = room as Room
		if room.room_position == pos:
			return room
	return null

signal completed
signal repositioned
signal move_to_room(Room)

var room_position:Vector2i:
	set(v):
		room_position = v
		repositioned.emit(room_global_position())
		queue_redraw()

@export var room_type:RoomType = RoomType.Normal
var _npcs:Array[NPC] = []
var paused = false:
	set(v):
		for e in get_enemies():
			e.paused = v
		paused = v

func on_move_up_pressed():
	var room = get_neighbor(Vector2i(0, -1))
	if room:
		move_to_room.emit(room)

func on_move_right_pressed():
	var room = get_neighbor(Vector2i(1, 0))
	if room:
		move_to_room.emit(room)
		
func on_move_down_pressed():
	var room = get_neighbor(Vector2i(0, 1))
	if room:
		move_to_room.emit(room)
		
func on_move_left_pressed():
	var room = get_neighbor(Vector2i(-1, 0))
	if room:
		move_to_room.emit(room)

func get_neighbor(relative_pos:Vector2i) -> Room:
	return Room.get_at_position(room_position + relative_pos)

func show_move_buttons():
	var move_buttons = %MoveButtons as Control
	move_buttons.visible = true

func room_global_position() -> Vector2:
	return Game.size() * Vector2(room_position)

func get_bounds() -> Rect2:
	var size = Game.size()
	return Rect2(global_position, size)

func get_center() -> Vector2:
	var b = get_bounds()
	return b.position + (b.size/2.0)

func set_room_name(n:String):
	var label = %RoomType
	label.text = n

func add_npc(e:NPC):
	_npcs.append(e)
	add_child(e)

func get_enemies() -> Array[NPC]:
	return _npcs.filter(func(npc): return npc.type == NPC.NPCType.Enemy)
	
func enable():
	if !paused:
		return
	paused = false

func _update_move_buttons():
	# show buttons where neighbors exist
	(%GoUp as Button).visible = get_neighbor(Vector2i(0, -1)) != null
	(%GoRight as Button).visible = get_neighbor(Vector2i(1, 0)) != null
	(%GoDown as Button).visible = get_neighbor(Vector2i(0, 1)) != null
	(%GoLeft as Button).visible = get_neighbor(Vector2i(-1, 0)) != null

func _ready():
	l.debug("ready")
	add_to_group(Group)
	_update_move_buttons()
	Game.room_added.emit()
	Game.room_added.connect(_update_move_buttons)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var room_type_label := %RoomType as Label
	room_type_label.text = "{name} {x},{y}".format({ "name":RoomType.find_key(room_type), "x":room_position.x, "y":room_position.y })

func _draw():
	var b = get_bounds()
	b.position = Vector2.ZERO
	draw_rect(b, Color.BLUE, false, 2)
