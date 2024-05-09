class_name Logger
enum Level {Debug, Info, Warn, Error}

static var level:Level = Level.Info

static func create(_name:String, _level:Level = Level.Info) -> _Logger:
	var logger = _Logger.new()
	logger._name = _name
	logger.level = _level
	return logger

class _Logger:
	var level:Level
	var _name:String
	
	func _is_level(l:Level) -> bool:
		return self.level <= l or level <= l
		
	func error(msg:String, args:Variant = null):
		if _is_level(Level.Error):
			push_error("[!] ", _name, " \t", msg.format(args))
			
	func warn(msg:String, args:Variant = null):
		if _is_level(Level.Warn):
			push_warning("[!] ", _name, " \t", msg.format(args))
			
	func debug(msg:String, args:Variant = null):
		if _is_level(Level.Debug):
			print("[?] ", _name, " \t", msg.format(args))
		
	func info(msg:String, args:Variant = null):
		if _is_level(Level.Info):
			print("[i] ", _name, " \t", msg.format(args))
