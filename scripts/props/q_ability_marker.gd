@tool
extends Area2D
class_name QAbilityMarker

enum SelectionMode {
	FIXED,
	WEIGHTED_RANDOM,
}

const EFFECT_PERSISTENT_PLATFORM := "persistent_platform"
const EFFECT_BRIDGE_SEGMENT := "bridge_segment"
const EFFECT_ONE_SHOT_TELEPORT := "one_shot_teleport"
const EFFECT_GLIDE_FIELD := "glide_field"
const EFFECT_BURDEN_FIELD := "burden_field"
const EFFECT_IDS := [
	EFFECT_PERSISTENT_PLATFORM,
	EFFECT_BRIDGE_SEGMENT,
	EFFECT_ONE_SHOT_TELEPORT,
	EFFECT_GLIDE_FIELD,
	EFFECT_BURDEN_FIELD,
]

@export var marker_id := ""
@export var active := true
@export var selection_mode := SelectionMode.FIXED
@export_enum(
	"persistent_platform",
	"bridge_segment",
	"one_shot_teleport",
	"glide_field",
	"burden_field"
) var fixed_effect := EFFECT_PERSISTENT_PLATFORM:
	set(value):
		fixed_effect = value
		queue_redraw()

@export var weighted_effects: Array[String] = [EFFECT_PERSISTENT_PLATFORM]
@export var effect_weights: Array[float] = [1.0]
@export_range(8.0, 256.0, 1.0) var trigger_radius := 48.0:
	set(value):
		trigger_radius = maxf(value, 1.0)
		_refresh_collision_shape()
		queue_redraw()

@export var effect_offset := Vector2(96.0, 0.0):
	set(value):
		effect_offset = value
		queue_redraw()

@export var teleport_target_offset := Vector2(160.0, 0.0):
	set(value):
		teleport_target_offset = value
		queue_redraw()

@export var platform_size := Vector2(96.0, 32.0)
@export var bridge_size := Vector2(240.0, 32.0)
@export var field_size := Vector2(128.0, 96.0)
@export var editor_color := Color(0.9, 0.82, 0.2, 0.38):
	set(value):
		editor_color = value
		queue_redraw()


func _ready() -> void:
	add_to_group("q_ability_marker")
	_refresh_collision_shape()


func get_resolved_marker_id() -> String:
	if not marker_id.is_empty():
		return marker_id

	return "%s:%s" % [GameState.current_level_id, str(get_path())]


func is_player_in_range(player: Node2D) -> bool:
	if not active or player == null:
		return false

	return global_position.distance_to(player.global_position) <= trigger_radius


func select_effect_id(rng: RandomNumberGenerator) -> String:
	if selection_mode == SelectionMode.FIXED:
		return fixed_effect

	var weighted_count: int = mini(weighted_effects.size(), effect_weights.size())
	var total_weight := 0.0
	for index in range(weighted_count):
		var effect_id := weighted_effects[index]
		var weight := maxf(effect_weights[index], 0.0)
		if effect_id in EFFECT_IDS and weight > 0.0:
			total_weight += weight

	if total_weight <= 0.0:
		return fixed_effect

	var roll := rng.randf_range(0.0, total_weight)
	for index in range(weighted_count):
		var effect_id := weighted_effects[index]
		var weight := maxf(effect_weights[index], 0.0)
		if not (effect_id in EFFECT_IDS) or weight <= 0.0:
			continue

		roll -= weight
		if roll <= 0.0:
			return effect_id

	return fixed_effect


func get_effect_position(effect_id: String) -> Vector2:
	if effect_id == EFFECT_ONE_SHOT_TELEPORT:
		return global_position + teleport_target_offset

	return global_position + effect_offset


func get_effect_size(effect_id: String) -> Vector2:
	match effect_id:
		EFFECT_BRIDGE_SEGMENT:
			return bridge_size
		EFFECT_GLIDE_FIELD, EFFECT_BURDEN_FIELD:
			return field_size
		_:
			return platform_size


func _refresh_collision_shape() -> void:
	if not is_inside_tree():
		return

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return

	var circle_shape := collision_shape.shape as CircleShape2D
	if circle_shape == null or not circle_shape.resource_local_to_scene:
		circle_shape = CircleShape2D.new()
		circle_shape.resource_local_to_scene = true
		collision_shape.shape = circle_shape

	circle_shape.radius = trigger_radius


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	draw_circle(Vector2.ZERO, trigger_radius, Color(editor_color.r, editor_color.g, editor_color.b, 0.12))
	draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 48, Color(editor_color.r, editor_color.g, editor_color.b, 0.9), 2.0)

	var effect_id := fixed_effect
	var preview_offset := teleport_target_offset if effect_id == EFFECT_ONE_SHOT_TELEPORT else effect_offset
	draw_line(Vector2.ZERO, preview_offset, Color(editor_color.r, editor_color.g, editor_color.b, 0.9), 2.0)
	draw_circle(preview_offset, 4.0, Color(editor_color.r, editor_color.g, editor_color.b, 0.9))

	if effect_id != EFFECT_ONE_SHOT_TELEPORT:
		var preview_size := get_effect_size(effect_id)
		draw_rect(Rect2(preview_offset - preview_size * 0.5, preview_size), Color(editor_color.r, editor_color.g, editor_color.b, 0.16), true)
		draw_rect(Rect2(preview_offset - preview_size * 0.5, preview_size), Color(editor_color.r, editor_color.g, editor_color.b, 0.9), false, 2.0)
