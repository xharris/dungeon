extends Node

var start_room = preload("res://scene/room/start.tscn")

var rooms:Dictionary = {
	Game.Easy: {
		"spike_s": preload("res://scene/room/spike_s.tscn"),
	}
}

var starter_rooms:Array[PackedScene] = [
	preload("res://scene/room/spike_s.tscn")
]
