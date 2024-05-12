class_name ShopItem
extends Node2D

static var Group = "shop_item"

var cost:int = 0
var is_purchased = false

signal purchased

func _ready():
	add_to_group(Group)

func disable():
	var button := %Button as Button
	button.disabled = true

func _on_button_pressed():
	disable()
	Game.money -= cost
	is_purchased = true
	purchased.emit()

