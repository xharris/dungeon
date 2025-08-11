extends Node2D

var logs = Logger.new("main")

const test_combat_config:RoomConfig = preload("res://rooms/test_combat.tres")

func _ready() -> void:
    # move player onto screen
    var player = Game.get_player()
    if player:
        player.move_to_x(200)
    else:
        logs.warn("player not found")

## play game
func _on_button_pressed() -> void:
    logs.info("pressed play")
    Rooms.next_room(test_combat_config)
