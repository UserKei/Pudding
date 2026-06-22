extends Level

@onready var status_label: Label = $Labels/Status
@onready var status_light: Polygon2D = $Labels/StatusLight
@onready var backdrop: Polygon2D = $Background/Backdrop
@onready var spike_strip: IndustrialSpikeStrip = $Hazards/SpikeStrip
@onready var robot: IndustrialAtlasProp = $Props/GuideRobot
@onready var screen: IndustrialAtlasProp = $Props/Screen
@onready var warning_panel: IndustrialAtlasProp = $Props/WarningPanel
@onready var hazard_bridge_left: IndustrialBlock = $Geometry/HazardBridgeLeft
@onready var hazard_bridge_right: IndustrialBlock = $Geometry/HazardBridgeRight


func _ready() -> void:
	_connect_button("Buttons/SafeButton", Callable(self, "_on_safe_button_pressed"))
	_connect_button("Buttons/DangerButton", Callable(self, "_on_danger_button_pressed"))
	_connect_button("Buttons/UnknownButton", Callable(self, "_on_unknown_button_pressed"))
	_connect_button("Buttons/GoalButton", Callable(self, "_on_goal_button_pressed"))
	_connect_button("Buttons/ForbiddenButton", Callable(self, "_on_forbidden_button_pressed"))
	_set_status("Ready: walk over or interact with a button.", Color(0.68, 0.76, 0.86, 1.0))


func _connect_button(node_path: NodePath, callback: Callable) -> void:
	var button := get_node_or_null(node_path) as IndustrialButton
	if button == null:
		push_warning("Showcase button missing: %s" % [node_path])
		return

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_safe_button_pressed(_button: IndustrialButton) -> void:
	spike_strip.active = false
	spike_strip.modulate = Color(0.45, 1.0, 0.55, 0.45)
	_set_block_tint(hazard_bridge_left, Color(0.55, 1.0, 0.65, 1.0))
	_set_block_tint(hazard_bridge_right, Color(0.55, 1.0, 0.65, 1.0))
	_set_status("Safe button: hazard disabled.", Color(0.35, 1.0, 0.48, 1.0))


func _on_danger_button_pressed(_button: IndustrialButton) -> void:
	spike_strip.active = true
	spike_strip.modulate = Color(1.0, 0.28, 0.28, 1.0)
	_set_status("Danger button: hazard armed.", Color(1.0, 0.28, 0.28, 1.0))


func _on_unknown_button_pressed(_button: IndustrialButton) -> void:
	robot.visual_modulate = Color(1.0, 0.86, 0.25, 1.0)
	screen.visual_modulate = Color(1.0, 0.86, 0.25, 1.0)
	_set_status("Unknown button: robot and screen marked.", Color(1.0, 0.86, 0.25, 1.0))


func _on_goal_button_pressed(_button: IndustrialButton) -> void:
	warning_panel.visual_modulate = Color(0.35, 0.68, 1.0, 1.0)
	_set_status("Goal button: exit sample is highlighted.", Color(0.35, 0.68, 1.0, 1.0))


func _on_forbidden_button_pressed(_button: IndustrialButton) -> void:
	backdrop.color = Color(0.08, 0.01, 0.03, 1.0)
	_set_status("Forbidden button: room state contaminated.", Color(1.0, 0.12, 0.32, 1.0))


func _set_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)
	status_light.color = color


func _set_block_tint(block: IndustrialBlock, color: Color) -> void:
	block.visual_modulate = color
