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
	ash.passive_description = "Gun +15% dmg. Close/Melee +10% dmg. +5 HP, +1 energy."
	ash.base_armor = 1
	# Brotato-style: Small bonuses that add up over time
	ash.stat_modifiers = {
		"max_hp": 5,  # +5 HP (20 -> 25)
		"energy_per_turn": 1,  # +1 energy (1 -> 2)
		"gun_damage_percent": 15.0,  # +15% gun damage
		"damage_vs_melee_percent": 10.0,  # +10% vs Melee
		"damage_vs_close_percent": 10.0   # +10% vs Close
	}
	ash.passive_id = ""  # No special passive, all via stat_modifiers
	ash.portrait_color = Color(1.0, 0.4, 0.2)
	ash.icon = "🔥"
	# Brotato-style: Start with 1 themed weapon
	ash.starting_deck = [
		{"card_id": "shotgun", "tier": 1, "count": 1}  # Thematic gun with splash
	]
	result.append(ash)
	
	# Gloom Warden - Hex specialist (passive to be implemented in V2 Phase 7+)
	var gloom: WardenDefinition = WardenDefinition.new()
	gloom.warden_id = "gloom_warden"
	gloom.warden_name = "Gloom Warden"
	gloom.description = "Cult defector bound to a parasitic entity."
	gloom.passive_description = "Hex +20% dmg. Heal -10%. +5 HP, +1 energy."
	gloom.base_armor = 0
	# Brotato-style: Small bonuses that add up over time
	gloom.stat_modifiers = {
		"max_hp": 5,  # +5 HP (20 -> 25)
		"energy_per_turn": 1,  # +1 energy (1 -> 2)
		"hex_damage_percent": 20.0,   # +20% hex damage
		"heal_power_percent": -10.0   # -10% heal power
	}
	gloom.passive_id = ""  # hex_lifesteal to be added in V2 Phase 7+
	gloom.portrait_color = Color(0.5, 0.2, 0.6)
	gloom.icon = "🌑"
	# Brotato-style: Start with 1 themed weapon
	gloom.starting_deck = [
		{"card_id": "hex_bolt", "tier": 1, "count": 1}  # Thematic hex weapon
	]
	result.append(gloom)
	
	# Glass Warden - Defense specialist with cheat_death passive
	var glass: WardenDefinition = WardenDefinition.new()
	glass.warden_id = "glass_warden"
	glass.warden_name = "Glass Warden"
	glass.description = "Sigil-knight encased in reflective glass armor."
	glass.passive_description = "Survive fatal hit once/wave. Armor +25%. +10 HP."
	glass.base_armor = 2
	# Brotato-style: Tankier but less energy
	glass.stat_modifiers = {
		"max_hp": 10,  # +10 HP (20 -> 30) - tankiest warden
		"armor_gain_percent": 25.0  # +25% armor gain
		# Note: No energy bonus - needs to buy it
	}
	glass.passive_id = "cheat_death"  # Special passive: survive fatal hit once per wave
	glass.portrait_color = Color(0.7, 0.9, 1.0)
	glass.icon = "💎"
	# Brotato-style: Start with 1 themed weapon
	glass.starting_deck = [
		{"card_id": "shield_bash", "tier": 1, "count": 1}  # Thematic armor weapon
	]
	result.append(glass)
	
	# =============================================================================
	# VETERAN WARDEN - Neutral baseline for Brotato-style buildcraft
	# =============================================================================
	var veteran: WardenDefinition = WardenDefinition.new()
	veteran.warden_id = "veteran_warden"
	veteran.warden_name = "Veteran Warden"
	veteran.description = "Battle-hardened generalist who has seen every horror."
	veteran.passive_description = "Balanced stats. +5 HP, +1 energy. No special bonuses."
	veteran.base_armor = 0
	# Brotato-style: Small starting bonuses
	veteran.stat_modifiers = {
		"max_hp": 5,  # +5 HP (20 -> 25)
		"energy_per_turn": 1  # +1 energy (1 -> 2)
	}
	# V4: Empty preferred_tags = no family bias, random family each run
	veteran.preferred_tags = []
	veteran.passive_id = ""  # No special passive
	veteran.portrait_color = Color(0.6, 0.6, 0.7)  # Neutral gray-blue
	veteran.icon = "⚔️"
	veteran.is_unlocked_by_default = true  # V2 baseline, always available
	# Brotato-style: Start with just 1 basic weapon, build from scratch
	veteran.starting_deck = [
		{"card_id": "pistol", "tier": 1, "count": 1}  # Basic gun - the classic starter
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
	
	# Calculate actual HP and energy after modifiers
	var hp: int = 50 + int(warden.stat_modifiers.get("max_hp", 0))
	var energy: int = 1 + int(warden.stat_modifiers.get("energy_per_turn", 0))
	
	var stats_label: Label = Label.new()
	stats_label.text = "HP: %d | ⚡: %d" % [hp, energy]
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
	
	# Calculate actual stats after modifiers (base: 50 HP, 1 energy, 1 draw)
	var hp: int = 50 + int(warden.stat_modifiers.get("max_hp", 0))
	var energy: int = 1 + int(warden.stat_modifiers.get("energy_per_turn", 0))
	var draw_amt: int = 1 + int(warden.stat_modifiers.get("draw_per_turn", 0))
	
	preview_stats.text = "HP: %d | Armor: %d | Energy: %d | Draw: %d" % [
		hp, warden.base_armor, energy, draw_amt
	]
	preview_passive.text = "[b]Passive:[/b] %s" % warden.passive_description
	
	# Show starting deck count
	var deck_size: int = selected_warden.starting_deck.reduce(
		func(acc: int, entry: Dictionary) -> int: return acc + entry.get("count", 1), 0
	)
	preview_deck.text = "Starting Deck: %d cards" % deck_size


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
	
	print("[WardenSelect] Selected warden: ", selected_warden.warden_name)
	
	# V2: Use set_warden to apply all stat modifiers and initialize deck
	RunManager.set_warden(selected_warden)
	RunManager.danger_level = int(difficulty_slider.value)
	
	print("[WardenSelect] Initialized deck with %d cards" % RunManager.deck.size())
	
	# Start combat directly
	GameManager.start_new_run()


func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()
