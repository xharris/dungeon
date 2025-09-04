extends Visitor
class_name VisitorAddCharacter
    
@export var config: CharacterConfig

func _init() -> void:
    id = "VisitorAddCharacter"
    logs.set_prefix("add_character")

func run():
    # only one player allowed
    var player: Character = Util.get_first_node_in_group(Groups.CHARACTER_PLAYER)
    if config.group == Groups.CHARACTER_PLAYER and player and player.stats.is_alive():
        logs.warn("cannot create multiple players: %s" % [player.name])
        return
    # create new player
    var c = Character.create(config)
    logs.info("add %s" % [c.name])
    finished.emit()
