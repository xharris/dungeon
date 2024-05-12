extends Node

var l = Logger.create("scenes")

var _shop_npc = preload("res://scene/shop/shop_npc.tscn")
func shop_npc() -> ShopNPC:
	return _shop_npc.instantiate() as ShopNPC

var _npc = preload("res://scene/npc/npc.tscn")
func npc(ability:Ability, sprite:NPCSprite, health:Health) -> NPC:
	var n := _npc.instantiate() as NPC
	n.ability = ability
	n.sprite = sprite
	n.health = health
	return n

var _action_text = preload("res://scene/action_text.tscn")
func action_text(source:Node2D, direction:int = 1, animation_type:ActionText.AnimationType = ActionText.AnimationType.Fly) -> ActionText:
	var at := _action_text.instantiate() as ActionText
	at.global_position = source.global_position
	at.z_index = 10
	# animation type
	match animation_type:
		ActionText.AnimationType.Fly:
			at.velocity = Vector2(randi_range(1,2) * direction, -3)
			at.gravity = Vector2(0, 0.25)
			at._disappear_timer.wait_time = 0.25
	source.get_tree().root.add_child(at)
	return at

var _projectile = preload("res://scene/projectile.tscn")
func projectile(from:Node2D, target:Node2D) -> Projectile:
	var p := _projectile.instantiate() as Projectile
	p.global_position = from.global_position
	p.target = target
	from.get_tree().root.add_child(p)
	return p

var _shop = preload("res://scene/room/shop.tscn")
func room_shop() -> Shop:
	var s := _shop.instantiate() as Shop
	return s

var _entrance = preload("res://scene/room/entrance.tscn")
func room_entrance() -> Entrance:
	var e := _entrance.instantiate() as Entrance
	return e

var _dungeon = preload("res://scene/dungeon.tscn")
func dungeon(size:int = 3) -> Dungeon:
	var d := _dungeon.instantiate() as Dungeon
	d.size = 3
	return d
