extends Node
class_name QGlobalPool

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

@export var pool_id := ""
@export var active := true
@export var weighted_effects: Array[String] = [
	EFFECT_PERSISTENT_PLATFORM,
	EFFECT_BRIDGE_SEGMENT,
	EFFECT_GLIDE_FIELD,
]
@export var effect_weights: Array[float] = [4.0, 2.0, 1.0]
@export var fallback_effect := EFFECT_PERSISTENT_PLATFORM
@export var effect_offset := Vector2(96.0, 0.0)
@export var teleport_target_offset := Vector2(160.0, -32.0)
@export var platform_size := Vector2(96.0, 32.0)
@export var bridge_size := Vector2(240.0, 32.0)
@export var field_size := Vector2(128.0, 96.0)


func _ready() -> void:
	add_to_group("q_global_pool")


func get_resolved_pool_id() -> String:
	if not pool_id.is_empty():
		return pool_id

	return "%s:global_pool" % GameState.current_level_id


func select_effect_id(rng: RandomNumberGenerator) -> String:
	if not active:
		return ""

	var weighted_count: int = mini(weighted_effects.size(), effect_weights.size())
	var total_weight := 0.0
	for index in range(weighted_count):
		var effect_id := weighted_effects[index]
		var weight := maxf(effect_weights[index], 0.0)
		if effect_id in EFFECT_IDS and weight > 0.0:
			total_weight += weight

	if total_weight <= 0.0:
		return fallback_effect

	var roll := rng.randf_range(0.0, total_weight)
	for index in range(weighted_count):
		var effect_id := weighted_effects[index]
		var weight := maxf(effect_weights[index], 0.0)
		if not (effect_id in EFFECT_IDS) or weight <= 0.0:
			continue

		roll -= weight
		if roll <= 0.0:
			return effect_id

	return fallback_effect


func get_effect_position_for_player(effect_id: String, player: Node2D) -> Vector2:
	if player == null:
		return Vector2.ZERO

	if effect_id == EFFECT_ONE_SHOT_TELEPORT:
		return player.global_position + teleport_target_offset

	return player.global_position + effect_offset


func get_effect_size(effect_id: String) -> Vector2:
	match effect_id:
		EFFECT_BRIDGE_SEGMENT:
			return bridge_size
		EFFECT_GLIDE_FIELD, EFFECT_BURDEN_FIELD:
			return field_size
		_:
			return platform_size
