extends Node

var UI_LAYER = preload("res://src/ui/ui_layer.tscn")
var UI_BUTTON = preload("res://src/ui/ui_button.tscn")
var THEME_BASE = preload("res://themes/base.tres")

var logs = Logger.new("ui_elements")

func layer() -> UILayer:
    var e = UI_LAYER.instantiate()
    return e

func rich_text_label() -> RichTextLabel:
    var e = RichTextLabel.new()
    e.theme = Scenes.THEME_BASE
    e.fit_content = true
    e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return e

func label(text: String = "") -> Label:
    var e = Label.new()
    e.theme = Scenes.THEME_BASE
    e.text = text
    e.focus_mode = Control.FOCUS_NONE
    return e

func button(config: UIButtonConfig = null) -> UIButton:
    var e = UI_BUTTON.instantiate() as UIButton
    if config:
        e.config = config
    return e
