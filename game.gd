extends Node

enum GameOverType {PLAYER_DEATH}

signal over(type:GameOverType)
        
var size:Vector2:
    get:
        return get_viewport().get_visible_rect().size

func _ready() -> void:
    Characters.character_created.connect(_on_character_created)

func _on_character_created(c:Character):
    if c.is_in_group(Groups.CHARACTER_PLAYER):
        over.emit(GameOverType.PLAYER_DEATH)

func start():
    # create first room
    var room = Rooms.next_room(Scenes.ROOM_MAIN)
    
func reset():
    Characters.destroy_all()
    Rooms.destroy_all()

func is_over() -> bool:
    var player = Characters.get_player()
    return player and not player.stats.is_alive()
