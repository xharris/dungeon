class_name Room
extends Node2D

static var l = Logger.create("room")
const Group = "room"

enum RoomType {Normal, Entrance, Exit}

static func get_by_type(room_type:Room.RoomType) -> Array[Room]:
	var rooms:Array[Room] = []
	rooms.assign(Game.get_tree().get_nodes_in_group(Group).filter(func(r:Room): return r.room_type == room_type))
	return rooms

signal completed
signal repositioned

var up:Room
var down:Room
var left:Room
var right:Room

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

func _connect_room(other:Room):
	if other.room_position.x > room_position.x:
		right = other
	elif other.room_position.x < room_position.x:
		left = other
	elif other.room_position.y < room_position.y:
		up = other
	elif other.room_position.y > room_position.y:
		down = other

func connect_room(other:Room):
	_connect_room(other)
	other._connect_room(self)

func is_neighboring(other:Room) -> bool:
	var xdelta = abs(room_position.x - other.x)
	var ydelta = abs(room_position.y - other.y)
	return xdelta <= 1 && ydelta <= 1

func add_npc(e:NPC):
	_npcs.append(e)
	add_child(e)

func get_enemies() -> Array[NPC]:
	return _npcs.filter(func(npc): return npc.type == NPC.NPCType.Enemy)
	
func enable():
	if !paused:
		return
	paused = false

func _ready():
	l.debug("ready")
	add_to_group(Group)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var room_type_label := %RoomType as Label
	room_type_label.text = "{name} {x},{y}".format({ "name":RoomType.find_key(room_type), "x":room_position.x, "y":room_position.y })

func _draw():
	var b = get_bounds()
	b.position = Vector2.ZERO
	draw_rect(b, Color.BLUE, false, 2)
