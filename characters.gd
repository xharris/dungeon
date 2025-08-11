extends Node

enum GroupSide {Left, Right}

signal arrange_finished

var logs = Logger.new("characters")

# arrange all characters to their designated side of the screen
func arrange_characters(room:Rooms.Room):
    var side_size = Game.size.x / 3
    var group_side = {
        "player": GroupSide.Left,
        "ally": GroupSide.Left,
        "enemy": GroupSide.Right,
    }
    var group_count = {}
    var group_sep = {}
    for group in group_side:
        group_count[group] = get_tree().get_node_count_in_group(group)
    for group in group_count:
        var count = max(1, group_count[group])
        group_sep[group] = side_size / count
    logs.info("arrange characters %s" % group_count)
    var move_signals:Array[Signal] = []
    for group in group_sep:
        var side:GroupSide = group_side[group]
        var x = (0.0 if side == GroupSide.Left else side_size)
        x += (side_size / 2)
        x += room.node.global_position.x
        for character in get_tree().get_nodes_in_group(group):
            if character is Character:
                move_signals.append(character.move_to_finished)
                character.move_to_x(x)
                x += group_sep[group]
    
    await Async.all(move_signals)
    arrange_finished.emit()
