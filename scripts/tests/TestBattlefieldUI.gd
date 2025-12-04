extends Node
## Regression tests for battlefield stack layout and hover behavior.

const STACK_SYSTEM_SCENE: PackedScene = preload("res://scenes/combat/nodes/BattlefieldStackSystem.tscn")
const HOVER_SYSTEM_SCENE: PackedScene = preload("res://scenes/combat/nodes/BattlefieldHoverSystem.tscn")
const STACK_PANEL_SCENE: PackedScene = preload("res://scenes/combat/components/EnemyStackPanel.tscn")
const MINI_PANEL_SCENE: PackedScene = preload("res://scenes/combat/components/MiniEnemyPanel.tscn")


class StubEnemy:
	extends RefCounted
	var enemy_id: String
	var instance_id: int
	var current_hp: int
	var max_hp: int
	var ring: int
	var group_id: String = ""
	
	func _init(id: String, inst_id: int, hp: int, max_health: int, ring_idx: int) -> void:
		enemy_id = id
		instance_id = inst_id
		current_hp = hp
		max_hp = max_health
		ring = ring_idx
	
	func get_hp_percentage() -> float:
		return float(current_hp) / float(max_hp)
	
	func get_status_value(_status: String) -> int:
		return 0
	
	func is_alive() -> bool:
		return current_hp > 0
	
	func will_attack_this_turn(_enemy_def = null) -> bool:
		return ring == 0


func _ready() -> void:
	await get_tree().process_frame
	var layout_passed: bool = await _test_stack_expansion_layout()
	var hover_passed: bool = await _test_stack_hover_cards()
	
	print("[TEST] Stack mini-panels above card: ", layout_passed)
	print("[TEST] Stack hover info card + mini suppression: ", hover_passed)
	
	var passed: bool = layout_passed and hover_passed
	print("[TEST] RESULT: ", "PASSED ✓" if passed else "FAILED ✗")
	get_tree().quit(0 if passed else 1)


func _make_stub_enemies(count: int, ring: int) -> Array:
	var enemies: Array = []
	for i: int in range(count):
		enemies.append(StubEnemy.new("husk", 100 + i, 8, 8, ring))
	return enemies


func _test_stack_expansion_layout() -> bool:
	var stack_system: BattlefieldStackSystem = STACK_SYSTEM_SCENE.instantiate()
	stack_system.arena_center = Vector2(360, 360)
	stack_system.arena_max_radius = 300.0
	add_child(stack_system)
	
	var enemies: Array = _make_stub_enemies(3, 2)
	var stack_key: String = stack_system.create_stack(2, "husk", enemies, "test_layout")
	stack_system.expand_stack(stack_key)
	
	# Allow mini-panels to instantiate and position
	await get_tree().process_frame
	await get_tree().process_frame
	
	var stack_data: Dictionary = stack_system.stack_visuals[stack_key]
	var panel: Panel = stack_data.panel
	var mini_panels: Array = stack_data.mini_panels
	# Mini panels should be above the stack (smaller y, 16px gap + 50px panel height)
	var expected_y: float = max(panel.position.y - 50.0 - 16.0, 0.0)
	var all_match: bool = true
	
	for mini_panel in mini_panels:
		if not is_instance_valid(mini_panel):
			continue
		# Mini panels must be positioned above the stack panel
		if mini_panel.position.y >= panel.position.y:
			all_match = false
	
	stack_system.queue_free()
	return all_match and not mini_panels.is_empty()


func _test_stack_hover_cards() -> bool:
	var hover_system: BattlefieldHoverSystem = HOVER_SYSTEM_SCENE.instantiate()
	hover_system.size = Vector2(800, 600)
	hover_system.info_card_delay = 0.0  # Instant for test
	add_child(hover_system)
	
	var stack_panel: EnemyStackPanel = STACK_PANEL_SCENE.instantiate()
	var enemies: Array = _make_stub_enemies(3, 1)
	add_child(stack_panel)
	stack_panel.setup("husk", 1, enemies, Color(0.8, 0.3, 0.3), "hover_stack", Vector2(110, 120))
	stack_panel.position = Vector2(220, 260)
	
	await get_tree().process_frame
	hover_system.on_stack_hover_enter(stack_panel, "hover_stack")
	await get_tree().process_frame
	var info_from_stack: bool = hover_system._info_card != null
	
	# Verify info card appears to the right of the stack
	var info_card_position_ok: bool = true
	if hover_system._info_card:
		var card_x: float = hover_system._info_card.position.x
		var stack_right: float = stack_panel.position.x + stack_panel.size.x
		info_card_position_ok = card_x >= stack_right
	hover_system._hide_info_card()
	
	var mini_panel: MiniEnemyPanel = MINI_PANEL_SCENE.instantiate()
	add_child(mini_panel)
	await mini_panel.setup(enemies[0], Vector2(55, 50), Color(0.8, 0.3, 0.3), "hover_stack")
	await get_tree().process_frame
	hover_system.on_mini_panel_hover_enter(mini_panel, enemies[0], "hover_stack")
	await get_tree().process_frame
	var mini_no_card: bool = hover_system._info_card == null
	
	hover_system.queue_free()
	stack_panel.queue_free()
	mini_panel.queue_free()
	return info_from_stack and info_card_position_ok and mini_no_card

