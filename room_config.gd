extends Resource
class_name RoomConfig

var logs = Logger.new("room")

@export var id:String = "unknown":
    set(v):
        id = v
        logs.set_prefix(id)
## Spawn given characters in the room. Their positions will be arranged.
@export var characters:Array[CharacterConfig]
## Instantiate [code]scene[/code] and add it to the room node (optional)
@export var scene:PackedScene
## Start combat as soon as all characters are arranged
@export var enable_combat = false
