extends Node2D

var money:int = 0
var allies:Array[NPC] = []
var level:int = 1
var dungeon:Dungeon

func add_ally(item:ShopNPC):
	var ally = Scenes.npc(item.ability, item.sprite, item.health)
	ally.global_position = item.global_position
	allies.append(ally)
	dungeon.add_child(ally)

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
