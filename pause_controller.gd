## Needed because process mode is set to Always (this node itself will not be paused)
extends Node

@export var pause_ui: UILayer

func _ready() -> void:
    Game.paused.connect(_on_game_paused)
    Game.resumed.connect(_on_game_resumed)

func _on_game_resumed():
    pause_ui.set_state(UILayer.State.HIDDEN)

func _on_game_paused():
    pause_ui.set_state(UILayer.State.VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        Game.toggle_pause()
