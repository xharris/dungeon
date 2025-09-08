extends Resource
class_name Item

# config

@export var id: String = "unknown"
## hide this item from the inventory
@export var hide: bool = false
@export var disable_unequip: bool = false
@export var is_weapon: bool = false

# visual

## scene to use when creating an instance
@export var scene: PackedScene
@export var icon: Texture2D
@export var animation_library:AnimationLibrary:
    set(v):
        animation_library = v.duplicate()
        if animation_library:
            animation_library.resource_name = id

# combat

@export var attack_config: ItemAttackConfig:
    set(v):
        attack_config = v
        if attack_config:
            attack_config = attack_config.duplicate()

func get_description() -> String:
    var texts:Array[String] = [id]  
    return "\n".join(texts)
