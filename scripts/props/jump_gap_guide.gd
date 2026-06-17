@tool
extends Node2D
class_name JumpGapGuide

@export_range(1, 24, 1) var horizontal_tiles := 6:
	set(value):
		horizontal_tiles = value
		queue_redraw()

@export_range(-12, 12, 1) var vertical_tiles := 0:
	set(value):
		vertical_tiles = value
		queue_redraw()

@export var tile_size := 16.0:
	set(value):
		tile_size = maxf(value, 1.0)
		queue_redraw()

@export var guide_color := Color(0.95, 0.78, 0.28, 0.75):
	set(value):
		guide_color = value
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var end_position := Vector2(horizontal_tiles * tile_size, vertical_tiles * tile_size)
	draw_line(Vector2.ZERO, end_position, guide_color, 2.0)
	draw_circle(Vector2.ZERO, 3.0, guide_color)
	draw_circle(end_position, 4.0, guide_color)
