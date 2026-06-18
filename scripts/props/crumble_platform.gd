@tool
extends StaticBody2D
class_name CrumblePlatform

@export var platform_size := Vector2(96.0, 16.0):
	set(value):
		platform_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh_platform()

@export var crumble_delay := 0.45
@export var respawn_delay := 2.0
@export var active := true

@export var visual_color := Color(0.55, 0.58, 0.62, 1.0):
	set(value):
		visual_color = value
		_refresh_platform()

@export var warning_color := Color(1.0, 0.52, 0.18, 1.0):
	set(value):
		warning_color = value
		_refresh_platform()

var is_crumbling := false
var is_broken := false
var crumble_remaining := 0.0
var respawn_remaining := 0.0


func _ready() -> void:
	_refresh_platform()
	if Engine.is_editor_hint():
		return

	var trigger_area := get_node_or_null("TriggerArea") as Area2D
	if trigger_area != null and not trigger_area.body_entered.is_connected(_on_trigger_body_entered):
		trigger_area.body_entered.connect(_on_trigger_body_entered)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if is_crumbling:
		crumble_remaining = maxf(crumble_remaining - delta, 0.0)
		_update_warning_visual()
		if crumble_remaining == 0.0:
			_break_platform()
		return

	if is_broken:
		respawn_remaining = maxf(respawn_remaining - delta, 0.0)
		if respawn_remaining == 0.0:
			_restore_platform()


func _on_trigger_body_entered(body: Node2D) -> void:
	if not active:
		return
	if is_crumbling or is_broken:
		return
	if not body.has_method("die"):
		return

	is_crumbling = true
	crumble_remaining = maxf(crumble_delay, 0.0)
	_update_warning_visual()


func _break_platform() -> void:
	is_crumbling = false
	is_broken = true
	respawn_remaining = maxf(respawn_delay, 0.0)
	_set_collision_enabled(false)

	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		visual.visible = false

	var crack_visual := get_node_or_null("CrackVisual") as Line2D
	if crack_visual != null:
		crack_visual.visible = false


func _restore_platform() -> void:
	is_broken = false
	respawn_remaining = 0.0
	_set_collision_enabled(true)

	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		visual.visible = true
		visual.color = visual_color

	var crack_visual := get_node_or_null("CrackVisual") as Line2D
	if crack_visual != null:
		crack_visual.visible = true


func _set_collision_enabled(enabled: bool) -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not enabled)

	var trigger_area := get_node_or_null("TriggerArea") as Area2D
	if trigger_area != null:
		trigger_area.set_deferred("monitoring", enabled)
		trigger_area.set_deferred("monitorable", enabled)

	var trigger_shape := get_node_or_null("TriggerArea/CollisionShape2D") as CollisionShape2D
	if trigger_shape != null:
		trigger_shape.set_deferred("disabled", not enabled)


func _update_warning_visual() -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual == null:
		return

	var blink := floori(float(Time.get_ticks_msec()) / 90.0) % 2 == 0
	visual.color = warning_color if blink else visual_color


func _refresh_platform() -> void:
	if not is_inside_tree():
		return

	var half_size := platform_size * 0.5

	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		visual.polygon = PackedVector2Array([
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y),
		])
		visual.color = warning_color if is_crumbling else visual_color

	var crack_visual := get_node_or_null("CrackVisual") as Line2D
	if crack_visual != null:
		crack_visual.points = PackedVector2Array([
			Vector2(-half_size.x * 0.75, -1.0),
			Vector2(-half_size.x * 0.45, half_size.y * 0.35),
			Vector2(-half_size.x * 0.1, -half_size.y * 0.2),
			Vector2(half_size.x * 0.18, half_size.y * 0.4),
			Vector2(half_size.x * 0.55, -half_size.y * 0.15),
		])

	_refresh_rectangle_shape("CollisionShape2D", platform_size)

	var trigger_shape := get_node_or_null("TriggerArea/CollisionShape2D") as CollisionShape2D
	if trigger_shape != null:
		var trigger_height := 10.0
		trigger_shape.position = Vector2(0.0, -half_size.y - trigger_height * 0.5 + 2.0)
		_refresh_rectangle_shape("TriggerArea/CollisionShape2D", Vector2(platform_size.x, trigger_height))


func _refresh_rectangle_shape(shape_path: NodePath, size: Vector2) -> void:
	var collision_shape := get_node_or_null(shape_path) as CollisionShape2D
	if collision_shape == null:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null or not rectangle_shape.resource_local_to_scene:
		rectangle_shape = RectangleShape2D.new()
		rectangle_shape.resource_local_to_scene = true
		collision_shape.shape = rectangle_shape

	rectangle_shape.size = size
