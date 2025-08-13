extends Node2D

var logs = Logger.new("main")

func _ready() -> void:
    # move player onto screen
    var player = Characters.get_player()
    if player:
        player.move_to_x(200)
    else:
        logs.warn("player not found")

## play game
func _on_button_pressed() -> void:
    logs.info("pressed play")
    Rooms.next_room(Scenes.ROOM_TEST_COMBAT)
