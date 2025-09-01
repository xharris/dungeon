extends Node2D
class_name ActionText

static var scene = preload("res://src/action_text/action_text.tscn")

static func create(modifiers: Array[Callable] = []) -> ActionText:
    var me = scene.instantiate() as ActionText
    me._tween = me.create_tween().set_parallel(true)
    Mod.duration = 0.5
    Util.main_node.add_child(me)
    for m in modifiers:
        m.call(me)
    me._tween.finished.connect(me._done)
    return me

class FontSize:
    const SMALL:int = 32
    const NORMAL:int = 60
    const LARGE:int = 72

class Mod extends Object:
    static var duration = 0.5

    static func set_duration(v: float):
        return func(_me: ActionText):
            duration = v

    static func chain():
        return func(me: ActionText):
            me._tween = me._tween.chain()
    
    static func set_font_size(size:int):
        return func(me: ActionText):
            me._label["theme_override_font_sizes/normal_font_size"] = size
            
    static func use_global_position(node: Node2D):
        return func(me: ActionText):
            me.global_position = node.global_position
            
    static func set_text(text):
        return func(me: ActionText):
            me.text = str(text)
            me.name = "action-text-%s" % me.text

    static func velocity(initial_speed: Vector2 = Vector2(0, -700)):
        return func(me: ActionText):
            me.velocity = initial_speed
            # slow down
            me._tween.tween_property(me, "velocity", Vector2.ZERO, duration)
            
    static func modulate(to: Color, from: Color = Color.TRANSPARENT):
        return func(me: ActionText):
            var t = me._tween.tween_property(me, "modulate", to, duration)
            if from != Color.TRANSPARENT:
                t.from(from)

signal finished

@onready var _label = %RichTextLabel as RichTextLabel

@export var text: String = "":
    set(v):
        text = v
        _label.text = text
@export var destroy_when_finished:bool = true

var velocity: Vector2
@warning_ignore("unused_private_class_variable")
var _tween: Tween

func _process(delta: float) -> void:
    global_position += velocity * delta

func _done():
    finished.emit()
    if destroy_when_finished:
        Util.destroy(self)
