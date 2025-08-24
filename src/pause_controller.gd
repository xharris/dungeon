## Needed because process mode is set to Always (this node itself will not be paused)
extends Node
class_name PauseController

signal paused
signal resumed

@export var show_ui:UILayer
@export var action:String = "pause"

var logs = Logger.new("pause_controller")
var _paused = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(action):
        toggle_pause()
        
func is_paused() -> bool:
    return _paused

func toggle_pause() -> bool:
    if _paused:
        return resume()
    return pause()

func pause() -> bool:
    logs.info("pause")
    if logs.warn_if(_paused, "game already paused"):
        return false
    # pause
    _paused = true
    if show_ui:
        show_ui.set_state(UILayer.State.VISIBLE)
    paused.emit()
    get_tree().paused = true
    return true

func resume() -> bool:
    logs.info("resume")
    if logs.warn_if(not _paused, "game not paused"):
        return false
    # resume game
    _paused = false
    get_tree().paused = false
    if show_ui:
        show_ui.set_state(UILayer.State.HIDDEN)
    resumed.emit()
    return true
