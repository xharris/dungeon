extends Node

class Room:
    var characters:Array[Character]
    var node:Node2D
    var config:RoomConfig

signal create_next_room(room:Room)

var logs = Logger.new("rooms")
## index of current room
var rooms:Array[Room]

func _ready() -> void:
    Characters.arrange_finished.connect(_on_arrange_finished)

func _on_arrange_finished():
    var current = current_room()
    if current and current.config.enable_combat:
        # enable combat
        for c in current_characters():
            c.enable_combat()

func current_room() -> Room:
    if rooms.size() > 0:
        return rooms[-1]
    return null

## get all characters in current room (plus player)
func current_characters() -> Array[Character]:
    var current = current_room()
    var out:Array[Character]
    # add player
    var player = Game.get_player()
    if player:
        out.append(player)
    # add characters in currenet room
    if current:
        out.append_array(current.characters)
    return out

func next_room(config:RoomConfig):    
    var room = Room.new()
    room.config = config
    
    # position room node
    room.node = Node2D.new()
    room.node.name = "room-%d-%s" % [rooms.size(), config.id]
    if rooms.size() > 0:
        room.node.position += \
            rooms[-1].node.position + \
            Vector2(Game.size.x, 0)
    
    logs.info("next_room %s position=%.0v" % [config.id, room.node.global_position])
    
    # instantiate scene
    if config.scene:
        var scene = config.scene.instantiate()
        room.node.add_child(scene)
    
    # add characters
    for c in config.characters:
        var char = Character.create(c)
        # position depending on group
        match c.group:
            CharacterConfig.Group.PLAYER, CharacterConfig.Group.ALLY:
                char.global_position.x = 0
            CharacterConfig.Group.ENEMY:
                char.global_position.x = Game.size.x - 30
        char.global_position += room.node.global_position
        char.position.y = Game.size.y / 2
        room.characters.append(char)
    
    rooms.append(room)
    create_next_room.emit(room)
