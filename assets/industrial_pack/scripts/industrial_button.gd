@tool
extends Area2D
class_name IndustrialButton

signal pressed(button: IndustrialButton)

const ATLAS_TEXTURE := preload("res://assets/industrial_pack/art/industrial.png")

const KIND_SAFE := 0
const KIND_DANGER := 1
const KIND_UNKNOWN := 2
const KIND_GOAL := 3
const KIND_FORBIDDEN := 4

const ROUND_BUTTON_REGION := Rect2(336.0, 144.0, 16.0, 16.0)
const FORBIDDEN_BUTTON_REGION := Rect2(352.0, 160.0, 16.0, 16.0)
const KIND_COLORS := [
	Color(0.35, 1.0, 0.48, 1.0),
	Color(1.0, 0.28, 0.28, 1.0),
	Color(1.0, 0.86, 0.25, 1.0),
	Color(0.35, 0.68, 1.0, 1.0),
	Color(1.0, 0.12, 0.32, 1.0),
]

@export_enum("Safe", "Danger", "Unknown", "Goal", "Forbidden") var button_kind := KIND_SAFE:
	set(value):
		button_kind = clampi(value, KIND_SAFE, KIND_FORBIDDEN)
		_refresh_button()

@export var trigger_on_body_enter := true
@export var one_shot := true
@export var starts_pressed := false:
	set(value):
		starts_pressed = value
		if is_inside_tree():
			is_pressed = starts_pressed
			_refresh_button()

var is_pressed := false


func _ready() -> void:
	is_pressed = starts_pressed
	_refresh_button()
	set_interaction_hint_visible(false)

	if Engine.is_editor_hint():
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func interact(_player: Player) -> void:
	press()


func press() -> void:
	if one_shot and is_pressed:
		return

	is_pressed = true
	_refresh_button()
	pressed.emit(self)


func reset_button() -> void:
	is_pressed = false
	_refresh_button()


func set_interaction_hint_visible(should_show: bool) -> void:
	var prompt_visual := get_node_or_null("PromptVisual") as CanvasItem
	if prompt_visual != null:
		prompt_visual.visible = should_show and not is_pressed


func _on_body_entered(_body: Node2D) -> void:
	if trigger_on_body_enter:
		press()


func _refresh_button() -> void:
	if not is_inside_tree():
		return

	var visual := get_node_or_null("Visual") as Sprite2D
	if visual != null:
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.texture = ATLAS_TEXTURE
		visual.region_enabled = true
		visual.region_rect = FORBIDDEN_BUTTON_REGION if button_kind == KIND_FORBIDDEN else ROUND_BUTTON_REGION
		visual.modulate = KIND_COLORS[button_kind]
		visual.position = Vector2(0.0, 2.0 if is_pressed else 0.0)

	var pressed_visual := get_node_or_null("PressedGlow") as CanvasItem
	if pressed_visual != null:
		pressed_visual.visible = is_pressed
