@tool
extends Node2D
class_name Room

@export var room_id := ""
@export var display_name := ""
@export var default_spawn_name := "PlayerSpawn"
@export var room_size := Vector2i(1280, 704):
	set(value):
		room_size = Vector2i(maxi(value.x, 16), maxi(value.y, 16))
		queue_redraw()

@export var camera_limit_offset := Vector2i.ZERO:
	set(value):
		camera_limit_offset = value
		queue_redraw()

@export var camera_limit_size := Vector2i.ZERO:
	set(value):
		camera_limit_size = Vector2i(maxi(value.x, 0), maxi(value.y, 0))
		queue_redraw()

@export var editor_color := Color(0.28, 0.62, 1.0, 0.18):
	set(value):
		editor_color = value
		queue_redraw()

@export var camera_limit_color := Color(1.0, 0.86, 0.28, 0.18):
	set(value):
		camera_limit_color = value
		queue_redraw()


func get_effective_room_id() -> String:
	return room_id if not room_id.is_empty() else str(name).to_snake_case()


func get_effective_display_name() -> String:
	return display_name if not display_name.is_empty() else str(name)


func get_room_rect() -> Rect2i:
	var room_position := global_position.round()
	return Rect2i(
		int(room_position.x),
		int(room_position.y),
		room_size.x,
		room_size.y
	)


func get_camera_limits() -> Rect2i:
	var room_position := global_position.round()
	var effective_limit_size := get_effective_camera_limit_size()
	return Rect2i(
		int(room_position.x) + camera_limit_offset.x,
		int(room_position.y) + camera_limit_offset.y,
		effective_limit_size.x,
		effective_limit_size.y
	)


func get_effective_camera_limit_size() -> Vector2i:
	if camera_limit_size.x > 0 and camera_limit_size.y > 0:
		return camera_limit_size

	return Vector2i(
		maxi(room_size.x - camera_limit_offset.x, 16),
		maxi(room_size.y - camera_limit_offset.y, 16)
	)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var rect := Rect2(Vector2.ZERO, Vector2(room_size))
	draw_rect(rect, editor_color, true)
	draw_rect(rect, Color(editor_color.r, editor_color.g, editor_color.b, 0.85), false, 2.0)

	var limit_rect := Rect2(Vector2(camera_limit_offset), Vector2(get_effective_camera_limit_size()))
	if limit_rect != rect:
		draw_rect(limit_rect, camera_limit_color, true)
		draw_rect(limit_rect, Color(camera_limit_color.r, camera_limit_color.g, camera_limit_color.b, 0.9), false, 2.0)
