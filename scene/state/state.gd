extends Node
class_name State

func get_machine() -> StateMachine:
	var parent = get_parent() as StateMachine
	if parent == null:
		push_warning("state does not have machine parent", parent)
	return parent
