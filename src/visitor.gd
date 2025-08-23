extends Resource
class_name Visitor

signal finished

var logs = Logger.new("visitor")

## WARNING Do not override
func visit():
    run()

## Emit [code]finished[/code] when done. Optional, but can cause
## bugs if it has connections but it's not called
func run():
    pass
