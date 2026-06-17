extends Node2D

@export var player_path: NodePath = ^"Player"
@export var level_container_path: NodePath = ^"LevelContainer"
@export var initial_level_scene: PackedScene
@export var default_spawn_name := "PlayerSpawn"

@onready var player: Player = get_node_or_null(player_path) as Player
@onready var level_container: Node2D = get_node_or_null(level_container_path) as Node2D

var current_level: Node2D
var current_spawn_name := ""


func _ready() -> void:
	if player != null:
		player.died.connect(respawn_player)

	if initial_level_scene == null:
		push_error("Main has no initial_level_scene assigned.")
		return

	change_level(initial_level_scene, default_spawn_name)


func change_level(level_scene: PackedScene, spawn_name := default_spawn_name) -> void:
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
	current_spawn_name = spawn_name
	move_player_to_spawn(spawn_name)


func change_level_by_path(level_path: String, spawn_name := default_spawn_name) -> void:
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
	if current_spawn_name.is_empty():
		current_spawn_name = default_spawn_name

	move_player_to_spawn(current_spawn_name)


func get_spawn_point(spawn_name: String) -> Marker2D:
	if current_level == null:
		push_error("Main has no current level loaded.")
		return null

	var spawn_points := current_level.get_node_or_null("SpawnPoints")
	if spawn_points == null:
		push_warning("Current level has no SpawnPoints node.")
		return null

	return spawn_points.get_node_or_null(spawn_name) as Marker2D
