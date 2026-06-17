extends CanvasLayer
class_name DialogueBox

signal dialogue_started
signal dialogue_finished

@export var interact_action := "interact"

@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var continue_label: Label = %ContinueLabel

var active := false
var dialogue_lines := PackedStringArray()
var current_line_index := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_box")
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed(interact_action) or event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()


func show_dialogue(speaker_name: String, lines: PackedStringArray) -> void:
	if lines.is_empty():
		return

	dialogue_lines = lines
	current_line_index = 0
	active = true
	visible = true
	speaker_label.text = speaker_name
	_update_dialogue_text()
	dialogue_started.emit()


func advance() -> void:
	if not active:
		return

	current_line_index += 1
	if current_line_index >= dialogue_lines.size():
		close_dialogue()
		return

	_update_dialogue_text()


func close_dialogue() -> void:
	active = false
	visible = false
	dialogue_lines = PackedStringArray()
	current_line_index = 0
	dialogue_finished.emit()


func is_active() -> bool:
	return active


func _update_dialogue_text() -> void:
	dialogue_label.text = dialogue_lines[current_line_index]
	continue_label.text = "E"
