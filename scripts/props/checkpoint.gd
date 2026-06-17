extends Area2D
class_name Checkpoint

@export var spawn_name := ""
@export var active := true

var activated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not active or activated or not (body is Player):
		return

	var resolved_spawn_name: String = spawn_name if not spawn_name.is_empty() else str(name)
	var main: Node = get_tree().current_scene
	if main == null or not main.has_method("set_checkpoint"):
		return

	main.set_checkpoint(resolved_spawn_name)
	activated = true
	modulate = Color(1.2, 1.2, 1.2, 1.0)
	play_sfx("checkpoint")


func play_sfx(sfx_name: String) -> void:
	var sfx_player: Node = get_node_or_null("/root/SfxPlayer")
	if sfx_player != null and sfx_player.has_method("play_sfx"):
		sfx_player.play_sfx(sfx_name)
