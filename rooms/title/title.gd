extends Node2D

var ZONE_FOREST: ZoneConfig = preload("res://zones/forest/forest.tres")

@export var ui_layer:UILayer

var logs = Logger.new("title")

func _ready() -> void:
    ui_layer.build_finished.connect(_on_ui_layer_build_finished)
    
    # move player onto screen
    var player = Characters.get_player()
    logs.error(not player, "player not found")
    player.move(Vector2(Game.size.x / 3, 0))
    
func _on_ui_layer_build_finished():
    # button events
    for b in get_tree().get_nodes_in_group(Groups.UI_BUTTON) as Array[UIButton]:
        match b.config.id:
            "play":
                b.pressed.connect(_on_play_button_pressed)
            "settings":
                pass
            # TODO settings_button.pressed.connect()

## play game
func _on_play_button_pressed() -> void:
    logs.info("pressed play")
    ZONE_FOREST.start()
