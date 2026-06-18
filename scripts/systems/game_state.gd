extends Node

signal level_changed(level_id: String, display_name: String)
signal room_changed(room_id: String)
signal checkpoint_changed(spawn_name: String)
signal collectibles_changed(count: int)
signal death_count_changed(count: int)
signal pause_changed(is_paused: bool)
signal q_charges_changed(count: int)
signal q_used(use_record: Dictionary)

const SAVE_PATH := "user://pudding_save.json"
const INITIAL_Q_CHARGES := 1
const RESET_Q_ON_START := true

var current_level_id := ""
var current_level_name := ""
var current_room_id := ""
var current_spawn_name := ""
var current_checkpoint_name := ""
var collectible_count := 0
var death_count := 0
var collected_ids: Dictionary = {}
var q_charges := INITIAL_Q_CHARGES
var q_uses: Array[Dictionary] = []
var persistent_effects: Array[Dictionary] = []
var used_q_marker_ids: Dictionary = {}


func _ready() -> void:
	if RESET_Q_ON_START:
		reset_q_state()
	else:
		load_save()


func reset_run() -> void:
	current_level_id = ""
	current_level_name = ""
	current_room_id = ""
	current_spawn_name = ""
	current_checkpoint_name = ""
	collectible_count = 0
	death_count = 0
	collected_ids.clear()
	reset_q_state(false)
	level_changed.emit(current_level_id, current_level_name)
	room_changed.emit(current_room_id)
	checkpoint_changed.emit(current_checkpoint_name)
	collectibles_changed.emit(collectible_count)
	death_count_changed.emit(death_count)
	save_game()


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


func add_q_charges(amount: int) -> void:
	if amount <= 0:
		return

	q_charges += amount
	q_charges_changed.emit(q_charges)
	save_game()


func reset_q_state(should_save := true) -> void:
	q_charges = INITIAL_Q_CHARGES
	q_uses.clear()
	persistent_effects.clear()
	used_q_marker_ids.clear()
	q_charges_changed.emit(q_charges)

	if should_save:
		save_game()


func can_use_q_marker(marker_id: String) -> bool:
	if marker_id.is_empty():
		return false
	if q_charges <= 0:
		return false

	return not used_q_marker_ids.has(marker_id)


func is_q_marker_used(marker_id: String) -> bool:
	return not marker_id.is_empty() and used_q_marker_ids.has(marker_id)


func record_q_use(
	marker_id: String,
	effect_id: String,
	use_position: Vector2,
	persistent_effect := {},
	source_type := "event_marker",
	source_id := "",
	consume_source_once := true
) -> bool:
	if marker_id.is_empty():
		return false
	if q_charges <= 0:
		return false
	if consume_source_once and is_q_marker_used(marker_id):
		return false
	if effect_id.is_empty():
		return false

	q_charges -= 1
	if consume_source_once:
		used_q_marker_ids[marker_id] = true

	var resolved_source_id := source_id if not source_id.is_empty() else marker_id

	var use_record := {
		"use_id": get_next_q_use_id(),
		"level_id": current_level_id,
		"room_id": current_room_id,
		"position": vector_to_save_dict(use_position),
		"effect_id": effect_id,
		"marker_id": marker_id,
		"source_type": source_type,
		"source_id": resolved_source_id,
		"source_consumed_once": consume_source_once,
	}
	q_uses.append(use_record)

	if not persistent_effect.is_empty():
		persistent_effects.append(persistent_effect)

	q_charges_changed.emit(q_charges)
	q_used.emit(use_record)
	save_game()
	return true


func get_next_q_use_id() -> String:
	return "q_use_%04d" % [q_uses.size() + 1]


func get_persistent_effects_for_level(level_id: String) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for effect in persistent_effects:
		if str(effect.get("level_id", "")) == level_id:
			effects.append(effect)

	return effects


func vector_to_save_dict(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}


func save_dict_to_vector(value: Variant) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2.ZERO

	var dict := value as Dictionary
	return Vector2(
		float(dict.get("x", 0.0)),
		float(dict.get("y", 0.0))
	)


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		q_charges = INITIAL_Q_CHARGES
		return

	var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		push_warning("Could not open save file: %s" % SAVE_PATH)
		q_charges = INITIAL_Q_CHARGES
		return

	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file was not a dictionary: %s" % SAVE_PATH)
		q_charges = INITIAL_Q_CHARGES
		return

	var save_data := parsed as Dictionary
	q_charges = int(save_data.get("q_charges", INITIAL_Q_CHARGES))
	q_uses = normalize_dictionary_array(save_data.get("q_uses", []))
	persistent_effects = normalize_dictionary_array(save_data.get("persistent_effects", []))
	rebuild_used_q_markers()


func save_game() -> void:
	var save_data := {
		"q_charges": q_charges,
		"q_uses": q_uses,
		"persistent_effects": persistent_effects,
	}

	var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_warning("Could not write save file: %s" % SAVE_PATH)
		return

	save_file.store_string(JSON.stringify(save_data, "\t"))


func normalize_dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for item in value:
		if typeof(item) == TYPE_DICTIONARY:
			result.append(item as Dictionary)

	return result


func rebuild_used_q_markers() -> void:
	used_q_marker_ids.clear()
	for use_record in q_uses:
		var source_type := str(use_record.get("source_type", "event_marker"))
		var source_consumed_once := bool(use_record.get("source_consumed_once", true))
		if source_type != "event_marker" or not source_consumed_once:
			continue

		var marker_id := str(use_record.get("marker_id", ""))
		if not marker_id.is_empty():
			used_q_marker_ids[marker_id] = true
