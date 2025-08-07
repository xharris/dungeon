class_name Room
extends Node

@export var camera:Camera2D

static var position:Vector2
## index of current room
static var index:int

static func next_room():
	position.x += Game.size.x
