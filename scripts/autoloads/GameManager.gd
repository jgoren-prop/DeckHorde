extends Node
## GameManager - Global game state and scene transitions
## MINIMAL STUB for testing - will be expanded later

enum GameState { MAIN_MENU, WARDEN_SELECT, COMBAT, SHOP, REWARD, RUN_END, META_MENU }

var current_state: GameState = GameState.MAIN_MENU


func _ready() -> void:
	print("[GameManager] Initialized")


func change_state(new_state: GameState) -> void:
	current_state = new_state
	print("[GameManager] State changed to: ", new_state)


func go_to_scene(scene_name: String) -> void:
	var scene_paths: Dictionary = {
		"main_menu": "res://scenes/MainMenu.tscn",
		"warden_select": "res://scenes/WardenSelect.tscn",
		"combat": "res://scenes/Combat.tscn",
		"shop": "res://scenes/Shop.tscn",
		"reward": "res://scenes/PostWaveReward.tscn",
		"run_end": "res://scenes/RunEnd.tscn",
		"meta_menu": "res://scenes/MetaMenu.tscn"
	}
	
	if scene_paths.has(scene_name):
		change_scene(scene_paths[scene_name])
	else:
		push_error("[GameManager] Unknown scene: " + scene_name)


func change_scene(scene_path: String) -> void:
	print("[GameManager] Changing scene to: ", scene_path)
	get_tree().change_scene_to_file(scene_path)


func start_new_run() -> void:
	print("[GameManager] Starting new run")
	current_state = GameState.COMBAT
	change_scene("res://scenes/Combat.tscn")


func go_to_warden_select() -> void:
	print("[GameManager] Going to warden select")
	current_state = GameState.WARDEN_SELECT
	change_scene("res://scenes/WardenSelect.tscn")


func return_to_main_menu() -> void:
	print("[GameManager] Returning to main menu")
	current_state = GameState.MAIN_MENU
	change_scene("res://scenes/MainMenu.tscn")


func go_to_shop() -> void:
	print("[GameManager] Going to shop")
	current_state = GameState.SHOP
	change_scene("res://scenes/Shop.tscn")


func go_to_reward() -> void:
	print("[GameManager] Going to reward screen")
	current_state = GameState.REWARD
	change_scene("res://scenes/PostWaveReward.tscn")


func end_run(victory: bool) -> void:
	print("[GameManager] Run ended - Victory: ", victory)
	current_state = GameState.RUN_END
	change_scene("res://scenes/RunEnd.tscn")


func go_to_post_wave_reward() -> void:
	print("[GameManager] Going to post-wave reward")
	current_state = GameState.REWARD
	change_scene("res://scenes/PostWaveReward.tscn")


func next_wave() -> void:
	print("[GameManager] Starting next wave")
	RunManager.advance_wave()
	current_state = GameState.COMBAT
	change_scene("res://scenes/Combat.tscn")
