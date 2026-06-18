@tool
extends Area2D
class_name QPersistentField

const FIELD_GLIDE := "glide_field"
const FIELD_BURDEN := "burden_field"

@export_enum("glide_field", "burden_field") var field_type := FIELD_GLIDE:
	set(value):
		field_type = value
		queue_redraw()

@export var active := true
@export var field_size := Vector2(128.0, 96.0):
	set(value):
		field_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh_collision_shape()
		queue_redraw()

@export var glide_color := Color(0.35, 0.7, 1.0, 0.24):
	set(value):
		glide_color = value
		queue_redraw()

@export var burden_color := Color(0.72, 0.28, 0.72, 0.24):
	set(value):
		burden_color = value
		queue_redraw()


func _ready() -> void:
	add_to_group("q_persistent_field")
	_refresh_collision_shape()
	if Engine.is_editor_hint():
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return

	if field_type == FIELD_GLIDE and body.has_method("enter_q_glide_field"):
		body.enter_q_glide_field()
	elif field_type == FIELD_BURDEN and body.has_method("enter_q_burden_field"):
		body.enter_q_burden_field()


func _on_body_exited(body: Node2D) -> void:
	if field_type == FIELD_GLIDE and body.has_method("exit_q_glide_field"):
		body.exit_q_glide_field()
	elif field_type == FIELD_BURDEN and body.has_method("exit_q_burden_field"):
		body.exit_q_burden_field()


func _refresh_collision_shape() -> void:
	if not is_inside_tree():
		return

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null or not rectangle_shape.resource_local_to_scene:
		rectangle_shape = RectangleShape2D.new()
		rectangle_shape.resource_local_to_scene = true
		collision_shape.shape = rectangle_shape

	rectangle_shape.size = field_size


func _draw() -> void:
	var color := burden_color if field_type == FIELD_BURDEN else glide_color
	var rect := Rect2(field_size * -0.5, field_size)
	draw_rect(rect, color, true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.82), false, 2.0)
