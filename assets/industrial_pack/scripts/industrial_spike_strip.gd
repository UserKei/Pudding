@tool
extends Area2D
class_name IndustrialSpikeStrip

const ATLAS_TEXTURE := preload("res://assets/industrial_pack/art/industrial.png")
const SPIKE_REGION := Rect2(192.0, 32.0, 16.0, 16.0)
const TILE_SIZE := 16.0

@export var active := true
@export var spike_size := Vector2(96.0, 18.0):
	set(value):
		spike_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh_spikes()


func _ready() -> void:
	_refresh_spikes()
	if Engine.is_editor_hint():
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if active and body.has_method("die"):
		body.die()


func _refresh_spikes() -> void:
	if not is_inside_tree():
		return

	_refresh_visuals()
	_refresh_collision_shape()


func _refresh_visuals() -> void:
	var spike_visual := get_node_or_null("SpikeVisual") as Node2D
	if spike_visual == null:
		return

	for child in spike_visual.get_children():
		spike_visual.remove_child(child)
		child.free()

	var spike_count: int = max(1, ceili(spike_size.x / TILE_SIZE))
	var left := -spike_size.x * 0.5
	var spacing := spike_size.x / float(spike_count)

	for index in range(spike_count):
		var sprite := Sprite2D.new()
		sprite.name = "Spike%02d" % [index + 1]
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = ATLAS_TEXTURE
		sprite.region_enabled = true
		sprite.region_rect = SPIKE_REGION
		sprite.position = Vector2(left + spacing * (float(index) + 0.5), 0.0)
		spike_visual.add_child(sprite)


func _refresh_collision_shape() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null or not rectangle_shape.resource_local_to_scene:
		rectangle_shape = RectangleShape2D.new()
		rectangle_shape.resource_local_to_scene = true
		collision_shape.shape = rectangle_shape

	rectangle_shape.size = spike_size
	collision_shape.position = Vector2(0.0, maxf(spike_size.y * 0.08, 1.0))
