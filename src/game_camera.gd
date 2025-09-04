extends Camera2D
class_name GameCamera

signal tween_finished

@export var tween_duration:float = 5

func move_to(center:Vector2):
    # move camera to current Rooms
    var tween = create_tween()
    var prop = tween.tween_property(self, "position", center, tween_duration)
    prop.set_trans(Tween.TransitionType.TRANS_QUAD)
    prop.set_ease(Tween.EaseType.EASE_IN_OUT)
    tween.finished.connect(tween_finished.emit)
    tween.play()
