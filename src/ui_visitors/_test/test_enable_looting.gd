extends GutTest

func _create_character(group:StringName):
    var me = Scenes.CHARACTER.instantiate()
    me.add_to_group(group)
    return me

func _lootable_count() -> int:
    var count = 0
    for c in Characters.get_all():
        if c.inventory.lootable:
            count += 1
    return count

func test_groups():
    var visitor = load("res://src/ui_visitors/loot_enemies.tres") as VisitorEnableLooting
    
    _create_character(Groups.CHARACTER_PLAYER)
    _create_character(Groups.CHARACTER_ALLY)
    _create_character(Groups.CHARACTER_ENEMY)
    _create_character(Groups.CHARACTER_ENEMY)

    assert_eq(_lootable_count(), 0, "nobody is lootable")

    # enable looting on enemies
    visitor.run()
    for c in Characters.get_all():
        assert_false(c.is_in_character_group(Groups.CHARACTER_PLAYER), "player should not be lootable")
        assert_false(c.is_in_character_group(Groups.CHARACTER_ALLY), "allies should not be lootable")
        assert_true(c.is_in_character_group(Groups.CHARACTER_ENEMY), "enemies should be lootable")
