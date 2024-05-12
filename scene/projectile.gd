class_name Projectile
extends Node2D

static var l = Logger.create("projectile")

enum PathType {Linear, Parabola, Oscillate}

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
