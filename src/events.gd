extends Node
@warning_ignore_start("unused_signal")

signal character_created(c:Character)
signal characters_arranged

signal room_created(room:RoomConfig, node:Node2D)
signal room_finished(room:RoomConfig)

signal trigger_rooms_next
signal trigger_game_restart
