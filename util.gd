extends Node

var logs = Logger.new("util")
var main_node:Node2D

## Returns [code]false[/code] if object is already being destroyed
func destroy(node:Node) -> bool:
    if node == null:
        return true
    var parent = node.get_parent()
    if not parent and node.is_queued_for_deletion():
        return false
    if parent:
        parent.remove_child(node)
    node.queue_free()
    return true

func clear_children(node:Node):
    for c in node.get_children():
        node.remove_child(c)

func get_rect(node:Node2D) -> Rect2:
    var top_left:Vector2 = Vector2.ZERO
    var size:Vector2 = Vector2.ZERO
    for n in node.find_children("*"):
        var n_top_left = Vector2.ZERO
        var n_size = Vector2.ZERO
        
        if n is Sprite2D:
            var rect = n.get_rect()
            n_top_left = rect.position
            n_size = rect.size
        
        if n is Node2D:
            n_top_left *= n.global_scale
            n_size *= n.global_scale
            
        top_left = top_left.min(n_top_left)
        size = size.max(n_top_left + n_size)
    
    return Rect2(top_left, size)

func chain_call(funcs:Array):
    for f in funcs:
        if f is Callable:
            await f.call()

class UI:
    static var logs = Logger.new("util.ui")#, Logger.Level.DEBUG)
    
    static func is_valid_neighbor(c:Node, neighbor_of:Node = null) -> bool:
        if c == null:
            return false
        if neighbor_of == c:
            return false
        if c is BaseButton and (c as BaseButton).disabled:
            return false
        if c is Control and (c as Control).focus_mode == Control.FocusMode.FOCUS_NONE:
            return false
        if not (
            c.find_parent("UIInspectNode") or
            c is UIButton or
            c.get_class() == "Control"
        ):
            return false
        return true
    
    static func set_neighbor_horiz(controls:Array[Control]) -> Array:
        var i = 0
        while i < controls.size() and controls.size() > 1:
            var ctrl = controls[i]
            var next_i = clampi(i + 1, 0, controls.size() - 1)
            var next = controls[next_i]
            if not is_valid_neighbor(next, ctrl):
                controls.remove_at(next_i)
            else:
                i += 1
        for j in controls.size():
            var left = controls[j]
            var right_j = clampi(j + 1, 0, controls.size() - 1)
            var right = controls[right_j]
            
            var right_path = right.get_path()
            var left_path = left.get_path()
            UI.logs.debug("connect %s" % {"left":left_path, "right":right_path})
            left.focus_neighbor_right = right_path
            right.focus_neighbor_left = left_path
            
        return controls

    static func set_neighbor_vert(controls:Array[Control]) -> Array:
        var i = 0
        while i < controls.size() and controls.size() > 1:
            var ctrl = controls[i]
            var next_i = clampi(i + 1, 0, controls.size() - 1)
            var next = controls[next_i]
            if not is_valid_neighbor(next, ctrl):
                controls.remove_at(next_i)
            else:
                i += 1
        for j in controls.size():
            var top = controls[j]
            var bottom_j = clampi(j + 1, 0, controls.size() - 1)
            var bottom = controls[bottom_j]
            
            var bottom_path = bottom.get_path()
            var top_path = top.get_path()
            UI.logs.debug("connect %s" % {"top":top_path, "bottom":bottom_path})
            top.focus_neighbor_right = bottom_path
            bottom.focus_neighbor_left = top_path
            
        return controls
