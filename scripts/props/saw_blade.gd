@tool
extends Area2D
class_name SawBlade

const TOOTH_COUNT := 16

@export var radius := 18.0:
	set(value):
		radius = maxf(value, 4.0)
		_refresh_saw()

@export var rotation_speed := 360.0
@export var travel_offset := Vector2.ZERO:
	set(value):
		travel_offset = value
		_refresh_saw()

@export var move_speed := 80.0
@export var pause_time := 0.2
@export var active := true

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var moving_to_end := true
var pause_remaining := 0.0


func _ready() -> void:
	_refresh_saw()
	if Engine.is_editor_hint():
		return

	start_position = global_position
	end_position = start_position + travel_offset
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var blade_visual := get_node_or_null("BladeVisual") as Node2D
	if blade_visual != null:
		blade_visual.rotation_degrees += rotation_speed * delta

	if not active:
		return
	if travel_offset.is_zero_approx() or move_speed <= 0.0:
		return

	if pause_remaining > 0.0:
		pause_remaining = maxf(pause_remaining - delta, 0.0)
		return

	var target := end_position if moving_to_end else start_position
	global_position = global_position.move_toward(target, move_speed * delta)
	if global_position.is_equal_approx(target):
		moving_to_end = not moving_to_end
		pause_remaining = pause_time


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if body.has_method("die"):
		body.die()


func _refresh_saw() -> void:
	if not is_inside_tree():
		return

	var teeth := get_node_or_null("BladeVisual/Teeth") as Polygon2D
	if teeth != null:
		var points := PackedVector2Array()
		for index in range(TOOTH_COUNT * 2):
			var angle := TAU * float(index) / float(TOOTH_COUNT * 2)
			var point_radius := radius if index % 2 == 0 else radius * 0.68
			points.append(Vector2(cos(angle), sin(angle)) * point_radius)
		teeth.polygon = points

	var core := get_node_or_null("BladeVisual/Core") as Polygon2D
	if core != null:
		var points := PackedVector2Array()
		for index in range(16):
			var angle := TAU * float(index) / 16.0
			points.append(Vector2(cos(angle), sin(angle)) * radius * 0.38)
		core.polygon = points

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		var circle_shape := collision_shape.shape as CircleShape2D
		if circle_shape == null or not circle_shape.resource_local_to_scene:
			circle_shape = CircleShape2D.new()
			circle_shape.resource_local_to_scene = true
			collision_shape.shape = circle_shape
		circle_shape.radius = radius * 0.88

	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if travel_offset.is_zero_approx():
		return

	draw_line(Vector2.ZERO, travel_offset, Color(1.0, 0.25, 0.25, 0.65), 2.0)
	draw_circle(travel_offset, 4.0, Color(1.0, 0.25, 0.25, 0.8))
