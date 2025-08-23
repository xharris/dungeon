extends Visitor
class_name VisitorAddCharacter

@export var config:CharacterConfig

func _init() -> void:
    logs.set_prefix("add_character")

func run():
    var c = Scenes.CHARACTER.instantiate() as Character
    c.use_config(config)
    logs.info("add %s" % config.id)
    GameUtil.characters().add_child(c)
    finished.emit()
