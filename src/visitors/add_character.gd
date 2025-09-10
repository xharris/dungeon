extends Visitor
class_name AddCharacter
    
@export var config: CharacterConfig

func _init() -> void:
    logs.set_prefix("add_character")

func visit():
    var characters = Util.get_first_node_in_group(Groups.CHARACTERS)
    logs.error(not characters, "could not find characters node")
    # only one player allowed
    var player: Character = Util.get_first_node_in_group(Groups.CHARACTER_PLAYER)
    if config.group == Groups.CHARACTER_PLAYER and player and player.stats.is_alive():
        logs.warn("cannot create multiple players: %s" % [player.name])
        return
    # create new player
    var c = Character.create(config)
    logs.info("add %s" % [c.name])
    Events.character_created.emit(c)
