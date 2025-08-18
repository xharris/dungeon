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
    
    static func is_valid_neighbor(c:Node) -> bool:
        if c is Control and (c as Control).focus_mode == Control.FocusMode.FOCUS_NONE:
            return false
        if c is Button and (c as Button).disabled:
            return false
        return true
    
    static func set_neighbor_horiz(left:Control, right:Control):
        if left == right:
            return
        var right_path = right.get_path()
        var left_path = left.get_path()
        UI.logs.debug("connect %s" % {"left":left_path, "right":right_path})
        left.focus_neighbor_right = right_path
        right.focus_neighbor_left = left_path

    static func set_neighbor_vert(top:Control, bottom:Control):
        if top == bottom:
            return
        var top_path = top.get_path()
        var bottom_path = bottom.get_path()
        UI.logs.debug("connect %s" % {"top":top_path, "bottom":bottom_path})
        top.focus_neighbor_bottom = bottom_path
        bottom.focus_neighbor_top = top_path
