extends Node2D

@export var ui_layer:UILayer

var logs = Logger.new("title")

func _ready() -> void:
    ui_layer.build_finished.connect(_on_ui_layer_build_finished)
    
func _on_ui_layer_build_finished():
    # button events
    for b in get_tree().get_nodes_in_group(Groups.UI_BUTTON) as Array[UIButton]:
        match b.config.id:
            "play":
                b.pressed.connect(_on_play_button_pressed)
            "settings":
                pass # TODO

## play game
func _on_play_button_pressed() -> void:
    logs.info("pressed play")
    Events.trigger_rooms_next.emit()
