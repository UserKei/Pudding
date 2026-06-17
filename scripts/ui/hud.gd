extends CanvasLayer
class_name HUD

@onready var level_label: Label = %LevelLabel
@onready var collectible_label: Label = %CollectibleLabel
@onready var death_label: Label = %DeathLabel


func _ready() -> void:
	GameState.level_changed.connect(_on_level_changed)
	GameState.collectibles_changed.connect(_on_collectibles_changed)
	GameState.death_count_changed.connect(_on_death_count_changed)
	_on_level_changed(GameState.current_level_id, GameState.current_level_name)
	_on_collectibles_changed(GameState.collectible_count)
	_on_death_count_changed(GameState.death_count)


func _on_level_changed(_level_id: String, display_name: String) -> void:
	level_label.text = display_name if not display_name.is_empty() else "Level"


func _on_collectibles_changed(count: int) -> void:
	collectible_label.text = "Fruit %d" % count


func _on_death_count_changed(count: int) -> void:
	death_label.text = "Deaths %d" % count
