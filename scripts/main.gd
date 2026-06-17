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
	var resolved_spawn_name := spawn_name
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

	var level := current_level as Level
	if level == null:
		return

	player_camera.limit_left = level.camera_limit_left
	player_camera.limit_top = level.camera_limit_top
	player_camera.limit_right = level.camera_limit_right
	player_camera.limit_bottom = level.camera_limit_bottom


func play_sfx(sfx_name: String) -> void:
	var sfx_player := get_node_or_null("/root/SfxPlayer")
	if sfx_player != null and sfx_player.has_method("play_sfx"):
		sfx_player.play_sfx(sfx_name)
