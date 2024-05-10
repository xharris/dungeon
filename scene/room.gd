class_name Room
extends Node2D

static var scn_room = preload("res://scene/room.tscn")
static var l = Logger.create("room")

enum RoomType {Fight, Shop, Choice, Entrance}

static func create(type:RoomType):
	var r := scn_room.instantiate() as Room
	r.room_type = type
	return r

var room_type:RoomType

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var room_type_label := %RoomType as Label
	room_type_label.text = RoomType.find_key(room_type)
