extends Node

class Room:
    var characters:Array[Character]
    var node:Node2D
    var config:RoomConfig

signal room_created(room:Room)
signal room_finished(room:Room)
signal combat_finished(room:Room)

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

func _on_death(character:Character, room:Room):
    var enemies = room.characters.filter(func(c:Character): 
        return c.is_in_group(Groups.CHARACTER_ENEMY)
    )
    var enemies_alive = enemies.reduce(func(prev:int, curr:Character): 
        return prev + (1 if curr.stats.is_alive() else 0)
    , 0)
    
    if Game.is_over():
        finish_room()
    
    elif enemies_alive == 0:
        # combat is over
        combat_finished.emit(self)
        for c in current_characters():
            c.disable_combat()
            
        finish_room() # TODO remove
        
        for e in enemies:
            # TODO add looting UI to each `e.inventory`
            pass
        
        if room.config.enable_continue:
            # TODO show 'continue' button
            pass

func destroy_all():
    for r in rooms:
        # remove node
        r.node.get_parent().remove_child(r.node)
        # remove characters
        for c in r.characters:
            c.destroy()
    
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
    
    # add characters
    for c in config.characters:
        var char = Characters.create(c)
        # position depending on group
        match c.group:
            Groups.CHARACTER_PLAYER, Groups.CHARACTER_ALLY:
                char.global_position.x = 0
            Groups.CHARACTER_ENEMY:
                char.global_position.x = Game.size.x - 30
        char.global_position += room.node.global_position
        char.position.y = Game.size.y / 2
        char.stats.death.connect(_on_death.bind(char, room))
        room.characters.append(char)
    
    rooms.append(room)
    room_created.emit(room)
    return room

func finish_room():
    var current = current_room()
    if current:
        logs.info("'%s' finished" % current.config.id)
        room_finished.emit(current)
