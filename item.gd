class_name Item
extends Resource

enum AttackAnimation {None, Swing}
enum Hold {None, Primary, Secondary}

class Data:
    var source: Character
    var target: Character
    var item: Item

signal item_activated(item: Item)

# config

@export var item_id: String = "unknown"
## max stack size in inventory[br]
## [code]0[/code] infinite
@export var max_stack: int = 1

# visual

## scene to use when creating an instance
@export var scene: PackedScene
@export var icon: Texture2D
## which hand the item is held in
@export var hold: Hold

# combat

@export var attack_animation: AttackAnimation
## charges required to activate this item
@export var max_charge: int = 0

var charges: int = 0

func add_charge(x: int = 1):
    if charges >= max_charge:
        item_activated.emit(self)
        charges = 0
    else:
        charges += x

func get_possible_targets() -> Array[String]:
    return []

func on_attack_landed():
    add_charge()

func apply_damage(_data: Data) -> int:
    return 0
