class_name Projectile
extends Node2D

static var l = Logger.create("projectile")

static var scn_projectile = preload("res://scene/projectile.tscn")

enum PathType {Linear, Parabola, Oscillate}

static func create(from:Node2D, target:Node2D) -> Projectile:
	var p := scn_projectile.instantiate() as Projectile
	p.global_position = from.global_position
	p.target = target
	from.get_tree().root.add_child(p)
	return p

signal target_reached

var path_type:PathType = PathType.Linear
var from_ability:Ability
var target:Node2D
var speed:int = 3


# Called when the node enters the scene tree for the first time.
func _ready():
	l.debug("created")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !target:
		return l.error("no projectile target: {self}", { "self":self })
	if target.global_position.distance_to(global_position) < 5:
		target_reached.emit()
		get_parent().remove_child(self)
	match path_type:
		PathType.Linear:
			var velocity = Velocity.calc(global_position, target.global_position) * 10
			rotation = velocity.angle()
			global_position += velocity
