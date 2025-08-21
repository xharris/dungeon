extends Resource
class_name UILayerConfig

## TODO change to {TOP, BOTTOM, INSPECT}
enum Type {TOP_BOTTOM, INSPECT}

## state when node becomes visible
@export var id:String
## TODO change to Array[Type]
@export var type:Type = Type.TOP_BOTTOM
@export var background_color:Color =  Color.TRANSPARENT
@export var top_row:Array[UIButtonConfig] = []
@export var bottom_row:Array[UIButtonConfig] = []
@export var esc_to_close:bool = true
@export var visible:bool = false
## instantiate a scene
@export var scene:PackedScene
@export var block_next_layer:Array[String] = []
@export var allow_next_layer:Array[String] = []

func _to_string() -> String:
    return str(to_dict())

func to_dict() -> Dictionary:
    return {
        "id": id,
        "type": Type.find_key(type),
        "background_color": background_color,
        "top_row": top_row.map(func(c): return c.to_dict()),
        "bottom_row": bottom_row.map(func(c): return c.to_dict()),
        "esc_to_close": esc_to_close,
        "visible": visible,
    }
