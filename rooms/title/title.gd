extends Node2D

var logs = Logger.new("main")

@onready var _ui_layer = $UILayer
var ZONE_FOREST:ZoneConfig = preload("res://zones/forest/forest.tres")

func _ready() -> void:
    # move player onto screen
    var player = Characters.get_player()
    logs.error(not player, "player not found")
    player.move(Vector2(Game.size.x / 3, 0))
    
    # button events
    for b in get_tree().get_nodes_in_group(Groups.UI_BUTTON) as Array[UIButton]:
        match b.config.id:
            "play":
                b.pressed.connect(_on_play_button_pressed)
            "settings":
                pass
            # TODO settings_button.pressed.connect(_)

## play game
func _on_play_button_pressed() -> void:
    logs.info("pressed play")
    ZONE_FOREST.start()
    _ui_layer.set_state(UILayer.State.HIDDEN)
