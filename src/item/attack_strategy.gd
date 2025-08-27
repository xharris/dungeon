extends Resource
class_name AttackStrategy

enum TARGET {SELF, ALLY, ENEMY}

@export var str_ratio:int = 1.0
@export var target:TARGET

var logs = Logger.new("attack_strategy")

func run(source:Character):
    var possible_stats:Array[Stats]
    var self_is_ally = source.is_in_group(Groups.CHARACTER_PLAYER) or source.is_in_group(Groups.CHARACTER_ALLY)
    for c in GameUtil.all_characters():
        var add_stats:bool = false
        var other_is_ally = c.is_in_group(Groups.CHARACTER_PLAYER) or c.is_in_group(Groups.CHARACTER_ALLY)
        match target:
            TARGET.SELF:
                if c == source:
                    add_stats = true
            TARGET.ALLY:
                if self_is_ally == other_is_ally:
                    add_stats = true
            TARGET.ENEMY:
                if self_is_ally != other_is_ally:
                    add_stats = true
        if add_stats:
            possible_stats.append(c.stats)
        
    logs.info("got %d stats" % [possible_stats.size()])
    for s in possible_stats:
        s.take_damage(source.stats.strength * str_ratio)
