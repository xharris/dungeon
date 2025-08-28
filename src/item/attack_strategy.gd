extends Resource
class_name AttackStrategy

enum TARGET {SELF, ALLY, ENEMY}

@export var deal_damage:bool = true
@export var strength_ratio:int = 1.0
@export var target:TARGET
@export var modify_stats:Stats

var logs = Logger.new("attack_strategy")

func get_targets(source:Character, _target:TARGET = target) -> Array[Character]:
    var possible_characters:Array[Character]
    var self_is_ally = source.is_in_group(Groups.CHARACTER_PLAYER) or source.is_in_group(Groups.CHARACTER_ALLY)
    for c in GameUtil.all_characters():
        var add:bool = false
        var other_is_ally = c.is_in_group(Groups.CHARACTER_PLAYER) or c.is_in_group(Groups.CHARACTER_ALLY)
        match _target:
            TARGET.SELF:
                if c == source:
                    add = true
            TARGET.ALLY:
                if self_is_ally == other_is_ally:
                    add = true
            TARGET.ENEMY:
                if self_is_ally != other_is_ally:
                    add = true
        if add:
            possible_characters.append(c)
    return possible_characters

func run(source:Character):
    for c in get_targets(source):
        if deal_damage:
            c.stats.take_damage(c.stats.strength * strength_ratio)
        if modify_stats:
            modify_stats.apply_to(c.stats)
