extends Node2D

@export var pathfinder:Pathfinder

var velocity:Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	pathfinder.velocity_changed.connect(_on_pathfinder_velocity_changed)

func _on_pathfinder_velocity_changed(v:Vector2):
	velocity = v

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position += velocity * delta * 80
