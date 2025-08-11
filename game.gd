extends Node

var size:Vector2:
    get:
        return get_viewport().get_visible_rect().size

func get_player() -> Character:
    return get_tree().get_first_node_in_group("player")
