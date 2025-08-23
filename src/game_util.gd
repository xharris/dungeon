extends Node

func all_characters() -> Array[Character]:
    var out:Array[Character]
    out.assign(get_tree().get_nodes_in_group(Groups.CHARACTER_ANY))
    return out

func characters() -> Characters:
    return get_tree().get_first_node_in_group(Groups.CHARACTERS)

func rooms() -> Rooms:
    return get_tree().get_first_node_in_group(Groups.ROOMS)
