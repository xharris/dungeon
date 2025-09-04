extends Visitor
class_name VisitorSetCombat

## if [code]true[/code], waits for characters to be arranged
@export var combat_enabled:bool

func _init() -> void:
    logs.set_prefix("set_combat")
    
func run():
    if combat_enabled:
        logs.info("enable combat, wait for arrange")
        Events.characters_arranged.connect(_on_arrange_finished, CONNECT_ONE_SHOT)
    else:
        for c in GameUtil.all_characters():
            c.disable_combat()
        finished.emit()

func _on_arrange_finished():
    logs.info("arrange finished")
    for c in GameUtil.all_characters():
        var fn_char_death = _on_character_death.bind(c)
        if not c.stats.death.is_connected(fn_char_death):
            c.stats.death.connect(fn_char_death)
        c.enable_combat()

func _on_character_death(character:Character):
    var enemies:Array[Character] = GameUtil.all_characters().filter(func(c:Character): 
        return c.get_combat_state() == Character.CombatState.ENABLED and \
            c.is_in_group(Groups.CHARACTER_ENEMY)
    )
    var enemies_alive = enemies.reduce(func(prev:int, curr:Character): 
        return prev + (1 if curr.stats.is_alive() else 0)
    , 0)

    if enemies_alive == 0 or character.is_in_group(Groups.CHARACTER_PLAYER):
        # combat is over
        logs.info("combat finished")
        for c in GameUtil.all_characters():
            c.disable_combat()
        finished.emit()
