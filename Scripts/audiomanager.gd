extends Node

const CONFIG_PATH := "res://audio/audio.ini"
const MAX_PLAYERS := 16

var sound_map: Dictionary = {}
var _players: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	randomize()
	_init_audio_players()
	load_sound_config(CONFIG_PATH)

func _init_audio_players() -> void:
	for i in MAX_PLAYERS:
		var player := AudioStreamPlayer3D.new()
		player.name = "AudioPlayer%d" % i
		player.bus = "SFX"
		player.volume_db = 0.0
		player.stream_paused = false
		player.autoplay = false
		add_child(player)
		_players.append(player)

func load_sound_config(path: String) -> void:
	sound_map.clear()
	var config := ConfigFile.new()
	var err: int = config.load(path)
	if err != OK:
		push_error("AudioManager: Fehler beim Laden: %s" % path)
		return

	var temp_map: Dictionary = {}

	for key in config.get_section_keys("Sounds"):
		var base_key: String = key.split("_")[0]
		var file_path: String = config.get_value("Sounds", key, "")
		if file_path != "":
			var stream: Resource = load(file_path)
			if stream is AudioStream:
				if not temp_map.has(base_key):
					temp_map[base_key] = []
				temp_map[base_key].append(stream)
			else:
				push_warning("AudioManager: Kein gültiger Stream: %s" % file_path)
		else:
			push_warning("AudioManager: Leerer Pfad bei Key: %s" % key)

	sound_map = temp_map

func get_available_player() -> AudioStreamPlayer3D:
	for player in _players:
		if not player.playing:
			return player
	return null

## GENERISCHE 3D-Funktion
func play_3d(key: String, position: Vector3) -> void:
	if sound_map.has(key):
		var list: Array = sound_map[key]
		if list.size() == 0:
			return
		var stream: AudioStream = list[randi() % list.size()]
		var player := get_available_player()
		if player:
			player.stream = stream
			player.global_transform.origin = position
			player.play()
		else:
			push_warning("AudioManager: Kein freier AudioPlayer für '%s'" % key)
	else:
		push_warning("AudioManager: Unbekannter Sound-Schlüssel '%s'" % key)
