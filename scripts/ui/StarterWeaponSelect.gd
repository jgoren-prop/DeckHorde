extends Control
## StarterWeaponSelect - Brotato-style starter weapon selection
## Player picks 1 of 7 starter weapons before combat begins
## V2: Each warden also gets bonus starter cards (instant + defense)

signal weapon_selected(weapon_card)

@onready var weapon_container: HBoxContainer = $MarginContainer/VBoxContainer/WeaponContainer
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton
@onready var weapon_preview: PanelContainer = $WeaponPreview
@onready var preview_name: Label = $WeaponPreview/PreviewContent/PreviewName
@onready var preview_effect: RichTextLabel = $WeaponPreview/PreviewContent/PreviewEffect
@onready var preview_synergy: Label = $WeaponPreview/PreviewContent/PreviewSynergy
@onready var warden_info: Label = $MarginContainer/VBoxContainer/WardenInfo

var selected_weapon = null  # CardDefinition
var starter_weapons: Array = []

# V2: Warden starter bundles - each warden gets bonus cards alongside the picked weapon
# Format: { "warden_id": ["card_id1", "card_id2"] }
const WARDEN_STARTER_BUNDLES: Dictionary = {
	"veteran": ["guard_stance", "ammo_cache"],  # Defense + Draw/Utility
	"ash": ["minor_hex", "guard_stance"],  # Hex setup + Defense
	"gloom": ["minor_hex", "guard_stance"],  # Hex + Defense
	"glass": ["guard_stance", "minor_barrier"],  # Defense + Barrier
}

# Synergy descriptions for each starter weapon
const SYNERGY_HINTS: Dictionary = {
	"rusty_pistol": "Generic gun scaling - works with any build",
	"worn_hex_staff": "Hex/Ritual builds - stack curses for big damage",
	"cracked_barrier_gem": "Fortress/Trap builds - ring control and armor synergy",
	"leaky_siphon": "Lifedrain sustain - stay alive through healing",
	"volatile_handgun": "High-risk/High-reward - glass cannon builds",
	"mini_turret": "Engine/Board builds - multi-target efficiency",
	"barrier_mine_layer": "Passive trap generation - set and forget"
}


func _ready() -> void:
	_load_starter_weapons()
	_create_weapon_cards()
	_update_warden_info()
	continue_button.disabled = true
	weapon_preview.visible = false


func _load_starter_weapons() -> void:
	"""Load all starter weapons from CardDatabase."""
	starter_weapons = CardDatabase.get_starter_weapons()
	print("[StarterWeaponSelect] Loaded %d starter weapons" % starter_weapons.size())


func _update_warden_info() -> void:
	"""Show the selected warden's info and bundle preview."""
	var warden_name: String = "Veteran"
	if RunManager.current_warden and RunManager.current_warden is WardenDefinition:
		warden_name = RunManager.current_warden.warden_name
	
	var stats_text: String = "Warden: %s | HP: %d | Energy: %d/turn | Draw: %d/turn" % [
		warden_name,
		RunManager.player_stats.max_hp,
		RunManager.player_stats.energy_per_turn,
		RunManager.player_stats.draw_per_turn
	]
	
	# V2: Show bundle cards preview
	var warden_id: String = _get_warden_id()
	if WARDEN_STARTER_BUNDLES.has(warden_id):
		var bundle_names: Array = []
		for card_id: String in WARDEN_STARTER_BUNDLES[warden_id]:
			var card = CardDatabase.get_card(card_id)
			if card:
				bundle_names.append(card.card_name)
		if bundle_names.size() > 0:
			stats_text += "\nStarting bundle: Pick 1 weapon + %s" % " + ".join(bundle_names)
	
	warden_info.text = stats_text


func _create_weapon_cards() -> void:
	"""Create weapon selection cards."""
	for child: Node in weapon_container.get_children():
		child.queue_free()
	
	for weapon in starter_weapons:
		var card: PanelContainer = _create_weapon_card(weapon)
		weapon_container.add_child(card)


func _create_weapon_card(weapon) -> PanelContainer:  # weapon: CardDefinition
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 240)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18)
	style.border_color = _get_weapon_color(weapon)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Icon based on weapon type
	var icon_label: Label = Label.new()
	icon_label.text = _get_weapon_icon(weapon)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(icon_label)
	
	# Name
	var name_label: Label = Label.new()
	name_label.text = weapon.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", _get_weapon_color(weapon))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = 150
	vbox.add_child(name_label)
	
	# Cost
	var cost_label: Label = Label.new()
	cost_label.text = "Cost: %d ⚡" % weapon.base_cost
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(cost_label)
	
	# Tags
	var tags_label: Label = Label.new()
	tags_label.text = ", ".join(weapon.tags.slice(0, 3))  # Show first 3 tags
	tags_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tags_label.add_theme_font_size_override("font_size", 10)
	tags_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	tags_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tags_label.custom_minimum_size.x = 150
	vbox.add_child(tags_label)
	
	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Select button
	var select_btn: Button = Button.new()
	select_btn.text = "Select"
	select_btn.custom_minimum_size = Vector2(100, 35)
	select_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_btn.pressed.connect(_on_weapon_selected.bind(weapon, panel))
	vbox.add_child(select_btn)
	
	# Store reference
	panel.set_meta("weapon", weapon)
	
	# Hover for preview
	panel.mouse_entered.connect(_on_weapon_hover.bind(weapon))
	
	return panel


func _get_weapon_icon(weapon) -> String:
	"""Get icon based on weapon tags."""
	if weapon.has_tag("hex"):
		return "🔮"
	elif weapon.has_tag("barrier"):
		return "🛡️"
	elif weapon.has_tag("lifedrain"):
		return "🩸"
	elif weapon.has_tag("volatile"):
		return "💥"
	elif weapon.has_tag("engine"):
		return "⚙️"
	else:
		return "🔫"


func _get_weapon_color(weapon) -> Color:
	"""Get border color based on weapon type."""
	if weapon.has_tag("hex"):
		return Color(0.6, 0.3, 0.8)  # Purple
	elif weapon.has_tag("barrier"):
		return Color(0.3, 0.7, 0.9)  # Cyan
	elif weapon.has_tag("lifedrain"):
		return Color(0.8, 0.2, 0.3)  # Red
	elif weapon.has_tag("volatile"):
		return Color(1.0, 0.6, 0.2)  # Orange
	elif weapon.has_tag("engine"):
		return Color(0.5, 0.8, 0.4)  # Green
	else:
		return Color(0.7, 0.7, 0.7)  # Gray


func _on_weapon_hover(weapon) -> void:
	"""Show weapon preview on hover."""
	_update_preview(weapon)


func _on_weapon_selected(weapon, card: PanelContainer) -> void:
	"""Handle weapon selection."""
	selected_weapon = weapon
	
	# Update visual selection
	for child: Node in weapon_container.get_children():
		if child is PanelContainer:
			var style: StyleBoxFlat = child.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if child == card:
				style.border_color = Color(1, 1, 1)
				style.set_border_width_all(4)
			else:
				var w = child.get_meta("weapon")
				style.border_color = _get_weapon_color(w)
				style.set_border_width_all(2)
			child.add_theme_stylebox_override("panel", style)
	
	_update_preview(weapon)
	continue_button.disabled = false
	
	AudioManager.play_button_click()


func _update_preview(weapon) -> void:
	"""Update the preview panel with weapon details."""
	weapon_preview.visible = true
	preview_name.text = weapon.card_name
	
	# Build effect text
	var effect_text: String = weapon.get_description_with_values(1)
	preview_effect.text = "[b]Effect:[/b] %s" % effect_text
	
	# Synergy hint
	var synergy: String = SYNERGY_HINTS.get(weapon.card_id, "Flexible build potential")
	preview_synergy.text = "Synergy: %s" % synergy


func _on_continue_pressed() -> void:
	"""Start the run with selected weapon and warden bundle."""
	if selected_weapon == null:
		return
	
	print("[StarterWeaponSelect] Selected starter weapon: %s" % selected_weapon.card_name)
	
	# Clear deck and add the selected starter weapon
	RunManager.deck.clear()
	RunManager.deck.append({
		"card_id": selected_weapon.card_id,
		"tier": 1
	})
	
	# V2: Add warden-specific starter bundle cards
	var warden_id: String = _get_warden_id()
	if WARDEN_STARTER_BUNDLES.has(warden_id):
		var bundle_cards: Array = WARDEN_STARTER_BUNDLES[warden_id]
		for card_id: String in bundle_cards:
			if CardDatabase.get_card(card_id):
				RunManager.deck.append({
					"card_id": card_id,
					"tier": 1
				})
				print("[StarterWeaponSelect] Added bundle card: %s" % card_id)
			else:
				push_warning("[StarterWeaponSelect] Bundle card not found: %s" % card_id)
	
	print("[StarterWeaponSelect] Final deck size: %d cards" % RunManager.deck.size())
	
	# Emit signal for any listeners
	weapon_selected.emit(selected_weapon)
	
	# Start combat
	GameManager.start_new_run()


func _get_warden_id() -> String:
	"""Get the current warden's ID for bundle lookup."""
	if RunManager.current_warden == null:
		return "veteran"  # Default to veteran
	if RunManager.current_warden is WardenDefinition:
		return RunManager.current_warden.warden_id.to_lower()
	return "veteran"


func _on_back_pressed() -> void:
	"""Return to warden select."""
	GameManager.go_to_warden_select()

