extends ItemVisitor
class_name TwoChargeAttack

func on_attack_landed():
    if ctx.source:
        add_charge_all(ctx.source.inventory.items, 2) # extra charge
