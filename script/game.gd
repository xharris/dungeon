extends Node2D

var l = Logger.create("game")

enum Mode {Normal, Random}

var dev = true
var mode:Mode = Mode.Normal
var difficulty = 1
var current_room_node:Node2D
var current_room_name:Scenes.RoomName
var visited_rooms:Array[String] = []

func mark_room_visited(room:String):
	visited_rooms.append(room)

func is_room_visited(room:String):
	visited_rooms.has(room)

func get_next_room() -> PackedScene:
	var possible_rooms:Array[String] = []
	# get rooms for current difficulty
	var difficulty_rooms:Array[String] = []
	if Scenes.difficulty.has(difficulty):
		difficulty_rooms.assign(Scenes.difficulty.get(difficulty))
	possible_rooms.append_array(difficulty_rooms)
	# remove visited
	possible_rooms = possible_rooms.filter(func(r:String):return !is_room_visited(r))
	return Scenes.rooms.get(possible_rooms.pick_random() as String) as PackedScene

func go_to_room(next:Scenes.RoomName, player:Player = null) -> Room:
	l.info("load room {name}",{"name":Scenes.RoomName.find_key(next)})
	# load next room
	var next_room_node = Scenes.room(next)
	if !next_room_node:
		l.error("could not load room {name}",{"name":Scenes.RoomName.find_key(next)})
	# move player
	if player:
		player.reparent(next_room_node)
	# swap old with new
	Main.main.add_child(next_room_node)
	Main.main.remove_child(current_room_node)
	current_room_node = next_room_node
	current_room_name = next
	return current_room_node.get_tree().get_first_node_in_group(Room.Group) as Room

func clean():
	for child in Main.main.get_children():
		Main.main.remove_child(child)
	current_room_node = null
	visited_rooms = []

func start():
	go_to_room(Scenes.start_room)

func restart():
	clean()
	start()

