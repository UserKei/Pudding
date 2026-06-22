@tool
extends Node2D
class_name IndustrialAtlasProp

const ATLAS_TEXTURE := preload("res://assets/industrial_pack/art/industrial.png")

@export var region := Rect2(0.0, 0.0, 16.0, 16.0):
	set(value):
		region = value
		_refresh_visual()

@export var visual_scale := Vector2.ONE:
	set(value):
		visual_scale = value
		_refresh_visual()

@export var visual_modulate := Color.WHITE:
	set(value):
		visual_modulate = value
		_refresh_visual()


func _ready() -> void:
	_refresh_visual()


func _refresh_visual() -> void:
	if not is_inside_tree():
		return

	var visual := get_node_or_null("Visual") as Sprite2D
	if visual == null:
		return

	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = ATLAS_TEXTURE
	visual.region_enabled = true
	visual.region_rect = region
	visual.scale = visual_scale
	visual.modulate = visual_modulate
