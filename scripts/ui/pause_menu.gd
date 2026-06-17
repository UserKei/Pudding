extends CanvasLayer
class_name PauseMenu

@onready var overlay: ColorRect = %Overlay
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	set_pause_state(not get_tree().paused)


func set_pause_state(is_paused: bool) -> void:
	get_tree().paused = is_paused
	visible = is_paused
	GameState.set_pause_state(is_paused)
	if is_paused:
		resume_button.grab_focus()


func _on_resume_pressed() -> void:
	set_pause_state(false)


func _on_restart_pressed() -> void:
	set_pause_state(false)
	var main: Node = get_tree().current_scene
	if main != null and main.has_method("restart_current_level"):
		main.restart_current_level()


func _on_quit_pressed() -> void:
	set_pause_state(false)
	get_tree().quit()
