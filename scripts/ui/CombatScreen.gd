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

# UI References - Incoming wave preview
@onready var incoming_wave_content: VBoxContainer = $ThreatPreview/ThreatContent/IncomingWaveContent
@onready var no_spawns_label: Label = $ThreatPreview/ThreatContent/IncomingWaveContent/NoSpawnsLabel
@onready var spawns_remaining_label: Label = $ThreatPreview/ThreatContent/SpawnsRemainingLabel

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

# UI References - Tag Tracker panel (created dynamically)
var tag_tracker_panel: PanelContainer = null
var tag_tracker_content: VBoxContainer = null
var tag_labels: Dictionary = {}  # tag_name -> Label

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")
var levelup_picker_scene: PackedScene = preload("res://scenes/ui/LevelUpPicker.tscn")
var damage_tooltip_scene: PackedScene = preload("res://scenes/ui/DamageTooltip.tscn")
var levelup_picker: Control = null
var damage_tooltip: Control = null
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
	_setup_tag_tracker_panel()
	_create_v2_debug_stat_panel()
	_setup_animation_manager()
	_setup_levelup_picker()
	_setup_damage_tooltip()
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


func _setup_tag_tracker_panel() -> void:
	"""Create the tag tracker panel at bottom left, next to the energy/discard sidebar."""
	# Create panel container
	tag_tracker_panel = PanelContainer.new()
	tag_tracker_panel.name = "TagTrackerPanel"
	
	# Style the panel
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	panel_style.border_color = Color(0.3, 0.4, 0.5, 0.8)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(8)
	tag_tracker_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Position at bottom left, to the right of LeftSidebar (which is ~120px wide with margins)
	tag_tracker_panel.anchor_left = 0.0
	tag_tracker_panel.anchor_right = 0.0
	tag_tracker_panel.anchor_top = 1.0
	tag_tracker_panel.anchor_bottom = 1.0
	tag_tracker_panel.offset_left = 125  # Right of LeftSidebar
	tag_tracker_panel.offset_right = 275  # 150px wide
	tag_tracker_panel.offset_top = -290  # Aligned with BottomSection
	tag_tracker_panel.offset_bottom = -10
	tag_tracker_panel.custom_minimum_size = Vector2(150, 200)
	
	# Create content container
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	tag_tracker_panel.add_child(margin)
	
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	
	tag_tracker_content = VBoxContainer.new()
	tag_tracker_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(tag_tracker_content)
	
	# Add title
	var title: Label = Label.new()
	title.text = "📊 TAGS PLAYED"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_tracker_content.add_child(title)
	
	# Add separator
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	tag_tracker_content.add_child(sep)
	
	add_child(tag_tracker_panel)
	
	# Initialize with empty tracker
	_update_tag_tracker()


func _update_tag_tracker() -> void:
	"""Update the tag tracker display with current counts."""
	if not tag_tracker_content:
		return
	
	# Get current tags from CombatManager
	var tags_played: Dictionary = CombatManager.get_tags_played()
	
	# Clear existing tag labels (keep title and separator)
	while tag_tracker_content.get_child_count() > 2:
		var child: Node = tag_tracker_content.get_child(2)
		tag_tracker_content.remove_child(child)
		child.queue_free()
	
	tag_labels.clear()
	
	# If no tags, show placeholder
	if tags_played.is_empty():
		var placeholder: Label = Label.new()
		placeholder.text = "No tags played yet"
		placeholder.add_theme_font_size_override("font_size", 10)
		placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_tracker_content.add_child(placeholder)
		return
	
	# Sort tags by count (descending), then alphabetically
	var sorted_tags: Array = tags_played.keys()
	sorted_tags.sort_custom(func(a: String, b: String) -> bool:
		if tags_played[a] != tags_played[b]:
			return tags_played[a] > tags_played[b]
		return a < b
	)
	
	# Create label for each tag
	for tag: String in sorted_tags:
		var count: int = tags_played[tag]
		var tag_row: HBoxContainer = HBoxContainer.new()
		tag_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Tag icon/name
		var tag_label: Label = Label.new()
		tag_label.text = _get_tag_display_name(tag)
		tag_label.add_theme_font_size_override("font_size", 11)
		tag_label.add_theme_color_override("font_color", _get_tag_color(tag))
		tag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tag_label.clip_text = true
		tag_row.add_child(tag_label)
		
		# Count
		var count_label: Label = Label.new()
		count_label.text = "×" + str(count)
		count_label.add_theme_font_size_override("font_size", 11)
		count_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tag_row.add_child(count_label)
		
		tag_tracker_content.add_child(tag_row)
		tag_labels[tag] = count_label


func _get_tag_display_name(tag: String) -> String:
	"""Get display name with icon for a tag."""
	match tag:
		"gun":
			return "🔫 Gun"
		"hex":
			return "☠️ Hex"
		"barrier":
			return "🚧 Barrier"
		"defense":
			return "🛡️ Defense"
		"skill":
			return "✨ Skill"
		"buff":
			return "⬆️ Buff"
		"aoe":
			return "💥 AoE"
		"single_target":
			return "🎯 Single"
		"piercing":
			return "➡️ Piercing"
		"explosive":
			return "💣 Explosive"
		"beam":
			return "⚡ Beam"
		"sniper":
			return "🔭 Sniper"
		"shotgun":
			return "🔥 Shotgun"
		"scaling":
			return "📈 Scaling"
		"draw":
			return "📜 Draw"
		"heal":
			return "❤️ Heal"
		"armor":
			return "🛡️ Armor"
		"ring_control":
			return "↔️ Ring Ctrl"
		"rapid_fire":
			return "⚡ Rapid"
		"multi_target":
			return "🎯× Multi"
		"gun_support":
			return "🔧 Gun Supp"
		"damage_boost":
			return "⚔️ Dmg Boost"
		"hex_synergy":
			return "☠️+ Hex Syn"
		"utility":
			return "🔧 Utility"
		_:
			return tag.capitalize()


func _get_tag_color(tag: String) -> Color:
	"""Get color for a tag based on its type."""
	# Core types
	match tag:
		"gun":
			return Color(0.9, 0.5, 0.3)  # Orange
		"hex":
			return Color(0.7, 0.3, 0.9)  # Purple
		"barrier":
			return Color(0.9, 0.7, 0.3)  # Gold
		"defense":
			return Color(0.4, 0.7, 0.9)  # Cyan
		"skill":
			return Color(0.5, 0.9, 0.5)  # Green
		"buff":
			return Color(0.5, 0.7, 1.0)  # Blue
		"aoe", "explosive":
			return Color(1.0, 0.6, 0.2)  # Orange
		"piercing", "beam":
			return Color(0.9, 0.9, 0.4)  # Yellow
		"heal":
			return Color(0.4, 0.9, 0.4)  # Green
		"armor":
			return Color(0.6, 0.8, 1.0)  # Light blue
		_:
			return Color(0.8, 0.8, 0.8)  # Gray default


func _setup_animation_manager() -> void:
	"""Initialize the CombatAnimationManager with UI references."""
	if CombatAnimationManager:
		CombatAnimationManager.set_references(battlefield_arena, self, combat_lane)
	
	# Also set combat_lane reference on BattlefieldArena for weapon projectile origins
	if battlefield_arena:
		battlefield_arena.combat_lane = combat_lane


func _setup_levelup_picker() -> void:
	"""Create the Brotato-style level-up picker UI."""
	levelup_picker = levelup_picker_scene.instantiate()
	levelup_picker.name = "LevelUpPicker"
	# Add as top layer so it appears above everything
	add_child(levelup_picker)
	# Move to end so it renders on top
	move_child(levelup_picker, get_child_count() - 1)


func _setup_damage_tooltip() -> void:
	"""Create the damage calculation tooltip for cards."""
	damage_tooltip = damage_tooltip_scene.instantiate()
	damage_tooltip.name = "DamageTooltip"
	# Add as top layer so it appears above everything
	add_child(damage_tooltip)
	# Move to end so it renders on top
	move_child(damage_tooltip, get_child_count() - 1)


func _setup_card_debug_overlay() -> void:
	"""Debug overlay removed - using console logging instead."""
	# No visual overlay needed - all debugging via console
	pass




# These are kept for potential future use in ring highlighting system
@warning_ignore("unused_private_class_variable")
var _last_highlighted_ring: int = -2  # Use -2 so first check always triggers
@warning_ignore("unused_private_class_variable")
var _highlight_all_mode: bool = false  # Track if we're in "highlight all" mode
var _combat_lane_highlighted: bool = false  # Track if combat lane is highlighted for weapon drop
var _dragging_instant_ring_card: bool = false  # Track if dragging an instant ring-targeting card
var _highlighted_ring_for_drop: int = -1  # Track which ring is currently highlighted for drop

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
	# While dragging a card, provide visual feedback based on card type
	if dragging_card_def != null:
		var mouse_pos: Vector2 = get_global_mouse_position()
		
		# Check if this is an instant card that requires ring targeting
		if _dragging_instant_ring_card and battlefield_arena:
			# Highlight the ring under the mouse for instant ring-targeting cards
			var ring: int = battlefield_arena.get_ring_at_position(mouse_pos)
			
			# Only highlight valid target rings
			if ring >= 0 and ring in dragging_card_def.target_rings:
				if ring != _highlighted_ring_for_drop:
					# Clear previous highlight
					if _highlighted_ring_for_drop >= 0:
						battlefield_arena.highlight_ring(_highlighted_ring_for_drop, false)
					# Highlight new ring
					battlefield_arena.highlight_ring(ring, true)
					_highlighted_ring_for_drop = ring
			else:
				# Mouse not over a valid ring - clear highlight
				if _highlighted_ring_for_drop >= 0:
					battlefield_arena.highlight_ring(_highlighted_ring_for_drop, false)
					_highlighted_ring_for_drop = -1
		else:
			# V3: Combat cards go to the staging lane
			if combat_lane:
				var is_over_lane: bool = _is_over_combat_lane(mouse_pos)
				if is_over_lane and not _combat_lane_highlighted:
					_combat_lane_highlighted = true
					_highlight_combat_lane(true)
				elif not is_over_lane and _combat_lane_highlighted:
					_combat_lane_highlighted = false
					_highlight_combat_lane(false)


func _connect_signals() -> void:
	# CombatManager signals
	CombatManager.phase_changed.connect(_on_phase_changed)
	CombatManager.turn_started.connect(_on_turn_started)
	CombatManager.energy_changed.connect(_on_energy_changed)
	CombatManager.wave_ended.connect(_on_wave_ended)
	CombatManager.card_played.connect(_on_card_played)
	CombatManager.card_staged.connect(_on_card_staged)
	CombatManager.instant_card_played.connect(_on_instant_card_played)
	CombatManager.tag_played.connect(_on_tag_played)
	CombatManager.execution_started.connect(_on_execution_started)
	CombatManager.execution_completed.connect(_on_execution_completed)
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
	RunManager.level_up_queued.connect(_on_level_up_queued)
	
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
	
	# Check for test encounter from Encounter Designer first
	var wave_def: WaveDefinition = EncounterDesigner.load_test_wave()
	
	if wave_def:
		print("[CombatScreen] Loading TEST ENCOUNTER: ", wave_def.wave_name)
		# Clear the test file so subsequent plays don't use it
		if FileAccess.file_exists("user://test_encounter.json"):
			DirAccess.remove_absolute("user://test_encounter.json")
	else:
		# Create standard wave definition
		wave_def = WaveDefinition.create_basic_wave(RunManager.current_wave)
	
	# Initialize combat
	CombatManager.initialize_combat(wave_def)
	
	_update_ui()


func _update_ui() -> void:
	_update_wave_info()
	_update_stats()
	_update_threat_preview()
	_update_intent_bar()
	_update_incoming_wave_preview()
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


func _update_incoming_wave_preview() -> void:
	"""Update the incoming wave preview showing what enemies spawn next turn."""
	if not incoming_wave_content:
		return
	
	# Clear existing spawn labels (keep NoSpawnsLabel as first child)
	while incoming_wave_content.get_child_count() > 1:
		var child: Node = incoming_wave_content.get_child(1)
		incoming_wave_content.remove_child(child)
		child.queue_free()
	
	# Get next turn's spawns
	var next_spawns: Array[Dictionary] = CombatManager.get_spawns_for_next_turn()
	var spawns_remaining: int = CombatManager.get_total_spawns_remaining()
	
	# Update remaining label
	if spawns_remaining_label:
		if spawns_remaining > 0:
			spawns_remaining_label.text = "%d more incoming" % spawns_remaining
			spawns_remaining_label.visible = true
		else:
			spawns_remaining_label.text = "No more spawns"
			spawns_remaining_label.visible = true
	
	# Show/hide no spawns label
	if no_spawns_label:
		no_spawns_label.visible = next_spawns.is_empty()
	
	if next_spawns.is_empty():
		return
	
	# Consolidate spawns by enemy type for cleaner display
	var consolidated: Dictionary = {}  # enemy_id -> {name, count, ring}
	for spawn: Dictionary in next_spawns:
		var key: String = spawn.enemy_id
		if not consolidated.has(key):
			consolidated[key] = {
				"name": spawn.enemy_name,
				"count": 0,
				"ring": spawn.ring
			}
		consolidated[key].count += spawn.count
	
	# Ring names for display
	var ring_names: Array[String] = ["Melee", "Close", "Mid", "Far"]
	
	# Create labels for each spawn group
	for enemy_id: String in consolidated.keys():
		var data: Dictionary = consolidated[enemy_id]
		var spawn_label: Label = Label.new()
		
		# Format: "3× Husk (Far)"
		var ring_name: String = ring_names[data.ring] if data.ring >= 0 and data.ring < 4 else "?"
		spawn_label.text = "%d× %s (%s)" % [data.count, data.name, ring_name]
		spawn_label.add_theme_font_size_override("font_size", 11)
		
		# Color based on threat level
		var enemy_def = EnemyDatabase.get_enemy(enemy_id)
		if enemy_def:
			match enemy_def.behavior_type:
				EnemyDefinition.BehaviorType.BOMBER:
					spawn_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))  # Orange
				EnemyDefinition.BehaviorType.BUFFER:
					spawn_label.add_theme_color_override("font_color", Color(1.0, 0.6, 1.0))  # Pink
				EnemyDefinition.BehaviorType.SPAWNER:
					spawn_label.add_theme_color_override("font_color", Color(0.4, 1.0, 1.0))  # Cyan
				EnemyDefinition.BehaviorType.FAST:
					spawn_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))  # Yellow
				EnemyDefinition.BehaviorType.TANK:
					spawn_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))  # Light blue
				_:
					spawn_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))  # Light green
		else:
			spawn_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
		
		incoming_wave_content.add_child(spawn_label)


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


func _on_level_up_queued(new_level: int) -> void:
	"""Flash a level-up notification banner when level-up is queued during combat."""
	print("[CombatScreen] Level up queued! New level: ", new_level)
	_show_levelup_flash_banner(new_level)


func _show_levelup_flash_banner(new_level: int) -> void:
	"""Show a brief flash banner for level-up notification."""
	var banner: PanelContainer = PanelContainer.new()
	banner.name = "LevelUpFlashBanner"
	
	# Style the banner
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.25, 0.95)
	style.border_color = Color(1.0, 0.85, 0.3, 1.0)  # Gold border
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(15)
	banner.add_theme_stylebox_override("panel", style)
	
	# Position at top-center
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.offset_top = 80
	banner.offset_bottom = 140
	banner.offset_left = -150
	banner.offset_right = 150
	
	# Content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	banner.add_child(vbox)
	
	var title: Label = Label.new()
	title.text = "⭐ LEVEL UP!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))  # Gold
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)
	
	var level_lbl: Label = Label.new()
	level_lbl.text = "Level %d" % new_level
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.add_theme_font_size_override("font_size", 16)
	level_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	vbox.add_child(level_lbl)
	
	add_child(banner)
	move_child(banner, get_child_count() - 1)
	
	# Animation: fade in, pulse scale, hold, then fade out
	banner.modulate.a = 0.0
	banner.scale = Vector2(0.8, 0.8)
	banner.pivot_offset = banner.size / 2
	
	var tween: Tween = create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(banner, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(1.5)  # Hold for 1.5 seconds
	tween.tween_property(banner, "modulate:a", 0.0, 0.3)
	tween.tween_callback(banner.queue_free)


func _on_card_played(_card, _tier: int) -> void:
	# V3: Card played just updates the hand display
	_update_hand()


func _on_card_staged(card_def, tier: int, _lane_index: int) -> void:
	"""V3: Card was staged to the combat lane."""
	# Deploy visual to combat lane
	if combat_lane:
		combat_lane.stage_card(card_def, tier, _last_weapon_card_position)
	
	_update_hand()


func _on_instant_card_played(_card_def, _tier: int) -> void:
	"""V3: Instant card was played and resolved immediately."""
	# Instant cards don't go to staging lane, just update hand
	_update_hand()
	_update_stats()
	_update_threat_preview()
	_update_intent_bar()
	_refresh_enemy_displays()


func _on_tag_played(_tag: String) -> void:
	"""Update the tag tracker when a tag is played."""
	_update_tag_tracker()


func _on_execution_started() -> void:
	"""V3: Combat lane execution started."""
	end_turn_button.disabled = true


func _on_execution_completed() -> void:
	"""V3: Combat lane execution completed."""
	_update_hand()
	_update_threat_preview()
	_update_intent_bar()
	_refresh_enemy_displays()


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
	"""V3: Update the staged cards count in sidebar (simplified)."""
	# V3: Weapons section shows staged card count instead of persistent weapons
	if weapons_section:
		var staged_count: int = CombatManager.get_staged_card_count()
		weapons_section.visible = staged_count > 0
		
		if weapons_list:
			for child in weapons_list.get_children():
				child.queue_free()
			
			if staged_count > 0:
				var staged_label: Label = Label.new()
				staged_label.text = "⚔️ %d cards staged" % staged_count
				staged_label.add_theme_font_size_override("font_size", 11)
				staged_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5, 1.0))
				weapons_list.add_child(staged_label)


func _on_wave_ended(success: bool) -> void:
	print("[CombatScreen] Wave ended. Success: ", success)
	
	if success and RunManager.current_wave < RunManager.MAX_WAVES:
		# Restore HP to full after each successful wave
		RunManager.restore_hp_to_full()
		await get_tree().create_timer(1.0).timeout
		
		# Check for pending level-ups before going to shop
		if RunManager.has_pending_levelups():
			print("[CombatScreen] Has pending level-ups, showing picker before shop")
			# Connect to all_levelups_resolved to know when to proceed
			if not RunManager.all_levelups_resolved.is_connected(_on_levelups_resolved_go_to_shop):
				RunManager.all_levelups_resolved.connect(_on_levelups_resolved_go_to_shop, CONNECT_ONE_SHOT)
			# Trigger the level-up picker
			RunManager.trigger_pending_levelups()
		else:
			# No pending level-ups, go directly to shop
			GameManager.go_to_shop()
	elif success:
		# Run victory!
		RunManager.restore_hp_to_full()
		await get_tree().create_timer(1.0).timeout
		
		# Check for pending level-ups before ending run
		if RunManager.has_pending_levelups():
			if not RunManager.all_levelups_resolved.is_connected(_on_levelups_resolved_end_run_victory):
				RunManager.all_levelups_resolved.connect(_on_levelups_resolved_end_run_victory, CONNECT_ONE_SHOT)
			RunManager.trigger_pending_levelups()
		else:
			GameManager.end_run(true)
	else:
		# Player died - no level-up choices when you die
		await get_tree().create_timer(1.0).timeout
		GameManager.end_run(false)


func _on_levelups_resolved_go_to_shop() -> void:
	"""Called when all level-up choices are made - proceed to shop."""
	print("[CombatScreen] All level-ups resolved, going to shop")
	GameManager.go_to_shop()


func _on_levelups_resolved_end_run_victory() -> void:
	"""Called when all level-up choices are made on final wave - end run."""
	print("[CombatScreen] All level-ups resolved, ending run with victory")
	GameManager.end_run(true)


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
		
		# Show damage calculation tooltip
		if damage_tooltip and card_def:
			# Position tooltip near the card (offset to the right)
			var mouse_pos: Vector2 = get_global_mouse_position()
			var tooltip_pos: Vector2 = mouse_pos + Vector2(20, -100)
			damage_tooltip.show_tooltip(card_def, tier, tooltip_pos)
	else:
		# Clear targeting hints when mouse leaves card
		if battlefield_arena:
			battlefield_arena.clear_card_targeting_hints()
		
		# Hide damage tooltip
		if damage_tooltip:
			damage_tooltip.hide_tooltip()


func _on_card_drag_started(card_def, _tier: int, hand_index: int) -> void:  # card_def: CardDefinition
	"""Called when player starts dragging a card."""
	pending_card_index = hand_index
	pending_card_def = card_def
	
	# Hide tooltip when dragging
	if damage_tooltip:
		damage_tooltip.hide_tooltip()
	
	# Track the card being dragged
	dragging_card_def = card_def
	
	# Check if this is an instant card that requires ring targeting
	_dragging_instant_ring_card = card_def.requires_ring_target() if card_def.has_method("requires_ring_target") else false
	_highlighted_ring_for_drop = -1


func _on_card_drag_ended(card_def, tier: int, hand_index: int, drop_position: Vector2) -> void:
	"""V3: Called when player releases a dragged card - stages to combat lane or plays instantly."""
	# Store instant ring targeting state before clearing
	var was_instant_ring_card: bool = _dragging_instant_ring_card
	var target_ring: int = _highlighted_ring_for_drop
	
	# Clear drag tracking and lane highlighting
	dragging_card_def = null
	_combat_lane_highlighted = false
	_highlight_combat_lane(false)
	_dragging_instant_ring_card = false
	
	# Clear ring highlight
	if _highlighted_ring_for_drop >= 0 and battlefield_arena:
		battlefield_arena.highlight_ring(_highlighted_ring_for_drop, false)
	_highlighted_ring_for_drop = -1
	
	if CombatManager.current_phase != CombatManager.CombatPhase.PLAYER_PHASE:
		pending_card_index = -1
		pending_card_def = null
		return
	
	if not CombatManager.can_stage_card(card_def, tier):
		pending_card_index = -1
		pending_card_def = null
		return
	
	# Card must be dragged outside the hand area
	if not _is_outside_hand_area(drop_position):
		pending_card_index = -1
		pending_card_def = null
		return
	
	# Determine card type and target
	var is_instant: bool = card_def.is_instant() if card_def.has_method("is_instant") else false
	var requires_ring: bool = card_def.requires_ring_target() if card_def.has_method("requires_ring_target") else false
	
	# INSTANT RING-TARGETING cards: must be dropped on a valid ring
	if was_instant_ring_card and requires_ring:
		if target_ring < 0 or target_ring not in card_def.target_rings:
			# Not dropped on a valid ring - cancel
			pending_card_index = -1
			pending_card_def = null
			return
	# COMBAT cards: must be dropped on the combat lane
	elif not is_instant and not _is_over_combat_lane(drop_position):
		pending_card_index = -1
		pending_card_def = null
		return
	
	# Get the card UI for animation
	var card_ui: Control = null
	if hand_index < card_hand.get_child_count():
		card_ui = card_hand.get_child(hand_index)
	
	# Store visual position for staging animation
	if card_ui:
		_last_weapon_card_position = card_ui.global_position
		
		# Mark card as being played to prevent return animation
		if "is_being_played" in card_ui:
			card_ui.is_being_played = true
		# Kill any existing tweens
		if "active_tween" in card_ui and card_ui.active_tween and card_ui.active_tween.is_valid():
			card_ui.active_tween.kill()
			card_ui.active_tween = null
	else:
		_last_weapon_card_position = drop_position
	
	# Play card fly animation
	if card_ui:
		await _play_card_fly_animation(card_ui, drop_position, card_def.effect_type)
	
	# V3: Stage the card (CombatManager handles instant vs combat internally)
	# For instant ring-targeting cards, pass the target ring
	if requires_ring and target_ring >= 0:
		var card_type_str: String = "INSTANT (Ring %d)" % target_ring
		print("[CombatScreen] Playing %s card: %s at hand_index: %d" % [card_type_str, card_def.card_name, hand_index])
		CombatManager.stage_card(hand_index, target_ring)
	else:
		var card_type_str: String = "INSTANT" if is_instant else "COMBAT"
		print("[CombatScreen] Playing %s card: %s at hand_index: %d" % [card_type_str, card_def.card_name, hand_index])
		CombatManager.stage_card(hand_index)
	
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


func _show_drag_hint(_is_weapon: bool = false) -> void:
	"""Show a brief hint that this card should be dragged."""
	var hint: Label = Label.new()
	# V3: All cards go to staging lane
	hint.text = "Drag cards to staging lane, then click EXECUTE"
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
