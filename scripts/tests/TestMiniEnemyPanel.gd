extends Node
## Automated test verifying MiniEnemyPanel pulls data from EnemyDatabase safely.

const PANEL_SCENE: PackedScene = preload("res://scenes/combat/components/MiniEnemyPanel.tscn")

class StubEnemy:
	extends RefCounted
	var enemy_id: String
	var instance_id: int
	var current_hp: int
	var max_hp: int
	
	func _init(id: String, inst_id: int, hp: int, max_health: int) -> void:
		enemy_id = id
		instance_id = inst_id
		current_hp = hp
		max_hp = max_health
	
	func get_hp_percentage() -> float:
		return float(current_hp) / float(max_hp)
	
	func get_status_value(_status: String) -> int:
		return 0
	
	func is_alive() -> bool:
		return current_hp > 0


func _ready() -> void:
	await get_tree().process_frame
	var passed: bool = await _test_mini_enemy_panel_setup()
	print("[TEST] RESULT: ", "PASSED ✓" if passed else "FAILED ✗")
	get_tree().quit(0 if passed else 1)


func _test_mini_enemy_panel_setup() -> bool:
	var stub_enemy := StubEnemy.new("husk", 42, 5, 10)
	var panel: MiniEnemyPanel = PANEL_SCENE.instantiate()
	add_child(panel)
	await panel.setup(stub_enemy, Vector2(60.0, 50.0), Color(0.8, 0.3, 0.3), "test_stack")
	await get_tree().process_frame
	
	var enemy_def: EnemyDefinition = EnemyDatabase.get_enemy(stub_enemy.enemy_id)
	var icon_matches: bool = panel.icon_label.text == enemy_def.display_icon
	var badge_exists: bool = panel.behavior_badge != null
	
	print("[TEST] Icon text: ", panel.icon_label.text)
	print("[TEST] Expected icon: ", enemy_def.display_icon)
	print("[TEST] Behavior badge exists: ", badge_exists)
	
	return icon_matches and badge_exists

