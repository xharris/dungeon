class_name ShopNPC
extends Node2D

static func sword(npc:ShopNPC):
	npc.sprite.weapon_texture = load("res://image/sword.png")

static var npc_pool:Array[Callable] = [ShopNPC.sword]

@export var sprite:NPCSprite
@export var health:Health
@export var ability:Ability
@export var shop_item:ShopItem

func _ready():
	shop_item.purchased.connect(on_purchased)

func on_purchased():
	Game.add_ally(self)
