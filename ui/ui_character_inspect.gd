extends UIInspectNode
class_name UICharacterInspect

@export var character:Character

func _ready() -> void:
    super._ready()   
    logs.set_prefix(character.name)

func select(layer:UILayer):
    super.select(layer)
    var items = character.inventory.items
    for item in items:
        var button = Scenes.UI_BUTTON.instantiate() as UIButton
        button.text = item.id
        layer.add_to_bottom_row(button)
