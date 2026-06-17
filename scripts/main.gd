extends Node2D

@export var player_path: NodePath = ^"Player"
@export var level_container_path: NodePath = ^"LevelContainer"
@export var initial_level_scene: PackedScene
@export var default_spawn_name := "PlayerSpawn"

@onready var player: Player = get_node_or_null(player_path) as Player
@onready var level_container: Node2D = get_node_or_null(level_container_path) as Node2D
@onready var player_camera: Camera2D = get_node_or_null(^"Player/Camera2D") as Camera2D

var current_level: Node2D
var current_level_id := ""
var current_room: Node2D
var current_room_id := ""
var current_spawn_name := ""


func _ready() -> void:
	if player != null:
		player.died.connect(respawn_player)

	if initial_level_scene == null:
		push_error("Main has no initial_level_scene assigned.")
		return

	change_level(initial_level_scene, default_spawn_name)


func change_level(level_scene: PackedScene, spawn_name := "") -> void:
	if level_container == null:
		push_error("Main could not find LevelContainer at path: %s" % level_container_path)
		return

	if current_level != null:
		current_level.queue_free()

	current_level = level_scene.instantiate() as Node2D
	if current_level == null:
		push_error("The requested level scene root must be a Node2D.")
		return

	level_container.add_child(current_level)
	var level := current_level as Level
	current_room = level.get_default_room() if level != null else null
	current_room_id = get_room_id(current_room)
	var resolved_spawn_name := spawn_name
	if resolved_spawn_name.is_empty() and current_room != null:
		resolved_spawn_name = get_room_default_spawn_name(current_room)
	if resolved_spawn_name.is_empty():
		resolved_spawn_name = level.default_spawn_name if level != null else default_spawn_name

	current_level_id = level.get_effective_level_id() if level != null else current_level.name.to_snake_case()
	current_spawn_name = resolved_spawn_name
	var display_name: String = level.get_effective_display_name() if level != null else str(current_level.name)
	GameState.enter_level(
		current_level_id,
		display_name,
		current_spawn_name
	)
	if not current_room_id.is_empty():
		GameState.enter_room(current_room_id, current_spawn_name)
	apply_camera_limits()
	move_player_to_spawn(current_spawn_name)


func change_level_by_id(level_id: String, spawn_name := "") -> void:
	var level_scene := LevelRegistry.load_level(level_id)
	if level_scene == null:
		push_error("Could not load level id: %s" % level_id)
		return

	change_level(level_scene, spawn_name)


func change_level_by_path(level_path: String, spawn_name := "") -> void:
	var level_scene := load(level_path) as PackedScene
	if level_scene == null:
		push_error("Could not load level scene: %s" % level_path)
		return

	change_level(level_scene, spawn_name)


func change_room(room_id: String, spawn_name := "") -> void:
	var level := current_level as Level
	if level == null:
		push_warning("Room transitions require the current level to use the Level script.")
		return

	var room := level.get_room(room_id)
	if room == null:
		push_warning("Room '%s' was not found in the current level." % room_id)
		return

	var resolved_spawn_name := spawn_name
	if resolved_spawn_name.is_empty():
		resolved_spawn_name = get_room_default_spawn_name(room)
	if resolved_spawn_name.is_empty():
		push_warning("Room '%s' has no target spawn." % room_id)
		return

	if get_spawn_point(resolved_spawn_name) == null:
		push_warning("Room target spawn '%s' was not found." % resolved_spawn_name)
		return

	current_room = room
	current_room_id = get_room_id(room)
	current_spawn_name = resolved_spawn_name
	GameState.enter_room(current_room_id, current_spawn_name)
	apply_camera_limits()
	move_player_to_spawn(current_spawn_name)
	snap_camera_to_player()


func move_player_to_spawn(spawn_name: String) -> void:
	if player == null:
		push_error("Main could not find Player at path: %s" % player_path)
		return

	var spawn_point := get_spawn_point(spawn_name)
	if spawn_point == null:
		push_warning("Spawn point '%s' was not found in the current level." % spawn_name)
		return

	player.global_position = spawn_point.global_position
	player.reset_motion()


func respawn_player() -> void:
	GameState.register_death()
	play_sfx("death")
	var respawn_name := GameState.get_respawn_name(current_spawn_name if not current_spawn_name.is_empty() else default_spawn_name)
	move_player_to_spawn(respawn_name)


func set_checkpoint(spawn_name: String) -> void:
	if get_spawn_point(spawn_name) == null:
		push_warning("Checkpoint spawn '%s' was not found in the current level." % spawn_name)
		return

	current_spawn_name = spawn_name
	GameState.set_checkpoint(spawn_name)


func restart_current_level() -> void:
	if current_level_id.is_empty():
		return

	change_level_by_id(current_level_id, default_spawn_name)


func get_spawn_point(spawn_name: String) -> Node2D:
	if current_level == null:
		push_error("Main has no current level loaded.")
		return null

	var level := current_level as Level
	if level != null:
		return level.get_spawn_point(spawn_name)

	var spawn_points := current_level.get_node_or_null("SpawnPoints")
	if spawn_points != null:
		return spawn_points.get_node_or_null(spawn_name) as Node2D

	return current_level.find_child(spawn_name, true, false) as Node2D


func apply_camera_limits() -> void:
	if player_camera == null:
		return

	if current_room != null:
		var room_limits: Rect2i = current_room.call("get_camera_limits")
		player_camera.limit_left = room_limits.position.x
		player_camera.limit_top = room_limits.position.y
		player_camera.limit_right = room_limits.position.x + room_limits.size.x
		player_camera.limit_bottom = room_limits.position.y + room_limits.size.y
		return

	var level := current_level as Level
	if level == null:
		return

	player_camera.limit_left = level.camera_limit_left
	player_camera.limit_top = level.camera_limit_top
	player_camera.limit_right = level.camera_limit_right
	player_camera.limit_bottom = level.camera_limit_bottom


func snap_camera_to_player() -> void:
	if player_camera != null:
		player_camera.reset_smoothing()


func get_room_id(room: Node2D) -> String:
	if room != null and room.has_method("get_effective_room_id"):
		return str(room.call("get_effective_room_id"))

	return ""


func get_room_default_spawn_name(room: Node2D) -> String:
	if room == null:
		return ""

	var spawn_name: Variant = room.get("default_spawn_name")
	return str(spawn_name) if spawn_name != null else ""


func play_sfx(sfx_name: String) -> void:
	var sfx_player := get_node_or_null("/root/SfxPlayer")
	if sfx_player != null and sfx_player.has_method("play_sfx"):
		sfx_player.play_sfx(sfx_name)
