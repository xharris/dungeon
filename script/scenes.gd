extends Node

var l = Logger.create("scenes")
enum RoomName {
	None, Start, SBlock, SpikeS, OneLittleKnight,
	SpikeField, MovingSpikePillars,
}

var rooms:Dictionary = {
	RoomName.Start: preload("res://scene/room/start.tscn"),
	RoomName.SBlock: preload("res://scene/room/s_block.tscn"),
	RoomName.SpikeS: preload("res://scene/room/spike_s.tscn"),
	RoomName.OneLittleKnight: preload("res://scene/room/one_little_knight.tscn"),
	RoomName.SpikeField: preload("res://scene/room/spike_field.tscn"),
	RoomName.MovingSpikePillars: preload("res://scene/room/moving_spike_pillar.tscn"),
}

func get_room_name(room:Node2D) -> RoomName:
	for rn in rooms:
		if (rooms[rn] as PackedScene).resource_path == room.scene_file_path:
			return rn
	return RoomName.None

func room(room_name:RoomName) -> Node2D:
	if !rooms.has(room_name):
		l.error("Room {name} does not exist",{"name":RoomName.find_key(room_name)})
	var scene := rooms.get(room_name) as PackedScene
	return scene.instantiate()

var start_room = RoomName.Start

var difficulty:Dictionary = {
	1: [RoomName.SpikeS, RoomName.SpikeS],
}

var scn_action_text = preload("res://scene/action_text.tscn")
func action_text(from:Node2D, text:String, color:Color = Color.WHITE) -> ActionText:
	var at := scn_action_text.instantiate() as ActionText
	at.global_position = from.global_position
	at.set_text(text)
	at.set_color(color)
	Main.main.add_child(at)
	return at
