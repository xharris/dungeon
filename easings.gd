class_name Easings
extends Node

static func _linear(x:int): 
	return x

class Easing:
	static func In(x:int): return x
	static func Out(x:int): return x
	static func InOut(x:int): return x

class Quad extends Easing:
	static func In(x:int): return x * x
	static func Out(x:int): return 1 - (1 - x) * (1 - x)
	static func InOut(x:int):
		if x < 0.5:
			return 2 * x * x
		return 1 - pow(-2 * x + 2, 2) / 2
