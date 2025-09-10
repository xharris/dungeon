extends Node2D
class_name Characters

enum GroupSide {Left = 0, Right = 1}

var logs = Logger.new("characters")
var await_arrange = Async.AwaitAll.new()

func accept(v: Visitor):
    v.visit_characters(self)

func _ready() -> void:
    add_to_group(Groups.CHARACTERS)
    Events.character_created.connect(_on_character_created)
    
func _on_character_created(c: Character):
    add_child(c)

func get_player() -> Character:
    return get_tree().get_first_node_in_group(Groups.CHARACTER_PLAYER) as Character

# arrange all characters to their designated side of the screen
func arrange(characters: Array[Character], area: Rect2):
    logs.info("arrange characters (%d), area=%s" % [characters.size(), area])
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
    
    # put characters in a side depending on group
    await_arrange.reset()
    for c in characters:
        for g in group_side:
            if c.is_in_group(g):
                var side: GroupSide = group_side[g]
                side_chars[side].append(c)
                await_arrange.add(c.move_to_finished)
    await_arrange.done.connect(_on_arrange_finished, CONNECT_ONE_SHOT)
    
    var x = area.position.x # center.x - Util.size.x/2 + 30
    var w = area.position.x + area.size.x # center.x + Util.size.x/2 - 30
    logs.debug("arrange area x=[%d, %d]" % [x, w])
    var side_size = (w - x) / side_order.size()
    for i in side_order.size():
        var side: GroupSide = side_order[i]
        var side_x = side_size * i
        var side_sep = 64 # (side_size / side_chars[side].size())
        var char_count = side_chars[side].size()
        var chars_w = side_sep * (char_count - 1)
        logs.debug("side: %s, size: %d" % [GroupSide.find_key(side), char_count])
        for j in char_count:
            var c = side_chars[side][j] as Character
            var ok = c.move_to_x(x + side_x + (side_size / 2) - (chars_w / 2))
            if not ok:
                await_arrange.remove(c.move_to_finished)

func _on_arrange_finished():
    logs.info("arrange finished") # BUG finishing too early
    Events.characters_arranged.emit()
