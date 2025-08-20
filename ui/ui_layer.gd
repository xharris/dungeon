extends Node2D
class_name UILayer

enum State {HIDDEN, VISIBLE}

signal state_changed(state:State)

@onready var _top_row: HBoxContainer = %TopRow
@onready var _bottom_row: HBoxContainer = %BottomRow
@onready var _background: Panel = %Background

@export var config: UILayerConfig

var logs = Logger.new("ui_layer") # , Logger.Level.DEBUG)
var _rows_last_selected_idx: Array[int]
var _current_selected_row: int = 0
var _state: State

func _ready() -> void:
    add_to_group(Groups.UI_LAYER)
    logs.set_prefix(config.id)
    if config.visible:
        set_state(State.VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
    if config.esc_to_close and event.is_action_pressed("exit"):
        set_state(State.HIDDEN)

# BUG the top_row and bottom_row are FUCKING EMPTY
func _build_ui():
    logs.debug("build ui %s" % config)
    for c in config.top_row:
        var button = UIElements.button(c)
        button.pressed.connect(_on_ui_button_pressed.bind(button))
        add_to_top_row(button)
    for c in config.bottom_row:
        var button = UIElements.button(c)
        button.pressed.connect(_on_ui_button_pressed.bind(button))
        add_to_bottom_row(button)
    set_background_color(config.background_color)

func _on_ui_button_pressed(me:UIButton):
    if me.config.close_on_pressed:
        set_state(State.HIDDEN)

## normal visible background color is [code]Color.WHITE[/code]
func set_background_color(color: Color = Color.TRANSPARENT):
    var tween = create_tween()
    tween.tween_property(_background, "modulate", color, 1)
    tween.play()

func add_to_top_row(node: Node) -> UILayer:
    if node is UIButton:
        logs.debug("add top top row %s" % node.config)
    _top_row.add_child(node)
    _update_focus()
    return self

func add_to_bottom_row(node: Node) -> UILayer:
    if node is UIButton:
        logs.debug("add top bottom row %s" % node.config)
    _bottom_row.add_child(node)
    _update_focus()
    return self

func clear_top_row() -> UILayer:
    Util.clear_children(_top_row)
    _update_focus()
    return self

func clear_bottom_row() -> UILayer:
    Util.clear_children(_bottom_row)
    _update_focus()
    return self

func clear() -> UILayer:
    clear_top_row()
    clear_bottom_row()
    return self

func set_title(text: String) -> Label:
    logs.info("set title: %s" % text)
    var label = UIElements.label(text)
    add_to_top_row(label)
    return label

func _get_inspect_nodes() -> Array[UIInspectNode]:
    var inspect_nodes: Array[UIInspectNode]
    inspect_nodes.assign(get_tree().get_nodes_in_group(Groups.UI_INSPECT_NODE))
    return inspect_nodes

func is_active():
    return _state != State.HIDDEN

func set_state(state: State) -> bool:
    logs.info("set state %s" % State.find_key(state))
    
    match state:
        State.HIDDEN:
            visible = false
            # disable inspect
            for n in _get_inspect_nodes():
                n.set_state(UIInspectNode.State.HIDDEN)
            set_background_color()
            clear()

        State.VISIBLE:
            #var is_layer_active = get_tree().get_nodes_in_group(Groups.UI_LAYER)\
                #.filter(func(n:UILayer): return n.is_active())\
                #.size() > 0
            #if is_layer_active:
                #logs.warn("can only have one layer active at a time (for now)")
                #return false
                
            visible = true
            _build_ui()
            _update_focus()
            
            match config.type:
                UILayerConfig.Type.TOP_BOTTOM:
                    # hide inspect ui
                    for n in _get_inspect_nodes():
                        n.set_state(UIInspectNode.State.HIDDEN)
                        
                UILayerConfig.Type.INSPECT:
                    # show inspect ui
                    for n in _get_inspect_nodes():
                        n.set_state(UIInspectNode.State.VISIBLE)
                        
            set_background_color(config.background_color)
            
    _state = state
    state_changed.emit(state)
    return true

func _get_selected_inspect_node() -> UIInspectNode:
    var nodes = _get_inspect_nodes()\
        .filter(func(n: UIInspectNode): return n.is_selected())
    if nodes.size() > 0:
        return nodes[0]
    return null

## Update focus relationships for all controls
func _update_focus():
    logs.info("update focus")
    var inspect_nodes = _get_inspect_nodes()
    var inspect_controls = inspect_nodes \
        .filter(func(n: UIInspectNode): return n.is_visible_on_screen()) \
        .map(func(n: UIInspectNode): return n.control) as Array[Control]
    var selected_inspect_node = _get_selected_inspect_node()
    
    # connect inspect node(s)
    var middle_row = inspect_controls

    var ctrl_rows = [_top_row.get_children(), middle_row, _bottom_row.get_children()]
    logs.debug("rows before %s" % [ctrl_rows])
    for i in ctrl_rows.size():
        var row: Array = ctrl_rows[i]
        logs.debug("row %d %s" % [i, row])
        if i == _current_selected_row:
            # all controls in current row are focusable
            pass
        elif row.size() > 0:
            # only last selected control in other rows are focusable
            _rows_last_selected_idx.resize(i + 1)
            var last_index = _rows_last_selected_idx[i]
            logs.debug("last index, row=%d idx=%d" % [i, last_index])
            row = [row[last_index]]
        # remove invalid controls
        row = row.filter(func(c: Node): return Util.UI.is_valid_neighbor(c))
        ctrl_rows[i] = row
    logs.debug("rows after %s" % [ctrl_rows])
    # BUG some buttons are removed from row?
    
    ctrl_rows = ctrl_rows \
        .filter(func(r): return r.size() > 0)
    var max_row_size = ctrl_rows.map(func(c: Array): return c.size()).max() if ctrl_rows.size() > 0 else 0
    var all_ctrls: Array[Control]
    
    for c in max_row_size:
        for r in ctrl_rows.size():
            var row: Array[Control]
            row.assign(ctrl_rows[r])
            Util.UI.set_neighbor_horiz(row)
            
            var vert_controls: Array[Control]
            for r2 in ctrl_rows.size():
                var c2 = clampi(r + 1, 0, ctrl_rows[r2].size() - 1)
                vert_controls.append(ctrl_rows[r2][c2])
            Util.UI.set_neighbor_vert(vert_controls)
            
            for i in row.size():
                var ctrl = row[i]
                if not ctrl.focus_entered.is_connected(_set_current_selected.bind(r, i)):
                    ctrl.focus_entered.connect(_set_current_selected.bind(r, i))
            
            all_ctrls.append_array(row)
    
    var auto_focus = true
    var first_ctrl: Control
    for ctrl in all_ctrls:
        # check if this node is already focused
        if not first_ctrl:
            first_ctrl = ctrl
        if ctrl.has_focus():
            logs.debug("%s has focus" % ctrl)
            auto_focus = false
                
    if auto_focus and first_ctrl:
        logs.debug("auto focus %s" % first_ctrl)
        first_ctrl.grab_focus()

func _set_current_selected(row: int, col: int):
    _current_selected_row = row
    _rows_last_selected_idx.resize(row + 1)
    _rows_last_selected_idx[row] = col
