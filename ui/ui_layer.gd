extends Control
class_name UILayer

@onready var top_row:HBoxContainer = %TopRow
@onready var bottom_row:HBoxContainer = %BottomRow
@onready var background:Panel = %Background

var logs = Logger.new("ui_layer") #, Logger.Level.DEBUG)

## normal visible background color is [code]Color.WHITE[/code]
func set_background_color(color:Color = Color.TRANSPARENT):
    var tween = create_tween()
    tween.tween_property(background, "modulate", color, 1)
    tween.play()

func add_to_top_row(node:Node) -> UILayer:
    top_row.add_child(node)
    _update_focus()
    return self

func add_to_bottom_row(node:Node) -> UILayer:
    bottom_row.add_child(node)
    _update_focus()
    return self

func clear_top_row() -> UILayer:
    Util.clear_children(top_row)
    return self

func clear_bottom_row() -> UILayer:
    Util.clear_children(bottom_row)
    return self

func clear() -> UILayer:
    clear_top_row()
    clear_bottom_row()
    return self

func set_title(text:String) -> Label:
    var label = Label.new()
    label.text = text
    label.focus_mode = Control.FOCUS_NONE
    add_to_top_row(label)
    return label

func _get_inspect_nodes() -> Array[UIInspectNode]:
    var inspect_nodes:Array[UIInspectNode]
    inspect_nodes.assign(get_tree().get_nodes_in_group(Groups.UI_INSPECT_NODE))
    inspect_nodes = inspect_nodes.filter(func(n:UIInspectNode):
        return n.is_visible_on_screen()    
    )
    return inspect_nodes

func _get_selected_inspect_node() -> UIInspectNode:
    var inspect_nodes = _get_inspect_nodes()
    var idx = inspect_nodes.find_custom(func(n:UIInspectNode):
        return n.is_selected()    
    )
    if idx >= 0:
        return inspect_nodes[idx]
    return null

## Update focus relationships for all controls
func _update_focus():
    logs.info("update focus")
    var all_ctrls:Array[Control]
    var inspect_nodes = _get_inspect_nodes()
    var inspect_controls = inspect_nodes.map(func(n:UIInspectNode):
        return n.control    
    ) as Array[Control]
    all_ctrls.append_array(inspect_controls)
    var selected_inspect_node = _get_selected_inspect_node()
    
    var rows = []
    if selected_inspect_node != null:
        # top and bottom should be connected to the selected inspect node
        rows = [top_row, [selected_inspect_node.control], bottom_row]
    else:
        rows = [top_row, bottom_row]
    
    var ctrl_rows:Array = rows.map(func(r):
        match typeof(r):
            TYPE_OBJECT:
                if r is Control:
                    return r.get_children().filter(func(c): return c is Control) as Array[Control]
            TYPE_ARRAY:
                return r
        return r
    )
    # filter out non-controls, non-focusable
    for r in ctrl_rows.size():
        var row = ctrl_rows[r] as Array
        row = row.filter(func(c):
            return c is Control and (c as Control).focus_mode != FocusMode.FOCUS_NONE
        )
        ctrl_rows[r] = row
    var max_row_size = ctrl_rows.map(func(children:Array): return children.size()).max()

    for c in max_row_size:
        for r in ctrl_rows.size():
            var row = ctrl_rows[r] as Array[Control]
            logs.debug("row %d %s" % [r, row])
            if c < row.size():
                var ctrl:Control = row[c]
                # neighbor left/right
                Util.UI.set_neighbor_horiz(row[wrapi(c - 1, 0, row.size())], ctrl)
                Util.UI.set_neighbor_horiz(ctrl, row[wrapi(c + 1, 0, row.size())])
                # neighbor top
                var row_up = ctrl_rows[clampi(r - 1, 0, ctrl_rows.size()-1)] as Array[Control]
                if row_up.size() > 0:
                    var ctrl_up = row_up[wrapi(c, 0, row_up.size())]
                    Util.UI.set_neighbor_vert(ctrl_up, ctrl)
                # neighbor bottom
                var row_down = ctrl_rows[clampi(r + 1, 0, ctrl_rows.size()-1)] as Array[Control]
                if row_down.size() > 0:
                    var ctrl_down = row_down[wrapi(c, 0, row_down.size())]
                    Util.UI.set_neighbor_vert(ctrl, ctrl_down)
                if not ctrl in all_ctrls:
                    all_ctrls.append(ctrl)
    
    # focus first control found
    var auto_focus = true
    var first_ctrl:Control
    for ctrl in all_ctrls:
        if not first_ctrl:
            first_ctrl = ctrl
        if ctrl.has_focus():
            auto_focus = false
    
    # connect inspect nodes horizontally
    for n in inspect_controls.size():
        Util.UI.set_neighbor_horiz(
            inspect_controls[n],
            inspect_controls[wrapi(n + 1, 0, inspect_controls.size())]
        )    
                
    if auto_focus and first_ctrl:
        logs.debug("auto focus %s" % first_ctrl)
        first_ctrl.grab_focus()
    
