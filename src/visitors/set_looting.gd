extends Visitor
class_name VisitorSetLooting

var LOOTING:UILayerConfig = preload("res://src/ui_layer_configs/looting.tres")

@export_enum(
    Groups.CHARACTER_ALLY, Groups.CHARACTER_ENEMY,
    ) var character_groups:Array[String]
@export var enabled:bool = true

func _init() -> void:
    logs.set_id("enable_looting")

func run():
    for c in GameUtil.all_characters():
        if character_groups.any(func(g:String):
            return c.is_in_character_group(g)
        ):
            c.inventory.lootable = true
    # TODO show looting ui and connect `finished` to when UI is closed
    _show_looting_ui()
    finished.emit()

func _show_looting_ui():
    var layer = UIElements.layer()
    layer.config = LOOTING
    Util.main_node.add_child(layer)
    
    # show create looting ui
    if logs.warn_if(layer.set_state(UILayer.State.VISIBLE), "could not create looting ui"):
        return
    for c in GameUtil.all_characters():
        if c.is_in_character_group(Groups.CHARACTER_ENEMY):
            c.inventory.lootable = true
        
    var first = false
    for c in GameUtil.all_characters():
        if c.is_in_group(Groups.CHARACTER_PLAYER) or c.is_in_character_group(Groups.CHARACTER_ALLY):
            c.inspect_node.set_state(UIInspectNode.State.HIDDEN)
            continue
        c.inspect_node.set_state(UIInspectNode.State.VISIBLE)
        c.inventory.lootable = true
        if not first:
            first = true
            c.inspect_node.control.grab_focus()
