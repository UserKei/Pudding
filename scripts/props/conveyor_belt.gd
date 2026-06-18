@tool
extends StaticBody2D
class_name ConveyorBelt

@export var belt_size := Vector2(128.0, 16.0):
	set(value):
		belt_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh_belt()

@export var belt_speed := 60.0
@export_range(-1, 1, 2) var direction := 1:
	set(value):
		direction = -1 if value < 0 else 1
		_refresh_belt()

@export var active := true:
	set(value):
		active = value
		_refresh_belt()

@export var visual_color := Color(0.18, 0.2, 0.24, 1.0):
	set(value):
		visual_color = value
		_refresh_belt()

@export var arrow_color := Color(0.95, 0.78, 0.28, 1.0):
	set(value):
		arrow_color = value
		_refresh_belt()


func _ready() -> void:
	_refresh_belt()


func get_conveyor_velocity() -> Vector2:
	if not active:
		return Vector2.ZERO

	return Vector2(float(direction) * belt_speed, 0.0)


func _refresh_belt() -> void:
	if not is_inside_tree():
		return

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		var rectangle_shape := collision_shape.shape as RectangleShape2D
		if rectangle_shape == null or not rectangle_shape.resource_local_to_scene:
			rectangle_shape = RectangleShape2D.new()
			rectangle_shape.resource_local_to_scene = true
			collision_shape.shape = rectangle_shape
		rectangle_shape.size = belt_size

	queue_redraw()


func _draw() -> void:
	var half_size := belt_size * 0.5
	var belt_rect := Rect2(-half_size, belt_size)
	var edge_color := visual_color.lightened(0.25)
	var rendered_arrow_color := arrow_color if active else arrow_color.darkened(0.55)

	draw_rect(belt_rect, visual_color, true)
	draw_rect(belt_rect, edge_color, false, 2.0)

	var arrow_spacing := 24.0
	var arrow_count: int = max(1, floori(belt_size.x / arrow_spacing))
	var left := -half_size.x + arrow_spacing * 0.5
	for index in range(arrow_count):
		var center := Vector2(left + index * arrow_spacing, 0.0)
		_draw_arrow(center, rendered_arrow_color)


func _draw_arrow(center: Vector2, color: Color) -> void:
	var arrow_width := minf(14.0, belt_size.y * 0.9)
	var arrow_height := minf(8.0, belt_size.y * 0.55)
	var direction_sign := float(direction)

	var points := PackedVector2Array([
		center + Vector2(-direction_sign * arrow_width * 0.5, -arrow_height * 0.5),
		center + Vector2(direction_sign * arrow_width * 0.15, -arrow_height * 0.5),
		center + Vector2(direction_sign * arrow_width * 0.15, -arrow_height),
		center + Vector2(direction_sign * arrow_width * 0.5, 0.0),
		center + Vector2(direction_sign * arrow_width * 0.15, arrow_height),
		center + Vector2(direction_sign * arrow_width * 0.15, arrow_height * 0.5),
		center + Vector2(-direction_sign * arrow_width * 0.5, arrow_height * 0.5),
	])
	draw_colored_polygon(points, color)
