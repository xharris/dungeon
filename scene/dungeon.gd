class_name Dungeon
extends Node2D

static var l = Logger.create("dungeon")

static var scn_room = preload("res://scene/room.tscn")
static var scn_dungeon = preload("res://scene/dungeon.tscn")

static func create(size:int = 3) -> Dungeon:
	var d := scn_dungeon.instantiate() as Dungeon
	# generate list of possible room types
	var room_types:Array[Room.RoomType] = []
	var room_type_ratios = { Room.RoomType.Shop:0.2, Room.RoomType.Choice:0.2, Room.RoomType.Fight:0.6 }
	for type in room_type_ratios:
		var ratio = room_type_ratios[type]
		for c in ceil(ratio * (size**2)):
			room_types.append(type)
	# randomly pick starting room
	var entrance_idx = randi_range(0, room_types.size()-1)
	room_types[entrance_idx] = Room.RoomType.Entrance
	# create rooms
	room_types.shuffle()
	for x in size:
		for y in size:
			var room = Room.create(room_types.pop_front())
			if room.room_type == Room.RoomType.Entrance:
				d.current_room = room
			d.add_room(room, x, y)
	# put exit in random room
	var exit := d.rooms.values().pick_random() as Room
	## spawn exit
	return d

var rooms:Dictionary = {}
var current_room:Room
var size:Vector2

func print_grid():
	for x in size.x:
		var line = ""
		for y in size.y:
			line += Room.RoomType.find_key(get_room(x, y).room_type) + "\t "
		l.info(line)

func get_room(x:int, y:int) -> Room:
	var key = "{x},{y}".format({"x":x, "y":y})
	if !rooms.has(key):
		return null
	return rooms[key]

func add_room(room:Room, x:int, y:int) -> Room:
	var key = "{x},{y}".format({"x":x, "y":y})
	rooms[key] = room
	# update size
	if x + 1 > size.x:
		size.x = x + 1
	if y + 1 > size.y:
		size.y = y + 1
	# set room position
	var viewport_size = Global.get_viewport_rect().size
	l.info("viewport {w} {h}", {"w":viewport_size.x, "h":viewport_size.y})
	room.global_position = Vector2(viewport_size.x * x + (viewport_size.x/2.0), viewport_size.y * y + (viewport_size.y/2.0))
	l.info("add room {x} {y}, {px} {py}", { "x":x, "y":y, "px":room.global_position.x, "py":room.global_position.y })
	add_child(room)
	return room

func _process(delta):
	var camera := %Camera2D as Camera2D
	if current_room != null:
		camera.global_position = current_room.global_position
