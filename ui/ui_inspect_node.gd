extends Node2D
class_name UIInspectNode

@onready var anchor_node_holder:Node2D = %AnchorNodeHolder
@onready var canvas_layer:CanvasLayer = %CanvasLayer
@onready var visible_on_screen_notifier:VisibleOnScreenNotifier2D = $AnchorNodeHolder/VisibleOnScreenNotifier2D

@export var anchor_node:Node2D

var logs = Logger.new("ui_inspect_node")
var _selected:bool
var _is_visible:bool

func _ready() -> void:
    add_to_group(Groups.UI_INSPECT_NODE)

func _draw() -> void:
    if anchor_node and _selected:
        var size = Util.get_size(anchor_node)
        draw_circle(anchor_node.global_position, size, Color.WHITE)

## node is selected
func select(layer:UILayer):
    logs.info("selected")
    for node in get_tree().get_nodes_in_group(Groups.UI_INSPECT_NODE) as Array[UIInspectNode]:
        if node != self:
            node._deselect()
    if not anchor_node:
        logs.warn("no anchor node for %s" % get_path())
        return
    var game_ui:Node = get_tree().get_first_node_in_group(Groups.GAME_UI)
    if not game_ui:
        logs.warn("no game ui created")
        return
    _selected = true
    var anchor_position = anchor_node.global_position
    # reparent stuff
    anchor_node.replace_by(anchor_node_holder)
    canvas_layer.add_child(anchor_node)
    # reposition
    anchor_node_holder.global_position = anchor_position
    get_rect()

func get_rect() -> Rect2:
    if anchor_node:
        return Util.get_rect(anchor_node)
    return Rect2(Vector2.ZERO, Vector2.ONE)

func _deselect():
    if anchor_node:
        anchor_node_holder.replace_by(anchor_node)
    add_child(anchor_node_holder)
    _selected = false

func is_visible_on_screen() -> bool:
    var rect = get_rect()
    visible_on_screen_notifier.rect = rect
    return get_viewport().get_visible_rect().intersects(get_rect())
