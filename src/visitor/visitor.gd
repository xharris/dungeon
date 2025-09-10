extends Resource
class_name Visitor

var logs = Logger.new("visitor")

func visit():
    pass

func visit_characters(_v: Characters):
    pass

func visit_rooms(_v: Rooms):
    pass

func visit_stats(_v: Stats):
    pass

func visit_character(_v: Character):
    pass
