extends CharacterBody2D
class_name Hitbox

static var l = Logger.create("hitbox")
const Group = "hitbox"

signal collision(Vector2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var coll = move_and_collide(Vector2.ZERO, true)
	if coll:
		var norm = coll.get_normal().round()
		var other := coll.get_collider() as Hitbox
		if other:
			other.collision.emit(-norm)
		collision.emit(norm)
