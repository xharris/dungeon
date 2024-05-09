class_name Health
extends Node2D

var remaining:int
var total:int:
	set(v):
		var ratio = (remaining / total) * total
		total = v
		if remaining > v:
			remaining = v
		elif remaining > 0:
			remaining *= ratio

func take_damage(amt:int):
	remaining -= amt
	# show hit point text
