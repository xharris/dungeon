extends ItemVisitor
class_name BasicWeapon

func on_get_possible_targets() -> Array:
    return [TARGET.ENEMY]
