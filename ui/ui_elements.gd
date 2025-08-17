extends Node

func rich_text_label() -> RichTextLabel:
    var e = RichTextLabel.new()
    e.theme = Scenes.THEME_BASE
    e.fit_content = true
    e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return e

func label(text:String = "") -> Label:
    var e = Label.new()
    e.theme = Scenes.THEME_BASE
    e.text = text
    e.focus_mode = Control.FOCUS_NONE
    return e

func button() -> UIButton:
    return Scenes.UI_BUTTON.instantiate() as UIButton
