extends Visitor
class_name VisitorAddScene

@export var scene:PackedScene

func run():
    var s = scene.instantiate()
    Util.main_node.add_child(s)
    finished.emit()
