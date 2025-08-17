extends UIInspectNode
class_name UICharacterInspect

@export var character:Character

func _ready() -> void:
    super._ready()   
    logs.set_prefix(character.stats.id)
    set_title(character.stats.id)
    
    selected.connect(_on_selected)

func _on_selected(layer:UILayer) -> bool:
    # add hp
    var hp_button = Scenes.UI_BUTTON.instantiate() as UIButton
    hp_button.text = "HP: %d/%d" % [character.stats.hp, character.stats.max_hp]
    hp_button.disabled = true
    layer.add_to_bottom_row(hp_button)
    # add items
    var items = character.inventory.items
    for item in items:
        var button = UIElements.button()
        button.text = item.id
        button.focus_entered.connect(_on_item_focus_entered.bind(layer, item))
        layer.add_to_bottom_row(button)
    return true

func _on_item_focus_entered(layer:UILayer, item:Item):
    logs.info("focus item: %s" % item.id)
    layer.clear_top_row()
    var label = UIElements.rich_text_label()
    label.text = item.get_description()
    layer.add_to_top_row(label)
