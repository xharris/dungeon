extends Resource
class_name Order

enum Type {LINEAR, RANDOM, PING_PONG}

var _items:Array
var _type: Type = Type.LINEAR
var _index:int = -1
var _increment:bool = true
var _wrap:bool = true

func set_items(items:Array) -> Order:
    _items.assign(items)
    return self
    
func set_type(type:Type) -> Order:
    _type = type
    match _type:
        Type.PING_PONG, Type.RANDOM:
            set_wrap(true)
    return self

func set_wrap(wrap:bool) -> Order:
    _wrap = wrap
    return self

func next():
    if _items.size() == 0:
        return null
    
    match _type:
        Type.LINEAR:
            _index += 1
        Type.RANDOM:
            _index = randi() * _items.size()
        Type.PING_PONG:
            _index += 1
            var i = pingpong(_index, _items.size() - 1)
            return _items[i]
            
    if _wrap:
        _index = wrapi(_index, 0, _items.size())
    if _index < 0 or _index >= _items.size():
        return
    
    return _items[_index]
