extends Node2D

var current_room:Room

func _ready():
	Game.start()
	add_child(Game.dungeon)
