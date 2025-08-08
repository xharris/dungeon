class_name Sword
extends Item

func on_attack_landed():
    super.on_attack_landed()
    add_charge() # add extra charge
