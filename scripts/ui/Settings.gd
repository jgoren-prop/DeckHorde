extends Control
## Settings - Settings menu screen controller
## Works as both a standalone scene and as an overlay

# Audio controls
@onready var master_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_value: Label = $PanelContainer/MarginContainer/VBoxContainer/MasterVolumeContainer/MasterVolumeValue
@onready var sfx_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_value: Label = $PanelContainer/MarginContainer/VBoxContainer/SFXVolumeContainer/SFXVolumeValue
@onready var music_volume_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_value: Label = $PanelContainer/MarginContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeValue
@onready var mute_checkbox: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/MuteContainer/MuteCheckBox

# Gameplay controls
@onready var screen_shake_checkbox: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/ScreenShakeContainer/ScreenShakeCheckBox
@onready var damage_numbers_checkbox: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/DamageNumbersContainer/DamageNumbersCheckBox
@onready var auto_end_turn_checkbox: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/AutoEndTurnContainer/AutoEndTurnCheckBox

# Display controls
@onready var screen_mode_dropdown: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/ScreenModeContainer/ScreenModeDropdown
@onready var vsync_checkbox: CheckBox = $PanelContainer/MarginContainer/VBoxContainer/VSyncContainer/VSyncCheckBox

# Buttons
@onready var reset_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/ResetButton
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/BackButton

# Flag to prevent saving during initial load
var _loading: bool = true

# Track if running as overlay
var _is_overlay: bool = false

# Background reference for overlay mode
@onready var background: ColorRect = $Background


func _ready() -> void:
	# Check if we're running as an overlay (set by GameManager)
	_is_overlay = has_meta("is_overlay") and get_meta("is_overlay")
	
	_load_current_settings()
	_loading = false
	
	# Configure overlay mode appearance
	if _is_overlay:
		back_button.text = "Close"
		# Make background semi-transparent so you can see the game behind
		background.color = Color(0.08, 0.06, 0.12, 0.85)
	else:
		# Only animate entrance for standalone scene mode
		_animate_entrance()


func _load_current_settings() -> void:
	# Load values from SettingsManager
	master_volume_slider.value = SettingsManager.master_volume
	sfx_volume_slider.value = SettingsManager.sfx_volume
	music_volume_slider.value = SettingsManager.music_volume
	mute_checkbox.button_pressed = SettingsManager.muted
	
	screen_shake_checkbox.button_pressed = SettingsManager.screen_shake
	damage_numbers_checkbox.button_pressed = SettingsManager.show_damage_numbers
	auto_end_turn_checkbox.button_pressed = SettingsManager.auto_end_turn
	
	screen_mode_dropdown.selected = SettingsManager.window_mode
	vsync_checkbox.button_pressed = SettingsManager.vsync
	
	# Update labels
	_update_volume_labels()


func _update_volume_labels() -> void:
	master_volume_value.text = str(int(master_volume_slider.value * 100)) + "%"
	sfx_volume_value.text = str(int(sfx_volume_slider.value * 100)) + "%"
	music_volume_value.text = str(int(music_volume_slider.value * 100)) + "%"


func _animate_entrance() -> void:
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


# === Audio callbacks ===

func _on_master_volume_changed(value: float) -> void:
	master_volume_value.text = str(int(value * 100)) + "%"
	if not _loading:
		SettingsManager.set_master_volume(value)
		AudioManager.play_button_click()


func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume_value.text = str(int(value * 100)) + "%"
	if not _loading:
		SettingsManager.set_sfx_volume(value)
		AudioManager.play_button_click()


func _on_music_volume_changed(value: float) -> void:
	music_volume_value.text = str(int(value * 100)) + "%"
	if not _loading:
		SettingsManager.set_music_volume(value)
		AudioManager.play_button_click()


func _on_mute_toggled(toggled_on: bool) -> void:
	if not _loading:
		SettingsManager.set_muted(toggled_on)
		if not toggled_on:
			AudioManager.play_button_click()


# === Gameplay callbacks ===

func _on_screen_shake_toggled(toggled_on: bool) -> void:
	if not _loading:
		SettingsManager.set_screen_shake(toggled_on)
		AudioManager.play_button_click()


func _on_damage_numbers_toggled(toggled_on: bool) -> void:
	if not _loading:
		SettingsManager.set_show_damage_numbers(toggled_on)
		AudioManager.play_button_click()


func _on_auto_end_turn_toggled(toggled_on: bool) -> void:
	if not _loading:
		SettingsManager.set_auto_end_turn(toggled_on)
		AudioManager.play_button_click()


# === Display callbacks ===

func _on_screen_mode_selected(index: int) -> void:
	if not _loading:
		SettingsManager.set_window_mode(index)
		AudioManager.play_button_click()


func _on_vsync_toggled(toggled_on: bool) -> void:
	if not _loading:
		SettingsManager.set_vsync(toggled_on)
		AudioManager.play_button_click()


# === Button callbacks ===

func _on_reset_pressed() -> void:
	AudioManager.play_button_click()
	SettingsManager.reset_to_defaults()
	_loading = true
	_load_current_settings()
	_loading = false
	print("[Settings] Reset to defaults")


func _on_back_pressed() -> void:
	AudioManager.play_button_click()
	print("[Settings] Back pressed")
	if _is_overlay:
		# Close overlay instead of navigating
		GameManager.close_settings_overlay()
	else:
		# Navigate back to main menu (standalone scene mode)
		GameManager.go_to_scene("main_menu")


func _on_quit_pressed() -> void:
	AudioManager.play_button_click()
	print("[Settings] Quit game pressed")
	get_tree().quit()
