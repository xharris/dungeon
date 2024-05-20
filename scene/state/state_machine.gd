class_name StateMachine
extends Node

var states:Array[State] = []
var stack:Array[State] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		states.append(child)
		remove_child(child)

func replace_state(state_name:String):
	pop_state()
	push_state(state_name)

func push_state(state_name:String, args:Array = []):
	for state in states:
		if state.name == state_name:
			stack.append(state)
			add_child(state)

func pop_state():
	var current = stack.pop_back()
	remove_child(current)
