extends Control
## WardenSelect - Warden selection screen
## MINIMAL STUB for testing

@onready var warden_container: HBoxContainer = $MarginContainer/VBoxContainer/WardenContainer
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var difficulty_slider: HSlider = $MarginContainer/VBoxContainer/DifficultySection/DifficultySlider
@onready var difficulty_value: Label = $MarginContainer/VBoxContainer/DifficultySection/DifficultyValue
@onready var warden_preview: PanelContainer = $WardenPreview
@onready var preview_name: Label = $WardenPreview/PreviewContent/PreviewName
@onready var preview_stats: Label = $WardenPreview/PreviewContent/PreviewStats
@onready var preview_passive: RichTextLabel = $WardenPreview/PreviewContent/PreviewPassive
@onready var preview_deck: Label = $WardenPreview/PreviewContent/PreviewDeck

var selected_warden: Dictionary = {}
var wardens: Array = []

const DIFFICULTY_NAMES: Array[String] = ["Normal", "Hard", "Expert", "Nightmare", "Apocalypse"]


func _ready() -> void:
	_load_wardens()
	_create_warden_cards()
	_update_difficulty_display(int(difficulty_slider.value))


func _load_wardens() -> void:
	wardens = _create_default_wardens()


func _create_default_wardens() -> Array:
	var result: Array = []
	
	result.append({
		"warden_id": "ash_warden",
		"warden_name": "Ash Warden",
		"description": "Ex-riot cop branded with a burning sigil.",
		"passive_description": "Gun cards deal +15% damage to Close/Melee.",
		"drawback_description": "-10% Max HP.",
		"max_hp": 54,
		"base_armor": 2,
		"damage_multiplier": 1.15,
		"base_energy": 3,
		"hand_size": 5,
		"portrait_color": Color(1.0, 0.4, 0.2),
		"icon": "🔥",
		"starting_deck": [
			{"card_id": "infernal_pistol", "tier": 1, "count": 3},
			{"card_id": "glass_ward", "tier": 1, "count": 3},
			{"card_id": "simple_hex", "tier": 1, "count": 2},
			{"card_id": "emergency_medkit", "tier": 1, "count": 2}
		]
	})
	
	result.append({
		"warden_id": "gloom_warden",
		"warden_name": "Gloom Warden",
		"description": "Cult defector bound to a parasitic entity.",
		"passive_description": "Heal 1 HP when Hexed enemies die.",
		"drawback_description": "-10% Armor.",
		"max_hp": 55,
		"base_armor": 1,
		"damage_multiplier": 1.1,
		"base_energy": 3,
		"hand_size": 5,
		"portrait_color": Color(0.5, 0.2, 0.6),
		"icon": "🌑",
		"starting_deck": [
			{"card_id": "infernal_pistol", "tier": 1, "count": 2},
			{"card_id": "simple_hex", "tier": 1, "count": 4},
			{"card_id": "glass_ward", "tier": 1, "count": 2},
			{"card_id": "emergency_medkit", "tier": 1, "count": 2}
		]
	})
	
	result.append({
		"warden_id": "glass_warden",
		"warden_name": "Glass Warden",
		"description": "Sigil-knight encased in reflective glass armor.",
		"passive_description": "First death per wave: survive at 1 HP.",
		"drawback_description": "Base Energy reduced to 2.",
		"max_hp": 70,
		"base_armor": 4,
		"damage_multiplier": 1.0,
		"base_energy": 2,
		"hand_size": 5,
		"portrait_color": Color(0.7, 0.9, 1.0),
		"icon": "💎",
		"starting_deck": [
			{"card_id": "infernal_pistol", "tier": 1, "count": 2},
			{"card_id": "glass_ward", "tier": 1, "count": 4},
			{"card_id": "simple_hex", "tier": 1, "count": 2},
			{"card_id": "emergency_medkit", "tier": 1, "count": 2}
		]
	})
	
	return result


func _create_warden_cards() -> void:
	for child: Node in warden_container.get_children():
		child.queue_free()
	
	for warden: Dictionary in wardens:
		var card: PanelContainer = _create_warden_card(warden)
		warden_container.add_child(card)


func _create_warden_card(warden: Dictionary) -> PanelContainer:
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
	
	panel.set_meta("warden", warden)
	return panel


func _on_warden_selected(warden: Dictionary, card: PanelContainer) -> void:
	selected_warden = warden
	
	for child: Node in warden_container.get_children():
		if child is PanelContainer:
			var style: StyleBoxFlat = child.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if child == card:
				style.border_color = Color(1, 1, 1)
				style.set_border_width_all(4)
			else:
				var w: Dictionary = child.get_meta("warden")
				style.border_color = w.portrait_color
				style.set_border_width_all(2)
			child.add_theme_stylebox_override("panel", style)
	
	_update_preview(warden)
	start_button.disabled = false


func _update_preview(warden: Dictionary) -> void:
	warden_preview.visible = true
	preview_name.text = warden.warden_name
	preview_stats.text = "HP: %d | Armor: %d | Energy: %d | Hand: %d" % [
		warden.max_hp, warden.base_armor, warden.base_energy, warden.hand_size
	]
	preview_passive.text = "[b]Passive:[/b] %s\n\n[b]Drawback:[/b] %s" % [
		warden.passive_description, warden.drawback_description
	]
	
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
	if selected_warden.is_empty():
		return
	
	print("[WardenSelect] Starting run with: ", selected_warden.warden_name)
	
	# Set up run state
	RunManager.max_hp = selected_warden.max_hp
	RunManager.current_hp = selected_warden.max_hp
	RunManager.armor = selected_warden.base_armor
	RunManager.base_energy = selected_warden.base_energy
	RunManager.max_energy = selected_warden.base_energy
	RunManager.damage_multiplier = selected_warden.damage_multiplier
	RunManager.danger_level = int(difficulty_slider.value)
	
	# Initialize deck
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
