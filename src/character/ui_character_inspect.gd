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
    var config = UIButtonConfig.new("hp")
    if character.stats.is_alive():
        config.text = "HP: %d/%d" % [character.stats.hp, character.stats.max_hp]
    else:
        config.text = "Dead"
    config.disabled = true
    var hp_button = UIElements.button(config)
    layer.add_to_bottom_row(hp_button)
    
    # add inventory slots
    var items = character.inventory.items
    for i in character.inventory.capacity: 
        var item = character.inventory.get_item_at(i)
        var button:UIButton
        config = UIButtonConfig.new()
        if item:
            # add item
            config.id = item.id
            config.text = item.id
        else:
            # add empty slot
            config.id = "inventory-slot-%d" % i
            config.text = ""
        button = UIElements.button(config)
        button.pressed.connect(_on_item_pressed.bind(i))
        button.focus_entered.connect(_on_item_focus_entered.bind(i))
        layer.add_to_bottom_row(button)
        
    return true

func _on_item_pressed(i:int):
    pass 
    # TODO show help info for this item? 
    # TODO or should it go in the top row with a 'press SPACE to view more' if needed?

func _on_item_focus_entered(i:int):
    var layer = get_layer()
    layer.clear_top_row()
    # display item info
    var item = character.inventory.get_item_at(i)
    if item:
        logs.info("focus item: %s" % item.id)
        var label = UIElements.rich_text_label()
        label.text = item.get_description()
        layer.add_to_top_row(label)
