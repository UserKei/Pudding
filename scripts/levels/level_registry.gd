extends RefCounted
class_name LevelRegistry

const LEVEL_PATHS := {
	"level_01": "res://scenes/levels/level_01.tscn",
	"level_02": "res://scenes/levels/level_02.tscn",
	"level_03": "res://scenes/levels/level_03.tscn",
	"level_end": "res://scenes/levels/level_end.tscn",
}


static func has_level(level_id: String) -> bool:
	return LEVEL_PATHS.has(level_id)


static func get_level_path(level_id: String) -> String:
	return LEVEL_PATHS.get(level_id, "")


static func load_level(level_id: String) -> PackedScene:
	var level_path := get_level_path(level_id)
	if level_path.is_empty():
		return null
	return load(level_path) as PackedScene
