extends Resource
class_name AttackStrategy

enum TARGET {SELF, ALLY, ENEMY}

@export var str_ratio:int = 1.0
@export var target:TARGET

var logs = Logger.new("attack_strategy")

func run(source:Character):
    var possible_stats:Array[Stats]
    for c in GameUtil.all_characters():
        possible_stats.append(c.stats)
    logs.info("got %d stats" % [possible_stats.size()])
    for s in possible_stats:
        s.take_damage(source.stats.strength * str_ratio)
