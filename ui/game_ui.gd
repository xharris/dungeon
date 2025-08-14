extends Node2D
class_name GameUI

enum State {
    NONE,
    ## title screen
    TITLE,
    ## default while playing the game
    PLAY,
    ## inspect characters
    PAUSE,
}

signal state_popped(state:State)

@onready var canvas_layer:CanvasLayer = $CanvasLayer

var initial_state:State
var allowed_next_state = {
    State.TITLE: [State.PLAY],
    State.PLAY: [State.PAUSE],
    State.PAUSE: [],
}
var cannot_exit:Array[State] = [State.TITLE, State.PLAY]

var logs = Logger.new("game_ui")
var _state:Array[State]
var _layer:Array[UILayer]
## {UI.State: Node2D}
var _state_node:Dictionary

func _ready() -> void:
    logs.info("ready")
    add_to_group(Groups.GAME_UI)
    if initial_state:
        push_state(initial_state)

func _unhandled_input(event: InputEvent) -> void:        
    var current = current_state()
    if event.is_action_pressed("exit") and current != State.NONE:
        if not current in cannot_exit:
            pop_state()
    if event.is_action_pressed("pause"):
        Game.toggle_pause()
        
func current_state() -> State:
    if _state.size() > 0:
        return _state.back()
    return State.NONE

func current_layer() -> UILayer:
    if _layer.size() > 0:
        return _layer.back()
    return null

func push_state(state:State) -> UILayer:
    logs.info("push '%s'" % State.find_key(state))
    var current = current_state()
    if current != State.NONE and not allowed_next_state.has(current):
        logs.warn("missing `allowed_next_state` list for '%s'" % State.find_key(current))
        return null
    if current != State.NONE and not (allowed_next_state.get(current) as Array[State]).has(state):
        logs.warn("next state not allowed %s" % {
            "current":State.find_key(current),
            "next":State.find_key(state)
        })
        return null
    var layer = Scenes.UI_LAYER.instantiate()
    canvas_layer.add_child(layer)
    _state.append(state)
    _layer.append(layer)
    return layer

func pop_state() -> bool:
    if _state.size() > 0:
        var state = _state.pop_back() as State
        var ui_layer = _layer.pop_back() as UILayer
        Util.destroy(ui_layer)
        state_popped.emit(state)
        logs.info("pop '%s'" % State.find_key(state))
        return true
    return false
