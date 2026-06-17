extends Area2D
class_name Spikes

@export var active := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if body.has_method("die"):
		body.die()
