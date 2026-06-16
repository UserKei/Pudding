extends Area2D
class_name Door

@export_file("*.tscn") var target_level_path := ""
@export var target_spawn_name := "PlayerSpawn"

@onready var prompt_visual: Polygon2D = $PromptVisual


func _ready() -> void:
	prompt_visual.visible = false


func interact(_player: Player) -> void:
	if target_level_path.is_empty():
		push_warning("Door has no target_level_path assigned.")
		return

	var main := get_tree().current_scene
	if main == null or not main.has_method("change_level_by_path"):
		push_error("Door could not find a current scene with change_level_by_path().")
		return

	main.change_level_by_path(target_level_path, target_spawn_name)


func set_interaction_hint_visible(should_show: bool) -> void:
	prompt_visual.visible = should_show
