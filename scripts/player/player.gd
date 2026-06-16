extends CharacterBody2D
class_name Player

@export var speed := 180.0
@export var acceleration := 1200.0
@export var friction := 1400.0
@export var jump_velocity := -360.0
@export var gravity := 980.0
@export var max_fall_speed := 900.0
@export var interact_action := "interact"

@onready var body_visual: Polygon2D = $BodyVisual
@onready var interaction_area: Area2D = $InteractionArea

var nearby_interactables: Array[Node] = []


func _ready() -> void:
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interact_action):
		interact_with_nearest()


func _physics_process(delta: float) -> void:
	var input_axis := Input.get_axis("ui_left", "ui_right")

	if input_axis != 0.0:
		velocity.x = move_toward(velocity.x, input_axis * speed, acceleration * delta)
		body_visual.scale.x = sign(input_axis)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()


func interact_with_nearest() -> void:
	var interactable := get_nearest_interactable()
	if interactable == null:
		return

	interactable.interact(self)


func get_nearest_interactable() -> Node:
	var nearest: Node = null
	var nearest_distance := INF

	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue
		if not interactable.has_method("interact"):
			continue

		var interactable_2d := interactable as Node2D
		if interactable_2d == null:
			continue

		var distance := global_position.distance_squared_to(interactable_2d.global_position)
		if distance < nearest_distance:
			nearest = interactable
			nearest_distance = distance

	return nearest


func _on_interaction_area_entered(area: Area2D) -> void:
	if not area.has_method("interact"):
		return
	if nearby_interactables.has(area):
		return

	nearby_interactables.append(area)
	if area.has_method("set_interaction_hint_visible"):
		area.set_interaction_hint_visible(true)


func _on_interaction_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)
	if area.has_method("set_interaction_hint_visible"):
		area.set_interaction_hint_visible(false)
