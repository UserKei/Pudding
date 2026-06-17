extends Area2D
class_name RoomTransition

@export var target_room_id := ""
@export var target_spawn_name := ""
@export var active := true
@export var one_shot := false

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not active or triggered or not (body is Player):
		return

	var main := get_tree().current_scene
	if main == null or not main.has_method("change_room"):
		push_warning("RoomTransition could not find change_room() on the current scene.")
		return
	if target_room_id.is_empty():
		push_warning("RoomTransition has no target_room_id assigned.")
		return

	if one_shot:
		triggered = true
		monitoring = false

	main.change_room(target_room_id, target_spawn_name)
