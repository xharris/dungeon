class_name Item
extends Resource

enum AttackAnimation {None, Swing}
enum Hold {None, Primary, Secondary}

signal item_activated(item: Item)

# config

@export var visitors:Array[ItemVisitor]
@export var id: String = "unknown"
## max stack size in inventory[br]
## [code]0[/code] infinite
@export var max_stack: int = 1
## hide this item from the inventory
@export var hide: bool = false
@export var disable_unequip: bool = false

# visual

## scene to use when creating an instance
@export var scene: PackedScene
@export var icon: Texture2D
## which hand the item is held in
@export var hold: Hold
@export var animation_library:AnimationLibrary
## optional, if this item is a weapon
@export var weapon_visitor:Array[WeaponVisitor]

# combat

@export var attack_animation: AttackAnimation
## charges required to activate this item
@export var max_charge: int = 0
@export var base_damage: int = 0

var charges: int = 0

func add_charge(x: int = 1):
    if charges >= max_charge:
        item_activated.emit(self)
        charges = 0
    else:
        charges += x

func get_description() -> String:
    var texts:Array[String] = [id]  
    
    var descriptions = visitors\
        .map(func(v:ItemVisitor): return v.get_description())\
        .filter(func(v:String): return v.length() > 0)\
        .map(func(v:String): return "- %s" % v)
    texts.append_array(descriptions)
    
    return "\n".join(texts)
