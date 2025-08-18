extends Node2D
class_name UIInspectNode

signal selected(layer:UILayer)
signal deselected

@onready var visible_on_screen_notifier:VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D
@onready var control:Control = $UIInspectNodeControl
@onready var canvas_layer:CanvasLayer = $CanvasLayer
@onready var remote_tansform:RemoteTransform2D = %RemoteTransform2D
@onready var outline:UIInspectOutline = %Outline
@onready var ui_title:RichTextLabel = %UIInspectTitle

@export var anchor_node:Node2D

var logs = Logger.new("ui_inspect_node")
var _title:String = "???"
var _selected:bool
var _is_visible:bool
var _prev_parent:Node2D
var _prev_visible:bool
var _anchor_node_copy:Node2D
var _enabled:bool = false
var _layer:UILayer

func _ready() -> void:
    add_to_group(Groups.UI_INSPECT_NODE)
    
    control.focus_entered.connect(select)
    control.focus_exited.connect(_on_focus_exited)
    visible_on_screen_notifier.screen_entered.connect(_on_screen_entered)
    visible_on_screen_notifier.screen_exited.connect(_on_screen_exited)
    
    remote_tansform.remote_path = remote_tansform.get_path_to(outline)
    
    visible_on_screen_notifier.rect = get_rect()

func _on_screen_entered():
    _is_visible = true
    
func _on_screen_exited():
    disable()
    _is_visible = false

func _on_focus_exited():
    outline.set_state(UIInspectOutline.State.VISIBLE)

func _process(delta: float) -> void:
    var rect = get_rect()
    #ui_title.position.x = rect.size.x
    ui_title.position.y = -rect.size.length()

func is_selected() -> bool:
    return _selected

func set_title(title:String):
    _title = title
    ui_title.text = title

## node is selected
func select() -> bool:
    logs.info("selected")
    outline.set_state(UIInspectOutline.State.SELECTED)
    if _selected:
        _layer.clear_top_row()
        return true
    if not _layer:
        logs.warn("no layer set for %s" % get_path())
        return false
    if not anchor_node:
        logs.warn("no anchor node for %s" % get_path())
        return false
    _layer.clear()
    # deselect other inspect nodes
    for node in get_tree().get_nodes_in_group(Groups.UI_INSPECT_NODE) as Array[UIInspectNode]:
        if node != self:
            node._deselect()
    _selected = true
    selected.emit(_layer)
    return true

func _deselect():
    if not _selected:
        return
    if not _layer:
        return
    outline.set_state(UIInspectOutline.State.VISIBLE)
    _selected = false
    deselected.emit()

func enable(layer:UILayer):
    if _enabled:
        return
    _enabled = true
    _layer = layer
    outline.set_state(UIInspectOutline.State.VISIBLE)
    # copy anchor to canvas to draw on top of background
    if anchor_node:
        outline.set_rect(get_rect())
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
        
        visible_on_screen_notifier.rect = get_rect()
    else:
        logs.warn("no anchor node set (%s)" % get_path())

func disable():
    if not _enabled:
        return
    _enabled = false
    _deselect()
    outline.set_state(UIInspectOutline.State.HIDDEN)
    if _anchor_node_copy:
        Util.destroy(_anchor_node_copy)
        anchor_node.visible = _prev_visible

func get_rect() -> Rect2:
    if anchor_node:
        return Util.get_rect(anchor_node)
    return Rect2(Vector2.ZERO, Vector2.ONE)

func is_visible_on_screen() -> bool:
    visible_on_screen_notifier.rect = get_rect()
    return _is_visible
