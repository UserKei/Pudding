extends Node
class_name QAbilityManager

const GROUND_BLOCK_SCENE := preload("res://scenes/props/ground_block.tscn")
const PERSISTENT_FIELD_SCRIPT := preload("res://scripts/props/q_persistent_field.gd")
const Q_GLOBAL_POOL_SCRIPT := preload("res://scripts/systems/q_global_pool.gd")
const EFFECT_CONTAINER_NAME := "QPersistentEffects"
const GLOBAL_POOL_NODE_NAME := "QGlobalPool"
const SOURCE_EVENT_MARKER := "event_marker"
const SOURCE_LEVEL_POOL := "level_pool"
const EFFECT_PERSISTENT_PLATFORM := "persistent_platform"
const EFFECT_BRIDGE_SEGMENT := "bridge_segment"
const EFFECT_ONE_SHOT_TELEPORT := "one_shot_teleport"
const EFFECT_GLIDE_FIELD := "glide_field"
const EFFECT_BURDEN_FIELD := "burden_field"

@export var player_path: NodePath = ^"../Player"
@export var q_action := "q_ability"
@export var enable_default_global_pool := true

@onready var player: Player = get_node_or_null(player_path) as Player

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	if not GameState.level_changed.is_connected(_on_level_changed):
		GameState.level_changed.connect(_on_level_changed)
	call_deferred("restore_persistent_effects_for_current_level")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(q_action):
		if try_use_q_ability():
			get_viewport().set_input_as_handled()


func _on_level_changed(_level_id: String, _display_name: String) -> void:
	call_deferred("restore_persistent_effects_for_current_level")


func try_use_q_ability() -> bool:
	var resolved_player := get_player()
	if resolved_player == null:
		return false
	if GameState.q_charges <= 0:
		return false

	var source := get_q_source(resolved_player)
	var source_node := source.get("node") as Node
	var source_key := str(source.get("marker_id", ""))
	var source_type := str(source.get("source_type", SOURCE_EVENT_MARKER))
	var source_id := str(source.get("source_id", source_key))
	var consume_source_once := bool(source.get("consume_source_once", true))
	if source_node == null or source_key.is_empty():
		return false

	if consume_source_once and not GameState.can_use_q_marker(source_key):
		return false

	var effect_id := str(source_node.call("select_effect_id", rng))
	if effect_id.is_empty():
		return false

	var use_position := resolved_player.global_position
	var result := apply_effect(effect_id, source_node, resolved_player, source)
	if not bool(result.get("ok", false)):
		return false

	var persistent_effect := result.get("persistent_effect", {}) as Dictionary
	if not GameState.record_q_use(
		source_key,
		effect_id,
		use_position,
		persistent_effect,
		source_type,
		source_id,
		consume_source_once
	):
		var spawned_node := result.get("spawned_node") as Node
		if spawned_node != null and is_instance_valid(spawned_node):
			spawned_node.queue_free()
		return false

	return true


func get_player() -> Player:
	if player != null and is_instance_valid(player):
		return player

	player = get_node_or_null(player_path) as Player
	return player


func get_q_source(resolved_player: Player) -> Dictionary:
	var marker := get_nearest_available_marker(resolved_player)
	if marker != null:
		var marker_id := str(marker.call("get_resolved_marker_id"))
		return {
			"node": marker,
			"marker_id": marker_id,
			"source_type": SOURCE_EVENT_MARKER,
			"source_id": marker_id,
			"consume_source_once": true,
		}

	var global_pool := get_level_global_pool()
	if global_pool == null:
		return {}

	var pool_id := get_global_pool_id(global_pool)
	if pool_id.is_empty():
		return {}

	return {
		"node": global_pool,
		"marker_id": pool_id,
		"source_type": SOURCE_LEVEL_POOL,
		"source_id": pool_id,
		"consume_source_once": false,
	}


func get_nearest_available_marker(resolved_player: Player) -> Node:
	var current_level := get_current_level()
	var nearest_marker: Node = null
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group("q_ability_marker"):
		var marker := node as Node2D
		if marker == null or not marker.has_method("is_player_in_range"):
			continue
		if current_level != null and not current_level.is_ancestor_of(marker):
			continue
		if not bool(marker.call("is_player_in_range", resolved_player)):
			continue

		var marker_id := str(marker.call("get_resolved_marker_id"))
		if GameState.is_q_marker_used(marker_id):
			continue

		var distance := resolved_player.global_position.distance_squared_to(marker.global_position)
		if distance < nearest_distance:
			nearest_marker = marker
			nearest_distance = distance

	return nearest_marker


func get_level_global_pool() -> Node:
	var current_level := get_current_level()
	if current_level == null:
		return null

	var named_pool := current_level.get_node_or_null(GLOBAL_POOL_NODE_NAME)
	if is_usable_global_pool(named_pool):
		return named_pool

	for node in get_tree().get_nodes_in_group("q_global_pool"):
		var pool := node as Node
		if pool == null:
			continue
		if current_level != pool and not current_level.is_ancestor_of(pool):
			continue
		if is_usable_global_pool(pool):
			return pool

	if enable_default_global_pool:
		return create_default_global_pool(current_level)

	return null


func is_usable_global_pool(pool: Node) -> bool:
	if pool == null:
		return false
	if not pool.has_method("select_effect_id"):
		return false
	if not pool.has_method("get_effect_position_for_player"):
		return false
	if not pool.has_method("get_effect_size"):
		return false

	var active: Variant = pool.get("active")
	return typeof(active) != TYPE_BOOL or bool(active)


func create_default_global_pool(current_level: Node2D) -> Node:
	var pool := Node.new()
	pool.name = GLOBAL_POOL_NODE_NAME
	pool.set_script(Q_GLOBAL_POOL_SCRIPT)
	current_level.add_child(pool)
	return pool


func get_global_pool_id(pool: Node) -> String:
	if pool.has_method("get_resolved_pool_id"):
		return str(pool.call("get_resolved_pool_id"))

	return "%s:%s" % [GameState.current_level_id, str(pool.get_path())]


func apply_effect(effect_id: String, source: Node, resolved_player: Player, source_info: Dictionary) -> Dictionary:
	match effect_id:
		EFFECT_PERSISTENT_PLATFORM, EFFECT_BRIDGE_SEGMENT:
			return apply_solid_effect(effect_id, source, resolved_player, source_info)
		EFFECT_ONE_SHOT_TELEPORT:
			return apply_one_shot_teleport(source, resolved_player)
		EFFECT_GLIDE_FIELD, EFFECT_BURDEN_FIELD:
			return apply_field_effect(effect_id, source, resolved_player, source_info)
		_:
			push_warning("Unknown Q ability effect: %s" % effect_id)
			return {"ok": false}


func apply_solid_effect(
	effect_id: String,
	source: Node,
	resolved_player: Player,
	source_info: Dictionary
) -> Dictionary:
	var data := build_persistent_effect_data(effect_id, source, resolved_player, source_info)
	var spawned_node := spawn_persistent_effect(data)
	return {
		"ok": spawned_node != null,
		"persistent_effect": data,
		"spawned_node": spawned_node,
	}


func apply_field_effect(
	effect_id: String,
	source: Node,
	resolved_player: Player,
	source_info: Dictionary
) -> Dictionary:
	var data := build_persistent_effect_data(effect_id, source, resolved_player, source_info)
	var spawned_node := spawn_persistent_effect(data)
	return {
		"ok": spawned_node != null,
		"persistent_effect": data,
		"spawned_node": spawned_node,
	}


func apply_one_shot_teleport(source: Node, resolved_player: Player) -> Dictionary:
	resolved_player.global_position = get_source_effect_position(
		source,
		EFFECT_ONE_SHOT_TELEPORT,
		resolved_player
	)
	resolved_player.reset_motion()
	var main := get_tree().current_scene
	if main != null and main.has_method("update_current_room_from_player"):
		main.call_deferred("update_current_room_from_player", true)

	return {"ok": true}


func build_persistent_effect_data(
	effect_id: String,
	source: Node,
	resolved_player: Player,
	source_info: Dictionary
) -> Dictionary:
	var effect_instance_id := "%s_%s" % [GameState.get_next_q_use_id(), effect_id]
	var effect_position := get_source_effect_position(source, effect_id, resolved_player)
	var current_level := get_current_level()
	if current_level != null:
		effect_position = current_level.to_local(effect_position)

	return {
		"effect_instance_id": effect_instance_id,
		"level_id": GameState.current_level_id,
		"room_id": GameState.current_room_id,
		"effect_id": effect_id,
		"marker_id": str(source_info.get("marker_id", "")),
		"source_type": str(source_info.get("source_type", SOURCE_EVENT_MARKER)),
		"source_id": str(source_info.get("source_id", "")),
		"position": GameState.vector_to_save_dict(effect_position),
		"size": GameState.vector_to_save_dict(get_source_effect_size(source, effect_id)),
	}


func get_source_effect_position(source: Node, effect_id: String, resolved_player: Player) -> Vector2:
	if source.has_method("get_effect_position_for_player"):
		return source.call("get_effect_position_for_player", effect_id, resolved_player)

	return source.call("get_effect_position", effect_id)


func get_source_effect_size(source: Node, effect_id: String) -> Vector2:
	return source.call("get_effect_size", effect_id)


func restore_persistent_effects_for_current_level() -> void:
	var current_level := get_current_level()
	if current_level == null or GameState.current_level_id.is_empty():
		return

	for effect_data in GameState.get_persistent_effects_for_level(GameState.current_level_id):
		spawn_persistent_effect(effect_data)


func spawn_persistent_effect(effect_data: Dictionary) -> Node:
	var current_level := get_current_level()
	if current_level == null:
		return null

	var effect_id := str(effect_data.get("effect_id", ""))
	var container := get_effect_container(current_level)
	var node_name := get_effect_node_name(effect_data)
	var existing_node := container.get_node_or_null(node_name)
	if existing_node != null:
		return existing_node

	match effect_id:
		EFFECT_PERSISTENT_PLATFORM, EFFECT_BRIDGE_SEGMENT:
			return spawn_solid_effect(container, node_name, effect_data)
		EFFECT_GLIDE_FIELD, EFFECT_BURDEN_FIELD:
			return spawn_field_effect(container, node_name, effect_data)
		_:
			return null


func spawn_solid_effect(container: Node2D, node_name: String, effect_data: Dictionary) -> Node:
	var block := GROUND_BLOCK_SCENE.instantiate() as Node2D
	if block == null:
		return null

	block.name = node_name
	block.position = GameState.save_dict_to_vector(effect_data.get("position", {}))
	block.set("block_size", GameState.save_dict_to_vector(effect_data.get("size", {})))
	container.add_child(block)
	return block


func spawn_field_effect(container: Node2D, node_name: String, effect_data: Dictionary) -> Node:
	var field := Area2D.new()
	field.name = node_name
	field.set_script(PERSISTENT_FIELD_SCRIPT)
	field.set("field_type", str(effect_data.get("effect_id", EFFECT_GLIDE_FIELD)))
	field.set("field_size", GameState.save_dict_to_vector(effect_data.get("size", {})))
	field.position = GameState.save_dict_to_vector(effect_data.get("position", {}))
	container.add_child(field)
	return field


func get_effect_container(current_level: Node2D) -> Node2D:
	var container := current_level.get_node_or_null(EFFECT_CONTAINER_NAME) as Node2D
	if container != null:
		return container

	container = Node2D.new()
	container.name = EFFECT_CONTAINER_NAME
	current_level.add_child(container)
	return container


func get_current_level() -> Node2D:
	var main := get_tree().current_scene
	if main == null:
		return null

	return main.get("current_level") as Node2D


func get_effect_node_name(effect_data: Dictionary) -> String:
	var raw_name := str(effect_data.get("effect_instance_id", "q_effect"))
	return raw_name.replace(":", "_").replace("/", "_").replace("\\", "_")
