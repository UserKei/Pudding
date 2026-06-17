extends CharacterBody2D
class_name Player

signal died

@export var speed := 180.0
@export var acceleration := 1200.0
@export var friction := 1400.0
@export var jump_velocity := -360.0
@export var gravity := 980.0
@export var max_fall_speed := 900.0
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12
@export_range(0.1, 1.0, 0.05) var jump_cut_multiplier := 0.45
@export var jump_action := "ui_accept"
@export var down_action := "ui_down"
@export var interact_action := "interact"
@export_range(1, 32, 1) var one_way_platform_collision_layer := 2
@export var one_way_drop_duration := 0.18

const PLAYER_FRAME_SIZE := Vector2(32.0, 32.0)
const PLAYER_ANIMATION_TEXTURES := {
	"idle": preload("res://assets/game/player/ninja_frog/idle.png"),
	"run": preload("res://assets/game/player/ninja_frog/run.png"),
	"jump": preload("res://assets/game/player/ninja_frog/jump.png"),
	"fall": preload("res://assets/game/player/ninja_frog/fall.png"),
}
const PLAYER_ANIMATION_FRAMES := {
	"idle": 11,
	"run": 12,
	"jump": 1,
	"fall": 1,
}
const PLAYER_ANIMATION_FPS := {
	"idle": 10.0,
	"run": 14.0,
	"jump": 1.0,
	"fall": 1.0,
}

@onready var body_visual: Sprite2D = $BodyVisual
@onready var interaction_area: Area2D = $InteractionArea

var nearby_interactables: Array[Node] = []
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var one_way_drop_timer := 0.0
var body_animation_name := ""
var body_animation_frame := 0
var body_animation_elapsed := 0.0


func _ready() -> void:
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	body_visual.region_enabled = true
	set_body_animation("idle")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interact_action):
		interact_with_nearest()


func _physics_process(delta: float) -> void:
	update_one_way_drop_timer(delta)
	update_jump_buffer(delta)

	var input_axis := Input.get_axis("ui_left", "ui_right")

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if input_axis != 0.0:
		velocity.x = move_toward(velocity.x, input_axis * speed, acceleration * delta)
		body_visual.flip_h = input_axis < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if Input.is_action_just_released(jump_action):
		cut_jump_short()

	try_consume_jump_buffer()

	move_and_slide()
	update_body_animation(input_axis, delta)


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


func die() -> void:
	died.emit()


func reset_motion() -> void:
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	one_way_drop_timer = 0.0
	set_collision_mask_value(one_way_platform_collision_layer, true)


func update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed(jump_action):
		jump_buffer_timer = jump_buffer_time
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)


func try_consume_jump_buffer() -> void:
	if jump_buffer_timer <= 0.0:
		return

	if should_drop_through_one_way_platform():
		jump_buffer_timer = 0.0
		start_one_way_drop()
		return

	if coyote_timer <= 0.0 or one_way_drop_timer > 0.0:
		return

	velocity.y = jump_velocity
	if not Input.is_action_pressed(jump_action):
		cut_jump_short()

	play_sfx("jump")
	coyote_timer = 0.0
	jump_buffer_timer = 0.0


func cut_jump_short() -> void:
	if velocity.y >= 0.0:
		return

	velocity.y *= jump_cut_multiplier


func update_one_way_drop_timer(delta: float) -> void:
	if one_way_drop_timer <= 0.0:
		return

	one_way_drop_timer = maxf(one_way_drop_timer - delta, 0.0)
	if one_way_drop_timer == 0.0:
		set_collision_mask_value(one_way_platform_collision_layer, true)


func should_drop_through_one_way_platform() -> bool:
	return Input.is_action_pressed(down_action) and is_on_floor() and is_on_one_way_platform()


func is_on_one_way_platform() -> bool:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if collision.get_normal().dot(Vector2.UP) < 0.7:
			continue

		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group("one_way_platform"):
			return true

		var collision_object := collider as CollisionObject2D
		if collision_object != null and collision_object.get_collision_layer_value(one_way_platform_collision_layer):
			return true

	return false


func start_one_way_drop() -> void:
	coyote_timer = 0.0
	one_way_drop_timer = one_way_drop_duration
	set_collision_mask_value(one_way_platform_collision_layer, false)
	velocity.y = maxf(velocity.y, 90.0)


func update_body_animation(input_axis: float, delta: float) -> void:
	var next_animation := "idle"
	if not is_on_floor():
		next_animation = "jump" if velocity.y < 0.0 else "fall"
	elif input_axis != 0.0:
		next_animation = "run"

	set_body_animation(next_animation)
	advance_body_animation(delta)


func set_body_animation(animation_name: String) -> void:
	if body_animation_name == animation_name:
		return

	body_animation_name = animation_name
	body_animation_frame = 0
	body_animation_elapsed = 0.0
	body_visual.texture = PLAYER_ANIMATION_TEXTURES[body_animation_name]
	update_body_animation_frame()


func advance_body_animation(delta: float) -> void:
	var frame_count: int = PLAYER_ANIMATION_FRAMES[body_animation_name]
	if frame_count <= 1:
		return

	body_animation_elapsed += delta
	var frame_duration: float = 1.0 / PLAYER_ANIMATION_FPS[body_animation_name]
	while body_animation_elapsed >= frame_duration:
		body_animation_elapsed -= frame_duration
		body_animation_frame = (body_animation_frame + 1) % frame_count
		update_body_animation_frame()


func update_body_animation_frame() -> void:
	body_visual.region_rect = Rect2(
		body_animation_frame * PLAYER_FRAME_SIZE.x,
		0.0,
		PLAYER_FRAME_SIZE.x,
		PLAYER_FRAME_SIZE.y
	)


func play_sfx(sfx_name: String) -> void:
	var sfx_player: Node = get_node_or_null("/root/SfxPlayer")
	if sfx_player != null and sfx_player.has_method("play_sfx"):
		sfx_player.play_sfx(sfx_name)
