extends Control
class_name UILayer

@onready var top_row:HBoxContainer = %TopRow
@onready var bottom_row:HBoxContainer = %BottomRow
@onready var background:Panel = %Background

var logs = Logger.new("ui_layer")

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
    
## Update focus relationships for all controls
func _update_focus():
    var inspect_nodes:Array[UIInspectNode]
    inspect_nodes.assign(get_tree().get_nodes_in_group(Groups.UI_INSPECT_NODE))
    inspect_nodes = inspect_nodes.filter(func(n:UIInspectNode):
        return n.is_visible_on_screen()    
    )
    var inspect_controls = inspect_nodes.map(func(n:UIInspectNode):
        return n.control    
    ) as Array[Control]
    var ctrl_rows:Array = [top_row, inspect_controls, bottom_row].map(func(r):
        match typeof(r):
            TYPE_OBJECT:
                if r is Control:
                    return r.get_children().filter(func(c): return c is Control) as Array[Control]
            TYPE_ARRAY:
                return r
        return r
    )
    var max_row_size = ctrl_rows.map(func(children:Array): return children.size()).max()
    
    var no_auto_focus = true
    var first_ctrl:Control
    for c in max_row_size:
        var i = 0
        for r in ctrl_rows.size():
            var row = ctrl_rows[r] as Array[Control]
            if c < row.size() - 1:
                var ctrl:Control = row[c]
                if not first_ctrl and ctrl.focus_mode != FocusMode.FOCUS_NONE:
                    first_ctrl = ctrl          
                # neighbor left/right
                ctrl.focus_neighbor_left = row[wrapi(c - 1, 0, row.size())].get_path()
                ctrl.focus_neighbor_right = row[wrapi(c + 1, 0, row.size())].get_path()
                # neighbor top
                var row_up = ctrl_rows[wrapi(r - 1, 0, ctrl_rows.size())] as Array[Control]
                if row_up.size():
                    var ctrl_up = row_up[wrapi(c, 0, row_up.size())].get_path()
                    logs.debug("connect up %s to %s" % [ctrl, ctrl_up])
                    ctrl.focus_neighbor_top = ctrl_up
                # neighbor bottom
                var row_down = ctrl_rows[wrapi(r + 1, 0, ctrl_rows.size())] as Array[Control]
                if row_down.size():
                    var ctrl_down = row_down[wrapi(c, 0, row_down.size())].get_path()
                    logs.debug("connect down %s to %s" % [ctrl, ctrl_down])
                    ctrl.focus_neighbor_bottom = ctrl_down
                if ctrl.has_focus():
                    no_auto_focus = false
        if no_auto_focus and first_ctrl:
            logs.debug("auto focus %s" % first_ctrl)
            first_ctrl.grab_focus()
    
