extends Resource
class_name Async

static var logs = Logger.new("async")

class AwaitAll:
    signal all_done
    
    var _signals: Array[Signal]
    var _done_count = 0
    
    func _init(signals: Array[Signal]) -> void:
        _signals = signals

    func _done():
        _done_count += 1
        if _done_count >= _signals.size():
            all_done.emit()
        
    func go():
        for s in _signals:
            if s.is_connected(_done):
                s.disconnect(_done)
            s.connect(_done, CONNECT_ONE_SHOT)
        await all_done
        
## Untested[br]
## Usage: await await_all(timer1.timeout, timer2.timeout, ...)
static func all(signals:Array[Signal]):
    var await_all = AwaitAll.new(signals)
    await await_all.go()
