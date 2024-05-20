extends Node2D

var l = Logger.create("game")

const Easy = "easy"
const Hard = "hard"

var mode:String
var level:int = 1
var current_room:Node2D
var visited_rooms:Array[String]

func get_next_room() -> PackedScene:
	var possible_rooms:Array[PackedScene] = []
	# get starter rooms if there's any left
	if Scenes.starter_rooms.size() > 0:
		Scenes.starter_rooms.shuffle()
		return Scenes.starter_rooms.pop_back()
	# get rooms for current mode
	var mode_rooms:Array[PackedScene] = []
	mode_rooms.assign((Scenes.rooms.get(mode) as Dictionary).values())
	possible_rooms.append_array(mode_rooms)
	return possible_rooms.pick_random()

func go_to_room(next:PackedScene):
	l.info("load room {path}",{"path":next.resource_path})
	# load next room
	var next_room := next.instantiate() as Node2D
	if !next_room:
		l.error("could not load room {path}",{"path":next.resource_path})
	# get player
	var player:Player
	if current_room:
		## TODO there are 2 players for some reason
		player = current_room.get_tree().get_nodes_in_group(Player.Group).front()
		player.reparent(next_room)
	# swap old with new
	Main.main.add_child(next_room)
	Main.main.remove_child(current_room)
	current_room = next_room

func go_to_next_room():
	var next = get_next_room()
	go_to_room(next)

func clean():
	for child in get_children():
		remove_child(child)

func start():
	go_to_room(Scenes.start_room)

func restart():
	clean()
	start()

