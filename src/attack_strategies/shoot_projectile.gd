extends AttackStrategy
class_name ShootProjectile

@export var count: int = 1
#@export var visitors: Array[ProjectileVisitor] # NOTE not used
@export var config: ProjectileConfig

func run(stats: Stats):
    logs.set_prefix("shoot_projectile")
    for i in count:
        var data = Projectile.Data.new()
        data.source = _source_node
        data.target = _target_node
        data.target_stats = stats
        #data.visitors = visitors
        for p in Projectile.create(data):
            p.set_config(config)
            Util.main_node.add_child(p)
