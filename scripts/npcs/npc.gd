extends Area2D
class_name DialogueNPC

const IDLE_FRAME_SIZE := Vector2(32.0, 32.0)
const IDLE_FRAME_COUNT := 11

@export var speaker_name := "NPC"
@export_multiline var dialogue_text := "Hello.\nPress E to continue."
@export var idle_animation_fps := 8.0
@export var idle_bob_distance := 2.0
@export var idle_bob_speed := 2.0
@export var face_left := false

@onready var body_visual: Sprite2D = $BodyVisual
@onready var prompt_visual: Polygon2D = $PromptVisual

var idle_frame := 0
var idle_elapsed := 0.0
var bob_elapsed := 0.0
var base_visual_position := Vector2.ZERO


func _ready() -> void:
	prompt_visual.visible = false
	body_visual.region_enabled = true
	body_visual.flip_h = face_left
	base_visual_position = body_visual.position
	update_idle_frame()


func _process(delta: float) -> void:
	advance_idle_animation(delta)
	apply_idle_bob(delta)


func interact(_player: Player) -> void:
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box == null or not dialogue_box.has_method("show_dialogue"):
		push_warning("NPC could not find a DialogueBox in the current scene.")
		return

	dialogue_box.show_dialogue(speaker_name, get_dialogue_lines())


func get_dialogue_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for raw_line in dialogue_text.split("\n"):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			lines.append(line)

	if lines.is_empty():
		lines.append("...")

	return lines


func set_interaction_hint_visible(should_show: bool) -> void:
	prompt_visual.visible = should_show


func advance_idle_animation(delta: float) -> void:
	if idle_animation_fps <= 0.0:
		return

	idle_elapsed += delta
	var frame_duration := 1.0 / idle_animation_fps
	while idle_elapsed >= frame_duration:
		idle_elapsed -= frame_duration
		idle_frame = (idle_frame + 1) % IDLE_FRAME_COUNT
		update_idle_frame()


func update_idle_frame() -> void:
	body_visual.region_rect = Rect2(
		idle_frame * IDLE_FRAME_SIZE.x,
		0.0,
		IDLE_FRAME_SIZE.x,
		IDLE_FRAME_SIZE.y
	)


func apply_idle_bob(delta: float) -> void:
	bob_elapsed += delta * idle_bob_speed
	body_visual.position = base_visual_position + Vector2(0.0, sin(bob_elapsed) * idle_bob_distance)
