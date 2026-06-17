extends Node

const STREAM_PATHS := {
	"jump": "res://assets/game/audio/jump.wav",
	"collect": "res://assets/game/audio/collect.wav",
	"death": "res://assets/game/audio/death.wav",
	"checkpoint": "res://assets/game/audio/checkpoint.wav",
	"door": "res://assets/game/audio/door.wav",
}

var players: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sfx_name in STREAM_PATHS:
		var stream := load(STREAM_PATHS[sfx_name]) as AudioStream
		if stream == null:
			push_warning("Could not load SFX: %s" % STREAM_PATHS[sfx_name])
			continue

		var audio_player := AudioStreamPlayer.new()
		audio_player.stream = stream
		audio_player.bus = "Master"
		add_child(audio_player)
		players[sfx_name] = audio_player


func play_sfx(sfx_name: String) -> void:
	var audio_player := players.get(sfx_name) as AudioStreamPlayer
	if audio_player == null:
		return

	audio_player.stop()
	audio_player.play()
