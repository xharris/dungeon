extends Visitor
class_name VisitorAddCharacter

static var _player_created: bool = false

@export var config:CharacterConfig

func _init() -> void:
    id = "VisitorAddCharacter"
    logs.set_prefix("add_character")

func run():
    # only one player
    if _player_created and config.group == Groups.CHARACTER_PLAYER:
        logs.warn("cannot create multiple players")
        return
    if config.group == Groups.CHARACTER_PLAYER:
        _player_created = true
    
    var c = Characters.create(config)
    logs.info("add %s" % config.id)
    GameUtil.characters().add_child(c)
    finished.emit()

func reset():
    _player_created = false
