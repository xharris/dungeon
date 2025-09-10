extends Node2D
class_name Projectile

const DURATION: float = 1.0
static var _SCENE = preload("res://src/projectile/projectile.tscn")

class Data:
    var source: Node2D
    var target: Node2D
    var target_stats: Stats

static func create(data: Data, count: int = 1) -> Array[Projectile]:
    var projectiles: Array[Projectile]
    for _i in count:
        var me = _SCENE.instantiate() as Projectile
        me._data = data
        projectiles.append(me)
    return projectiles

signal reached_target

@onready var _sprite2d: Sprite2D = $Sprite2D

var logs = Logger.new("projectile")
var _data: Data
var _start_position: Vector2
var _config: ProjectileConfig
var _t = 0
var _reached_target = false

func set_config(config: ProjectileConfig):
    _config = config

func _ready():
    if not _config:
        logs.warn("no projectile config")
    _start_position = _data.source.global_position
    var target = _data.target
    for v in _data.visitors:
        v.setup(self, _data.source, _data.target)
        v.run()

func _process(delta: float) -> void:
    if _reached_target:
        return
    for v in _data.visitors:
        v.process(delta)
    if _config:
        if _t >= DURATION:
            _reached_target = true
            # apply projectile effects
            for s in _config.on_reached_target:
                s.run(_data.target_stats)
            reached_target.emit()
            if _config.destroy_on_reached:
                Util.destroy(self)
            return
        # path to target
        _t += delta
        var progress = _t / DURATION
        var target = _data.target
        global_position.lerp(_data.target.global_position, _config.speed_curve.sample(_t))
