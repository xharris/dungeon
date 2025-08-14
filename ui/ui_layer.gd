extends MarginContainer
class_name UILayer

@onready var top_row = %TopRow
@onready var bottom_row = %BottomRow
@onready var background = %Background

## normal visible background color is [code]Color.WHITE[/code]
func set_background_color(color:Color = Color.TRANSPARENT):
    var tween = create_tween()
    tween.tween_property(background, "modulate", color, 1)
    tween.play()

func add_to_top_row(node:Node) -> UILayer:
    top_row.add_child(node)
    return self

func add_to_bottom_row(node:Node) -> UILayer:
    bottom_row.add_child(node)
    return self
