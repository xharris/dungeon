extends Node2D

var logs = Logger.new("main")

var ROOM_TEST_COMBAT:RoomConfig = preload("res://rooms/test_combat.tres")

func _ready() -> void:
    # move player onto screen
    var player = Characters.get_player()
    assert(player, "player not found")
    player.move_to_x(200)

## play game
func _on_button_pressed() -> void:
    logs.info("pressed play")
    Rooms.next_room(ROOM_TEST_COMBAT)
