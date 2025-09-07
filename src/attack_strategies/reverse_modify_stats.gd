## Is this even being used?
extends AttackStrategy
class_name ReverseModifyStats

@export var attack_strategy: AttackStrategy

func run(stats: Stats):
    deal_damage = false
    # copy stuff
    strength_ratio = attack_strategy.strength_ratio
    target = attack_strategy.target
    # reverse stats
    var orig_stats = attack_strategy.modify_stats
    modify_stats = Stats.new()
    modify_stats.ignore_limits = true
    modify_stats.attack_speed = -orig_stats.attack_speed
    modify_stats.max_hp = -orig_stats.max_hp
    modify_stats.movespeed = -orig_stats.movespeed
    modify_stats.strength = -orig_stats.strength
    logs.info("reverse attack speed: %.2f -> %.2f" % [orig_stats.attack_speed, modify_stats.attack_speed])
    super.run(stats)
