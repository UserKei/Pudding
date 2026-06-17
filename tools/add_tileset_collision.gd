extends SceneTree

const TILESET_PATH := "res://resources/tilesets/terrain_16x16.tres"
const TILE_SIZE := Vector2i(16, 16)
const SOLID_ALPHA_THRESHOLD := 0.35
const SOLID_PIXEL_RATIO := 0.45


func _init() -> void:
	var tile_set := load(TILESET_PATH) as TileSet
	if tile_set == null:
		push_error("Could not load TileSet: %s" % TILESET_PATH)
		quit(1)
		return

	if tile_set.get_physics_layers_count() == 0:
		tile_set.add_physics_layer()

	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)

	var atlas_source := tile_set.get_source(0) as TileSetAtlasSource
	if atlas_source == null:
		push_error("TileSet source 0 is not a TileSetAtlasSource.")
		quit(1)
		return

	var image := atlas_source.texture.get_image()
	var solid_tile_count := 0
	var empty_tile_count := 0

	for tile_index in range(atlas_source.get_tiles_count()):
		var atlas_coords := atlas_source.get_tile_id(tile_index)
		var tile_data := atlas_source.get_tile_data(atlas_coords, 0)
		if tile_data == null:
			continue

		if is_solid_tile(image, atlas_coords):
			set_tile_collision(tile_data)
			solid_tile_count += 1
		else:
			tile_data.set_collision_polygons_count(0, 0)
			empty_tile_count += 1

	var save_result := ResourceSaver.save(tile_set, TILESET_PATH)
	if save_result != OK:
		push_error("Could not save TileSet. Error: %s" % save_result)
		quit(1)
		return

	print("TileSet collision updated. Solid tiles: %d, empty tiles: %d" % [solid_tile_count, empty_tile_count])
	quit()


func is_solid_tile(image: Image, atlas_coords: Vector2i) -> bool:
	var start := atlas_coords * TILE_SIZE
	var solid_pixels := 0
	var total_pixels := TILE_SIZE.x * TILE_SIZE.y

	for y in range(TILE_SIZE.y):
		for x in range(TILE_SIZE.x):
			var pixel := image.get_pixel(start.x + x, start.y + y)
			if pixel.a >= SOLID_ALPHA_THRESHOLD:
				solid_pixels += 1

	return float(solid_pixels) / float(total_pixels) >= SOLID_PIXEL_RATIO


func set_tile_collision(tile_data: TileData) -> void:
	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-8.0, -8.0),
		Vector2(8.0, -8.0),
		Vector2(8.0, 8.0),
		Vector2(-8.0, 8.0),
	]))
	tile_data.set_collision_polygon_one_way(0, 0, false)
