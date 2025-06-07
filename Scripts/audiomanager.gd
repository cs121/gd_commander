extends Node

const CONFIG_PATH := "res://audio/audio_config.ini"

# Dictionary mit Soundgruppen (key → Array von AudioStreams)
var sound_map: Dictionary = {}

# Einzelner AudioPlayer für einfache Nutzung
var _player: AudioStreamPlayer3D

func _ready() -> void:
	randomize()  # Zufall initialisieren
	_player = AudioStreamPlayer3D.new()
	add_child(_player)
	load_sound_config(CONFIG_PATH)

# Lade und gruppiere Sounds aus der INI-Datei
func load_sound_config(path: String) -> void:
	sound_map.clear()
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(path)
	if err != OK:
		push_error("AudioManager: Fehler beim Laden der Sound-INI-Datei: %s" % path)
		return

	var temp_map: Dictionary = {}

	for key in config.get_section_keys("Sounds"):
		var base_key: String = key.split("_")[0]  # z. B. "hit_1" → "hit"
		var file_path: String = config.get_value("Sounds", key, "")
		if file_path != "":
			var stream: Resource = load(file_path)
			if stream is AudioStream:
				if not temp_map.has(base_key):
					temp_map[base_key] = []
				temp_map[base_key].append(stream)
			else:
				push_warning("AudioManager: Ungültiger AudioStream: %s" % file_path)
		else:
			push_warning("AudioManager: Leerer Pfad für Key: %s" % key)

	sound_map = temp_map

func reload() -> void:
	load_sound_config(CONFIG_PATH)

# Spiele zufälligen Stream aus der Gruppe (wenn mehrere Varianten vorhanden)
func play(key: String, position: Vector3) -> void:
	if sound_map.has(key):
		var stream_list: Array = sound_map[key]
		if stream_list.size() > 0:
			var index: int = randi() % stream_list.size()
			var stream: AudioStream = stream_list[index]
			_player.stop()
			_player.stream = stream
			_player.global_transform.origin = position
			_player.play()
	else:
		push_warning("AudioManager: Kein Sound mit Schlüssel '%s' gefunden." % key)

# Helper-Funktionen
func play_hit(position: Vector3) -> void: play("hit", position)
func play_shield_hit(position: Vector3) -> void: play("shield_hit", position)
func play_death_explosion(position: Vector3) -> void: play("death_explosion", position)
func play_final_explosion(position: Vector3) -> void: play("final_explosion", position)
func play_missile_launch(position: Vector3) -> void: play("missile_launch", position)
func play_weapon_fire(position: Vector3) -> void: play("weapon_fire", position)
func play_lock_acquired(position: Vector3) -> void: play("lock_acquire", position)
func play_lock_lost(position: Vector3) -> void: play("lock_lost", position)
