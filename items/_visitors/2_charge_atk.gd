extends ItemVisitor
class_name TwoChargeAttack

func on_attack_landed():
    ctx.item.add_charge(2) # extra charge
