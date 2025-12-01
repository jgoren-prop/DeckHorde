extends Node
## AudioManager - Sound effect handling
## Uses procedural AudioStreamGenerator for placeholder SFX until real audio added

signal sfx_played(sfx_name: String)

# Audio bus for SFX volume control
var sfx_volume: float = 0.8
var music_volume: float = 0.5
var muted: bool = false

# Audio players pool for overlapping sounds
var sfx_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8


func _ready() -> void:
	_create_audio_pool()
	print("[AudioManager] Initialized with ", POOL_SIZE, " audio channels")


func _create_audio_pool() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"  # Can change to "SFX" bus if created
		add_child(player)
		sfx_players.append(player)


func _get_available_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# All busy, reuse first one
	return sfx_players[0]


## Play a sound effect by name
func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	if muted:
		return
	
	var player: AudioStreamPlayer = _get_available_player()
	var stream: AudioStream = _generate_placeholder_sound(sfx_name)
	
	if stream:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume)
		if pitch_variation > 0:
			player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		else:
			player.pitch_scale = 1.0
		player.play()
		sfx_played.emit(sfx_name)


## Generate placeholder procedural sounds
func _generate_placeholder_sound(sfx_name: String) -> AudioStream:
	# Create a short tone-based placeholder
	# In future, replace with actual loaded audio files
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1  # Short buffer
	
	# Return generator - actual sound will be a beep/tone
	# This is a structural placeholder; real implementation would load .wav/.ogg
	match sfx_name:
		"card_play":
			return _create_tone(440.0, 0.08)  # A4 note, short
		"card_draw":
			return _create_tone(523.0, 0.05)  # C5 note, very short
		"damage_dealt":
			return _create_tone(220.0, 0.1)  # A3 note, impact
		"damage_taken":
			return _create_tone(165.0, 0.15)  # E3 note, deeper
		"enemy_death":
			return _create_tone(330.0, 0.12)  # E4 note
		"heal":
			return _create_tone(659.0, 0.1)  # E5 note, bright
		"armor_gain":
			return _create_tone(392.0, 0.08)  # G4 note
		"hex_apply":
			return _create_tone(277.0, 0.1)  # C#4 note, eerie
		"turn_start":
			return _create_tone(587.0, 0.06)  # D5 note
		"turn_end":
			return _create_tone(494.0, 0.06)  # B4 note
		"wave_complete":
			return _create_tone(880.0, 0.2)  # A5 note, victory
		"wave_fail":
			return _create_tone(146.0, 0.3)  # D3 note, defeat
		"button_click":
			return _create_tone(698.0, 0.03)  # F5 note, quick
		"button_hover":
			return _create_tone(784.0, 0.02)  # G5 note, very quick
		"merge_complete":
			return _create_tone(1047.0, 0.15)  # C6 note, high success
		"shop_purchase":
			return _create_tone(523.0, 0.1)  # C5 note
		"error":
			return _create_tone(130.0, 0.1)  # Low buzz for errors
		_:
			return _create_tone(440.0, 0.05)  # Default beep


## Create a simple tone (sine wave)
func _create_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050  # Lower quality for placeholders
	var num_samples: int = int(sample_rate * duration)
	var audio := AudioStreamWAV.new()
	
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false
	
	var data := PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		# Sine wave with envelope (fade out)
		var envelope: float = 1.0 - (float(i) / float(num_samples))
		envelope = envelope * envelope  # Quadratic falloff
		var sample: float = sin(2.0 * PI * frequency * t) * envelope
		# Convert to 8-bit unsigned (0-255, centered at 128)
		var byte_val: int = int((sample * 0.5 + 0.5) * 255)
		data[i] = clampi(byte_val, 0, 255)
	
	audio.data = data
	return audio


# === Convenience functions for common sounds ===

func play_card_play() -> void:
	play_sfx("card_play", 0.1)


func play_card_draw() -> void:
	play_sfx("card_draw", 0.15)


func play_damage_dealt() -> void:
	play_sfx("damage_dealt", 0.1)


func play_damage_taken() -> void:
	play_sfx("damage_taken", 0.05)


func play_enemy_death() -> void:
	play_sfx("enemy_death", 0.1)


func play_heal() -> void:
	play_sfx("heal", 0.05)


func play_armor_gain() -> void:
	play_sfx("armor_gain", 0.1)


func play_hex_apply() -> void:
	play_sfx("hex_apply", 0.1)


func play_turn_start() -> void:
	play_sfx("turn_start")


func play_turn_end() -> void:
	play_sfx("turn_end")


func play_wave_complete() -> void:
	play_sfx("wave_complete")


func play_wave_fail() -> void:
	play_sfx("wave_fail")


func play_button_click() -> void:
	play_sfx("button_click")


func play_button_hover() -> void:
	play_sfx("button_hover")


func play_merge_complete() -> void:
	play_sfx("merge_complete")


func play_shop_purchase() -> void:
	play_sfx("shop_purchase")


func play_error() -> void:
	play_sfx("error")


# === Volume control ===

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)


func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)


func toggle_mute() -> void:
	muted = not muted








