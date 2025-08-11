extends Resource
class_name CharacterConfig

enum Group {PLAYER, ALLY, ENEMY}
var group_names = ["player", "ally", "enemy"]

var logs = Logger.new("character_config")

@export var id = "unknown":
    set(v):
        id = v
        logs.set_prefix(id) # set prefix instead of id
@export var group: Group
@export var stats:Stats:
    set(v):
        stats = v
        stats.id = id
@export var inventory:Inventory:
    set(v):
        inventory = v
        inventory.id = id

func group_name():
    return group_names[group]
