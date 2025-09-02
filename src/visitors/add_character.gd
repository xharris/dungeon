extends Visitor
class_name VisitorAddCharacter
    
@export var config:CharacterConfig

func _init() -> void:
    id = "VisitorAddCharacter"
    logs.set_prefix("add_character")

func run():
    # only one player allowed
    var tree = Util.main_node.get_tree()
    if not tree:
        logs.debug("not in tree")
        return
    var player = tree.get_first_node_in_group(Groups.CHARACTER_PLAYER) as Character
    if config.group == Groups.CHARACTER_PLAYER and player and player.stats.is_alive():
        logs.warn("cannot create multiple players")
        return
    # create new player
    var c = Character.create(config)
    logs.info("add %s" % config.id)
    finished.emit()
