extends Area2D
class_name Door

@export_file("*.tscn") var target_level_path := ""
@export var target_level_id := ""
@export var target_spawn_name := "PlayerSpawn"

@onready var prompt_visual: Polygon2D = $PromptVisual


func _ready() -> void:
	prompt_visual.visible = false


func interact(_player: Player) -> void:
	var main: Node = get_tree().current_scene
	if main == null:
		push_error("Door could not find the current scene.")
		return

	play_sfx("door")
	if not target_level_id.is_empty() and main.has_method("change_level_by_id"):
		main.change_level_by_id(target_level_id, target_spawn_name)
		return

	if not target_level_path.is_empty() and main.has_method("change_level_by_path"):
		main.change_level_by_path(target_level_path, target_spawn_name)
		return

	push_warning("Door has no valid target_level_id or target_level_path assigned.")


func set_interaction_hint_visible(should_show: bool) -> void:
	prompt_visual.visible = should_show


func play_sfx(sfx_name: String) -> void:
	var sfx_player: Node = get_node_or_null("/root/SfxPlayer")
	if sfx_player != null and sfx_player.has_method("play_sfx"):
		sfx_player.play_sfx(sfx_name)
