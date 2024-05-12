extends Node2D

var l = Logger.create("game")

signal room_added

var money:int = 0
var allies:Array[NPC] = []
var level:int = 1
var dungeon:Dungeon

func delete_node(node:Node):
	node.get_parent().remove_child(node)
	node.queue_free()

func hire_ally(item:ShopNPC):
	var ally = Scenes.npc(item.ability, item.sprite, item.health)
	allies.append(ally)
	dungeon.add_child(ally)
	ally.global_position = item.global_position
	return ally

func clean():
	for a in allies:
		a.get_parent().remove_child(a)
	allies = []
	if dungeon:
		dungeon.get_parent().remove_child(dungeon)

func start():
	level = 1
	money = 10
	# create dungeon
	dungeon = Scenes.dungeon()

func restart():
	## TODO transition
	clean()
	start()

func size() -> Vector2:
	return get_viewport_rect().size
