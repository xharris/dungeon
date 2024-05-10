class_name Health
extends Node2D

signal damaged

@export var remaining:int = 5
@export var total:int = 5:
	set(v):
		var ratio = (remaining / total) * total
		total = v
		if remaining > v:
			remaining = v
		elif remaining > 0:
			remaining *= ratio

func take_damage(amt:int):
	remaining -= amt
	damaged.emit(amt)
