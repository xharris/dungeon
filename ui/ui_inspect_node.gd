extends Node2D
class_name UIInspectNode

enum State {HIDDEN, VISIBLE, SELECTED}
static var _last_selected_node:UIInspectNode

signal selected(layer:UILayer)
signal deselected

@onready var visible_on_screen_notifier:VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D
@onready var control:Control = $Graphics/UIInspectNodeControl
@onready var canvas_layer:CanvasLayer = %CanvasLayer
@onready var remote_tansform:RemoteTransform2D = %RemoteTransform2D
@onready var outline:UIInspectOutline = %Outline
@onready var ui_title:RichTextLabel = %UIInspectTitle
@onready var graphics:Node2D = %Graphics

@export var anchor_node:Node2D

var logs = Logger.new("ui_inspect_node")#, Logger.Level.DEBUG)
var _title:String = "???"
var _is_visible:bool
var _prev_visible:bool ## preserves anchor nodes visibility
var _anchor_node_copy:Node2D
var _layer:UILayer
var _state:State

func _ready() -> void:
    add_to_group(Groups.UI_INSPECT_NODE)
    
    control.focus_entered.connect(set_state.bind(State.SELECTED))
    control.focus_exited.connect(_on_focus_exited)
    visible_on_screen_notifier.screen_entered.connect(_on_screen_entered)
    visible_on_screen_notifier.screen_exited.connect(_on_screen_exited)
    
    remote_tansform.remote_path = remote_tansform.get_path_to(outline)
    set_state(State.HIDDEN)

func _on_screen_entered():
    _is_visible = true
    
func _on_screen_exited():
    _is_visible = false

func _on_focus_exited():
    match _state:
        State.SELECTED:
            outline.set_state(UIInspectOutline.State.VISIBLE)

func _clean_ui_layer() -> bool:
    if not _layer:
        logs.warn("no layer set for %s" % get_path())
        return false
    _layer.clear()
    return true

func set_state(state:State) -> bool:
    logs.info("set state %s" % State.find_key(state))
    
    match state:
        State.HIDDEN:
            graphics.modulate = Color.TRANSPARENT
            outline.set_state(UIInspectOutline.State.HIDDEN)
            
        State.VISIBLE:
            graphics.modulate = Color.WHITE
            outline.set_state(UIInspectOutline.State.VISIBLE)
            match _state:
                State.SELECTED:
                    _clean_ui_layer()
                    deselected.emit()
                State.HIDDEN:
                    if control.has_focus():
                        set_state.bind(State.SELECTED)
                    
        State.SELECTED:
            if not _layer:
                logs.warn("_layer is null")
                return false
            # deselect other inspect nodes
            for n in get_tree().get_nodes_in_group(Groups.UI_INSPECT_NODE) as Array[UIInspectNode]:
                if n.get_state() == State.SELECTED:
                    n.set_state(State.VISIBLE)
                    
            # enable visuals
            graphics.modulate = Color.WHITE
            outline.set_state(UIInspectOutline.State.SELECTED)
            
            selected.emit(_layer)
            _last_selected_node = self
                  
    _state = state 
    get_rect() 
    _anchor_node_updated()
    return true

func get_state() -> State:
    return _state

func is_selected() -> bool:
    return _state == State.SELECTED

func set_title(title:String):
    _title = title
    ui_title.text = title
    name = "ui_inspect_node_%s" % [title]
    control.name = "ui_inspect_node_ctrl_%s" % [title]
    outline.name = "ui_inspect_node_outline_%s" % [title]
    outline.logs.set_prefix(title)

func set_layer(layer:UILayer = null):
    _layer = layer

## node is selected
func select() -> bool:
    return set_state(State.SELECTED)

func deselect() -> bool:
    match _state:
        State.SELECTED:
            return set_state(State.VISIBLE)
    return true

func is_enabled() -> bool:
    return _state != State.HIDDEN

func _anchor_node_updated():
    logs.debug("anchor node updated")
    if not anchor_node:
        logs.warn("no anchor node set")
        return
    # copy anchor to canvas to draw on top of background
    match _state:
        State.HIDDEN:
            logs.debug("remove anchor node copy")
            anchor_node.visible = true
            if _anchor_node_copy:
                Util.destroy(_anchor_node_copy)
        State.VISIBLE, State.SELECTED when not _anchor_node_copy:
            logs.debug("copy anchor node")
            # hide anchor node
            _prev_visible = anchor_node.visible
            anchor_node.visible = false
            # configure anchor node copy
            _anchor_node_copy = anchor_node.duplicate() as Node2D
            _anchor_node_copy.global_position = anchor_node.global_position
            _anchor_node_copy.scale = anchor_node.scale
            _anchor_node_copy.visible = true
            _anchor_node_copy.z_as_relative = true
            _anchor_node_copy.z_index = 10
            canvas_layer.add_child(_anchor_node_copy)
    
    if not outline:
        logs.debug("outline is null (not loaded yet)")
        return
    if not canvas_layer:
        logs.debug("canvas_layer is null (not loaded yet)")
        return
    outline.set_rect(get_rect())
    visible_on_screen_notifier.rect = get_rect()

func disable() -> bool:
    return set_state(State.HIDDEN)

func get_rect() -> Rect2:
    var rect = Rect2(Vector2.ZERO, Vector2.ONE)
    if anchor_node:
        rect = Util.get_rect(anchor_node) 
    visible_on_screen_notifier.rect = rect
    outline.set_rect(rect)
    ui_title.position.y = -rect.size.length()
    return rect

func is_visible_on_screen() -> bool:
    return _is_visible

func is_valid_neighbor() -> bool:
    return not logs.info_if(_state == State.HIDDEN, "invalid neighbor: hidden")
