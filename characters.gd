extends Node

enum GroupSide {Left, Right}

signal character_created(c:Character)
signal arrange_finished

var logs = Logger.new("characters")

func get_all() -> Array[Character]:
    return get_tree().get_nodes_in_group(Groups.CHARACTER_ANY) as Array[Character]

func destroy_all():
    for c in get_tree().get_nodes_in_group(Groups.CHARACTER_ANY) as Array[Character]:
        c.destroy()

func get_player() -> Character:
    return get_tree().get_first_node_in_group(Groups.CHARACTER_PLAYER)

# arrange all characters to their designated side of the screen
func arrange_characters(room:Rooms.Room):
    var side_size = Game.size.x / 3
    var group_side = {
        Groups.CHARACTER_PLAYER: GroupSide.Left,
        Groups.CHARACTER_ALLY: GroupSide.Left,
        Groups.CHARACTER_ENEMY: GroupSide.Right,
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
            # move character to idle position in room
            if character is Character and character.move_to_x(x):
                move_signals.append(character.move_to_finished)
                x += group_sep[group]
    
    await Async.all(move_signals)
    arrange_finished.emit()
