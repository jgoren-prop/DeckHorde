extends Control
## RunEnd - End of run screen showing results and essence gained

@onready var result_title: Label = $VBoxContainer/ResultTitle
@onready var result_subtitle: Label = $VBoxContainer/ResultSubtitle
@onready var waves_reached: Label = $VBoxContainer/StatsContainer/WavesReached
@onready var enemies_killed: Label = $VBoxContainer/StatsContainer/EnemiesKilled
@onready var danger_level: Label = $VBoxContainer/StatsContainer/DangerLevel
@onready var essence_label: Label = $VBoxContainer/EssenceContainer/EssenceLabel


func _ready() -> void:
	_display_results()


func _display_results() -> void:
	var victory: bool = RunManager.current_wave >= RunManager.MAX_WAVES
	
	if victory:
		result_title.text = "VICTORY!"
		result_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		result_subtitle.text = "The Rift is sealed... for now."
	else:
		result_title.text = "DEFEAT"
		result_title.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		result_subtitle.text = "The darkness claims another Warden."
	
	waves_reached.text = "Waves Cleared: %d/%d" % [RunManager.current_wave, RunManager.MAX_WAVES]
	enemies_killed.text = "Enemies Slain: %d" % RunManager.enemies_killed
	danger_level.text = "Danger Level: %d" % RunManager.danger_level
	
	essence_label.text = "+%d Essence" % RunManager.essence_earned
	
	# TODO: Actually add essence to meta progression
	# MetaProgressionManager.add_essence(RunManager.essence_earned)


func _on_new_run_pressed() -> void:
	GameManager.change_state(GameManager.GameState.WARDEN_SELECT)
	GameManager.go_to_scene("warden_select")


func _on_main_menu_pressed() -> void:
	GameManager.return_to_main_menu()

