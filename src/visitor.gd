extends Resource
class_name Visitor

@warning_ignore("unused_signal")
signal finished

static var logs = Logger.new("visitor")
var id:String = "Visitor"

## WARNING Do not override
func visit():
    run()

## Emit [code]finished[/code] when done. Optional, but can cause
## bugs if it has connections but it's not called
func run():
    pass

func reset():
    pass
