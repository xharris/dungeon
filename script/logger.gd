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
		
	func error(msg:Variant, args:Variant = {}):
		if !Engine.is_editor_hint() and _is_level(Level.Error):
			push_error("[!] ", _name, " \t", str(msg).format(args))
			
	func warn(msg:Variant, args:Variant = {}):
		if !Engine.is_editor_hint() and _is_level(Level.Warn):
			push_warning("[!] ", _name, " \t", str(msg).format(args))
			
	func debug(msg:Variant, args:Variant = {}):
		if !Engine.is_editor_hint() and _is_level(Level.Debug):
			print("[?] ", _name, " \t", str(msg).format(args))
		
	func info(msg:Variant, args:Variant = {}):
		if !Engine.is_editor_hint() and _is_level(Level.Info):
			print("[i] ", _name, " \t", str(msg).format(args))
