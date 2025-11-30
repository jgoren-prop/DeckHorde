extends Control
## Shop - Post-wave shop screen with cards, artifacts, merges, and services

@onready var scrap_label: Label = $MarginContainer/VBox/Header/ScrapContainer/ScrapLabel
@onready var card_slots: HBoxContainer = $MarginContainer/VBox/CardsSection/CardSlots
@onready var artifact_slots: HBoxContainer = $MarginContainer/VBox/ArtifactsSection/ArtifactSlots
@onready var merge_section: Control = $MarginContainer/VBox/MergeSection
@onready var merge_slots: HBoxContainer = $MarginContainer/VBox/MergeSection/MergeSlots
@onready var remove_cost_label: Label = $MarginContainer/VBox/ServicesSection/ServiceButtons/RemoveCard/Cost
@onready var heal_cost_label: Label = $MarginContainer/VBox/ServicesSection/ServiceButtons/Heal/Cost
@onready var reroll_cost_label: Label = $MarginContainer/VBox/ServicesSection/ServiceButtons/Reroll/Cost
@onready var deck_view_panel: PanelContainer = $DeckViewPanel
@onready var deck_grid: GridContainer = $DeckViewPanel/VBox/ScrollContainer/DeckGrid

# Deck viewer overlay (view-only, created dynamically)
var deck_viewer_overlay: CanvasLayer = null
var deck_viewer_grid: GridContainer = null
var deck_viewer_title: Label = null

# Merge popup (optional - created dynamically if needed)
var merge_popup: PanelContainer = null
var merge_card_name: Label = null
var merge_preview: Label = null
var merge_confirm_btn: Button = null

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

var shop_cards: Array[CardDefinition] = []
var shop_artifacts: Array = []  # Array of artifact data dictionaries

var remove_cost: int = 50
var heal_cost: int = 30
var reroll_cost: int = 10
var reroll_count: int = 0

var pending_merge_card_id: String = ""
var pending_merge_tier: int = 0

const CARD_BASE_PRICE: int = 40
const ARTIFACT_BASE_PRICE: int = 80


func _ready() -> void:
	_create_deck_viewer_overlay()
	_create_dev_panel()
	_refresh_shop()
	_update_ui()
	_check_merges()
	
	RunManager.scrap_changed.connect(_on_scrap_changed)
	MergeManager.merge_completed.connect(_on_merge_completed)
	
	# Hide merge popup initially
	if merge_popup:
		merge_popup.visible = false


func _refresh_shop() -> void:
	# Generate shop cards
	shop_cards = CardDatabase.get_shop_cards(3, RunManager.current_wave)
	
	# Generate artifacts from ArtifactManager
	shop_artifacts = _get_shop_artifacts(2)
	
	_populate_card_slots()
	_populate_artifact_slots()


func _get_shop_artifacts(count: int) -> Array:
	"""Get random artifacts for the shop."""
	var available: Array = ArtifactManager.get_available_artifacts()
	available.shuffle()
	
	var result: Array = []
	for i: int in range(mini(count, available.size())):
		result.append(available[i])
	return result


func _populate_card_slots() -> void:
	# Clear existing
	for child: Node in card_slots.get_children():
		child.queue_free()
	
	# Create card slots
	for i: int in range(shop_cards.size()):
		var card = shop_cards[i]  # CardDefinition
		var slot: PanelContainer = _create_shop_card_slot(card, i)
		card_slots.add_child(slot)
	
	# Show "Sold Out" if empty
	if shop_cards.size() == 0:
		var sold_out: Label = Label.new()
		sold_out.text = "Sold Out"
		sold_out.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sold_out.add_theme_font_size_override("font_size", 20)
		card_slots.add_child(sold_out)


func _create_shop_card_slot(card, index: int) -> PanelContainer:  # card: CardDefinition
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 220)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Card preview (simplified)
	var card_ui: Control = card_ui_scene.instantiate()
	card_ui.check_playability = false  # Don't dim cards in shop
	card_ui.setup(card, 1, index)
	card_ui.card_clicked.connect(_on_shop_card_clicked)
	card_ui.custom_minimum_size = Vector2(130, 180)
	vbox.add_child(card_ui)
	
	# Price
	var price: int = _calculate_card_price(card)
	var price_label: Label = Label.new()
	price_label.text = "%d ⚙️" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if RunManager.scrap >= price:
		price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	else:
		price_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	vbox.add_child(price_label)
	
	panel.set_meta("card", card)
	panel.set_meta("price", price)
	panel.set_meta("index", index)
	
	return panel


func _populate_artifact_slots() -> void:
	# Clear existing
	for child: Node in artifact_slots.get_children():
		child.queue_free()
	
	# Create artifact slots
	for i: int in range(shop_artifacts.size()):
		var artifact: Dictionary = shop_artifacts[i]
		var slot: PanelContainer = _create_artifact_slot(artifact, i)
		artifact_slots.add_child(slot)
	
	# Show "Sold Out" if empty
	if shop_artifacts.size() == 0:
		var sold_out: Label = Label.new()
		sold_out.text = "No Artifacts"
		sold_out.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sold_out.add_theme_font_size_override("font_size", 16)
		artifact_slots.add_child(sold_out)


func _create_artifact_slot(artifact: Dictionary, index: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 120)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	
	# Border color by rarity
	match artifact.rarity:
		0: style.border_color = Color(0.5, 0.5, 0.5)  # Common
		1: style.border_color = Color(0.3, 0.6, 1.0)  # Uncommon
		2: style.border_color = Color(0.8, 0.5, 1.0)  # Rare
		_: style.border_color = Color(1.0, 0.8, 0.3)  # Legendary
	
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Icon
	var icon: Label = Label.new()
	icon.text = artifact.get("icon", "💎")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 28)
	vbox.add_child(icon)
	
	# Name
	var name_label: Label = Label.new()
	name_label.text = artifact.artifact_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	vbox.add_child(name_label)
	
	# Description
	var desc_label: Label = Label.new()
	desc_label.text = artifact.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 150
	vbox.add_child(desc_label)
	
	# Price
	var price: int = artifact.cost
	var price_label: Label = Label.new()
	price_label.text = "%d ⚙️" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if RunManager.scrap >= price:
		price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	else:
		price_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	vbox.add_child(price_label)
	
	# Buy button
	var buy_btn: Button = Button.new()
	buy_btn.text = "Buy"
	buy_btn.pressed.connect(_on_artifact_buy_pressed.bind(artifact, index))
	vbox.add_child(buy_btn)
	
	panel.set_meta("artifact", artifact)
	panel.set_meta("index", index)
	
	return panel


func _check_merges() -> void:
	"""Check for available merges and populate merge section."""
	if not merge_section or not merge_slots:
		return
	
	# Clear existing merge slots
	for child: Node in merge_slots.get_children():
		child.queue_free()
	
	var available_merges: Array[Dictionary] = MergeManager.check_for_merges()
	
	if available_merges.size() == 0:
		merge_section.visible = false
		return
	
	merge_section.visible = true
	
	# Create merge option for each available merge
	for merge_data: Dictionary in available_merges:
		var slot: PanelContainer = _create_merge_slot(merge_data)
		merge_slots.add_child(slot)


func _create_merge_slot(merge_data: Dictionary) -> PanelContainer:
	var card_def = CardDatabase.get_card(merge_data.card_id)
	if not card_def:
		return PanelContainer.new()
	
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 100)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.15)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.8, 0.4)
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Left side: card info
	var info_vbox: VBoxContainer = VBoxContainer.new()
	hbox.add_child(info_vbox)
	
	var name_label: Label = Label.new()
	name_label.text = card_def.card_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	info_vbox.add_child(name_label)
	
	var tier_label: Label = Label.new()
	tier_label.text = "3x T%d → 1x T%d" % [merge_data.tier, merge_data.tier + 1]
	tier_label.add_theme_font_size_override("font_size", 12)
	tier_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	info_vbox.add_child(tier_label)
	
	# Preview stat change
	var preview: Dictionary = MergeManager.get_upgrade_preview(merge_data.card_id, merge_data.tier)
	if preview.has("stat_changes"):
		var stat_text: String = ""
		for stat_name: String in preview.stat_changes:
			var change: Dictionary = preview.stat_changes[stat_name]
			stat_text += "%s: %d → %d  " % [stat_name.capitalize(), change.old, change.new]
		if stat_text != "":
			var stat_label: Label = Label.new()
			stat_label.text = stat_text
			stat_label.add_theme_font_size_override("font_size", 10)
			stat_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
			info_vbox.add_child(stat_label)
	
	# Right side: merge button
	var merge_btn: Button = Button.new()
	merge_btn.text = "⬆ Merge"
	merge_btn.custom_minimum_size = Vector2(70, 40)
	merge_btn.pressed.connect(_on_merge_pressed.bind(merge_data.card_id, merge_data.tier))
	hbox.add_child(merge_btn)
	
	return panel


func _calculate_card_price(card) -> int:  # card: CardDefinition
	var base: int = CARD_BASE_PRICE
	base += card.rarity * 20
	base += RunManager.current_wave * 5
	return base


func _update_ui() -> void:
	scrap_label.text = str(RunManager.scrap)
	
	remove_cost_label.text = "%d Scrap" % remove_cost
	heal_cost_label.text = "%d Scrap" % heal_cost
	reroll_cost_label.text = "%d Scrap" % reroll_cost
	
	# Refresh card/artifact displays to update price colors
	_populate_card_slots()
	_populate_artifact_slots()


func _on_scrap_changed(_amount: int) -> void:
	_update_ui()


func _on_shop_card_clicked(card_def, _tier: int, index: int) -> void:  # card_def: CardDefinition
	var price: int = _calculate_card_price(card_def)
	
	if RunManager.spend_scrap(price):
		AudioManager.play_shop_purchase()
		# Add card to deck
		RunManager.add_card_to_deck(card_def.card_id, 1)
		print("[Shop] Bought card: ", card_def.card_name)
		
		# Remove from shop
		shop_cards.remove_at(index)
		_populate_card_slots()
		_check_merges()  # Check if new card enables merge
	else:
		print("[Shop] Not enough scrap!")
		_show_not_enough_scrap()


func _on_artifact_buy_pressed(artifact: Dictionary, index: int) -> void:
	var price: int = artifact.cost
	
	if RunManager.spend_scrap(price):
		AudioManager.play_shop_purchase()
		# Add artifact
		ArtifactManager.acquire_artifact(artifact.artifact_id)
		print("[Shop] Bought artifact: ", artifact.artifact_name)
		
		# Remove from shop
		shop_artifacts.remove_at(index)
		_populate_artifact_slots()
	else:
		print("[Shop] Not enough scrap for artifact!")
		_show_not_enough_scrap()


func _on_merge_pressed(card_id: String, tier: int) -> void:
	"""Handle merge button press."""
	if MergeManager.execute_merge(card_id, tier):
		AudioManager.play_merge_complete()
		_check_merges()  # Refresh merge options
		_show_merge_success(card_id, tier + 1)


func _on_merge_completed(_card_id: String, _new_tier: int) -> void:
	"""Called when merge is completed."""
	_check_merges()


func _show_merge_success(card_id: String, new_tier: int) -> void:
	"""Show a brief success message for merge."""
	var card_def = CardDatabase.get_card(card_id)
	if not card_def:
		return
	
	var popup: Label = Label.new()
	popup.text = "✨ %s upgraded to Tier %d! ✨" % [card_def.card_name, new_tier]
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup.add_theme_constant_override("outline_size", 3)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(get_viewport_rect().size.x / 2 - 150, 100)
	add_child(popup)
	
	var tween: Tween = create_tween()
	tween.tween_property(popup, "position:y", 50, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)


func _show_not_enough_scrap() -> void:
	"""Show a brief 'not enough scrap' message."""
	AudioManager.play_error()
	var popup: Label = Label.new()
	popup.text = "Not enough Scrap!"
	popup.add_theme_font_size_override("font_size", 20)
	popup.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup.add_theme_constant_override("outline_size", 2)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(get_viewport_rect().size.x / 2 - 80, get_viewport_rect().size.y / 2)
	add_child(popup)
	
	var tween: Tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup.queue_free)


func _on_remove_card_pressed() -> void:
	if RunManager.scrap < remove_cost:
		_show_not_enough_scrap()
		return
	
	_show_deck_for_removal()


func _show_deck_for_removal() -> void:
	# Clear grid
	for child: Node in deck_grid.get_children():
		child.queue_free()
	
	# Populate with deck cards
	for i: int in range(RunManager.deck.size()):
		var entry: Dictionary = RunManager.deck[i]
		var card_def = CardDatabase.get_card(entry.card_id)  # CardDefinition
		if card_def:
			var card_ui: Control = card_ui_scene.instantiate()
			card_ui.check_playability = false  # Don't dim cards in deck removal view
			card_ui.setup(card_def, entry.tier, i)
			card_ui.card_clicked.connect(_on_remove_card_selected)
			deck_grid.add_child(card_ui)
	
	deck_view_panel.visible = true


func _on_remove_card_selected(card_def, _tier: int, index: int) -> void:  # card_def: CardDefinition
	if RunManager.spend_scrap(remove_cost):
		RunManager.remove_card_from_deck(index)
		remove_cost += 25  # Increase cost each time
		print("[Shop] Removed card: ", card_def.card_name)
		_check_merges()
	
	deck_view_panel.visible = false


func _on_deck_view_close() -> void:
	deck_view_panel.visible = false


func _on_heal_pressed() -> void:
	if RunManager.spend_scrap(heal_cost):
		RunManager.heal(10)
		heal_cost += 15  # Increase cost
		print("[Shop] Healed 10 HP")
	else:
		_show_not_enough_scrap()


func _on_reroll_pressed() -> void:
	if RunManager.spend_scrap(reroll_cost):
		reroll_count += 1
		reroll_cost = 10 + reroll_count * 10
		_refresh_shop()
		_check_merges()
		print("[Shop] Rerolled shop")
	else:
		_show_not_enough_scrap()


func _on_continue_pressed() -> void:
	GameManager.start_next_wave()


# === Deck Viewer Overlay Functions ===

func _create_deck_viewer_overlay() -> void:
	"""Create the deck viewer overlay for viewing the current run deck."""
	deck_viewer_overlay = CanvasLayer.new()
	deck_viewer_overlay.name = "DeckViewerOverlay"
	deck_viewer_overlay.layer = 50
	deck_viewer_overlay.visible = false
	add_child(deck_viewer_overlay)
	
	# Dimmer background
	var dimmer: ColorRect = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.85)
	deck_viewer_overlay.add_child(dimmer)
	
	# Main panel
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "DeckPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -450
	panel.offset_top = -400
	panel.offset_right = 450
	panel.offset_bottom = 400
	
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	panel_style.border_color = Color(0.5, 0.7, 0.9, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(16)
	panel_style.content_margin_left = 20.0
	panel_style.content_margin_right = 20.0
	panel_style.content_margin_top = 15.0
	panel_style.content_margin_bottom = 15.0
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	deck_viewer_overlay.add_child(panel)
	
	# VBox for content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	# Header with title and close button
	var header: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header)
	
	deck_viewer_title = Label.new()
	deck_viewer_title.text = "📚 YOUR DECK"
	deck_viewer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_viewer_title.add_theme_font_size_override("font_size", 28)
	deck_viewer_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	header.add_child(deck_viewer_title)
	
	var close_btn: Button = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(45, 45)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.flat = true
	close_btn.pressed.connect(_on_deck_viewer_close)
	header.add_child(close_btn)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Info label
	var info_label: Label = Label.new()
	info_label.text = "These are the cards in your current run deck."
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)
	
	# Scroll container for cards
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(860, 650)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Grid for cards
	deck_viewer_grid = GridContainer.new()
	deck_viewer_grid.columns = 5
	deck_viewer_grid.add_theme_constant_override("h_separation", 15)
	deck_viewer_grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(deck_viewer_grid)


func _on_view_deck_pressed() -> void:
	"""Called when the view deck button is pressed."""
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
			card_ui.check_playability = false  # Don't dim cards in deck viewer
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

func _create_dev_panel() -> void:
	"""Create a dev cheat panel in the top-right corner."""
	var dev_panel: PanelContainer = PanelContainer.new()
	dev_panel.name = "DevPanel"
	
	# Position in top-right corner using manual anchors
	dev_panel.anchor_left = 1.0
	dev_panel.anchor_right = 1.0
	dev_panel.anchor_top = 0.0
	dev_panel.anchor_bottom = 0.0
	dev_panel.offset_left = -180
	dev_panel.offset_top = 10
	dev_panel.offset_right = -10
	dev_panel.offset_bottom = 165
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.2, 0.9)
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.4, 0.4, 0.8)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	dev_panel.add_theme_stylebox_override("panel", style)
	
	# VBox for buttons
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	dev_panel.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "🔧 DEV"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Force Win button (skip to next wave)
	var win_btn: Button = Button.new()
	win_btn.text = "🏆 Skip Wave"
	win_btn.custom_minimum_size = Vector2(150, 30)
	win_btn.pressed.connect(_dev_skip_wave)
	vbox.add_child(win_btn)
	
	# Add Scrap button
	var scrap_btn: Button = Button.new()
	scrap_btn.text = "⚙️ +1000 Scrap"
	scrap_btn.custom_minimum_size = Vector2(150, 30)
	scrap_btn.pressed.connect(_dev_add_scrap)
	vbox.add_child(scrap_btn)
	
	# Full Heal button
	var heal_btn: Button = Button.new()
	heal_btn.text = "❤️ Full Heal"
	heal_btn.custom_minimum_size = Vector2(150, 30)
	heal_btn.pressed.connect(_dev_full_heal)
	vbox.add_child(heal_btn)
	
	add_child(dev_panel)


func _dev_skip_wave() -> void:
	"""Skip directly to next wave."""
	print("[DEV] Skip Wave triggered")
	GameManager.start_next_wave()


func _dev_add_scrap() -> void:
	"""Add 1000 scrap to the player."""
	print("[DEV] Add Scrap triggered")
	RunManager.add_scrap(1000)


func _dev_full_heal() -> void:
	"""Fully heal the player."""
	print("[DEV] Full Heal triggered")
	var heal_amount: int = RunManager.max_hp - RunManager.current_hp
	if heal_amount > 0:
		RunManager.heal(heal_amount)
