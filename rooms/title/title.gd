extends Node2D

var logs = Logger.new("main")

var ZONE_FOREST:ZoneConfig = preload("res://zones/forest/forest.tres")

func _ready() -> void:
    # move player onto screen
    var player = Characters.get_player()
    assert(player, "player not found")
    player.move_to_x(200)
    
    var game_ui = Game.get_ui()
    var ui_layer = game_ui.push_state(GameUI.State.TITLE)
    if ui_layer:
        ui_layer.set_background_color()
        var play_button = Scenes.UI_BUTTON.instantiate() as UIButton
        play_button.text = "PLAY"
        play_button.pressed.connect(_on_play_button_pressed)
        ui_layer.add_to_bottom_row(play_button)

## play game
func _on_play_button_pressed() -> void:
    logs.info("pressed play")
    ZONE_FOREST.start()
    Game.get_ui().pop_state()
