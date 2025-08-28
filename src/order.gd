extends Object
class_name Order

enum Type {LINEAR, RANDOM, PING_PONG}

var _items:Array
var _type: Type = Type.LINEAR
var _index:int = -1
var _increment:bool = true

func set_items(items:Array):
    _items.assign(items)
    
func set_type(type:Order.Type):
    _type = type
    
func next():
    if _items.size() == 0:
        return null
    
    match _type:
        Type.LINEAR:
            _index += 1
        Type.RANDOM:
            _index = randi() * _items.size()
        Type.PING_PONG:
            if _increment:
                _index += 1
            else:
                _index -= 1
            # switch direciton
            if _index <= 0:
                _increment = true
            elif _index >= _items.size() - 1:
                _increment = false
    _index = wrapi(_index, 0, _items.size())
    
    return _items[_index]
