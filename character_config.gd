extends Resource
class_name CharacterConfig
    
var logs = Logger.new("character_config")

@export var id = "unknown":
    set(v):
        id = v
        logs.set_prefix(id) # set prefix instead of id
@export_enum(
    Groups.CHARACTER_ANY, 
    Groups.CHARACTER_ALLY, 
    Groups.CHARACTER_ENEMY, 
    Groups.CHARACTER_PLAYER
) var group: String = Groups.CHARACTER_ANY
@export var stats:Stats:
    set(v):
        stats = v
        stats.id = id
@export var inventory:Inventory:
    set(v):
        inventory = v
        inventory.id = id
