extends Node
## SettingsManager - Handles saving/loading user settings to local config file

signal settings_changed

const SETTINGS_PATH: String = "user://settings.cfg"

# Window mode constants
const WINDOW_MODE_WINDOWED: int = 0
const WINDOW_MODE_FULLSCREEN: int = 1
const WINDOW_MODE_BORDERLESS: int = 2  # Windowed Fullscreen

# Default settings values
var master_volume: float = 1.0
var sfx_volume: float = 0.8
var music_volume: float = 0.5
var muted: bool = false
var screen_shake: bool = true
var show_damage_numbers: bool = true
var auto_end_turn: bool = false
var window_mode: int = WINDOW_MODE_BORDERLESS  # Default to borderless fullscreen
var vsync: bool = true


func _ready() -> void:
	load_settings()
	_apply_settings()
	print("[SettingsManager] Initialized - Settings loaded")


## Load settings from config file
func load_settings() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load(SETTINGS_PATH)
	
	if err != OK:
		print("[SettingsManager] No settings file found, using defaults")
		save_settings()  # Create default settings file
		return
	
	# Audio settings
	master_volume = config.get_value("audio", "master_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
	music_volume = config.get_value("audio", "music_volume", 0.5)
	muted = config.get_value("audio", "muted", false)
	
	# Gameplay settings
	screen_shake = config.get_value("gameplay", "screen_shake", true)
	show_damage_numbers = config.get_value("gameplay", "show_damage_numbers", true)
	auto_end_turn = config.get_value("gameplay", "auto_end_turn", false)
	
	# Display settings
	window_mode = config.get_value("display", "window_mode", WINDOW_MODE_BORDERLESS)
	vsync = config.get_value("display", "vsync", true)
	
	print("[SettingsManager] Settings loaded from file")


## Save settings to config file
func save_settings() -> void:
	var config := ConfigFile.new()
	
	# Audio settings
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "muted", muted)
	
	# Gameplay settings
	config.set_value("gameplay", "screen_shake", screen_shake)
	config.set_value("gameplay", "show_damage_numbers", show_damage_numbers)
	config.set_value("gameplay", "auto_end_turn", auto_end_turn)
	
	# Display settings
	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "vsync", vsync)
	
	var err: Error = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("[SettingsManager] Failed to save settings: " + str(err))
	else:
		print("[SettingsManager] Settings saved")
	
	settings_changed.emit()


## Apply all settings to the game systems
func _apply_settings() -> void:
	_apply_audio_settings()
	_apply_display_settings()


## Apply audio settings to AudioManager
func _apply_audio_settings() -> void:
	# Update AudioManager if it exists (check via Engine singleton to avoid load-order issues)
	var audio_mgr: Node = Engine.get_singleton("AudioManager") if Engine.has_singleton("AudioManager") else null
	if audio_mgr == null:
		audio_mgr = get_node_or_null("/root/AudioManager")
	
	if audio_mgr:
		audio_mgr.sfx_volume = sfx_volume * master_volume
		audio_mgr.music_volume = music_volume * master_volume
		audio_mgr.muted = muted
	
	# Update audio bus volumes
	var master_bus_idx: int = AudioServer.get_bus_index("Master")
	if master_bus_idx >= 0:
		AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(master_volume))
		AudioServer.set_bus_mute(master_bus_idx, muted)


## Apply display settings
func _apply_display_settings() -> void:
	# Window mode
	# Godot 4 modes:
	# - WINDOW_MODE_WINDOWED: Regular window with borders
	# - WINDOW_MODE_FULLSCREEN: Borderless fullscreen (fast alt-tab, windowed fullscreen)
	# - WINDOW_MODE_EXCLUSIVE_FULLSCREEN: True exclusive fullscreen (slow alt-tab)
	match window_mode:
		WINDOW_MODE_WINDOWED:
			# Regular windowed mode with borders
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			# Set a reasonable default window size (e.g., 1280x720)
			DisplayServer.window_set_size(Vector2i(1280, 720))
			# Center the window on screen
			var screen_id: int = DisplayServer.window_get_current_screen()
			var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
			var window_size: Vector2i = DisplayServer.window_get_size()
			var centered_pos: Vector2i = DisplayServer.screen_get_position(screen_id) + (screen_size - window_size) / 2
			DisplayServer.window_set_position(centered_pos)
		WINDOW_MODE_FULLSCREEN:
			# True exclusive fullscreen (takes over display, slower alt-tab)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		WINDOW_MODE_BORDERLESS:
			# Borderless windowed fullscreen (covers screen but fast alt-tab)
			# Use Godot's built-in borderless fullscreen mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# VSync
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


# === Setter functions that auto-save ===

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	save_settings()


func set_muted(value: bool) -> void:
	muted = value
	_apply_audio_settings()
	save_settings()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	save_settings()


func set_show_damage_numbers(value: bool) -> void:
	show_damage_numbers = value
	save_settings()


func set_auto_end_turn(value: bool) -> void:
	auto_end_turn = value
	save_settings()


func set_window_mode(value: int) -> void:
	window_mode = clampi(value, WINDOW_MODE_WINDOWED, WINDOW_MODE_BORDERLESS)
	_apply_display_settings()
	save_settings()


func set_vsync(value: bool) -> void:
	vsync = value
	_apply_display_settings()
	save_settings()


## Reset all settings to defaults
func reset_to_defaults() -> void:
	master_volume = 1.0
	sfx_volume = 0.8
	music_volume = 0.5
	muted = false
	screen_shake = true
	show_damage_numbers = true
	auto_end_turn = false
	window_mode = WINDOW_MODE_BORDERLESS
	vsync = true
	
	_apply_settings()
	save_settings()
	print("[SettingsManager] Settings reset to defaults")

