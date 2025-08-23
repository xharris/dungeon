extends Node2D
class_name Characters

enum GroupSide {Left=0, Right=1}

var logs = Logger.new("characters")
    
func _ready() -> void:
    add_to_group(Groups.CHARACTERS)
    
func get_all() -> Array[Character]:
    var out:Array[Character]
    out.append_array(get_tree().get_nodes_in_group(Groups.CHARACTER_ANY))
    return out

func get_player() -> Character:
    return get_tree().get_first_node_in_group(Groups.CHARACTER_PLAYER) as Character

# arrange all characters to their designated side of the screen
func arrange(characters:Array[Character], center:Vector2):
    characters = GameUtil.all_characters()
    
    var side_order = [GroupSide.Left, GroupSide.Right]
    var group_side = {
        Groups.CHARACTER_ALLY: GroupSide.Left,
        Groups.CHARACTER_PLAYER: GroupSide.Left,
        Groups.CHARACTER_ENEMY: GroupSide.Right
    }
    var side_chars = {
        GroupSide.Left: [] as Array[Character],
        GroupSide.Right: [] as Array[Character],
    }
    var side_start_x = {
        GroupSide.Left: 0,
        GroupSide.Right: 0,
    }
    var move_signals:Array[Signal] = []
    
    # put characters in a side depending on group
    for c in characters:
        for g in group_side:
            if c.is_in_group(g):
                var side:GroupSide = group_side[g]
                side_chars[side].append(c)
                move_signals.append(c.move_to_finished)
    
    var x = center.x - Util.size.x/2 + 30
    var w = center.x + Util.size.x/2 - 30
    logs.debug("arrange area x=[%d, %d]" % [x, w])
    var side_size = (w - x) / side_order.size()
    for i in side_order.size():
        var side:GroupSide = side_order[i]
        var side_x = side_size * i
        var side_sep = 64 # (side_size / side_chars[side].size())
        var char_count = side_chars[side].size()
        var chars_w = side_sep * (char_count - 1)
        logs.debug("side: %s, size: %d" % [GroupSide.find_key(side), char_count])
        for c in char_count:
            var character = side_chars[side][c] as Character
            character.move_to_x(x + side_x + (side_size / 2) - (chars_w / 2))

    await Async.all(move_signals)
    Events.characters_arranged.emit()
