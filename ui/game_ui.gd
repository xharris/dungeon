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
    ## TODO LOOTING
}

signal state_popped(state:State)

@onready var canvas_layer:CanvasLayer = $CanvasLayer
#@onready var container:Container = $CanvasLayer/Container

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
var _inspect_nodes:Array[UIInspectNode]
var _inspect_index:int
var _inspect_enabled:bool = false

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
        disable_inspect()
        var state = _state.pop_back() as State
        var ui_layer = _layer.pop_back() as UILayer
        Util.destroy(ui_layer)
        state_popped.emit(state)
        logs.info("pop '%s'" % State.find_key(state))
        return true
    return false

func enable_inspect() -> bool:
    logs.info("enable inspect")
    if _inspect_enabled:
        return true
    var layer = current_layer()
    if not layer:
        logs.warn("no current ui layer")
        return false
    # enable
    _inspect_enabled = true
    layer.set_background_color(Color.BLACK)
    _inspect_index = -1
    _get_inspect_nodes()
    for n in _inspect_nodes:
        n.enable(layer)
    layer._update_focus()
    move_inspect_right()
    return true

func disable_inspect() -> bool:
    logs.info("disable inspect")
    if not _inspect_enabled:
        return true
    var layer = current_layer()
    if not layer:
        logs.warn("no current ui layer")
        return false
    # disable
    layer.set_background_color(Color.BLACK)
    _inspect_index = -1
    # reset all inspect nodes
    _get_inspect_nodes()
    for n in _inspect_nodes:
        n.disable()
    _inspect_enabled = false
    return true

func _get_inspect_nodes():
    if not _inspect_enabled:
        _inspect_nodes = []
        _inspect_index = -1
        return
    _inspect_nodes.assign(get_tree().get_nodes_in_group(Groups.UI_INSPECT_NODE))
    _inspect_nodes = _inspect_nodes.filter(func(n:UIInspectNode):
        return n.is_visible_on_screen()    
    )
    if _inspect_nodes.size() == 0:
        logs.warn("no inspect nodes found")
        return
    _inspect_nodes.sort_custom(func(a:UIInspectNode, b:UIInspectNode):
        return a.global_position.x < b.global_position.x
    )
    logs.info("inspect nodes: %s" % [_inspect_nodes.map(func(n:UIInspectNode): 
        return n.get_parent().name if n.get_parent() else n.name
    )])

func move_inspect(amount:int):
    logs.info("move inspect: %d"%amount)
    if not _inspect_enabled:
        return
    var layer = current_layer()
    if not layer:
        logs.warn("no current layer")
        return
    # get inspect nodes
    _get_inspect_nodes()
    if _inspect_nodes.size() == 0:
        return
    # change index
    _inspect_index = wrapi(_inspect_index + amount, 0, _inspect_nodes.size())
    var node = _inspect_nodes[_inspect_index]
    if logs.error(node != null, "inspect node %d is somehow null" % _inspect_index):
        return
    layer.clear_top_row()
    layer.clear_bottom_row()
    node.select()
    layer._update_focus()

func move_inspect_right():
    return move_inspect(1)
    
func move_inspect_left():
    return move_inspect(-1)
