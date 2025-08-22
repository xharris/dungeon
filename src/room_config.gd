extends Resource
class_name RoomConfig

var logs = Logger.new("room")

@export var id:String = "unknown":
    set(v):
        id = v
        logs.set_prefix(id)
## Spawn given characters in the room. Their positions will be arranged.
@export var characters:Array[CharacterConfig]
## OPTIONAL Instantiate [code]scene[/code] and add it to the room node
@export var scene:PackedScene
## Start combat as soon as all characters are arranged
@export var enable_combat = false
## Show a 'continue' button when: combat is over
@export var enable_continue = true
## OPTIONAL call `Rooms.next_room(next_room)` when this room is finished
@export var next_room:RoomConfig
@export var on_room_finished:Array[Visitor]
