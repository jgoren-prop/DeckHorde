extends Node
## GameManager - Global game state and scene transitions
## Includes fade transition effects between scenes

enum GameState { MAIN_MENU, WARDEN_SELECT, COMBAT, SHOP, REWARD, RUN_END, META_MENU }

var current_state: GameState = GameState.MAIN_MENU

# Transition system
var transition_layer: CanvasLayer
var transition_rect: ColorRect
var is_transitioning: bool = false
const FADE_DURATION: float = 0.3


func _ready() -> void:
	_setup_transition_layer()
	print("[GameManager] Initialized")


func _setup_transition_layer() -> void:
	"""Create the transition overlay for fade effects."""
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 100  # Above everything
	add_child(transition_layer)
	
	transition_rect = ColorRect.new()
	transition_rect.color = Color(0.05, 0.03, 0.08, 0.0)  # Dark purple, transparent
	transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_layer.add_child(transition_rect)


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
		"meta_menu": "res://scenes/MetaMenu.tscn",
		"settings": "res://scenes/Settings.tscn"
	}
	
	if scene_paths.has(scene_name):
		transition_to_scene(scene_paths[scene_name])
	else:
		push_error("[GameManager] Unknown scene: " + scene_name)


func change_scene(scene_path: String) -> void:
	"""Direct scene change without transition (for internal use)."""
	print("[GameManager] Changing scene to: ", scene_path)
	get_tree().change_scene_to_file(scene_path)


func transition_to_scene(scene_path: String) -> void:
	"""Change scene with fade transition."""
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Fade out
	var tween: Tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_do_scene_change.bind(scene_path))
	tween.tween_property(transition_rect, "color:a", 0.0, FADE_DURATION)
	tween.tween_callback(_on_transition_complete)


func _do_scene_change(scene_path: String) -> void:
	"""Called mid-transition to actually change the scene."""
	print("[GameManager] Changing scene to: ", scene_path)
	get_tree().change_scene_to_file(scene_path)


func _on_transition_complete() -> void:
	"""Called when transition animation finishes."""
	is_transitioning = false


func start_new_run() -> void:
	print("[GameManager] Starting new run")
	current_state = GameState.COMBAT
	transition_to_scene("res://scenes/Combat.tscn")


func go_to_warden_select() -> void:
	print("[GameManager] Going to warden select")
	current_state = GameState.WARDEN_SELECT
	transition_to_scene("res://scenes/WardenSelect.tscn")


func return_to_main_menu() -> void:
	print("[GameManager] Returning to main menu")
	current_state = GameState.MAIN_MENU
	transition_to_scene("res://scenes/MainMenu.tscn")


func go_to_shop() -> void:
	print("[GameManager] Going to shop")
	current_state = GameState.SHOP
	transition_to_scene("res://scenes/Shop.tscn")


func go_to_reward() -> void:
	print("[GameManager] Going to reward screen")
	current_state = GameState.REWARD
	transition_to_scene("res://scenes/PostWaveReward.tscn")


func end_run(victory: bool) -> void:
	print("[GameManager] Run ended - Victory: ", victory)
	current_state = GameState.RUN_END
	transition_to_scene("res://scenes/RunEnd.tscn")


func go_to_post_wave_reward() -> void:
	print("[GameManager] Going to post-wave reward")
	current_state = GameState.REWARD
	transition_to_scene("res://scenes/PostWaveReward.tscn")


func next_wave() -> void:
	print("[GameManager] Starting next wave")
	RunManager.advance_wave()
	current_state = GameState.COMBAT
	transition_to_scene("res://scenes/Combat.tscn")


func start_next_wave() -> void:
	next_wave()


## Quick transition (faster for combat flow)
func quick_transition_to_scene(scene_path: String) -> void:
	"""Faster transition for responsive game flow."""
	if is_transitioning:
		return
	
	is_transitioning = true
	
	var tween: Tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, 0.15)
	tween.tween_callback(_do_scene_change.bind(scene_path))
	tween.tween_property(transition_rect, "color:a", 0.0, 0.15)
	tween.tween_callback(_on_transition_complete)
