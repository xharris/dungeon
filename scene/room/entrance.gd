class_name Entrance
extends Node2D

static var l = Logger.create("entrance")

@export var room:Room
var ally_choices = 3
var allies:Array[ShopNPC] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	room.repositioned.connect(on_room_repositioned)
	
	global_position = room.room_global_position()
	
	var game_size = Game.size()
	var sep = game_size.x / ally_choices
	for i in ally_choices:
		var ally = Scenes.shop_npc()
		add_child(ally)
		ShopNPC.npc_pool.pick_random().call(ally)
		allies.append(ally)
		ally.position.x = i * sep + (sep / 2.0)
		ally.position.y = game_size.y/2
		ally.shop_item.purchased.connect(on_ally_purchased)

func on_ally_purchased():
	for ally in get_tree().get_nodes_in_group(ShopItem.Group):
		(ally as ShopItem).disable()
	room.show_move_buttons()

func on_room_repositioned(p:Vector2):
	global_position = p
