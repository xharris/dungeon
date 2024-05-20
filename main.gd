extends Node2D
class_name Main

static var main:Main

func _ready():
	Main.main = self
	Game.start()
