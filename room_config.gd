extends Resource
class_name RoomConfig

var logs = Logger.new("room")

@export var id:String = "unknown":
    set(v):
        id = v
        logs.set_prefix(id)
@export var characters:Array[CharacterConfig]
@export var scene:PackedScene
@export var enable_combat = false
