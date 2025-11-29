extends Control
## MainMenu - Main menu screen controller

@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var meta_button: Button = $VBoxContainer/MetaButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	# Ensure buttons are properly connected
	if not new_run_button.pressed.is_connected(_on_new_run_pressed):
		new_run_button.pressed.connect(_on_new_run_pressed)
	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Play entrance animation (future)
	_animate_entrance()


func _animate_entrance() -> void:
	# Simple fade-in
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)


func _on_new_run_pressed() -> void:
	print("[MainMenu] New Run pressed")
	GameManager.change_state(GameManager.GameState.WARDEN_SELECT)
	GameManager.go_to_scene("warden_select")


func _on_meta_pressed() -> void:
	print("[MainMenu] Meta/Unlocks pressed")
	GameManager.change_state(GameManager.GameState.META_MENU)
	GameManager.go_to_scene("meta_menu")


func _on_settings_pressed() -> void:
	print("[MainMenu] Settings pressed")
	# TODO: Open settings overlay


func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	get_tree().quit()
