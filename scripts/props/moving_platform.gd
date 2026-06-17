extends AnimatableBody2D
class_name MovingPlatform

@export var travel_offset := Vector2(160.0, 0.0)
@export var speed := 70.0
@export var pause_time := 0.2
@export var starts_active := true

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var moving_to_end := true
var pause_remaining := 0.0


func _ready() -> void:
	start_position = global_position
	end_position = start_position + travel_offset
	set_physics_process(starts_active)


func _physics_process(delta: float) -> void:
	if pause_remaining > 0.0:
		pause_remaining = maxf(pause_remaining - delta, 0.0)
		return

	var target := end_position if moving_to_end else start_position
	global_position = global_position.move_toward(target, speed * delta)

	if global_position.is_equal_approx(target):
		moving_to_end = not moving_to_end
		pause_remaining = pause_time
