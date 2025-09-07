extends Visitor
class_name ProjectileVisitor

func setup(projectile: Node2D, source: Node2D, target: Node2D):
    _projectile = projectile
    _source = source
    _target = target
    
var _projectile: Node2D
var _source: Node2D
var _target: Node2D

func process(delta: float):
    pass
