extends Node2D
class_name Main

var logs = Logger.new("main")

@onready var camera:GameCamera = $GameCamera
@onready var environment:GameEnvironment = $Environment
@onready var characters = $Characters
@onready var rooms = $Rooms
@onready var pause_ui:UILayer = $PauseUI
@onready var looting_ui = $LootingUI

var ROOM_TEST_COMBAT:RoomConfig = preload("res://rooms/test_combat.tres")
var STARTING_ZONE:ZoneConfig = preload("res://zones/forest/forest.tres")

func _init() -> void:
    #Logger.set_global_level(Logger.Level.DEBUG)
    Util.main_node = self

func _ready() -> void:    
    Rooms.room_created.connect(_on_room_created)
    Rooms.room_finished.connect(_on_room_finished)
    Game.over.connect(_on_game_over)
    
    Game.start()
    
func _on_game_over(_type:Game.GameOverType):
    Game.reset()
    camera.reset()
    environment.reset()
    Game.start()

func _on_room_finished(room:Rooms.Room):
    # disable combat
    for c in Characters.get_all():
        c.disable_combat()
    Rooms.next_room(STARTING_ZONE.rooms.pick_random())

func _on_room_created(room:Rooms.Room):
    environment.expand()
    
    # add characters
    for c in room.config.characters:
        var char = Scenes.CHARACTER.instantiate() as Character
        char.use_config(c)
        char.global_position += room.node.global_position
        match c.group:
            Groups.CHARACTER_PLAYER:
                char.global_position.x -= (Game.size.x / 2) + (Util.get_rect(char).size.x * 2)
            Groups.CHARACTER_ENEMY:
                char.global_position.x += (Game.size.x / 2) + (Util.get_rect(char).size.x * 2)
        char.position.y = 0
        char.stats.death.connect(_on_character_death.bind(char, room))
        room.characters.append(char)
    # add characters to tree
    for c in room.characters:
        characters.add_child(c)  
    # add room to tree
    rooms.add_child(room.node)
    # move camera to current room
    camera.move_to(room.node.position)
    
    await Characters.arrange_characters(room)

func _on_character_death(character:Character, room:Rooms.Room):
    var enemies:Array[Character] = room.characters.filter(func(c:Character): 
        return c.is_in_group(Groups.CHARACTER_ENEMY)
    )
    var enemies_alive = enemies.reduce(func(prev:int, curr:Character): 
        return prev + (1 if curr.stats.is_alive() else 0)
    , 0)
    
    if Game.is_over():
        room.finish_room()
    
    elif enemies_alive == 0:
        # combat is over
        for c in Characters.get_all():
            c.disable_combat()
            
        # room.finish_room() # TODO remove
        
        # show create looting ui
        if logs.warn_if(looting_ui.set_state(UILayer.State.VISIBLE), "could not create looting ui"):
            return
            
        var first = false
        for c in Characters.get_all():
            if c.is_in_group(Groups.CHARACTER_PLAYER) or c.is_in_character_group(Groups.CHARACTER_ALLY):
                c.inspect_node.set_state(UIInspectNode.State.HIDDEN)
                continue
            c.inspect_node.set_state(UIInspectNode.State.VISIBLE)
            c.inventory.lootable = true
            if not first:
                first = true
                c.inspect_node.control.grab_focus()
        
        if room.config.enable_continue:
            # TODO show 'continue' button
            pass
