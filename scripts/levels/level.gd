extends Node2D
class_name Level

@export var level_id := ""
@export var display_name := ""
@export var default_spawn_name := "PlayerSpawn"
@export var camera_limit_left := 0
@export var camera_limit_top := 0
@export var camera_limit_right := 1280
@export var camera_limit_bottom := 400


func get_effective_level_id() -> String:
	return level_id if not level_id.is_empty() else str(name).to_snake_case()


func get_effective_display_name() -> String:
	return display_name if not display_name.is_empty() else str(name)


func get_spawn_point(spawn_name: String) -> Node2D:
	var resolved_spawn_name: String = spawn_name if not spawn_name.is_empty() else default_spawn_name
	var spawn_points := get_node_or_null("SpawnPoints")
	if spawn_points != null:
		var spawn_point := spawn_points.get_node_or_null(resolved_spawn_name) as Node2D
		if spawn_point != null:
			return spawn_point

	var recursive_spawn := find_child(resolved_spawn_name, true, false) as Node2D
	if recursive_spawn != null:
		return recursive_spawn

	return null


func get_camera_limits() -> Rect2i:
	return Rect2i(
		camera_limit_left,
		camera_limit_top,
		camera_limit_right - camera_limit_left,
		camera_limit_bottom - camera_limit_top
	)
