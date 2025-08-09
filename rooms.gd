extends Node

var logs = Logger.new("rooms")

signal create_next_room

@export var camera:Camera2D

var position:Vector2
## index of current room
var index:int = 0

func next_room():
    index += 1
    position.x += Game.size.x
    logs.info("next_room index=%d x=[%d, %d]" % [index, position.x, position.x + Game.size.x])
    create_next_room.emit()
