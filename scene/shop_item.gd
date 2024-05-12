class_name ShopItem
extends Node2D

var cost:int = 0
var is_purchased = false

signal purchased

func _on_button_pressed():
	var button := %Button as Button
	button.disabled = true
	Game.money -= cost
	is_purchased = true
	purchased.emit()
