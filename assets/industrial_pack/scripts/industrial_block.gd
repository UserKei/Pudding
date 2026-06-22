@tool
extends StaticBody2D
class_name IndustrialBlock

const TILE_SIZE := 16.0
const ATLAS_TEXTURE := preload("res://assets/industrial_pack/art/industrial.png")

const STYLE_PLATED := 0
const STYLE_GRATED := 1
const STYLE_DARK_PANEL := 2
const STYLE_CONCRETE := 3

const TILE_REGIONS := {
	STYLE_PLATED: Rect2(0.0, 128.0, 16.0, 16.0),
	STYLE_GRATED: Rect2(16.0, 128.0, 16.0, 16.0),
	STYLE_DARK_PANEL: Rect2(64.0, 0.0, 16.0, 16.0),
	STYLE_CONCRETE: Rect2(48.0, 16.0, 16.0, 16.0),
}

@export var block_size := Vector2(128.0, 32.0):
	set(value):
		block_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh_block()

@export_enum("Plated", "Grated", "Dark Panel", "Concrete") var block_style := STYLE_PLATED:
	set(value):
		block_style = value
		_refresh_block()

@export var visual_modulate := Color.WHITE:
	set(value):
		visual_modulate = value
		_refresh_block()


func _ready() -> void:
	_refresh_block()


func _refresh_block() -> void:
	if not is_inside_tree():
		return

	_refresh_visuals()
	_refresh_collision_shape()


func _refresh_visuals() -> void:
	var tile_visual := get_node_or_null("TileVisual") as Node2D
	if tile_visual == null:
		return

	for child in tile_visual.get_children():
		tile_visual.remove_child(child)
		child.free()

	var tile_count_x: int = max(1, ceili(block_size.x / TILE_SIZE))
	var tile_count_y: int = max(1, ceili(block_size.y / TILE_SIZE))
	var top_left := block_size * -0.5
	var region: Rect2 = TILE_REGIONS.get(block_style, TILE_REGIONS[STYLE_PLATED])

	for tile_y in range(tile_count_y):
		for tile_x in range(tile_count_x):
			var sprite := Sprite2D.new()
			sprite.name = "Tile_%02d_%02d" % [tile_x, tile_y]
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.texture = ATLAS_TEXTURE
			sprite.region_enabled = true
			sprite.region_rect = region
			sprite.modulate = visual_modulate
			sprite.position = top_left + Vector2(
				tile_x * TILE_SIZE + TILE_SIZE * 0.5,
				tile_y * TILE_SIZE + TILE_SIZE * 0.5
			)
			tile_visual.add_child(sprite)


func _refresh_collision_shape() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null or not rectangle_shape.resource_local_to_scene:
		rectangle_shape = RectangleShape2D.new()
		rectangle_shape.resource_local_to_scene = true
		collision_shape.shape = rectangle_shape

	rectangle_shape.size = block_size
