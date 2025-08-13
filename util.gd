extends Node

## Returns [code]false[/code] if object is already being destroyed
func destroy(node:Node) -> bool:
    var parent = node.get_parent()
    if not parent and node.is_queued_for_deletion():
        return false
    if parent:
        parent.remove_child(node)
    node.queue_free()
    return true
