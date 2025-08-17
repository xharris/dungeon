extends UIInspectNode
class_name UICharacterInspect

@export var character:Character

func _ready() -> void:
    super._ready()   
    logs.set_prefix(character.stats.id)
    set_title(character.stats.id)
    
    selected.connect(_on_selected)

func _on_selected(layer:UILayer) -> bool:
    var items = character.inventory.items
    for item in items:
        var button = Scenes.UI_BUTTON.instantiate() as UIButton
        button.text = item.id
        layer.add_to_bottom_row(button)
    return true
