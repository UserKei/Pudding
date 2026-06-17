extends Node

signal level_changed(level_id: String, display_name: String)
signal room_changed(room_id: String)
signal checkpoint_changed(spawn_name: String)
signal collectibles_changed(count: int)
signal death_count_changed(count: int)
signal pause_changed(is_paused: bool)

var current_level_id := ""
var current_level_name := ""
var current_room_id := ""
var current_spawn_name := ""
var current_checkpoint_name := ""
var collectible_count := 0
var death_count := 0
var collected_ids: Dictionary = {}


func reset_run() -> void:
	current_level_id = ""
	current_level_name = ""
	current_room_id = ""
	current_spawn_name = ""
	current_checkpoint_name = ""
	collectible_count = 0
	death_count = 0
	collected_ids.clear()
	level_changed.emit(current_level_id, current_level_name)
	room_changed.emit(current_room_id)
	checkpoint_changed.emit(current_checkpoint_name)
	collectibles_changed.emit(collectible_count)
	death_count_changed.emit(death_count)


func enter_level(level_id: String, display_name: String, spawn_name: String) -> void:
	current_level_id = level_id
	current_level_name = display_name
	current_room_id = ""
	current_spawn_name = spawn_name
	current_checkpoint_name = ""
	level_changed.emit(current_level_id, current_level_name)
	room_changed.emit(current_room_id)
	checkpoint_changed.emit(current_checkpoint_name)


func enter_room(room_id: String, spawn_name: String) -> void:
	current_room_id = room_id
	current_spawn_name = spawn_name
	current_checkpoint_name = ""
	room_changed.emit(current_room_id)
	checkpoint_changed.emit(current_checkpoint_name)


func set_checkpoint(spawn_name: String) -> void:
	current_checkpoint_name = spawn_name
	current_spawn_name = spawn_name
	checkpoint_changed.emit(current_checkpoint_name)


func get_respawn_name(default_spawn_name: String) -> String:
	if not current_checkpoint_name.is_empty():
		return current_checkpoint_name
	if not current_spawn_name.is_empty():
		return current_spawn_name
	return default_spawn_name


func register_death() -> void:
	death_count += 1
	death_count_changed.emit(death_count)


func collect(collectible_id: String) -> bool:
	if collectible_id.is_empty() or collected_ids.has(collectible_id):
		return false

	collected_ids[collectible_id] = true
	collectible_count += 1
	collectibles_changed.emit(collectible_count)
	return true


func is_collectible_collected(collectible_id: String) -> bool:
	return not collectible_id.is_empty() and collected_ids.has(collectible_id)


func set_pause_state(is_paused: bool) -> void:
	pause_changed.emit(is_paused)
