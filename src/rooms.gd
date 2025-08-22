extends Node

class Room:
    var characters:Array[Character]
    var node:Node2D
    var config:RoomConfig

signal room_created(room:Room)
signal room_finished(room:Room)

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

func destroy_all():
    logs.info("destroy all")
    for r in rooms:
        # remove node
        Util.destroy(r.node)
        # remove characters
        for c in r.characters:
            c.destroy()
    rooms.clear()
    
func current_room() -> Room:
    if rooms.size() > 0:
        return rooms[-1]
    return null

## get all characters in current room (plus player)
func current_characters() -> Array[Character]:
    var current = current_room()
    var out:Array[Character]
    # add player
    var player = Characters.get_player()
    if player:
        out.append(player)
    # add characters in currenet room
    if current:
        out.append_array(current.characters)
    return out

func next_room(config:RoomConfig) -> Room:    
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
    
    room_created.emit(room)
    rooms.append(room)
    return room

func finish_room():
    var current = current_room()
    if current:
        logs.info("'%s' finished" % current.config.id)
        for v in current.config.on_room_finished:
            v.run()
        room_finished.emit(current)
