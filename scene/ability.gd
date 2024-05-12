class_name Ability
extends Node2D

enum TargetType {Ally, Enemy, Self}
enum AbilityRange {Melee, Ranged}
enum AbilityEffect {Damage, Heal}

var l = Logger.create("ability")

@export var target_type:TargetType
@export var ability_range:AbilityRange
@export var cooldown:float = 1.0:
	set(v):
		cooldown = v
		timer.wait_time = v
@export var strength:int = 1
@export var effect:AbilityEffect
@export var times:int = 1
@export var projectile_speed:int = 0

var target:NPC
var timer = Timer.new()
var repeat_timer = Timer.new()
var _times_count = 0

signal activated
signal speed_changed(float)

func _ready():
	add_child(timer)
	timer.one_shot = false
	timer.timeout.connect(activate)
	add_child(repeat_timer)
	repeat_timer.one_shot = true

func inflict(from_projectile = false):
	if !target:
		l.warn("no target to inflict ability")
		return
	if ability_range == AbilityRange.Ranged && !from_projectile:
		var p := Scenes.projectile(self, target)
		p.target_reached.connect(inflict.bind(true))
	match effect:
		AbilityEffect.Damage:
			target.health.take_damage(strength)
			var at = Scenes.action_text(target, -1 if target.global_position.x < global_position.x else 1)
			at.set_text(strength)
			at.set_color(Color.hex(0xF44336FF))

func set_target(t:NPC):
	target = t

func reset():
	l.debug("reset")
	target = null

func get_range() -> int:
	match ability_range:
		AbilityRange.Melee:
			return 20
		AbilityRange.Ranged:
			return 80
	return 0

func is_stopped() -> bool:
	return timer.is_stopped()

func stop():
	if !is_stopped():
		l.debug("stop ability")
		timer.stop()
	
func start():
	if is_stopped():
		l.debug("start ability")
		speed_changed.emit(1.0 / (cooldown / times))
		activate()
		timer.start()

func activate():
	if _times_count < times:
		repeat_timer.timeout.connect(activate)
		repeat_timer.start(cooldown / times)
		_times_count += 1
		l.debug("ability activate (x{times}), range={range}",{ 
			"times":_times_count, 
			"range":ability_range,
			"wait_time": repeat_timer.wait_time
		})
		activated.emit()
	else:
		_times_count = 0
		repeat_timer.stop()
