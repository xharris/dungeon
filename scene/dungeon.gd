class_name Dungeon
extends Node2D

static var l = Logger.create("dungeon")

var rooms:Array[Room] = []
var current_room:Room
var size:int = 3

## Make all allies move to a new room
func move_to_room(room:Room):
	pass
	#for ally in Game.allies:
		#ally.

func add_room(node:Node2D, x:int, y:int):
	var room = node.find_child("Room") as Room
	if room == null:
		l.error("Could not find 'Room' component")
		return
	rooms.append(room)
	room.room_position = Vector2i(x, y)
	room.move_to_room.connect(move_to_room)
	add_child(node)

func _ready():
	# generate list of possible room types
	var room_fns:Array[Callable] = []
	var room_type_ratios = [
		[Scenes.room_shop, 1.0], # 0.2],
		#Room.RoomType.Choice:0.2, 
		#Room.RoomType.Fight:0.6 
	]
	for r in room_type_ratios:
		var fn := r[0] as Callable
		var ratio := r[1] as float
		l.debug("{count} {fn}", {"count":ceil(ratio * (size**2)), "fn":fn})
		for c in ceil(ratio * (size**2)):
			room_fns.append(fn)
	# randomly pick starting room
	var entrance_idx = randi_range(0, room_fns.size()-1)
	room_fns[entrance_idx] = Scenes.room_entrance
	# print rooms
	l.debug(room_fns)
	# create rooms
	room_fns.shuffle()
	for f in room_fns.size():
		var fn := room_fns[f] as Callable
		add_room(fn.call(), f % size, f / size)
	# randomly pick room to be entrance
	var entrances := Room.get_by_type(Room.RoomType.Entrance).filter(func(r:Room):return r.is_inside_tree())
	if !entrances.size():
		l.error("No entrance found for some reason...")
		return
	current_room = entrances.front()
	# TODO put exit in random room
	

func _process(_delta):
	var camera := %Camera2D as Camera2D
	if current_room != null:
		current_room.enable()
		camera.global_position = current_room.get_center()
