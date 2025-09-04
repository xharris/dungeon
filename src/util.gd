extends Node

var logs = Logger.new("util")
var main_node:Node2D

var size:Vector2:
    get:
        return get_viewport().get_visible_rect().size
        
func _get_tree() -> SceneTree:
    if not main_node:
        logs.warn("main node not set")
        return
    var tree = main_node.get_tree()
    if not tree:
        logs.warn("main node not in tree, main node=%s" % [main_node.name])
        return
    return tree
        
func get_first_node_in_group(group:String) -> Node:
    var tree = _get_tree()
    if logs.warn_if(not tree, "could not get tree, group=%s" % group):
        return
    return tree.get_first_node_in_group(group)

func get_last_node_in_group(group:String) -> Node:
    var tree = _get_tree()
    if logs.warn_if(not tree, "could not get tree, group=%s" % group):
        return
    var nodes = tree.get_nodes_in_group(group)
    if nodes.size() == 0:
        logs.debug("no nodes found, group=%s" % group)
        return
    return nodes.back()

func get_nodes_in_group(group:String) -> Array:
    var tree = _get_tree()
    if logs.warn_if(not tree, "could not get tree, group=%s" % group):
        return []
    return tree.get_nodes_in_group(group)

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

func clear_children(node:Node, free:bool = false):
    for c in node.get_children():
        node.remove_child(c)
        if free:
            c.queue_free()

func get_rect(node:Node2D) -> Rect2:
    var top_left:Vector2 = Vector2.ZERO
    var out:Vector2 = Vector2.ZERO
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
        out = out.max(n_top_left + n_size)
    
    return Rect2(top_left, out)

func chain_call(funcs:Array):
    for f in funcs:
        if f is Callable:
            await f.call()
            
func strip_bbcode(source:String) -> String:
    var regex = RegEx.new()
    regex.compile("\\[.+?\\]")
    return regex.sub(source, "", true)

func diminishing(x:float, max_x:float = 100) -> float:
    return x / (x + max_x) + 1

func connect_once(sig:Signal, callback:Callable, flags:int = 0) -> int:
    if sig.is_connected(callback):
        sig.disconnect(callback)
    return sig.connect(callback, flags)

class UI:
    static var logs = Logger.new("util.ui")#, Logger.Level.DEBUG)
    
    ## Also includes starting node in search
    static func find_parent_by_group(node:Node, group:StringName) -> Node:
        if not node:
            logs.debug("parent not found: %s" % group)
            return null
        if node.is_in_group(group):
            logs.debug("found parent: %s" % group)
            return node
        node = node.get_parent()
        return find_parent_by_group(node, group)
    
    static func is_valid_neighbor(c:Node, neighbor_of:Node = null) -> bool:
        if c == null:
            logs.warn("invalid neighbor: null")
            return false
        if c == neighbor_of:
            logs.debug("invalid neighbor: same (%s)" % c)
        
        UI.logs.debug("is valid neighbor %s" % ("%s <- %s" % [c, neighbor_of] if neighbor_of else str(c)))
           
        var ui_button:UIButton = find_parent_by_group(c, Groups.UI_BUTTON)
        var ui_inspect_node:UIInspectNode = find_parent_by_group(c, Groups.UI_INSPECT_NODE)

        if ui_button:
            return ui_button.is_valid_neighbor()
            
        if ui_inspect_node:
            return ui_inspect_node.is_valid_neighbor()

        logs.info("invalid neighbor: not supported")
        return false
    
    static func set_neighbor_horiz(controls:Array[Control]) -> Array:
        UI.logs.debug("set horiz neighbors %s" % [controls])
        for i in controls.size():
            var ctrl = controls[i]
            var next = controls[wrapi(i + 1, -1, controls.size() - 1)]
            
            if not is_valid_neighbor(ctrl, next):
                continue
                
            var next_path = next.get_path()
            var path = ctrl.get_path()
                
            ctrl.focus_neighbor_right = next_path
            next.focus_neighbor_left = path
            
        return controls

    static func set_neighbor_vert(controls:Array[Control]) -> Array:
        UI.logs.debug("set vert neighbors %s" % [controls])
        for i in controls.size():
            var ctrl = controls[i]
            var next = controls[wrapi(i + 1, -1, controls.size() - 1)]
            
            if not is_valid_neighbor(ctrl, next):
                continue
                
            var next_path = next.get_path()
            var path = ctrl.get_path()
            
            ctrl.focus_neighbor_bottom = next_path
            next.focus_neighbor_top = path
            
        return controls
