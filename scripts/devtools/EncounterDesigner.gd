extends Control
class_name EncounterDesigner
## Encounter Designer Dev Tool
## Design and test custom wave encounters with full control over:
## - Wave settings (name, turn limit, flags, multipliers)
## - Spawn groups (enemy type, count, ring, turn, lane)
## - Visual preview of the battlefield
## - Player configuration (warden, deck, stats)
## - Export to WaveDefinition or JSON

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")
const WardenDef = preload("res://scripts/resources/WardenDefinition.gd")

# ==============================================================================
# SIGNALS
# ==============================================================================
signal encounter_saved(wave_def: WaveDefinition)
signal encounter_loaded(wave_def: WaveDefinition)

# ==============================================================================
# UI REFERENCES
# ==============================================================================

# Wave Settings Panel
@onready var wave_number_spin: SpinBox = %WaveNumberSpin
@onready var wave_name_edit: LineEdit = %WaveNameEdit
@onready var wave_desc_edit: TextEdit = %WaveDescEdit
@onready var turn_limit_spin: SpinBox = %TurnLimitSpin
@onready var hp_mult_spin: SpinBox = %HPMultSpin
@onready var dmg_mult_spin: SpinBox = %DmgMultSpin
@onready var scrap_bonus_spin: SpinBox = %ScrapBonusSpin
@onready var elite_check: CheckBox = %EliteCheck
@onready var boss_check: CheckBox = %BossCheck
@onready var horde_check: CheckBox = %HordeCheck

# Spawn List Panel
@onready var spawn_list_container: VBoxContainer = %SpawnListContainer
@onready var add_spawn_btn: Button = %AddSpawnBtn

# Preview Panel
@onready var preview_container: Control = %PreviewContainer
@onready var turn_slider: HSlider = %TurnSlider
@onready var turn_label: Label = %TurnLabel
@onready var total_enemies_label: Label = %TotalEnemiesLabel
@onready var preview_ring_melee: Panel = %PreviewRingMelee
@onready var preview_ring_close: Panel = %PreviewRingClose
@onready var preview_ring_mid: Panel = %PreviewRingMid
@onready var preview_ring_far: Panel = %PreviewRingFar

# Timeline Panel
@onready var timeline_container: HBoxContainer = %TimelineContainer

# Action Buttons
@onready var back_btn: Button = %BackBtn
@onready var new_btn: Button = %NewBtn
@onready var load_btn: Button = %LoadBtn
@onready var save_btn: Button = %SaveBtn
@onready var export_json_btn: Button = %ExportJSONBtn
@onready var test_btn: Button = %TestBtn
@onready var load_wave_dropdown: OptionButton = %LoadWaveDropdown

# Player Config Panel (created dynamically)
var player_config_panel: PanelContainer = null
var warden_dropdown: OptionButton = null
var energy_spin: SpinBox = null
var max_hp_spin: SpinBox = null
var current_hp_spin: SpinBox = null
var armor_spin: SpinBox = null
var scrap_spin: SpinBox = null
var deck_list: VBoxContainer = null
var add_card_dropdown: OptionButton = null
var add_card_btn: Button = null

# ==============================================================================
# STATE
# ==============================================================================
var spawn_entries: Array[Dictionary] = []  # Array of spawn data
var spawn_ui_items: Array[Control] = []  # Array of UI item nodes
var current_preview_turn: int = 1
var enemy_icons: Dictionary = {}  # enemy_id -> icon emoji

# Player config state
var wardens: Array = []  # Array of WardenDefinition
var selected_warden_index: int = 3  # Default to Veteran (index 3)
var custom_deck: Array[Dictionary] = []  # Array of {card_id: String, tier: int}

# Preload the spawn entry scene
var SpawnEntryScene: PackedScene = null

# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_populate_enemy_icons()
	_populate_wave_dropdown()
	_create_wardens()
	_create_player_config_panel()
	_create_new_encounter()


func _setup_ui() -> void:
	# Set default values
	wave_number_spin.min_value = 1
	wave_number_spin.max_value = 100
	wave_number_spin.value = 1
	
	turn_limit_spin.min_value = 1
	turn_limit_spin.max_value = 20
	turn_limit_spin.value = 6
	
	hp_mult_spin.min_value = 0.1
	hp_mult_spin.max_value = 5.0
	hp_mult_spin.step = 0.05
	hp_mult_spin.value = 1.0
	
	dmg_mult_spin.min_value = 0.1
	dmg_mult_spin.max_value = 5.0
	dmg_mult_spin.step = 0.05
	dmg_mult_spin.value = 1.0
	
	scrap_bonus_spin.min_value = 0
	scrap_bonus_spin.max_value = 500
	scrap_bonus_spin.value = 0
	
	turn_slider.min_value = 1
	turn_slider.max_value = 6
	turn_slider.value = 1


func _connect_signals() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	add_spawn_btn.pressed.connect(_on_add_spawn_pressed)
	new_btn.pressed.connect(_create_new_encounter)
	load_btn.pressed.connect(_on_load_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	export_json_btn.pressed.connect(_on_export_json_pressed)
	test_btn.pressed.connect(_on_test_pressed)
	
	turn_slider.value_changed.connect(_on_turn_slider_changed)
	turn_limit_spin.value_changed.connect(_on_turn_limit_changed)
	
	# Update preview when any setting changes
	wave_number_spin.value_changed.connect(func(_v: float) -> void: _update_preview())
	hp_mult_spin.value_changed.connect(func(_v: float) -> void: _update_preview())
	dmg_mult_spin.value_changed.connect(func(_v: float) -> void: _update_preview())


func _populate_enemy_icons() -> void:
	"""Cache enemy icons from database."""
	for enemy_id: String in EnemyDatabase.get_all_enemies():
		var enemy_def = EnemyDatabase.get_enemy(enemy_id)
		if enemy_def:
			enemy_icons[enemy_id] = enemy_def.display_icon


func _populate_wave_dropdown() -> void:
	"""Populate dropdown with existing wave numbers."""
	load_wave_dropdown.clear()
	load_wave_dropdown.add_item("Select Wave...", 0)
	for i: int in range(1, 21):
		load_wave_dropdown.add_item("Wave " + str(i), i)


func _create_wardens() -> void:
	"""Create warden definitions for selection."""
	wardens.clear()
	
	# Ash Warden
	var ash: WardenDef = WardenDef.new()
	ash.warden_id = "ash_warden"
	ash.warden_name = "Ash Warden"
	ash.icon = "🔥"
	ash.stat_modifiers = {"max_hp": 5, "energy_per_turn": 1, "gun_damage_percent": 15.0}
	ash.starting_deck = [{"card_id": "shotgun", "tier": 1, "count": 1}]
	wardens.append(ash)
	
	# Gloom Warden
	var gloom: WardenDef = WardenDef.new()
	gloom.warden_id = "gloom_warden"
	gloom.warden_name = "Gloom Warden"
	gloom.icon = "🌑"
	gloom.stat_modifiers = {"max_hp": 5, "energy_per_turn": 1, "hex_damage_percent": 20.0}
	gloom.starting_deck = [{"card_id": "hex_bolt", "tier": 1, "count": 1}]
	wardens.append(gloom)
	
	# Glass Warden
	var glass: WardenDef = WardenDef.new()
	glass.warden_id = "glass_warden"
	glass.warden_name = "Glass Warden"
	glass.icon = "💎"
	glass.stat_modifiers = {"max_hp": 10, "armor_gain_percent": 25.0}
	glass.passive_id = "cheat_death"
	glass.starting_deck = [{"card_id": "shield_bash", "tier": 1, "count": 1}]
	wardens.append(glass)
	
	# Veteran Warden (DEFAULT)
	var veteran: WardenDef = WardenDef.new()
	veteran.warden_id = "veteran_warden"
	veteran.warden_name = "Veteran Warden"
	veteran.icon = "⚔️"
	veteran.stat_modifiers = {"max_hp": 5, "energy_per_turn": 1}
	veteran.starting_deck = [{"card_id": "pistol", "tier": 1, "count": 1}]
	wardens.append(veteran)
	
	selected_warden_index = 3  # Default to Veteran


func _create_player_config_panel() -> void:
	"""Create the player configuration panel dynamically."""
	# Find the right panel in the scene - insert after WaveSettingsPanel
	var left_panel: VBoxContainer = $MainContainer/VBox/MainSplit/LeftPanel
	if not left_panel:
		push_warning("[EncounterDesigner] Could not find LeftPanel for player config")
		return
	
	# Create player config panel
	player_config_panel = PanelContainer.new()
	player_config_panel.name = "PlayerConfigPanel"
	player_config_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	player_config_panel.add_child(vbox)
	
	# Header
	var header: Label = Label.new()
	header.text = "🎮 Player Configuration"
	header.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)
	
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Warden Selection Row
	var warden_row: HBoxContainer = _create_config_row("Warden:", 80)
	vbox.add_child(warden_row)
	
	warden_dropdown = OptionButton.new()
	warden_dropdown.custom_minimum_size.x = 180
	for i: int in range(wardens.size()):
		var w = wardens[i]
		warden_dropdown.add_item("%s %s" % [w.icon, w.warden_name], i)
	warden_dropdown.selected = selected_warden_index
	warden_dropdown.item_selected.connect(_on_warden_selected)
	warden_row.add_child(warden_dropdown)
	
	# Stats Row 1: Energy, Max HP
	var stats_row1: HBoxContainer = _create_config_row("Energy:", 60)
	vbox.add_child(stats_row1)
	
	energy_spin = SpinBox.new()
	energy_spin.min_value = 1
	energy_spin.max_value = 20
	energy_spin.value = 1
	energy_spin.custom_minimum_size.x = 60
	stats_row1.add_child(energy_spin)
	
	var hp_label: Label = Label.new()
	hp_label.text = "  Max HP:"
	hp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	stats_row1.add_child(hp_label)
	
	max_hp_spin = SpinBox.new()
	max_hp_spin.min_value = 1
	max_hp_spin.max_value = 500
	max_hp_spin.value = 25
	max_hp_spin.custom_minimum_size.x = 70
	max_hp_spin.value_changed.connect(func(v: float) -> void: _sync_hp_to_max(v))
	stats_row1.add_child(max_hp_spin)
	
	# Stats Row 2: Current HP, Armor
	var stats_row2: HBoxContainer = _create_config_row("HP:", 60)
	vbox.add_child(stats_row2)
	
	current_hp_spin = SpinBox.new()
	current_hp_spin.min_value = 1
	current_hp_spin.max_value = 500
	current_hp_spin.value = 25
	current_hp_spin.custom_minimum_size.x = 60
	stats_row2.add_child(current_hp_spin)
	
	var armor_label: Label = Label.new()
	armor_label.text = "  Armor:"
	armor_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	stats_row2.add_child(armor_label)
	
	armor_spin = SpinBox.new()
	armor_spin.min_value = 0
	armor_spin.max_value = 100
	armor_spin.value = 0
	armor_spin.custom_minimum_size.x = 60
	stats_row2.add_child(armor_spin)
	
	var scrap_label: Label = Label.new()
	scrap_label.text = "  Scrap:"
	scrap_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	stats_row2.add_child(scrap_label)
	
	scrap_spin = SpinBox.new()
	scrap_spin.min_value = 0
	scrap_spin.max_value = 9999
	scrap_spin.value = 0
	scrap_spin.custom_minimum_size.x = 70
	stats_row2.add_child(scrap_spin)
	
	# Deck Section Header
	var deck_header: HBoxContainer = HBoxContainer.new()
	vbox.add_child(deck_header)
	
	var deck_label: Label = Label.new()
	deck_label.text = "📋 Custom Deck"
	deck_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	deck_label.add_theme_font_size_override("font_size", 13)
	deck_header.add_child(deck_label)
	
	var deck_spacer: Control = Control.new()
	deck_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_header.add_child(deck_spacer)
	
	var clear_deck_btn: Button = Button.new()
	clear_deck_btn.text = "Clear"
	clear_deck_btn.pressed.connect(_on_clear_deck_pressed)
	deck_header.add_child(clear_deck_btn)
	
	# Add Card Row
	var add_card_row: HBoxContainer = HBoxContainer.new()
	add_card_row.add_theme_constant_override("separation", 4)
	vbox.add_child(add_card_row)
	
	add_card_dropdown = OptionButton.new()
	add_card_dropdown.custom_minimum_size.x = 200
	add_card_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_card_dropdown()
	add_card_row.add_child(add_card_dropdown)
	
	add_card_btn = Button.new()
	add_card_btn.text = "+ Add"
	add_card_btn.pressed.connect(_on_add_card_pressed)
	add_card_row.add_child(add_card_btn)
	
	# Deck List (scrollable)
	var deck_scroll: ScrollContainer = ScrollContainer.new()
	deck_scroll.custom_minimum_size.y = 100
	deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(deck_scroll)
	
	deck_list = VBoxContainer.new()
	deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_scroll.add_child(deck_list)
	
	# Insert after WaveSettingsPanel (index 0), before SpawnListPanel
	left_panel.add_child(player_config_panel)
	left_panel.move_child(player_config_panel, 1)
	
	# Initialize with warden's starter deck
	_load_warden_starter_deck()


func _create_config_row(label_text: String, label_width: int) -> HBoxContainer:
	"""Create a config row with a label."""
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = label_width
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	row.add_child(label)
	
	return row


func _sync_hp_to_max(max_val: float) -> void:
	"""Sync current HP max limit to max HP value."""
	if current_hp_spin:
		current_hp_spin.max_value = max_val
		if current_hp_spin.value > max_val:
			current_hp_spin.value = max_val


func _populate_card_dropdown() -> void:
	"""Populate the card dropdown with all available cards."""
	if not add_card_dropdown:
		return
	
	add_card_dropdown.clear()
	var all_cards: Array = CardDatabase.get_all_cards()
	
	# Sort alphabetically by name
	all_cards.sort_custom(func(a, b) -> bool: return a.card_name < b.card_name)
	
	for card in all_cards:
		var display_name: String = "%s (%d⚡)" % [card.card_name, card.base_cost]
		add_card_dropdown.add_item(display_name)
		add_card_dropdown.set_item_metadata(add_card_dropdown.item_count - 1, card.card_id)


func _on_warden_selected(idx: int) -> void:
	"""Handle warden selection change."""
	selected_warden_index = idx
	_load_warden_starter_deck()


func _load_warden_starter_deck() -> void:
	"""Load the selected warden's starter deck."""
	custom_deck.clear()
	
	if selected_warden_index >= 0 and selected_warden_index < wardens.size():
		var warden = wardens[selected_warden_index]
		for entry: Dictionary in warden.starting_deck:
			var card_id: String = entry.get("card_id", "")
			var count: int = entry.get("count", 1)
			var tier: int = entry.get("tier", 1)
			for i: int in range(count):
				custom_deck.append({"card_id": card_id, "tier": tier})
	
	_update_deck_list_ui()


func _on_add_card_pressed() -> void:
	"""Add the selected card to the custom deck."""
	if not add_card_dropdown or add_card_dropdown.selected < 0:
		return
	
	var card_id: String = add_card_dropdown.get_item_metadata(add_card_dropdown.selected)
	if card_id.is_empty():
		return
	
	custom_deck.append({"card_id": card_id, "tier": 1})
	_update_deck_list_ui()


func _on_clear_deck_pressed() -> void:
	"""Clear the custom deck."""
	custom_deck.clear()
	_update_deck_list_ui()


func _on_remove_card_pressed(idx: int) -> void:
	"""Remove a card from the custom deck."""
	if idx >= 0 and idx < custom_deck.size():
		custom_deck.remove_at(idx)
		_update_deck_list_ui()


func _update_deck_list_ui() -> void:
	"""Update the deck list UI to show current cards."""
	if not deck_list:
		return
	
	# Clear existing
	for child: Node in deck_list.get_children():
		child.queue_free()
	
	if custom_deck.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "(Empty - add cards above)"
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		deck_list.add_child(empty_label)
		return
	
	# Show each card
	for i: int in range(custom_deck.size()):
		var entry: Dictionary = custom_deck[i]
		var card_def = CardDatabase.get_card(entry.card_id)
		if not card_def:
			continue
		
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		deck_list.add_child(row)
		
		var name_label: Label = Label.new()
		name_label.text = "%d. %s" % [i + 1, card_def.card_name]
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		row.add_child(name_label)
		
		var remove_btn: Button = Button.new()
		remove_btn.text = "×"
		remove_btn.custom_minimum_size = Vector2(24, 20)
		remove_btn.pressed.connect(func() -> void: _on_remove_card_pressed(i))
		row.add_child(remove_btn)


# ==============================================================================
# ENCOUNTER MANAGEMENT
# ==============================================================================

func _create_new_encounter() -> void:
	"""Reset to a fresh empty encounter."""
	wave_number_spin.value = 1
	wave_name_edit.text = "New Encounter"
	wave_desc_edit.text = "Enter encounter description..."
	turn_limit_spin.value = 6
	hp_mult_spin.value = 1.0
	dmg_mult_spin.value = 1.0
	scrap_bonus_spin.value = 0
	elite_check.button_pressed = false
	boss_check.button_pressed = false
	horde_check.button_pressed = false
	
	# Clear all spawns
	_clear_all_spawns()
	
	_update_preview()
	_update_timeline()


func _clear_all_spawns() -> void:
	"""Remove all spawn entries."""
	spawn_entries.clear()
	for ui_item: Control in spawn_ui_items:
		ui_item.queue_free()
	spawn_ui_items.clear()


func _load_wave_definition(wave_def: WaveDefinition) -> void:
	"""Load a WaveDefinition into the editor."""
	wave_number_spin.value = wave_def.wave_number
	wave_name_edit.text = wave_def.wave_name
	wave_desc_edit.text = wave_def.description
	turn_limit_spin.value = wave_def.turn_limit
	hp_mult_spin.value = wave_def.hp_multiplier
	dmg_mult_spin.value = wave_def.damage_multiplier
	scrap_bonus_spin.value = wave_def.scrap_bonus
	elite_check.button_pressed = wave_def.is_elite_wave
	boss_check.button_pressed = wave_def.is_boss_wave
	horde_check.button_pressed = wave_def.is_horde_wave
	
	# Clear and rebuild spawns
	_clear_all_spawns()
	
	for spawn: Dictionary in wave_def.turn_spawns:
		_add_spawn_entry(spawn)
	
	_update_preview()
	_update_timeline()
	encounter_loaded.emit(wave_def)


func _build_wave_definition() -> WaveDefinition:
	"""Build a WaveDefinition from current editor state."""
	var wave_def: WaveDefinition = WaveDefinition.new()
	wave_def.wave_number = int(wave_number_spin.value)
	wave_def.wave_name = wave_name_edit.text
	wave_def.description = wave_desc_edit.text
	wave_def.turn_limit = int(turn_limit_spin.value)
	wave_def.hp_multiplier = hp_mult_spin.value
	wave_def.damage_multiplier = dmg_mult_spin.value
	wave_def.scrap_bonus = int(scrap_bonus_spin.value)
	wave_def.is_elite_wave = elite_check.button_pressed
	wave_def.is_boss_wave = boss_check.button_pressed
	wave_def.is_horde_wave = horde_check.button_pressed
	
	wave_def.turn_spawns = []
	for spawn: Dictionary in spawn_entries:
		wave_def.turn_spawns.append(spawn.duplicate())
	
	return wave_def


# ==============================================================================
# SPAWN ENTRY MANAGEMENT
# ==============================================================================

func _on_add_spawn_pressed() -> void:
	"""Add a new spawn entry with defaults."""
	var default_spawn: Dictionary = {
		"turn": 1,
		"enemy_id": "husk",
		"count": 1,
		"ring": BattlefieldStateScript.Ring.FAR,
		"lane": -1  # -1 = auto-assign
	}
	_add_spawn_entry(default_spawn)
	_update_preview()
	_update_timeline()


func _add_spawn_entry(spawn_data: Dictionary) -> void:
	"""Add a spawn entry to the list."""
	var idx: int = spawn_entries.size()
	spawn_entries.append(spawn_data.duplicate())
	
	# Create UI for this spawn entry
	var entry_ui: Control = _create_spawn_entry_ui(idx)
	spawn_list_container.add_child(entry_ui)
	spawn_ui_items.append(entry_ui)


func _create_spawn_entry_ui(idx: int) -> Control:
	"""Create the UI for a single spawn entry."""
	var container := PanelContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.22, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	container.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	container.add_child(hbox)
	
	# Turn selector
	var turn_lbl := Label.new()
	turn_lbl.text = "Turn:"
	turn_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(turn_lbl)
	
	var turn_spin := SpinBox.new()
	turn_spin.min_value = 1
	turn_spin.max_value = 20
	turn_spin.value = spawn_entries[idx].get("turn", 1)
	turn_spin.custom_minimum_size.x = 60
	turn_spin.value_changed.connect(func(v: float) -> void: _on_spawn_turn_changed(idx, int(v)))
	hbox.add_child(turn_spin)
	
	# Enemy selector
	var enemy_label := Label.new()
	enemy_label.text = "Enemy:"
	enemy_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(enemy_label)
	
	var enemy_dropdown := OptionButton.new()
	enemy_dropdown.custom_minimum_size.x = 140
	_populate_enemy_dropdown(enemy_dropdown)
	_select_enemy_in_dropdown(enemy_dropdown, spawn_entries[idx].get("enemy_id", "husk"))
	enemy_dropdown.item_selected.connect(func(item_idx: int) -> void: _on_spawn_enemy_changed(idx, enemy_dropdown.get_item_metadata(item_idx)))
	hbox.add_child(enemy_dropdown)
	
	# Count selector
	var count_label := Label.new()
	count_label.text = "Count:"
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(count_label)
	
	var count_spin := SpinBox.new()
	count_spin.min_value = 1
	count_spin.max_value = 20
	count_spin.value = spawn_entries[idx].get("count", 1)
	count_spin.custom_minimum_size.x = 60
	count_spin.value_changed.connect(func(v: float) -> void: _on_spawn_count_changed(idx, int(v)))
	hbox.add_child(count_spin)
	
	# Ring selector
	var ring_label := Label.new()
	ring_label.text = "Ring:"
	ring_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(ring_label)
	
	var ring_dropdown := OptionButton.new()
	ring_dropdown.custom_minimum_size.x = 90
	ring_dropdown.add_item("MELEE", BattlefieldStateScript.Ring.MELEE)
	ring_dropdown.add_item("CLOSE", BattlefieldStateScript.Ring.CLOSE)
	ring_dropdown.add_item("MID", BattlefieldStateScript.Ring.MID)
	ring_dropdown.add_item("FAR", BattlefieldStateScript.Ring.FAR)
	ring_dropdown.selected = spawn_entries[idx].get("ring", BattlefieldStateScript.Ring.FAR)
	ring_dropdown.item_selected.connect(func(item_idx: int) -> void: _on_spawn_ring_changed(idx, item_idx))
	hbox.add_child(ring_dropdown)
	
	# Lane selector (optional)
	var lane_label := Label.new()
	lane_label.text = "Lane:"
	lane_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(lane_label)
	
	var lane_spin := SpinBox.new()
	lane_spin.min_value = -1  # -1 = auto
	lane_spin.max_value = 11
	lane_spin.value = spawn_entries[idx].get("lane", -1)
	lane_spin.custom_minimum_size.x = 60
	lane_spin.tooltip_text = "-1 = Auto-assign lane"
	lane_spin.value_changed.connect(func(v: float) -> void: _on_spawn_lane_changed(idx, int(v)))
	hbox.add_child(lane_spin)
	
	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Delete button
	var delete_btn := Button.new()
	delete_btn.text = "🗑️"
	delete_btn.tooltip_text = "Delete this spawn"
	delete_btn.pressed.connect(func() -> void: _delete_spawn_entry(idx))
	hbox.add_child(delete_btn)
	
	# Duplicate button
	var dupe_btn := Button.new()
	dupe_btn.text = "📋"
	dupe_btn.tooltip_text = "Duplicate this spawn"
	dupe_btn.pressed.connect(func() -> void: _duplicate_spawn_entry(idx))
	hbox.add_child(dupe_btn)
	
	return container


func _populate_enemy_dropdown(dropdown: OptionButton) -> void:
	"""Fill dropdown with all enemies from database."""
	dropdown.clear()
	var all_enemies: Array = EnemyDatabase.get_all_enemies()
	for enemy_id: String in all_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy_id)
		if enemy_def:
			var display_text: String = "%s %s (%s)" % [enemy_def.display_icon, enemy_def.enemy_name, enemy_def.enemy_type]
			dropdown.add_item(display_text)
			dropdown.set_item_metadata(dropdown.item_count - 1, enemy_id)


func _select_enemy_in_dropdown(dropdown: OptionButton, enemy_id: String) -> void:
	"""Select the enemy ID in the dropdown."""
	for i: int in range(dropdown.item_count):
		if dropdown.get_item_metadata(i) == enemy_id:
			dropdown.selected = i
			return


func _on_spawn_turn_changed(idx: int, turn: int) -> void:
	if idx < spawn_entries.size():
		spawn_entries[idx]["turn"] = turn
		_update_preview()
		_update_timeline()


func _on_spawn_enemy_changed(idx: int, enemy_id: String) -> void:
	if idx < spawn_entries.size():
		spawn_entries[idx]["enemy_id"] = enemy_id
		_update_preview()
		_update_timeline()


func _on_spawn_count_changed(idx: int, count: int) -> void:
	if idx < spawn_entries.size():
		spawn_entries[idx]["count"] = count
		_update_preview()
		_update_timeline()


func _on_spawn_ring_changed(idx: int, ring: int) -> void:
	if idx < spawn_entries.size():
		spawn_entries[idx]["ring"] = ring
		_update_preview()
		_update_timeline()


func _on_spawn_lane_changed(idx: int, lane: int) -> void:
	if idx < spawn_entries.size():
		spawn_entries[idx]["lane"] = lane
		_update_preview()


func _delete_spawn_entry(idx: int) -> void:
	"""Delete a spawn entry by index."""
	if idx >= spawn_entries.size():
		return
	
	spawn_entries.remove_at(idx)
	
	# Rebuild UI
	_rebuild_spawn_list_ui()
	_update_preview()
	_update_timeline()


func _duplicate_spawn_entry(idx: int) -> void:
	"""Duplicate a spawn entry."""
	if idx >= spawn_entries.size():
		return
	
	var dupe: Dictionary = spawn_entries[idx].duplicate()
	_add_spawn_entry(dupe)
	_update_preview()
	_update_timeline()


func _rebuild_spawn_list_ui() -> void:
	"""Rebuild the entire spawn list UI from data."""
	for ui_item: Control in spawn_ui_items:
		ui_item.queue_free()
	spawn_ui_items.clear()
	
	for i: int in range(spawn_entries.size()):
		var entry_ui: Control = _create_spawn_entry_ui(i)
		spawn_list_container.add_child(entry_ui)
		spawn_ui_items.append(entry_ui)


# ==============================================================================
# PREVIEW
# ==============================================================================

func _on_turn_slider_changed(value: float) -> void:
	current_preview_turn = int(value)
	turn_label.text = "Turn: %d" % current_preview_turn
	_update_preview()


func _on_turn_limit_changed(value: float) -> void:
	turn_slider.max_value = value
	if turn_slider.value > value:
		turn_slider.value = value


func _update_preview() -> void:
	"""Update the battlefield preview based on current turn."""
	# Calculate what enemies would be on the field by this turn
	var enemies_by_ring: Dictionary = {
		BattlefieldStateScript.Ring.MELEE: [],
		BattlefieldStateScript.Ring.CLOSE: [],
		BattlefieldStateScript.Ring.MID: [],
		BattlefieldStateScript.Ring.FAR: []
	}
	
	var total_enemies: int = 0
	
	# Simulate spawns up to current turn
	for spawn: Dictionary in spawn_entries:
		var spawn_turn: int = spawn.get("turn", 1)
		if spawn_turn <= current_preview_turn:
			var enemy_id: String = spawn.get("enemy_id", "husk")
			var count: int = spawn.get("count", 1)
			var ring: int = spawn.get("ring", BattlefieldStateScript.Ring.FAR)
			
			# Simulate movement (simplified - just shows starting position for now)
			var enemy_def = EnemyDatabase.get_enemy(enemy_id)
			var speed: int = 1 if not enemy_def else enemy_def.movement_speed
			var turns_passed: int = current_preview_turn - spawn_turn
			var rings_moved: int = turns_passed * speed
			var final_ring: int = max(0, ring - rings_moved)
			
			# Clamp to target ring if it's a ranged enemy
			if enemy_def and enemy_def.target_ring > 0:
				final_ring = max(enemy_def.target_ring, final_ring)
			
			for _i: int in range(count):
				enemies_by_ring[final_ring].append(enemy_id)
				total_enemies += 1
	
	# Update ring displays
	_update_ring_panel(preview_ring_melee, enemies_by_ring[BattlefieldStateScript.Ring.MELEE], "MELEE")
	_update_ring_panel(preview_ring_close, enemies_by_ring[BattlefieldStateScript.Ring.CLOSE], "CLOSE")
	_update_ring_panel(preview_ring_mid, enemies_by_ring[BattlefieldStateScript.Ring.MID], "MID")
	_update_ring_panel(preview_ring_far, enemies_by_ring[BattlefieldStateScript.Ring.FAR], "FAR")
	
	total_enemies_label.text = "Total: %d enemies" % total_enemies


func _update_ring_panel(panel: Panel, enemies: Array, ring_name: String) -> void:
	"""Update a ring preview panel with enemy icons."""
	# Find or create label
	var label: Label = panel.get_node_or_null("Label")
	if not label:
		label = Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchors_preset = Control.PRESET_FULL_RECT
		panel.add_child(label)
	
	# Build display text
	var icon_counts: Dictionary = {}
	for enemy_id: String in enemies:
		var icon: String = enemy_icons.get(enemy_id, "?")
		icon_counts[icon] = icon_counts.get(icon, 0) + 1
	
	var parts: Array[String] = []
	for icon: String in icon_counts:
		if icon_counts[icon] > 1:
			parts.append("%s×%d" % [icon, icon_counts[icon]])
		else:
			parts.append(icon)
	
	if parts.is_empty():
		label.text = ring_name
	else:
		label.text = ring_name + "\n" + " ".join(parts)
	
	# Color panel based on danger level
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() if panel.get_theme_stylebox("panel") else StyleBoxFlat.new()
	if style is StyleBoxFlat:
		if enemies.size() == 0:
			style.bg_color = Color(0.15, 0.2, 0.15, 0.8)  # Green-ish
		elif enemies.size() < 3:
			style.bg_color = Color(0.25, 0.25, 0.15, 0.8)  # Yellow-ish
		elif enemies.size() < 6:
			style.bg_color = Color(0.3, 0.2, 0.1, 0.8)  # Orange-ish
		else:
			style.bg_color = Color(0.35, 0.15, 0.15, 0.8)  # Red-ish
		panel.add_theme_stylebox_override("panel", style)


func _update_timeline() -> void:
	"""Update the timeline showing spawns per turn."""
	# Clear existing
	for child in timeline_container.get_children():
		child.queue_free()
	
	var max_turn: int = int(turn_limit_spin.value)
	
	for turn: int in range(1, max_turn + 1):
		var turn_panel := PanelContainer.new()
		turn_panel.custom_minimum_size = Vector2(80, 80)
		turn_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.14, 0.18) if turn != current_preview_turn else Color(0.2, 0.25, 0.35)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.5, 0.8) if turn == current_preview_turn else Color(0.2, 0.2, 0.2)
		turn_panel.add_theme_stylebox_override("panel", style)
		
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		turn_panel.add_child(vbox)
		
		var turn_lbl := Label.new()
		turn_lbl.text = "T%d" % turn
		turn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		turn_lbl.add_theme_font_size_override("font_size", 12)
		turn_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
		vbox.add_child(turn_lbl)
		
		# Show spawns for this turn
		var spawns_this_turn: Array[String] = []
		for spawn: Dictionary in spawn_entries:
			if spawn.get("turn", 1) == turn:
				var enemy_id: String = spawn.get("enemy_id", "husk")
				var count: int = spawn.get("count", 1)
				var icon: String = enemy_icons.get(enemy_id, "?")
				spawns_this_turn.append("%s×%d" % [icon, count])
		
		if spawns_this_turn.size() > 0:
			var spawn_lbl := Label.new()
			spawn_lbl.text = "\n".join(spawns_this_turn)
			spawn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			spawn_lbl.add_theme_font_size_override("font_size", 11)
			spawn_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
			vbox.add_child(spawn_lbl)
		
		# Make clickable to select turn
		turn_panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				turn_slider.value = turn
		)
		
		timeline_container.add_child(turn_panel)


# ==============================================================================
# ACTIONS (Save/Load/Export/Test)
# ==============================================================================

func _on_back_pressed() -> void:
	"""Return to the main menu."""
	GameManager.change_scene("res://scenes/MainMenu.tscn")


func _on_load_pressed() -> void:
	"""Load a pre-defined wave from WaveDefinition."""
	var selected: int = load_wave_dropdown.selected
	if selected <= 0:
		return
	
	var wave_num: int = load_wave_dropdown.get_item_id(selected)
	var wave_def: WaveDefinition = WaveDefinition.create_wave(wave_num)
	_load_wave_definition(wave_def)


func _on_save_pressed() -> void:
	"""Save the current encounter."""
	var wave_def: WaveDefinition = _build_wave_definition()
	encounter_saved.emit(wave_def)
	print("[EncounterDesigner] Saved encounter: ", wave_def.wave_name)
	print("[EncounterDesigner] Turn spawns: ", wave_def.turn_spawns)


func _on_export_json_pressed() -> void:
	"""Export the encounter to JSON format."""
	var wave_def: WaveDefinition = _build_wave_definition()
	
	var json_data: Dictionary = {
		"wave_number": wave_def.wave_number,
		"wave_name": wave_def.wave_name,
		"description": wave_def.description,
		"turn_limit": wave_def.turn_limit,
		"hp_multiplier": wave_def.hp_multiplier,
		"damage_multiplier": wave_def.damage_multiplier,
		"scrap_bonus": wave_def.scrap_bonus,
		"is_elite_wave": wave_def.is_elite_wave,
		"is_boss_wave": wave_def.is_boss_wave,
		"is_horde_wave": wave_def.is_horde_wave,
		"turn_spawns": wave_def.turn_spawns
	}
	
	var json_string: String = JSON.stringify(json_data, "\t")
	
	# Copy to clipboard
	DisplayServer.clipboard_set(json_string)
	print("[EncounterDesigner] JSON exported to clipboard!")
	print(json_string)


func _on_test_pressed() -> void:
	"""Test the designed encounter by loading it into combat."""
	var wave_def: WaveDefinition = _build_wave_definition()
	
	# Store in RunManager for combat to use
	RunManager.current_wave = wave_def.wave_number
	
	# Apply player configuration
	_apply_player_config()
	
	print("[EncounterDesigner] Testing encounter: ", wave_def.wave_name)
	print("[EncounterDesigner] Total enemies: ", wave_def.get_total_enemy_count())
	print("[EncounterDesigner] Player config - HP: %d/%d, Energy: %d, Deck: %d cards" % [
		RunManager.current_hp, RunManager.max_hp, RunManager.base_energy, custom_deck.size()])
	
	# Store wave def for combat to use
	_store_test_wave(wave_def)
	
	# Transition to combat
	GameManager.change_scene("res://scenes/Combat.tscn")


func _apply_player_config() -> void:
	"""Apply the player configuration from the UI to RunManager."""
	# Set warden
	if selected_warden_index >= 0 and selected_warden_index < wardens.size():
		RunManager.set_warden(wardens[selected_warden_index])
	
	# Override stats from UI
	if max_hp_spin:
		RunManager.player_stats.max_hp = int(max_hp_spin.value)
	if current_hp_spin:
		RunManager.current_hp = int(current_hp_spin.value)
	if energy_spin:
		RunManager.player_stats.energy_per_turn = int(energy_spin.value)
	if armor_spin:
		RunManager.armor = int(armor_spin.value)
	if scrap_spin:
		RunManager.scrap = int(scrap_spin.value)
	
	# Override deck with custom deck
	RunManager.deck.clear()
	for entry: Dictionary in custom_deck:
		RunManager.deck.append(entry.duplicate())
	
	print("[EncounterDesigner] Applied player config - Warden: %s" % wardens[selected_warden_index].warden_name)


var _test_wave_override: WaveDefinition = null

func _store_test_wave(wave_def: WaveDefinition) -> void:
	"""Store the test wave for combat to use."""
	_test_wave_override = wave_def
	# Also store in a temp file for persistence
	var file := FileAccess.open("user://test_encounter.json", FileAccess.WRITE)
	if file:
		# Convert custom deck to JSON-friendly format
		var deck_json: Array = []
		for entry: Dictionary in custom_deck:
			deck_json.append({"card_id": entry.card_id, "tier": entry.tier})
		
		var json_data: Dictionary = {
			"wave_number": wave_def.wave_number,
			"wave_name": wave_def.wave_name,
			"description": wave_def.description,
			"turn_limit": wave_def.turn_limit,
			"hp_multiplier": wave_def.hp_multiplier,
			"damage_multiplier": wave_def.damage_multiplier,
			"scrap_bonus": wave_def.scrap_bonus,
			"is_elite_wave": wave_def.is_elite_wave,
			"is_boss_wave": wave_def.is_boss_wave,
			"is_horde_wave": wave_def.is_horde_wave,
			"turn_spawns": wave_def.turn_spawns,
			# Player configuration
			"player_config": {
				"warden_index": selected_warden_index,
				"energy": int(energy_spin.value) if energy_spin else 3,
				"max_hp": int(max_hp_spin.value) if max_hp_spin else 70,
				"current_hp": int(current_hp_spin.value) if current_hp_spin else 70,
				"armor": int(armor_spin.value) if armor_spin else 0,
				"scrap": int(scrap_spin.value) if scrap_spin else 0,
				"deck": deck_json
			}
		}
		file.store_string(JSON.stringify(json_data))
		file.close()


static func load_test_wave() -> WaveDefinition:
	"""Load the test wave from temp file (called from combat).
	Also applies player configuration if present."""
	if not FileAccess.file_exists("user://test_encounter.json"):
		return null
	
	var file := FileAccess.open("user://test_encounter.json", FileAccess.READ)
	if not file:
		return null
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return null
	
	var data: Dictionary = json.data
	
	# Build wave definition
	var wave_def: WaveDefinition = WaveDefinition.new()
	wave_def.wave_number = data.get("wave_number", 1)
	wave_def.wave_name = data.get("wave_name", "Test Wave")
	wave_def.description = data.get("description", "")
	wave_def.turn_limit = data.get("turn_limit", 6)
	wave_def.hp_multiplier = data.get("hp_multiplier", 1.0)
	wave_def.damage_multiplier = data.get("damage_multiplier", 1.0)
	wave_def.scrap_bonus = data.get("scrap_bonus", 0)
	wave_def.is_elite_wave = data.get("is_elite_wave", false)
	wave_def.is_boss_wave = data.get("is_boss_wave", false)
	wave_def.is_horde_wave = data.get("is_horde_wave", false)
	
	# Convert untyped JSON array to typed Array[Dictionary]
	var spawns_data: Array = data.get("turn_spawns", [])
	wave_def.turn_spawns.clear()
	for spawn in spawns_data:
		if spawn is Dictionary:
			wave_def.turn_spawns.append(spawn)
	
	# Apply player configuration if present (this happens before combat starts)
	var player_config: Dictionary = data.get("player_config", {})
	if not player_config.is_empty():
		_apply_loaded_player_config(player_config)
	
	return wave_def


static func _apply_loaded_player_config(config: Dictionary) -> void:
	"""Apply player configuration from loaded test encounter."""
	# Note: This is called from CombatScreen before combat initializes
	# The warden was already set in _on_test_pressed, but we need to override stats
	
	# Override stats
	var max_hp: int = config.get("max_hp", 70)
	var current_hp: int = config.get("current_hp", 70)
	var energy: int = config.get("energy", 3)
	var armor: int = config.get("armor", 0)
	var scrap: int = config.get("scrap", 0)
	
	RunManager.player_stats.max_hp = max_hp
	RunManager.current_hp = min(current_hp, max_hp)
	RunManager.player_stats.energy_per_turn = energy
	RunManager.armor = armor
	RunManager.scrap = scrap
	
	# Override deck
	var deck_data: Array = config.get("deck", [])
	if not deck_data.is_empty():
		RunManager.deck.clear()
		for entry in deck_data:
			if entry is Dictionary:
				RunManager.deck.append({
					"card_id": entry.get("card_id", "pistol"),
					"tier": entry.get("tier", 1)
				})
	
	print("[EncounterDesigner] Loaded player config - HP: %d/%d, Energy: %d, Deck: %d cards" % [
		RunManager.current_hp, RunManager.player_stats.max_hp, energy, RunManager.deck.size()])
