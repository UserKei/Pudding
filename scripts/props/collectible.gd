extends Area2D
class_name Collectible

@export var collectible_id := ""
@export var active := true

var resolved_collectible_id := ""


func _ready() -> void:
	resolved_collectible_id = get_resolved_collectible_id()
	if GameState.is_collectible_collected(resolved_collectible_id):
		queue_free()
		return

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not active or not (body is Player):
		return

	if GameState.collect(resolved_collectible_id):
		play_sfx("collect")
		queue_free()


func get_resolved_collectible_id() -> String:
	if not collectible_id.is_empty():
		return collectible_id

	return "%s:%s" % [GameState.current_level_id, str(get_path())]


func play_sfx(sfx_name: String) -> void:
	var sfx_player: Node = get_node_or_null("/root/SfxPlayer")
	if sfx_player != null and sfx_player.has_method("play_sfx"):
		sfx_player.play_sfx(sfx_name)
