extends Control
## CombatScreen - Main combat UI controller
## Uses CombatOverlayBuilder and GlossaryData for UI creation (see scripts/ui/combat/)

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")
const DebugStatPanelClass = preload("res://scripts/ui/DebugStatPanel.gd")
# Note: CombatOverlayBuilder and GlossaryData are globally available via class_name
# No const needed - use the class_name directly

# UI References - Top bar (just wave/turn/scrap)
@onready var wave_label: Label = $TopBar/HBox/WaveInfo/WaveLabel
@onready var turn_label: Label = $TopBar/HBox/WaveInfo/TurnLabel
@onready var scrap_label: Label = $TopBar/HBox/ScrapContainer/ScrapLabel

# UI References - Player Stats Panel (near battlefield, Slay the Spire style)
@onready var hp_label: Label = $PlayerStatsPanel/StatsVBox/HPSection/HPHeader/HPLabel
@onready var hp_bar_fill: ColorRect = $PlayerStatsPanel/StatsVBox/HPSection/HPBarBG/HPBarFill
@onready var armor_label: Label = $PlayerStatsPanel/StatsVBox/ArmorSection/ArmorLabel
@onready var armor_section: Control = $PlayerStatsPanel/StatsVBox/ArmorSection
@onready var weapons_list: VBoxContainer = $PlayerStatsPanel/StatsVBox/WeaponsSection/WeaponsList
@onready var weapons_section: Control = $PlayerStatsPanel/StatsVBox/WeaponsSection

# UI References - Combat Lane (persistent weapons display)
@onready var combat_lane: Control = $CombatLane

# UI References - Threat preview
@onready var incoming_damage: Label = $ThreatPreview/ThreatContent/IncomingDamage
@onready var threat_breakdown: RichTextLabel = $ThreatPreview/ThreatContent/ThreatBreakdown
@onready var moving_to_melee: Label = $ThreatPreview/ThreatContent/MovingToMelee

# UI References - Enemy counter
@onready var total_enemies: Label = $ThreatPreview/ThreatContent/TotalEnemies
@onready var melee_count: Label = $ThreatPreview/ThreatContent/RingBreakdown/MeleeCount
@onready var close_count: Label = $ThreatPreview/ThreatContent/RingBreakdown/CloseCount
@onready var mid_count: Label = $ThreatPreview/ThreatContent/RingBreakdown/MidCount
@onready var far_count: Label = $ThreatPreview/ThreatContent/RingBreakdown/FarCount

# UI References - Battlefield
@onready var battlefield_arena = $BattlefieldArena

# UI References - Bottom section
@onready var bottom_section: HBoxContainer = $BottomSection
@onready var card_hand: Control = $BottomSection/CardHand
@onready var deck_count: Label = $BottomSection/LeftSidebar/VBox/DeckInfo/DeckCount
@onready var energy_label: Label = $BottomSection/LeftSidebar/VBox/EnergyContainer/EnergyLabel
@onready var end_turn_button: Button = $BottomSection/LeftSidebar/VBox/EndTurnButton
@onready var discard_count: Label = $BottomSection/LeftSidebar/VBox/DiscardInfo/DiscardCount

# Fan layout constants
const FAN_CARD_WIDTH: float = 200.0  # Match card custom_minimum_size
const FAN_CARD_HEIGHT: float = 280.0  # Match card custom_minimum_size
const FAN_MAX_ROTATION: float = 0.20  # Max rotation in radians (~11 degrees)
const FAN_ARC_HEIGHT: float = 25.0  # How much cards arc up in the middle
const FAN_OVERLAP: float = 0.60  # How much cards overlap (0.6 = 60% overlap)

# UI References - Ring selector (kept for fallback, but hidden by default)
@onready var ring_selector: PanelContainer = $RingSelector

# UI References - Intent Bar (Combat Clarity system)
var intent_bar: PanelContainer = null
var intent_damage_label: Label = null
var intent_bomber_label: Label = null
var intent_buffer_label: Label = null
var intent_spawner_label: Label = null
var intent_fast_label: Label = null

# UI References - Settings overlay
@onready var settings_overlay: CanvasLayer = $SettingsOverlay
@onready var master_slider: HSlider = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/MasterVolumeRow/MasterSlider
@onready var master_value: Label = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/MasterVolumeRow/MasterValue

# Debug overlay removed - using console logging instead
@onready var sfx_slider: HSlider = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/SFXVolumeRow/SFXSlider
@onready var sfx_value: Label = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/SFXVolumeRow/SFXValue
@onready var music_slider: HSlider = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/MusicVolumeRow/MusicSlider
@onready var music_value: Label = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/MusicVolumeRow/MusicValue
@onready var mute_check: CheckBox = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/MuteRow/MuteCheck
@onready var screen_shake_check: CheckBox = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/ScreenShakeRow/ScreenShakeCheck
@onready var damage_numbers_check: CheckBox = $SettingsOverlay/SettingsPanel/MarginContainer/VBox/DamageNumbersRow/DamageNumbersCheck

# UI References - Glossary overlay
@onready var glossary_overlay: CanvasLayer = $GlossaryOverlay
@onready var glossary_content: VBoxContainer = $GlossaryOverlay/GlossaryPanel/VBox/ScrollContainer/GlossaryContent

# UI References - Deck viewer overlay (created dynamically)
var deck_viewer_overlay: CanvasLayer = null
var deck_viewer_grid: GridContainer = null
var deck_viewer_title: Label = null

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")
var pending_card_index: int = -1
var pending_card_def = null  # CardDefinition

# Drag-drop state
var dragging_card: Control = null
var dragging_card_def = null  # CardDefinition - track what card is being dragged
var _last_weapon_card_position: Vector2 = Vector2.ZERO  # Store card's visual position for weapon deployment

# Settings loading flag
var _loading_settings: bool = false


func _ready() -> void:
	_connect_signals()
	_setup_intent_bar()
	_setup_deck_viewer_overlay()
	_setup_dev_panel()
	_create_v2_debug_stat_panel()
	_setup_animation_manager()
	_hide_settings_overlay()
	# Defer combat start to ensure UI layout is computed first
	call_deferred("_start_combat")


func _setup_intent_bar() -> void:
	"""Create intent bar using CombatOverlayBuilder."""
	var result: Dictionary = CombatOverlayBuilder.create_intent_bar(self)
	intent_bar = result.panel
	intent_damage_label = result.damage_label
	intent_bomber_label = result.bomber_label
	intent_buffer_label = result.buffer_label
	intent_spawner_label = result.spawner_label
	intent_fast_label = result.fast_label


func _setup_deck_viewer_overlay() -> void:
	"""Create deck viewer overlay using CombatOverlayBuilder."""
	var result: Dictionary = CombatOverlayBuilder.create_deck_viewer_overlay(self)
	deck_viewer_overlay = result.overlay
	deck_viewer_grid = result.grid
	deck_viewer_title = result.title
	result.close_button.pressed.connect(_on_deck_viewer_close)


func _setup_dev_panel() -> void:
	"""Create dev panel using CombatOverlayBuilder."""
	var result: Dictionary = CombatOverlayBuilder.create_dev_panel(self)
	var dev_vbox: VBoxContainer = result.vbox
	
	CombatOverlayBuilder.create_dev_button(dev_vbox, "🏆 Force Win", _dev_force_win)
	CombatOverlayBuilder.create_dev_button(dev_vbox, "💀 Force Lose", _dev_force_lose)
	CombatOverlayBuilder.create_dev_button(dev_vbox, "⚡ +3 Energy", _dev_add_energy)
	CombatOverlayBuilder.create_dev_button(dev_vbox, "⚙️ +1000 Scrap", _dev_add_scrap)


func _setup_animation_manager() -> void:
	"""Initialize the CombatAnimationManager with UI references."""
	if CombatAnimationManager:
		CombatAnimationManager.set_references(battlefield_arena, self, combat_lane)
	
	# Also set combat_lane reference on BattlefieldArena for weapon projectile origins
	if battlefield_arena:
		battlefield_arena.combat_lane = combat_lane


func _setup_card_debug_overlay() -> void:
	"""Debug overlay removed - using console logging instead."""
	# No visual overlay needed - all debugging via console
	pass




var _last_highlighted_ring: int = -2  # Use -2 so first check always triggers
var _highlight_all_mode: bool = false  # Track if we're in "highlight all" mode
var _combat_lane_highlighted: bool = false  # Track if combat lane is highlighted for weapon drop

func _card_affects_battlefield(card_def) -> bool:
	"""Check if a card affects the battlefield (enemies/rings) vs self-only effects."""
	# Cards that don't affect the battlefield:
	# - Self-targeting cards (armor, heal, buffs)
	# - Pure utility cards (draw, energy gain)
	
	# Check target type first
	if card_def.target_type == "self":
		return false
	
	# Check effect types that don't target enemies
	var non_battlefield_effects: Array[String] = [
		"gain_armor",
		"heal",
		"buff",
		"draw",
		"draw_cards",
		"energy_and_draw",
		"gambit",
		"armor_and_heal"
	]
	
	if card_def.effect_type in non_battlefield_effects:
		return false
	
	return true

func _process(_delta: float) -> void:
	# While dragging a card, highlight the appropriate rings
	if dragging_card_def != null and battlefield_arena:
		var mouse_pos: Vector2 = get_global_mouse_position()
		
		# Persistent weapons can ONLY be dropped on combat lane (not battlefield)
		if dragging_card_def.effect_type == "weapon_persistent":
			# Clear any battlefield highlighting
			if _highlight_all_mode or _last_highlighted_ring >= 0:
				_highlight_all_mode = false
				_last_highlighted_ring = -1
				battlefield_arena.highlight_all_rings(false)
			
			# Only highlight combat lane for weapons
			if combat_lane:
				var is_over_lane: bool = _is_over_combat_lane(mouse_pos)
				if is_over_lane and not _combat_lane_highlighted:
					_combat_lane_highlighted = true
					_highlight_combat_lane(true)
				elif not is_over_lane and _combat_lane_highlighted:
					_combat_lane_highlighted = false
					_highlight_combat_lane(false)
			return
		
		# First check: does this card even affect the battlefield?
		if not _card_affects_battlefield(dragging_card_def):
			# Cards that don't affect battlefield (self-target, draw, armor, etc.)
			# should NOT highlight the battlefield at all
			if _highlight_all_mode or _last_highlighted_ring >= 0:
				_highlight_all_mode = false
				_last_highlighted_ring = -1
				battlefield_arena.highlight_all_rings(false)
			return
		
		var ring_under_cursor: int = battlefield_arena.get_ring_at_position(mouse_pos)
		
		# Check if this card targets all enemies or all rings
		var targets_all: bool = (
			dragging_card_def.target_type == "all_enemies" or
			(dragging_card_def.target_rings.size() == 4 and not dragging_card_def.requires_target)
		)
		
		if targets_all:
			# For cards that hit everything, highlight all rings when hovering battlefield
			if ring_under_cursor >= 0:
				if not _highlight_all_mode:
					_highlight_all_mode = true
					battlefield_arena.highlight_all_rings(true)
			else:
				if _highlight_all_mode:
					_highlight_all_mode = false
					battlefield_arena.highlight_all_rings(false)
		else:
			# Reset all-mode if we switched cards
			if _highlight_all_mode:
				_highlight_all_mode = false
			
			# Determine if this ring should be highlighted
			var should_highlight: bool = false
			if ring_under_cursor >= 0:
				if dragging_card_def.requires_target:
					# Targeting cards: only highlight if ring is in their target_rings
					if dragging_card_def.target_rings.size() == 0:
						# No restrictions - any ring is valid
						should_highlight = true
					elif ring_under_cursor in dragging_card_def.target_rings:
						# Ring is in the allowed list
						should_highlight = true
				else:
					# Non-targeting cards with specific rings: highlight those rings
					if dragging_card_def.target_rings.size() > 0 and not dragging_card_def.requires_target:
						# Auto-targeting card (like Shotgun) - highlight its target rings
						if ring_under_cursor >= 0:
							battlefield_arena.highlight_rings(dragging_card_def.target_rings, true)
							_last_highlighted_ring = ring_under_cursor
							return
					else:
						# Self-targeting or any-ring cards
						should_highlight = true
			
			# Only update highlight when ring changes to reduce overhead
			var target_ring: int = ring_under_cursor if should_highlight else -1
			if target_ring != _last_highlighted_ring:
				_last_highlighted_ring = target_ring
				if should_highlight:
					battlefield_arena.highlight_ring(ring_under_cursor, true)
				else:
					battlefield_arena.highlight_ring(-1, false)


func _connect_signals() -> void:
	# CombatManager signals
	CombatManager.phase_changed.connect(_on_phase_changed)
	CombatManager.turn_started.connect(_on_turn_started)
	CombatManager.energy_changed.connect(_on_energy_changed)
	CombatManager.wave_ended.connect(_on_wave_ended)
	CombatManager.card_played.connect(_on_card_played)
	CombatManager.weapon_triggered.connect(_on_weapon_triggered)
	CombatManager.ring_phase_started.connect(_on_ring_phase_started)
	CombatManager.ring_phase_ended.connect(_on_ring_phase_ended)
	CombatManager.enemy_attacking.connect(_on_enemy_attacking)
	CombatManager.enemy_moved.connect(_on_enemy_moved)
	CombatManager.player_damaged.connect(_on_player_damaged)
	CombatManager.enemy_spawned.connect(_on_enemy_spawned)
	
	# RunManager signals
	RunManager.health_changed.connect(_on_health_changed)
	RunManager.armor_changed.connect(_on_armor_changed)
	RunManager.scrap_changed.connect(_on_scrap_changed)
	
	# Create debug overlay for card tracking
	_setup_card_debug_overlay()


func _update_intent_bar() -> void:
	"""Update the intent bar with current battlefield threat information."""
	if not intent_bar or not CombatManager.battlefield:
		return
	
	var total_incoming: int = 0
	var bomber_count: int = 0
	var buffer_active: bool = false
	var buffer_amount: int = 0
	var spawner_active: bool = false
	var spawner_count: int = 0
	var fast_count: int = 0
	var bombers_in_close: int = 0
	
	# Analyze all enemies on the battlefield
	for ring: int in range(4):
		var enemies: Array = CombatManager.battlefield.get_enemies_in_ring(ring)
		
		for enemy in enemies:
			var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
			if not enemy_def:
				continue
			
			# Count incoming damage from melee enemies
			if ring == 0:
				total_incoming += enemy_def.get_scaled_damage(RunManager.current_wave)
			elif enemy_def.attack_type == "ranged" and ring <= enemy_def.attack_range and ring == enemy_def.target_ring:
				total_incoming += enemy_def.get_scaled_damage(RunManager.current_wave)
			
			# Check for bombers
			if enemy_def.behavior_type == EnemyDefinition.BehaviorType.BOMBER:
				bomber_count += 1
				if ring <= 1:  # Close or Melee
					bombers_in_close += 1
			
			# Check for active buffers
			if enemy_def.behavior_type == EnemyDefinition.BehaviorType.BUFFER:
				if ring <= enemy_def.target_ring:  # At or past target ring = active
					buffer_active = true
					buffer_amount += enemy_def.buff_amount
			
			# Check for active spawners
			if enemy_def.behavior_type == EnemyDefinition.BehaviorType.SPAWNER:
				if ring <= enemy_def.target_ring:  # At or past target ring = active
					spawner_active = true
					spawner_count += 1
			
			# Check for fast enemies
			if enemy_def.behavior_type == EnemyDefinition.BehaviorType.FAST:
				fast_count += 1
	
	# Update damage label
	intent_damage_label.text = str(total_incoming) + " Incoming"
	if total_incoming >= RunManager.current_hp:
		intent_damage_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif total_incoming > 10:
		intent_damage_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	else:
		intent_damage_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	# Update bomber label
	if bomber_count > 0:
		if bombers_in_close > 0:
			intent_bomber_label.text = str(bomber_count) + " Bombers (" + str(bombers_in_close) + " close!)"
			intent_bomber_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		else:
			intent_bomber_label.text = str(bomber_count) + " Bombers"
			intent_bomber_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		intent_bomber_label.get_parent().visible = true
	else:
		intent_bomber_label.get_parent().visible = false
	
	# Update buffer label
	if buffer_active:
		intent_buffer_label.text = "Buff Active (+" + str(buffer_amount) + ")"
		intent_buffer_label.add_theme_color_override("font_color", Color(1.0, 0.6, 1.0))
		intent_buffer_label.get_parent().visible = true
	else:
		intent_buffer_label.get_parent().visible = false
	
	# Update spawner label
	if spawner_active:
		intent_spawner_label.text = str(spawner_count) + " Spawning"
		intent_spawner_label.add_theme_color_override("font_color", Color(0.4, 1.0, 1.0))
		intent_spawner_label.get_parent().visible = true
	else:
		intent_spawner_label.get_parent().visible = false
	
	# Update fast enemies label
	if fast_count > 0:
		intent_fast_label.text = str(fast_count) + " Fast"
		intent_fast_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		intent_fast_label.get_parent().visible = true
	else:
		intent_fast_label.get_parent().visible = false


func _start_combat() -> void:
	# Start the wave
	RunManager.start_wave()
	
	# Create wave definition
	var wave_def: WaveDefinition = WaveDefinition.create_basic_wave(RunManager.current_wave)
	
	# Initialize combat
	CombatManager.initialize_combat(wave_def)
	
	_update_ui()


func _update_ui() -> void:
	_update_wave_info()
	_update_stats()
	_update_threat_preview()
	_update_intent_bar()
	_update_hand()
	_update_deck_info()


func _update_wave_info() -> void:
	wave_label.text = "Wave %d/%d" % [RunManager.current_wave, RunManager.MAX_WAVES]
	turn_label.text = "Turn %d" % CombatManager.current_turn
	
	if RunManager.is_elite_wave():
		wave_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
	elif RunManager.is_boss_wave():
		wave_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		wave_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))


func _update_stats() -> void:
	hp_label.text = "%d/%d" % [RunManager.current_hp, RunManager.max_hp]
	scrap_label.text = str(RunManager.scrap)
	
	# Update HP bar fill
	var hp_percent: float = float(RunManager.current_hp) / float(RunManager.max_hp)
	if hp_bar_fill:
		# Bar is 134 pixels wide (140 - 6 for margins)
		hp_bar_fill.size.x = 134.0 * hp_percent
		# Color gradient from green to red
		if hp_percent > 0.5:
			hp_bar_fill.color = Color(0.2, 0.85, 0.2, 1.0).lerp(Color(0.9, 0.9, 0.2, 1.0), 1.0 - (hp_percent - 0.5) * 2.0)
		else:
			hp_bar_fill.color = Color(0.9, 0.9, 0.2, 1.0).lerp(Color(0.85, 0.2, 0.2, 1.0), 1.0 - hp_percent * 2.0)
	
	# HP label color based on health
	if hp_percent <= 0.25:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif hp_percent <= 0.5:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	else:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	
	# Update armor display - hide if 0, show if > 0
	var current_armor: int = RunManager.armor
	armor_label.text = str(current_armor)
	if armor_section:
		armor_section.visible = current_armor > 0
		# Animate armor when it changes
		if current_armor > 0:
			armor_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))


func _update_threat_preview() -> void:
	if not CombatManager.battlefield:
		return
	
	var threat: Dictionary = CombatManager.calculate_incoming_damage()
	
	incoming_damage.text = str(threat.total)
	
	# Color based on severity
	if threat.total >= RunManager.current_hp:
		incoming_damage.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif threat.total >= RunManager.current_hp * 0.5:
		incoming_damage.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	else:
		incoming_damage.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
	
	# Build breakdown text
	var breakdown_text: String = ""
	for entry: Dictionary in threat.breakdown:
		breakdown_text += "%dx %s (%s): %d\n" % [
			entry.count,
			entry.name,
			BattlefieldStateScript.new().get_ring_name(entry.ring),
			entry.damage
		]
	threat_breakdown.text = breakdown_text
	
	# Enemies moving to melee
	var moving_count: int = CombatManager.get_enemies_moving_to_melee()
	moving_to_melee.text = "→ Melee next: %d" % moving_count
	
	# Update enemy counter
	_update_enemy_counter()


func _update_enemy_counter() -> void:
	if not CombatManager.battlefield:
		return
	
	var total: int = CombatManager.battlefield.get_total_enemy_count()
	var melee: int = CombatManager.battlefield.get_enemies_in_ring(0).size()
	var close: int = CombatManager.battlefield.get_enemies_in_ring(1).size()
	var mid: int = CombatManager.battlefield.get_enemies_in_ring(2).size()
	var far: int = CombatManager.battlefield.get_enemies_in_ring(3).size()
	
	total_enemies.text = str(total)
	melee_count.text = "Melee: %d" % melee
	close_count.text = "Close: %d" % close
	mid_count.text = "Mid: %d" % mid
	far_count.text = "Far: %d" % far


func _update_hand() -> void:
	# Clear existing cards - kill any active tweens first
	for child: Node in card_hand.get_children():
		if "active_tween" in child and child.active_tween and child.active_tween.is_valid():
			child.active_tween.kill()
			child.active_tween = null
		if "hover_tween" in child and child.hover_tween and child.hover_tween.is_valid():
			child.hover_tween.kill()
			child.hover_tween = null
		
		child.queue_free()
	
	if not CombatManager.deck_manager:
		return
	
	var hand_size: int = CombatManager.deck_manager.hand.size()
	if hand_size == 0:
		return
	
	# Ensure layout is computed before calculating positions
	# If card_hand size is not yet valid (< 100px), wait for a frame
	if card_hand.size.x < 100.0:
		await get_tree().process_frame
	
	# Calculate fan layout positions - center cards within the CardHand container
	# The CardHand container is designed to be centered on screen via the HBoxContainer layout
	# So centering within CardHand = centering on screen
	var local_center_x: float = card_hand.size.x / 2.0
	
	# Calculate card spacing based on number of cards
	var card_spacing: float = FAN_CARD_WIDTH * FAN_OVERLAP
	var total_width: float = (hand_size - 1) * card_spacing + FAN_CARD_WIDTH
	
	# Clamp to available width (leave margins on both sides)
	var margin: float = 80.0
	var max_width: float = card_hand.size.x - margin * 2.0
	if total_width > max_width and hand_size > 1:
		card_spacing = (max_width - FAN_CARD_WIDTH) / maxf(hand_size - 1, 1)
		total_width = (hand_size - 1) * card_spacing + FAN_CARD_WIDTH
	
	var start_x: float = local_center_x - total_width / 2.0
	
	# Base Y position - cards sit slightly below top of hand area
	var base_y: float = 60.0  # Distance from top of card_hand container
	
	# Create card UI for each card in hand
	for i: int in range(hand_size):
		var card_entry: Dictionary = CombatManager.deck_manager.hand[i]
		var card_def = CardDatabase.get_card(card_entry.card_id)  # CardDefinition
		
		if card_def:
			var card_ui: Control = card_ui_scene.instantiate()
			card_hand.add_child(card_ui)  # Add to tree first so @onready vars are initialized
			card_ui.setup(card_def, card_entry.tier, i)
			card_ui.card_clicked.connect(_on_card_clicked)
			card_ui.card_hovered.connect(_on_card_hovered)
			card_ui.card_drag_started.connect(_on_card_drag_started)
			card_ui.card_drag_ended.connect(_on_card_drag_ended)
			
			# Calculate fan position for this card
			var card_x: float = start_x + i * card_spacing
			
			# Calculate normalized position (-1 to 1, where 0 is center)
			var normalized_pos: float = 0.0
			if hand_size > 1:
				normalized_pos = (float(i) / float(hand_size - 1)) * 2.0 - 1.0
			
			# Calculate arc offset (cards in center are slightly higher)
			var arc_offset: float = normalized_pos * normalized_pos * FAN_ARC_HEIGHT
			var card_y: float = base_y + arc_offset
			
			# Calculate rotation (more rotation at edges)
			# Positive normalized_pos (right side) should rotate clockwise (positive)
			# Negative normalized_pos (left side) should rotate counter-clockwise (negative)
			var card_rotation: float = normalized_pos * FAN_MAX_ROTATION
			
			# Apply fan position
			card_ui.set_fan_position(i, hand_size, Vector2(card_x, card_y), card_rotation)


func _update_deck_info() -> void:
	if CombatManager.deck_manager:
		deck_count.text = str(CombatManager.deck_manager.get_deck_size())
		discard_count.text = str(CombatManager.deck_manager.get_discard_size())


func _refresh_enemy_displays() -> void:
	"""Refresh all enemy visuals to show updated HP, hex, etc."""
	if battlefield_arena and CombatManager.battlefield:
		for enemy in CombatManager.battlefield.get_all_enemies():
			battlefield_arena.update_enemy_hp(enemy)


func _on_phase_changed(phase: int) -> void:
	# Clear any lingering hover states on the battlefield (mini cards, tooltips, etc.)
	if battlefield_arena:
		battlefield_arena.clear_all_hover_states()
	
	match phase:
		CombatManager.CombatPhase.PLAYER_PHASE:
			end_turn_button.disabled = false
		CombatManager.CombatPhase.ENEMY_PHASE:
			end_turn_button.disabled = true
			_show_turn_banner("Enemy Turn")
		_:
			end_turn_button.disabled = true
	
	_update_ui()


func _on_turn_started(_turn: int) -> void:
	_show_turn_banner("Your Turn")
	_update_wave_info()
	_update_hand()
	_update_deck_info()


func _show_turn_banner(text: String) -> void:
	"""Show a banner that slides in and out using CombatOverlayBuilder."""
	CombatOverlayBuilder.create_turn_banner(self, text)


func _on_energy_changed(current: int, max_energy: int) -> void:
	energy_label.text = "%d/%d" % [current, max_energy]


func _on_health_changed(_current: int, _max_hp: int) -> void:
	_update_stats()


func _on_armor_changed(_amount: int) -> void:
	_update_stats()
	# Flash armor when it changes
	if armor_label:
		var tween: Tween = create_tween()
		tween.tween_property(armor_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(armor_label, "scale", Vector2.ONE, 0.15)


func _on_scrap_changed(amount: int) -> void:
	scrap_label.text = str(amount)


func _on_card_played(card, tier: int) -> void:
	# Check if this is a persistent weapon that should be deployed to the combat lane
	if card and card.effect_type == "weapon_persistent":
		# Get the card's visual position that was stored when the card was dropped
		# This is the ACTUAL position where the card appeared on screen when released
		var card_visual_pos: Vector2 = _last_weapon_card_position
		
		# Find the weapon data from CombatManager to get trigger duration
		var triggers: int = -1
		for weapon: Dictionary in CombatManager.active_weapons:
			if weapon.card_def.card_id == card.card_id:
				triggers = weapon.triggers_remaining
				break
		
		# Deploy to combat lane - animates from card's visual position to lane center
		if combat_lane:
			combat_lane.deploy_weapon(card, tier, triggers, card_visual_pos)
	
	# Update weapons text list display
	_update_weapons_display()


func _on_weapon_triggered(_card_name: String, _damage: int, _weapon_index: int) -> void:
	"""Called when a persistent weapon fires."""
	# CombatLane handles the visual effects via its own signal connection
	# No action needed here - this handler exists for potential future use
	pass


# Ring phase indicator reference
var ring_phase_indicator: Label = null


func _on_ring_phase_started(ring: int, _ring_name: String) -> void:
	"""Called when a specific ring starts processing during enemy turn."""
	# Update the battlefield to highlight the active ring
	if battlefield_arena and ring >= 0:
		battlefield_arena.highlight_ring(ring, true)
	
	# Show simple text indicator (disabled)
	#_show_simple_ring_indicator(ring_name)
	
	# Update UI to reflect current state
	_update_enemy_counter()
	_update_threat_preview()


func _on_ring_phase_ended(ring: int) -> void:
	"""Called when a specific ring finishes processing."""
	# Clear ring highlight
	if battlefield_arena and ring >= 0:
		battlefield_arena.highlight_ring(-1, false)
	
	# Update UI after each ring processes
	_update_enemy_counter()
	_update_threat_preview()
	_update_intent_bar()


func _on_enemy_attacking(_enemy, _damage: int) -> void:
	"""Called when an enemy is about to attack."""
	pass


func _on_enemy_moved(_enemy, _from_ring: int, _to_ring: int) -> void:
	"""Called when an enemy moves between rings."""
	_update_enemy_counter()
	_update_threat_preview()


func _on_player_damaged(_amount: int, _source: String) -> void:
	"""Called when the player takes damage."""
	_update_stats()


func _on_enemy_spawned(_enemy) -> void:
	"""Called when a new enemy spawns."""
	_update_enemy_counter()
	_update_threat_preview()
	_update_intent_bar()


func _show_simple_ring_indicator(ring_name: String) -> void:
	"""Show a simple indicator for which ring is being processed."""
	# Remove existing indicator
	if ring_phase_indicator and is_instance_valid(ring_phase_indicator):
		ring_phase_indicator.queue_free()
		ring_phase_indicator = null
	
	# Create simple label
	ring_phase_indicator = Label.new()
	ring_phase_indicator.text = ">> " + ring_name + " <<"
	ring_phase_indicator.add_theme_font_size_override("font_size", 24)
	ring_phase_indicator.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	ring_phase_indicator.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	ring_phase_indicator.add_theme_constant_override("outline_size", 3)
	ring_phase_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ring_phase_indicator.z_index = 100
	
	# Position at top center using simple positioning
	var viewport_size: Vector2 = get_viewport_rect().size
	ring_phase_indicator.position = Vector2(viewport_size.x / 2 - 80, 105)
	
	add_child(ring_phase_indicator)


func _update_weapons_display() -> void:
	"""Update the list of active persistent weapons in sidebar (text display)."""
	if weapons_list:
		for child in weapons_list.get_children():
			child.queue_free()
		
		if CombatManager.active_weapons.size() == 0:
			if weapons_section:
				weapons_section.visible = false
		else:
			if weapons_section:
				weapons_section.visible = true
			
			for weapon: Dictionary in CombatManager.active_weapons:
				var card_def = weapon.card_def
				var tier: int = weapon.tier
				var damage: int = card_def.get_scaled_value("damage", tier)
				
				var weapon_label: Label = Label.new()
				weapon_label.text = "⚡ " + card_def.card_name + " (" + str(damage) + " dmg)"
				weapon_label.add_theme_font_size_override("font_size", 11)
				weapon_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4, 1.0))
				weapons_list.add_child(weapon_label)


func _on_wave_ended(success: bool) -> void:
	print("[CombatScreen] Wave ended. Success: ", success)
	
	if success and RunManager.current_wave < RunManager.MAX_WAVES:
		# Restore HP to full after each successful wave
		RunManager.restore_hp_to_full()
		# Go directly to shop (skip reward screen)
		await get_tree().create_timer(1.0).timeout
		GameManager.go_to_shop()
	elif success:
		# Run victory!
		RunManager.restore_hp_to_full()
		await get_tree().create_timer(1.0).timeout
		GameManager.end_run(true)
	else:
		# Player died
		await get_tree().create_timer(1.0).timeout
		GameManager.end_run(false)


func _on_end_turn_pressed() -> void:
	CombatManager.end_player_turn()


func _on_card_clicked(card_def, tier: int, _hand_index: int) -> void:  # card_def: CardDefinition
	# All cards must now be dragged to play - show hint on click
	if CombatManager.current_phase != CombatManager.CombatPhase.PLAYER_PHASE:
		return
	
	if not CombatManager.can_play_card(card_def, tier):
		_show_cannot_play_hint()
		return
	
	# Show drag hint for all cards (different message for weapons)
	var is_weapon: bool = card_def.effect_type == "weapon_persistent"
	_show_drag_hint(is_weapon)


func _on_card_hovered(card_def, tier: int, is_hovering: bool) -> void:  # card_def: CardDefinition
	if is_hovering:
		# Show targeting hints on enemies that would be hit
		if battlefield_arena and card_def:
			battlefield_arena.show_card_targeting_hints(card_def, tier)
	else:
		# Clear targeting hints when mouse leaves card
		if battlefield_arena:
			battlefield_arena.clear_card_targeting_hints()


func _on_card_drag_started(card_def, _tier: int, hand_index: int) -> void:  # card_def: CardDefinition
	"""Called when player starts dragging a card."""
	pending_card_index = hand_index
	pending_card_def = card_def
	
	# All cards need to be dropped on a ring, so highlight for all
	dragging_card_def = card_def


func _on_card_drag_ended(card_def, tier: int, hand_index: int, drop_position: Vector2) -> void:  # card_def: CardDefinition
	"""Called when player releases a dragged card."""
	# Clear drag tracking and ring highlighting
	dragging_card_def = null
	_last_highlighted_ring = -1
	_highlight_all_mode = false
	_combat_lane_highlighted = false
	if battlefield_arena:
		battlefield_arena.highlight_all_rings(false)
	_highlight_combat_lane(false)  # Clear combat lane highlight
	
	if CombatManager.current_phase != CombatManager.CombatPhase.PLAYER_PHASE:
		pending_card_index = -1
		pending_card_def = null
		return
	
	if not CombatManager.can_play_card(card_def, tier):
		pending_card_index = -1
		pending_card_def = null
		return
	
	# First check: card must be dragged outside the hand area
	if not _is_outside_hand_area(drop_position):
		# Card wasn't dragged far enough out of hand area
		pending_card_index = -1
		pending_card_def = null
		return
	
	var target_ring: int = -1
	
	# Get the card UI to capture its actual visual position
	var card_ui_temp: Control = null
	if hand_index < card_hand.get_child_count():
		card_ui_temp = card_hand.get_child(hand_index)
	
	# Persistent weapons MUST be dropped on the combat lane (not battlefield)
	if card_def.effect_type == "weapon_persistent":
		if _is_over_combat_lane(drop_position):
			target_ring = -1  # Weapons don't need a ring target
			# Store the card's ACTUAL visual position (not mouse position) for weapon deployment
			if card_ui_temp:
				_last_weapon_card_position = card_ui_temp.global_position
			else:
				_last_weapon_card_position = drop_position  # Fallback to mouse position
		else:
			# Weapon dropped outside combat lane - reject
			pending_card_index = -1
			pending_card_def = null
			return
	else:
		# All other cards must be dropped on a valid ring on the battlefield
		if battlefield_arena:
			target_ring = battlefield_arena.get_ring_at_position(drop_position)
		
		if target_ring < 0:
			# Dropped outside valid ring area - cancel for all cards
			pending_card_index = -1
			pending_card_def = null
			return
		
		# For targeting cards: additionally check if the ring is valid for this specific card
		if card_def.requires_target:
			if card_def.target_rings.size() > 0 and target_ring not in card_def.target_rings:
				# Invalid ring for this card
				pending_card_index = -1
				pending_card_def = null
				return
	
	# Get the card UI for animation before playing
	var card_ui: Control = null
	if hand_index < card_hand.get_child_count():
		card_ui = card_hand.get_child(hand_index)
	
	# Mark card as being played to prevent return animation
	if card_ui:
		# Set flag to prevent return animation
		if "is_being_played" in card_ui:
			card_ui.is_being_played = true
		# Kill any existing tweens on the card
		if "active_tween" in card_ui and card_ui.active_tween and card_ui.active_tween.is_valid():
			card_ui.active_tween.kill()
			card_ui.active_tween = null
	
	print("[CombatScreen DEBUG] Playing card - card: ", card_def.card_name,
		  " | hand_index: ", hand_index, " | card_ui valid: ", is_instance_valid(card_ui),
		  " | card_ui global pos: ", card_ui.global_position if card_ui else Vector2.ZERO,
		  " | drop_position: ", drop_position)
	
	# Play card fly animation
	if card_ui:
		await _play_card_fly_animation(card_ui, drop_position, card_def.effect_type)
	
	# Play the card
	print("[CombatScreen DEBUG] ========== CALLING CombatManager.play_card ==========")
	print("[CombatScreen DEBUG] hand_index: ", hand_index, " | target_ring: ", target_ring)
	CombatManager.play_card(hand_index, target_ring)
	print("[CombatScreen DEBUG] CombatManager.play_card completed")
	
	_update_hand()
	_update_threat_preview()
	_refresh_enemy_displays()
	
	pending_card_index = -1
	pending_card_def = null


func _play_card_fly_animation(card_ui: Control, _drop_position: Vector2, _effect_type: String) -> void:
	"""Animate the card after being played.
	ALL cards: Fade in place from EXACT current position. No movement, no scale change, no reparenting.
	"""
	if not is_instance_valid(card_ui):
		return
	
	# Kill any existing tweens on the card first
	if "active_tween" in card_ui and card_ui.active_tween and card_ui.active_tween.is_valid():
		card_ui.active_tween.kill()
		card_ui.active_tween = null
	if "hover_tween" in card_ui and card_ui.hover_tween and card_ui.hover_tween.is_valid():
		card_ui.hover_tween.kill()
		card_ui.hover_tween = null
	
	# DO NOT reparent - this causes position shifts due to pivot_offset and coordinate space changes
	# Just raise z_index to ensure card is visible above siblings during fade
	card_ui.z_index = 100
	
	# Simply fade out from EXACTLY where the card is right now
	# No movement, no scale change, no position changes - JUST FADE
	var tween: Tween = card_ui.create_tween()
	tween.tween_property(card_ui, "modulate:a", 0.0, 0.2)
	
	# Store tween reference
	if "active_tween" in card_ui:
		card_ui.active_tween = tween
	
	await tween.finished
	
	# Clean up - remove the card
	if is_instance_valid(card_ui):
		card_ui.queue_free()


func _is_outside_hand_area(global_pos: Vector2) -> bool:
	"""Check if a position is outside the hand/card area (CardHand container)."""
	if not card_hand:
		return true
	
	# Get the global rect of the card hand area
	var hand_rect: Rect2 = card_hand.get_global_rect()
	
	# Add some margin - card needs to be dragged a bit above the hand area
	# Use the top of the card hand as the threshold
	var threshold_y: float = hand_rect.position.y + 50  # 50px into the hand area is the threshold
	
	# Card is "outside" if it's above the threshold
	return global_pos.y < threshold_y


func _is_over_combat_lane(global_pos: Vector2) -> bool:
	"""Check if a position is over the combat lane (for dropping persistent weapons)."""
	if not combat_lane:
		return false
	
	var lane_rect: Rect2 = combat_lane.get_global_rect()
	return lane_rect.has_point(global_pos)


func _highlight_combat_lane(highlight: bool) -> void:
	"""Highlight or unhighlight the combat lane for weapon drop targeting."""
	if not combat_lane:
		return
	
	if combat_lane.has_method("set_drop_highlight"):
		combat_lane.set_drop_highlight(highlight)


func _show_drag_hint(is_weapon: bool = false) -> void:
	"""Show a brief hint that this card should be dragged."""
	var hint: Label = Label.new()
	if is_weapon:
		hint.text = "Drag weapon onto combat lane to deploy"
	else:
		hint.text = "Drag card onto battlefield to play"
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	hint.add_theme_constant_override("outline_size", 3)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(get_viewport_rect().size.x / 2 - 150, get_viewport_rect().size.y - 300)
	add_child(hint)
	
	var tween: Tween = create_tween()
	tween.tween_property(hint, "modulate:a", 0.0, 1.5)
	tween.tween_callback(hint.queue_free)


func _show_cannot_play_hint() -> void:
	"""Show a hint that the card cannot be played (not enough energy)."""
	var hint: Label = Label.new()
	hint.text = "Not enough energy!"
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	hint.add_theme_constant_override("outline_size", 3)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(get_viewport_rect().size.x / 2 - 90, get_viewport_rect().size.y - 300)
	add_child(hint)
	
	var tween: Tween = create_tween()
	tween.tween_property(hint, "modulate:a", 0.0, 1.2)
	tween.tween_callback(hint.queue_free)


func _on_ring_selected(ring: int) -> void:
	# Fallback ring selector (kept for compatibility)
	ring_selector.visible = false
	
	if pending_card_index >= 0:
		CombatManager.play_card(pending_card_index, ring)
		_update_hand()
		_update_threat_preview()
	
	pending_card_index = -1
	pending_card_def = null


func _on_ring_cancel() -> void:
	ring_selector.visible = false
	pending_card_index = -1
	pending_card_def = null


# === Settings Overlay Functions ===

func _on_settings_pressed() -> void:
	AudioManager.play_button_click()
	_show_settings_overlay()


func _show_settings_overlay() -> void:
	_loading_settings = true
	
	# Load current settings values
	master_slider.value = SettingsManager.master_volume
	sfx_slider.value = SettingsManager.sfx_volume
	music_slider.value = SettingsManager.music_volume
	mute_check.button_pressed = SettingsManager.muted
	screen_shake_check.button_pressed = SettingsManager.screen_shake
	damage_numbers_check.button_pressed = SettingsManager.show_damage_numbers
	
	# Update labels
	master_value.text = str(int(SettingsManager.master_volume * 100)) + "%"
	sfx_value.text = str(int(SettingsManager.sfx_volume * 100)) + "%"
	music_value.text = str(int(SettingsManager.music_volume * 100)) + "%"
	
	_loading_settings = false
	settings_overlay.visible = true


func _hide_settings_overlay() -> void:
	settings_overlay.visible = false


func _on_master_volume_changed(value: float) -> void:
	master_value.text = str(int(value * 100)) + "%"
	if not _loading_settings:
		SettingsManager.set_master_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	sfx_value.text = str(int(value * 100)) + "%"
	if not _loading_settings:
		SettingsManager.set_sfx_volume(value)
		AudioManager.play_button_click()


func _on_music_volume_changed(value: float) -> void:
	music_value.text = str(int(value * 100)) + "%"
	if not _loading_settings:
		SettingsManager.set_music_volume(value)


func _on_mute_toggled(toggled_on: bool) -> void:
	if not _loading_settings:
		SettingsManager.set_muted(toggled_on)
		if not toggled_on:
			AudioManager.play_button_click()


func _on_screen_shake_toggled(toggled_on: bool) -> void:
	if not _loading_settings:
		SettingsManager.set_screen_shake(toggled_on)
		AudioManager.play_button_click()


func _on_damage_numbers_toggled(toggled_on: bool) -> void:
	if not _loading_settings:
		SettingsManager.set_show_damage_numbers(toggled_on)
		AudioManager.play_button_click()


func _on_settings_resume_pressed() -> void:
	AudioManager.play_button_click()
	_hide_settings_overlay()


func _on_settings_quit_pressed() -> void:
	AudioManager.play_button_click()
	_hide_settings_overlay()
	GameManager.return_to_main_menu()


# === Glossary Overlay Functions ===

func _on_glossary_pressed() -> void:
	AudioManager.play_button_click()
	_show_glossary_overlay()


func _on_glossary_close_pressed() -> void:
	AudioManager.play_button_click()
	_hide_glossary_overlay()


func _show_glossary_overlay() -> void:
	GlossaryData.populate_glossary_content(glossary_content)
	glossary_overlay.visible = true


func _hide_glossary_overlay() -> void:
	glossary_overlay.visible = false


# === Deck Viewer Overlay Functions ===

func _on_deck_view_pressed() -> void:
	"""Called when the deck view button is pressed."""
	AudioManager.play_button_click()
	_show_deck_viewer()


func _show_deck_viewer() -> void:
	"""Show the deck viewer overlay with all cards in the current run deck."""
	if not deck_viewer_overlay or not deck_viewer_grid:
		return
	
	# Clear existing cards
	for child: Node in deck_viewer_grid.get_children():
		child.queue_free()
	
	# Update title with card count
	deck_viewer_title.text = "📚 YOUR DECK (%d cards)" % RunManager.deck.size()
	
	# Populate with deck cards
	for i: int in range(RunManager.deck.size()):
		var entry: Dictionary = RunManager.deck[i]
		var card_def = CardDatabase.get_card(entry.card_id)
		if card_def:
			var card_ui: Control = card_ui_scene.instantiate()
			deck_viewer_grid.add_child(card_ui)
			card_ui.setup(card_def, entry.tier, i)
			# Make the card non-interactive (view only)
			card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Scale down slightly to fit more cards
			card_ui.scale = Vector2(0.85, 0.85)
	
	# Show empty message if deck is empty
	if RunManager.deck.size() == 0:
		var empty_label: Label = Label.new()
		empty_label.text = "Your deck is empty!"
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		deck_viewer_grid.add_child(empty_label)
	
	deck_viewer_overlay.visible = true


func _on_deck_viewer_close() -> void:
	"""Close the deck viewer overlay."""
	AudioManager.play_button_click()
	deck_viewer_overlay.visible = false


# === Dev Panel Functions ===

func _create_v2_debug_stat_panel() -> void:
	"""Create the V2 debug stat panel (toggle with F3)."""
	var debug_panel = DebugStatPanelClass.new()
	debug_panel.name = "V2DebugStatPanel"
	
	# Anchor to bottom-right corner
	# All anchors at 1.0 means positions are relative to parent's bottom-right
	debug_panel.anchor_left = 1.0
	debug_panel.anchor_right = 1.0
	debug_panel.anchor_top = 1.0
	debug_panel.anchor_bottom = 1.0
	
	# Offsets define the edges relative to the anchor point (bottom-right)
	# Panel width = 280, height = 400 (from custom_minimum_size)
	# We want: right edge 10px from right, bottom edge 390px from bottom
	var panel_width: float = 280.0
	var panel_height: float = 400.0
	var margin_right: float = 10.0
	var margin_bottom: float = 390.0  # Above the 380px hand area
	
	debug_panel.offset_right = -margin_right
	debug_panel.offset_left = -margin_right - panel_width
	debug_panel.offset_bottom = -margin_bottom
	debug_panel.offset_top = -margin_bottom - panel_height
	
	add_child(debug_panel)
	print("[CombatScreen] V2 Debug Stat Panel created (press F3 to toggle)")


func _dev_force_win() -> void:
	"""Force win the current wave by killing all enemies."""
	print("[DEV] Force Win triggered")
	if CombatManager.battlefield:
		# Kill all enemies on the battlefield
		var all_enemies: Array = CombatManager.battlefield.get_all_enemies()
		for enemy in all_enemies:
			CombatManager.battlefield.remove_enemy(enemy)
			CombatManager.enemy_killed.emit(enemy)
		
		# Trigger wave end check
		CombatManager._check_wave_end()


func _dev_force_lose() -> void:
	"""Force lose by setting player HP to 0."""
	print("[DEV] Force Lose triggered")
	RunManager.take_damage(RunManager.current_hp + RunManager.armor + 100)


func _dev_add_energy() -> void:
	"""Add 3 energy to the player."""
	print("[DEV] Add Energy triggered")
	CombatManager.current_energy += 3
	CombatManager.energy_changed.emit(CombatManager.current_energy, CombatManager.max_energy)


func _dev_add_scrap() -> void:
	"""Add 1000 scrap to the player."""
	print("[DEV] Add Scrap triggered")
	RunManager.add_scrap(1000)
