@tool
extends StaticBody2D
class_name SolidBlock

const TILE_SIZE := 16.0
const TERRAIN_TEXTURE := preload("res://assets/game/tilesets/terrain_16x16.png")
const STYLE_GRASS := 0
const STYLE_STONE := 1
const STYLE_BRICK := 2
const STYLE_WOOD := 3
const TILE_REGIONS := {
	STYLE_GRASS: {
		"top": Rect2(96.0, 0.0, 16.0, 16.0),
		"fill": Rect2(96.0, 16.0, 16.0, 16.0),
	},
	STYLE_STONE: {
		"top": Rect2(16.0, 0.0, 16.0, 16.0),
		"fill": Rect2(16.0, 16.0, 16.0, 16.0),
	},
	STYLE_BRICK: {
		"top": Rect2(272.0, 16.0, 16.0, 16.0),
		"fill": Rect2(272.0, 32.0, 16.0, 16.0),
	},
	STYLE_WOOD: {
		"top": Rect2(224.0, 112.0, 16.0, 16.0),
		"fill": Rect2(240.0, 128.0, 16.0, 16.0),
	},
}

@export var block_size := Vector2(96.0, 32.0):
	set(value):
		block_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh_block()

@export_enum("Grass", "Stone", "Brick", "Wood") var block_style := STYLE_GRASS:
	set(value):
		block_style = value
		_refresh_block()

@export var visual_color := Color(0.36, 0.42, 0.48, 1.0):
	set(value):
		visual_color = value
		_refresh_block()


func _ready() -> void:
	_refresh_block()


func _refresh_block() -> void:
	if not is_inside_tree():
		return

	_refresh_tile_visuals()
	_refresh_fallback_visual()
	_refresh_collision_shape()


func _refresh_tile_visuals() -> void:
	var tile_visual := get_node_or_null("TileVisual") as Node2D
	if tile_visual == null:
		return

	for child in tile_visual.get_children():
		tile_visual.remove_child(child)
		child.free()

	var tile_count_x: int = max(1, ceili(block_size.x / TILE_SIZE))
	var tile_count_y: int = max(1, ceili(block_size.y / TILE_SIZE))
	var top_left := block_size * -0.5

	for tile_y in range(tile_count_y):
		for tile_x in range(tile_count_x):
			var sprite := Sprite2D.new()
			sprite.name = "Tile_%02d_%02d" % [tile_x, tile_y]
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.texture = TERRAIN_TEXTURE
			sprite.region_enabled = true
			sprite.region_rect = _get_tile_region(tile_y)
			sprite.position = top_left + Vector2(
				tile_x * TILE_SIZE + TILE_SIZE * 0.5,
				tile_y * TILE_SIZE + TILE_SIZE * 0.5
			)
			tile_visual.add_child(sprite)


func _get_tile_region(tile_y: int) -> Rect2:
	var regions: Dictionary = TILE_REGIONS.get(block_style, TILE_REGIONS[STYLE_GRASS])
	if tile_y == 0:
		return regions["top"]

	return regions["fill"]


func _refresh_fallback_visual() -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		var half_size := block_size * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y),
		])
		visual.color = visual_color


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
