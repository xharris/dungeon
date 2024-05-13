extends Node2D

func _ready():
	Game.start()
	add_child(Game.dungeon)
