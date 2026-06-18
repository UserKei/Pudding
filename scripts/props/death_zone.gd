@tool
extends Area2D
class_name DeathZone

@export var active := true
@export var zone_size := Vector2(1280.0, 64.0):
	set(value):
		zone_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh_zone()

@export var editor_color := Color(0.0, 0.8, 0.9, 0.35):
	set(value):
		editor_color = value
		queue_redraw()


func _ready() -> void:
	_refresh_zone()
	if Engine.is_editor_hint():
		return
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if body.has_method("die"):
		body.die()


func _refresh_zone() -> void:
	if not is_inside_tree():
		return

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		var rectangle_shape := collision_shape.shape as RectangleShape2D
		if rectangle_shape == null or not rectangle_shape.resource_local_to_scene:
			rectangle_shape = RectangleShape2D.new()
			rectangle_shape.resource_local_to_scene = true
			collision_shape.shape = rectangle_shape
		rectangle_shape.size = zone_size

	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var half_size := zone_size * 0.5
	var rect := Rect2(-half_size, zone_size)
	draw_rect(rect, editor_color, true)
	draw_rect(rect, Color(editor_color.r, editor_color.g, editor_color.b, 0.9), false, 2.0)
