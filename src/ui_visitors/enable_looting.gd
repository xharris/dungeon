extends Visitor
class_name VisitorEnableLooting

@export_enum(
    Groups.CHARACTER_ALLY, Groups.CHARACTER_ENEMY,
    ) var character_groups:Array[String]

func _init() -> void:
    logs.set_id("enable_looting")

func run():
    for c in Characters.get_all():
        if character_groups.any(func(g:String):
            return c.is_in_character_group(g)
        ):
            c.inventory.lootable = true
