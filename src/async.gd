extends Resource
class_name Async

static var logs = Logger.new("async")#, Logger.Level.DEBUG)

class AwaitAll:
    signal done

    var _done_count = 0
    var _connection_count = 0
    
    func _init(signals: Array[Signal] = []) -> void:
        for s in signals:
            add(s)

    func _done():
        if _connection_count == 0:
            Async.logs.debug("no connections")
            return
        _done_count += 1
        Async.logs.debug("done (%d/%d)" % [_done_count, _connection_count])
        if _done_count >= _connection_count:
            done.emit()
        
    func add(sig: Signal):
        if sig.is_connected(_done):
            sig.disconnect(_done)
        Async.logs.debug("connect %s" % sig)
        sig.connect(_done, CONNECT_ONE_SHOT)
        _connection_count += 1
        
    func remove(sig: Signal):
        if sig.is_connected(_done):
            sig.disconnect(_done)
            _connection_count -= 1
            Async.logs.debug("disconnect %s" % sig)
        
    func reset():
        _done_count = 0
        _connection_count = 0
        for c: Dictionary in done.get_connections():
            done.disconnect(c.get("callable"))
        
## Untested[br]
## Usage: await await_all(timer1.timeout, timer2.timeout, ...)
static func all(signals: Array[Signal]) -> Signal:
    var await_all = AwaitAll.new(signals)
    return await_all.all_done
