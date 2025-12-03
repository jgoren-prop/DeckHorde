extends Control
## WardenSelect - Warden selection screen
## V2: Now uses WardenDefinition resources with stat_modifiers

@onready var warden_container: HBoxContainer = $MarginContainer/VBoxContainer/WardenContainer
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var difficulty_slider: HSlider = $MarginContainer/VBoxContainer/DifficultySection/DifficultySlider
@onready var difficulty_value: Label = $MarginContainer/VBoxContainer/DifficultySection/DifficultyValue
@onready var warden_preview: PanelContainer = $WardenPreview
@onready var preview_name: Label = $WardenPreview/PreviewContent/PreviewName
@onready var preview_stats: Label = $WardenPreview/PreviewContent/PreviewStats
@onready var preview_passive: RichTextLabel = $WardenPreview/PreviewContent/PreviewPassive
@onready var preview_deck: Label = $WardenPreview/PreviewContent/PreviewDeck

var selected_warden: WardenDefinition = null
var wardens: Array[WardenDefinition] = []

const DIFFICULTY_NAMES: Array[String] = ["Normal", "Hard", "Expert", "Nightmare", "Apocalypse"]


func _ready() -> void:
	_load_wardens()
	_create_warden_cards()
	_update_difficulty_display(int(difficulty_slider.value))


func _load_wardens() -> void:
	wardens = _create_default_wardens()


func _create_default_wardens() -> Array[WardenDefinition]:
	"""Create V2 WardenDefinition resources for each warden."""
	var result: Array[WardenDefinition] = []
	
	# Ash Warden - Gun specialist with Close/Melee damage bonus
	var ash: WardenDefinition = WardenDefinition.new()
	ash.warden_id = "ash_warden"
	ash.warden_name = "Ash Warden"
	ash.description = "Ex-riot cop branded with a burning sigil."
	ash.passive_description = "Gun cards deal +15% damage. +10% damage to Close/Melee."
	ash.max_hp = 63  # 70 * 0.9 = 63 (10% HP penalty)
	ash.base_armor = 2
	ash.base_energy = 3
	ash.hand_size = 5
	ash.stat_modifiers = {
		"gun_damage_percent": 15.0,  # +15% gun damage
		"damage_vs_melee_percent": 10.0,  # +10% vs Melee
		"damage_vs_close_percent": 10.0   # +10% vs Close
	}
	ash.passive_id = ""  # No special passive, all via stat_modifiers
	ash.portrait_color = Color(1.0, 0.4, 0.2)
	ash.icon = "🔥"
	# V2 Brainstorm: Gun-focused deck with damage-type synergies
	ash.starting_deck = [
		{"card_id": "rusty_pistol", "tier": 1, "count": 2},        # Persistent gun
		{"card_id": "mortar_team", "tier": 1, "count": 1},         # Explosive sniper
		{"card_id": "volley_rig", "tier": 1, "count": 1},          # Shotgun swarm clear
		{"card_id": "rail_piercer", "tier": 1, "count": 1},        # Piercing damage
		{"card_id": "flame_coil", "tier": 1, "count": 2},          # Explosive AoE
		{"card_id": "precision_strike", "tier": 1, "count": 1},    # Stack breaker
		{"card_id": "guard_stance", "tier": 1, "count": 1},        # Defense
		{"card_id": "overclock", "tier": 1, "count": 1}            # Fire all guns
	]
	result.append(ash)
	
	# Gloom Warden - Hex specialist (passive to be implemented in V2 Phase 7+)
	var gloom: WardenDefinition = WardenDefinition.new()
	gloom.warden_id = "gloom_warden"
	gloom.warden_name = "Gloom Warden"
	gloom.description = "Cult defector bound to a parasitic entity."
	gloom.passive_description = "Hex damage +20%. Heal power reduced by 10%."
	gloom.max_hp = 65
	gloom.base_armor = 1
	gloom.base_energy = 3
	gloom.hand_size = 5
	gloom.stat_modifiers = {
		"hex_damage_percent": 20.0,   # +20% hex damage
		"heal_power_percent": -10.0   # -10% heal power
	}
	gloom.passive_id = ""  # hex_lifesteal to be added in V2 Phase 7+
	gloom.portrait_color = Color(0.5, 0.2, 0.6)
	gloom.icon = "🌑"
	# V2 Brainstorm: Hex-focused deck with beam synergies
	gloom.starting_deck = [
		{"card_id": "rusty_pistol", "tier": 1, "count": 2},        # Persistent gun
		{"card_id": "minor_hex", "tier": 1, "count": 2},           # Basic hex
		{"card_id": "hex_bloom", "tier": 1, "count": 1},           # Hex AoE
		{"card_id": "hex_transfer", "tier": 1, "count": 1},        # Move hex + gun hex buff
		{"card_id": "arc_conductor", "tier": 1, "count": 1},       # Beam engine from hex
		{"card_id": "hex_lance_turret", "tier": 1, "count": 1},    # Hex beam engine
		{"card_id": "beam_splitter", "tier": 1, "count": 1},       # Beam damage + hex spread
		{"card_id": "guard_stance", "tier": 1, "count": 1}         # Defense
	]
	result.append(gloom)
	
	# Glass Warden - Defense specialist with cheat_death passive
	var glass: WardenDefinition = WardenDefinition.new()
	glass.warden_id = "glass_warden"
	glass.warden_name = "Glass Warden"
	glass.description = "Sigil-knight encased in reflective glass armor."
	glass.passive_description = "First fatal hit per wave: survive at 1 HP. Armor gain +25%."
	glass.max_hp = 70
	glass.base_armor = 4
	glass.base_energy = 2  # Drawback: reduced energy
	glass.hand_size = 5
	glass.stat_modifiers = {
		"armor_gain_percent": 25.0  # +25% armor gain
	}
	glass.passive_id = "cheat_death"  # Special passive: survive fatal hit once per wave
	glass.portrait_color = Color(0.7, 0.9, 1.0)
	glass.icon = "💎"
	# V2 Brainstorm: Defense-focused deck with fortress synergies
	glass.starting_deck = [
		{"card_id": "rusty_pistol", "tier": 1, "count": 2},        # Persistent gun
		{"card_id": "guard_stance", "tier": 1, "count": 2},        # Basic armor
		{"card_id": "minor_barrier", "tier": 1, "count": 2},       # Barrier trap
		{"card_id": "sentinel_barrier", "tier": 1, "count": 1},    # Fortress barrier engine
		{"card_id": "bulwark_drone", "tier": 1, "count": 1},       # Armor + barrier engine
		{"card_id": "barrier_channel", "tier": 1, "count": 1},     # Trigger all barriers
		{"card_id": "null_field", "tier": 1, "count": 1},          # Strong armor + melee debuff
		{"card_id": "runic_overload", "tier": 1, "count": 1}       # Armor + free Overclock
	]
	result.append(glass)
	
	# =============================================================================
	# V2 VETERAN WARDEN - Neutral baseline for Brotato-style buildcraft
	# =============================================================================
	var veteran: WardenDefinition = WardenDefinition.new()
	veteran.warden_id = "veteran_warden"
	veteran.warden_name = "Veteran Warden"
	veteran.description = "Battle-hardened generalist who has seen every horror."
	veteran.passive_description = "No bonuses or penalties. Adapt your build through shop choices."
	veteran.max_hp = 70
	veteran.base_armor = 0
	veteran.base_energy = 3
	veteran.hand_size = 5
	# V2: All stats at 100% baseline (neutral)
	veteran.stat_modifiers = {}  # Empty = all defaults (100%)
	veteran.passive_id = ""  # No special passive
	veteran.portrait_color = Color(0.6, 0.6, 0.7)  # Neutral gray-blue
	veteran.icon = "⚔️"
	veteran.is_unlocked_by_default = true  # V2 baseline, always available
	# V2 Brainstorm Starter Deck: 10-card board-first, tag-flex design
	veteran.starting_deck = [
		{"card_id": "rusty_pistol", "tier": 1, "count": 2},        # 2x persistent gun - baseline lane fill
		{"card_id": "storm_carbine", "tier": 1, "count": 1},       # 1x persistent gun - Close/Mid coverage
		{"card_id": "ammo_cache", "tier": 1, "count": 1},          # 1x engine_core skill - draw + cost reduction
		{"card_id": "minor_hex", "tier": 1, "count": 1},           # 1x hex - beam/hex synergy setup
		{"card_id": "minor_barrier", "tier": 1, "count": 1},       # 1x barrier - fortress hooks
		{"card_id": "guard_stance", "tier": 1, "count": 1},        # 1x defense - stabilizer
		{"card_id": "precision_strike", "tier": 1, "count": 1},    # 1x targeted attack - stack breaker
		{"card_id": "shove", "tier": 1, "count": 1},               # 1x ring_control - movement control
		{"card_id": "overclock", "tier": 1, "count": 1},           # 1x tempo - all guns fire at 75%
		{"card_id": "tag_infusion_piercing", "tier": 1, "count": 1} # 1x tag infusion - piercing upgrade
	]
	result.append(veteran)
	
	return result


func _create_warden_cards() -> void:
	for child: Node in warden_container.get_children():
		child.queue_free()
	
	var veteran_card: PanelContainer = null
	var veteran_warden: WardenDefinition = null
	
	for warden: WardenDefinition in wardens:
		var card: PanelContainer = _create_warden_card(warden)
		warden_container.add_child(card)
		
		# Track Veteran warden for default selection
		if warden.warden_id == "veteran_warden":
			veteran_card = card
			veteran_warden = warden
	
	# Auto-select Veteran warden by default (use timer to ensure styles are applied)
	if veteran_card and veteran_warden:
		await get_tree().process_frame
		_on_warden_selected(veteran_warden, veteran_card)


func _create_warden_card(warden: WardenDefinition) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 280)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2)
	style.border_color = warden.portrait_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var icon_label: Label = Label.new()
	icon_label.text = warden.icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 64)
	vbox.add_child(icon_label)
	
	var name_label: Label = Label.new()
	name_label.text = warden.warden_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", warden.portrait_color)
	vbox.add_child(name_label)
	
	var stats_label: Label = Label.new()
	stats_label.text = "HP: %d | ⚡: %d" % [warden.max_hp, warden.base_energy]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(stats_label)
	
	var select_btn: Button = Button.new()
	select_btn.text = "Select"
	select_btn.custom_minimum_size = Vector2(100, 40)
	select_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_btn.pressed.connect(_on_warden_selected.bind(warden, panel))
	vbox.add_child(select_btn)
	
	panel.set_meta("warden_id", warden.warden_id)
	return panel


func _on_warden_selected(warden: WardenDefinition, card: PanelContainer) -> void:
	selected_warden = warden
	
	for child: Node in warden_container.get_children():
		if child is PanelContainer:
			var style: StyleBoxFlat = child.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if child == card:
				style.border_color = Color(1, 1, 1)
				style.set_border_width_all(4)
			else:
				# Find the warden for this card
				var warden_id: String = child.get_meta("warden_id")
				for w: WardenDefinition in wardens:
					if w.warden_id == warden_id:
						style.border_color = w.portrait_color
						break
				style.set_border_width_all(2)
			child.add_theme_stylebox_override("panel", style)
	
	_update_preview(warden)
	start_button.disabled = false


func _update_preview(warden: WardenDefinition) -> void:
	warden_preview.visible = true
	preview_name.text = warden.warden_name
	preview_stats.text = "HP: %d | Armor: %d | Energy: %d | Hand: %d" % [
		warden.max_hp, warden.base_armor, warden.base_energy, warden.hand_size
	]
	preview_passive.text = "[b]Passive:[/b] %s" % warden.passive_description
	
	var deck_count: int = 0
	for entry: Dictionary in warden.starting_deck:
		deck_count += entry.get("count", 1)
	preview_deck.text = "Starting Deck: %d cards" % deck_count


func _on_difficulty_changed(value: float) -> void:
	_update_difficulty_display(int(value))


func _update_difficulty_display(level: int) -> void:
	var diff_name: String = DIFFICULTY_NAMES[level - 1] if level <= DIFFICULTY_NAMES.size() else "Level " + str(level)
	difficulty_value.text = "%d - %s" % [level, diff_name]
	
	var color: Color = Color(0.5, 1.0, 0.5)
	if level >= 4:
		color = Color(1.0, 0.3, 0.3)
	elif level >= 2:
		color = Color(1.0, 0.8, 0.3)
	difficulty_value.add_theme_color_override("font_color", color)


func _on_start_pressed() -> void:
	if selected_warden == null:
		return
	
	print("[WardenSelect] Starting V2 run with: ", selected_warden.warden_name)
	
	# V2: Use set_warden to apply all stat modifiers
	RunManager.set_warden(selected_warden)
	RunManager.danger_level = int(difficulty_slider.value)
	
	# Initialize deck from warden's starting deck
	RunManager.deck.clear()
	for entry: Dictionary in selected_warden.starting_deck:
		var count: int = entry.get("count", 1)
		for i: int in range(count):
			RunManager.deck.append({
				"card_id": entry.card_id,
				"tier": entry.get("tier", 1)
			})
	
	GameManager.start_new_run()


func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()
