class_name Entrance
extends Node2D

static var l = Logger.create("entrance", Logger.Level.Debug)

@export var room:Room
var ally_choices = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	room.repositioned.connect(on_room_repositioned)
	
	global_position = room.room_global_position()
	
	for i in ally_choices:
		var ally = Scenes.shop_npc()
		ShopNPC.npc_pool.pick_random().call(ally)
		add_child(ally)
		l.info([room.room_position, global_position])
		## TODO ally positioning is WRONG >:(

func on_room_repositioned(p:Vector2):
	global_position = p
