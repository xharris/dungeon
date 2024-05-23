extends Node2D
class_name Door

static var l = Logger.create("door")
const Group = "door"
enum Type {Entrance, Exit}

signal player_entered(player:Player)
signal opened
signal closed

@export var is_open = false
## Open when the player get nearby
@export var proximity_open = true
@export var next_room:Scenes.RoomName
@export var type:Type
@export var start_direction:Vector2i = Vector2i(1, 0)
@export var destroy_on_use = false
@export var locked = false

var disable_until_closed = false
var _player_entered = false

func _process(delta):
	if proximity_open:
		var players:Array[Player] = []
		players.assign(get_tree().get_nodes_in_group(Player.Group))
		var nearby = false
		for player in players:
			if player.global_position.distance_to(global_position) < 64:
				nearby = true
		if nearby:
			open()
		else:
			close()
		
func open():
	if !is_open && !locked:
		var sprite = %Sprite2D as AnimatedSprite2D
		sprite.play("open")
		opened.emit()
	is_open = true
	
func close():
	if is_open:
		var sprite = %Sprite2D as AnimatedSprite2D
		sprite.play("closed")
		disable_until_closed = false
		closed.emit()
	is_open = false

func _on_area_2d_body_entered(body):
	var player = body.get_parent() as Player
	if player != null && is_open && !disable_until_closed && !_player_entered:
		if locked:
			Scenes.action_text(self, "LOCKED!")
			return
		_player_entered = true
		player_entered.emit(player)
		# go to next room
		var prev_room = Game.current_room_name
		var room = Game.go_to_room(next_room, player)
		if !room:
			l.error("Room not found! {next_room}", {"next_room":Scenes.RoomName.find_key(next_room)})
		var matching_door:Door
		for other in room.get_all_doors():
			if other.type != type and (other.next_room == prev_room or other.next_room == Scenes.RoomName.None):
				matching_door = other
		if !matching_door:
			l.error("Could not find matching door for {to} from {from}",{
				"to":Scenes.RoomName.find_key(next_room),
				"from":Scenes.RoomName.find_key(prev_room),
			})
			return
		# put player at matching door
		matching_door.open()
		matching_door.disable_until_closed = true
		player.global_position = matching_door.global_position
		player.movement.direction = matching_door.start_direction
		
		if destroy_on_use:
			get_parent().remove_child(self)
