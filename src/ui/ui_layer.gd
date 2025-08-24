extends Node2D
class_name UILayer

enum State {HIDDEN, VISIBLE}

signal state_changed(state: State)
signal build_finished

@onready var _top_row: HBoxContainer = %TopRow
@onready var _bottom_row: HBoxContainer = %BottomRow
@onready var _background: Panel = %Background

@export var config: UILayerConfig

var logs = Logger.new("ui_layer") # , Logger.Level.DEBUG)
var _rows_last_selected_idx: Array[int]
var _state: State
var _prev_layer: UILayer

func _ready() -> void:
    add_to_group(Groups.UI_LAYER)
    name = "%s_%s" % [Groups.UI_LAYER, config.id]
    logs.set_prefix(config.id)
    if config.visible:
        set_state(State.VISIBLE)
        
func set_state(state: State, _from_layer := false) -> bool:
    logs.info("set state %s%s" % [State.find_key(state), " (from layer)" if _from_layer else ""])
    
    match state:
        State.HIDDEN:
            visible = false
            _hide_inspect_nodes()
            set_background_color()
            clear()
            
            # show prev layer
            if _prev_layer and not _from_layer:
                logs.info("restore previous ui layer: %s" % _prev_layer.config.id)
                _prev_layer.set_state(State.VISIBLE, true)
            _prev_layer = null
                
        State.VISIBLE:
            # check block list
            var is_blocked = _prev_layer and config.block_next_layer.any(func(id: String):
                return _prev_layer.config.id == id
            )
            if is_blocked:
                logs.warn("layer is blocked: %s -> %s" % [_prev_layer.config.id, config.id])
                return false
            # check allow list
            var is_allowed = \
            not _prev_layer or \
            config.allow_next_layer.size() == 0 or \
            config.allow_next_layer.any(func(id: String):
                return _prev_layer.config.id == id
            )
            if not is_allowed:
                logs.warn("layer is not allowed: %s -> %s" % [_prev_layer.config.id, config.id])
                return false
            _prev_layer = null
    
            for l in get_tree().get_nodes_in_group(Groups.UI_LAYER) as Array[UILayer]:
                if l != self:
                    if l._state == State.VISIBLE and not _from_layer:
                        # get previous ui layer
                        logs.info("previous layer was '%s'" % l.config.id)
                        _prev_layer = l
                    # hide other layer
                    l.set_state(State.HIDDEN, true)
            visible = true
            logs.info("layer stack: %s" % [_get_state_stack()])
            
            match config.type:
                UILayerConfig.Type.TOP_BOTTOM:
                    _hide_inspect_nodes()
                        
                UILayerConfig.Type.INSPECT:
                    _show_inspect_nodes()
                   
            _build_ui()
            _update_focus()
            set_background_color(config.background_color)
            
    _state = state
    state_changed.emit.call_deferred(state)
    return true

func _get_state_stack() -> Array[UILayer]:
    var node = self
    var stack: Array[UILayer] = []
    while node:
        stack.append(node)
        node = node._prev_layer
    return stack

func _unhandled_input(event: InputEvent) -> void:
    if config.esc_to_close and event.is_action_pressed("exit"):
        set_state(State.HIDDEN)

func _show_inspect_nodes():
    logs.info("show inspect nodes")
    for n in _get_inspect_nodes():
        n.set_state(UIInspectNode.State.VISIBLE)

func _hide_inspect_nodes():
    logs.info("hide inspect nodes")
    for n in _get_inspect_nodes():
        n.set_state(UIInspectNode.State.HIDDEN)

func _build_ui():
    logs.debug("build ui %s" % config)
    get_viewport().gui_release_focus()
    
    for c in config.top_row:
        var button = UIElements.button(c)
        button.pressed_to_close.connect(_on_ui_button_pressed_to_close.bind(button))
        add_to_top_row(button)
        
    for c in config.bottom_row:
        var button = UIElements.button(c)
        button.pressed_to_close.connect(_on_ui_button_pressed_to_close.bind(button))
        add_to_bottom_row(button)
        
    set_background_color(config.background_color)
    
    logs.info("emit build finished")
    build_finished.emit.call_deferred()

## Update focus relationships for all controls
func _update_focus() -> bool:
    logs.info("update focus")
    var inspect_nodes = _get_inspect_nodes()
    for n in inspect_nodes:
        n.set_layer(self)
    
    var inspect_controls = inspect_nodes \
        .filter(func(n: UIInspectNode): return n.is_visible_on_screen()) \
        .map(func(n: UIInspectNode): return n.control) as Array[Control]
    
    # connect inspect node(s)
    var middle_row = inspect_controls

    var ctrl_rows = [_top_row.get_children(), middle_row, _bottom_row.get_children()]
    var prev_rows_str = str(ctrl_rows)
    var focus_ctrl: Control = null
    
    var current_selected_row = ctrl_rows.find_custom(func(r:Array):
        return r.any(func(c): return c is Control and c.has_focus())    
    )
    
    var err = _rows_last_selected_idx.resize(max(ctrl_rows.size(), _rows_last_selected_idx.size()))
    if err != OK:
        logs.warn("could not resize _rows_last_selected_idx, error=%d" % err)
    logs.info("last selected control, row=%d col=%d" % [current_selected_row, _rows_last_selected_idx[current_selected_row]])
        
    for i in ctrl_rows.size():
        var row: Array = ctrl_rows[i]
        
        # remove invalid controls
        row = row.filter(func(c: Node): return Util.UI.is_valid_neighbor(c))
        
        if row.size() > 0:
            var col = clampi(_rows_last_selected_idx[i], 0, row.size()-1)
            
            if i == current_selected_row and not focus_ctrl:
                # focus last selected element
                focus_ctrl = row[col]
                logs.info("was selected: %s" % focus_ctrl)
            
            elif i != current_selected_row:
                # only last selected control in other rows is focusable
                row = [row[col]]
                logs.info("narrow row %d" % [i])
        else:
            logs.debug("empty row: %s" % [row])
            
        ctrl_rows[i] = row
        
    logs.info_if(
        str(ctrl_rows) != prev_rows_str,
        "nodes were filtered\n\n\tbefore %s\n\n\tafter %s\n" % [prev_rows_str, ctrl_rows]
    )
    
    # save place in each row when focus changes
    for r in ctrl_rows.size():
        var row = ctrl_rows[r]
        for i in row.size():
            var ctrl = row[i]
            if not ctrl.focus_entered.is_connected(_set_current_selected.bind(r, i)):
                ctrl.focus_entered.connect(_set_current_selected.bind(r, i))
                    
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
                var c2 = clampi(r, 0, ctrl_rows[r2].size() - 1)
                vert_controls.append(ctrl_rows[r2][c2])
            Util.UI.set_neighbor_vert(vert_controls)
            
            all_ctrls.append_array(row)
    
    var skip_auto_focus = false
    for ctrl in all_ctrls:
        if ctrl.has_focus():
            skip_auto_focus = true
        if not focus_ctrl:
            focus_ctrl = ctrl
    
    logs.warn_if(all_ctrls.size() > 0 and not focus_ctrl, "focus_ctrl is null")
    
    if not skip_auto_focus and focus_ctrl:
        _focus_control(focus_ctrl)
        
    return true

func _focus_control(control:Control):
    logs.info("focus_ctrl: %s" % control)
    if logs.warn_if(control and not control.is_visible_in_tree(), "focus_ctrl is not visible in tree"):
        return
    control.grab_focus()

func _on_ui_button_pressed_to_close(me: UIButton):
    logs.info("close on button pressed: %s" % me)
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
    Util.clear_children(_top_row)
    Util.clear_children(_bottom_row)
    _update_focus()
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

func _get_selected_inspect_node() -> UIInspectNode:
    var inspect_nodes: Array[UIInspectNode]
    inspect_nodes.assign(get_tree().get_nodes_in_group(Groups.UI_INSPECT_NODE))
    for n in inspect_nodes:
        if n.is_selected():
            return n
    return null

func _set_current_selected(row: int, col: int):
    _rows_last_selected_idx.resize(max(row + 1, _rows_last_selected_idx.size()))
    _rows_last_selected_idx[row] = col
    logs.info("save place in row %d: %d" % [row, col])
