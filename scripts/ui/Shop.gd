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

# Stats panel (always visible in workshop)
var stats_panel: PanelContainer = null

# Tag tracker panel
var tag_tracker_panel: PanelContainer = null

# Merge popup (optional - created dynamically if needed)
var merge_popup: PanelContainer = null
var merge_card_name: Label = null
var merge_preview: Label = null
var merge_confirm_btn: Button = null

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

var shop_cards: Array = []  # Array of CardDefinition (can't type due to preload issues)
var shop_artifacts: Array = []  # Array of artifact data dictionaries
var shop_stat_upgrades: Array = []  # Brotato Economy: stat upgrades

# V2: Service costs calculated by ShopGenerator
var remove_cost: int = 10
var heal_cost: int = 10
var reroll_cost: int = 3

# Stat upgrades UI
var stat_upgrades_panel: PanelContainer = null
var stat_upgrades_container: HBoxContainer = null

var pending_merge_card_id: String = ""
var pending_merge_tier: int = 0

# V2: Use ShopGenerator for pricing
const CARD_BASE_PRICE: int = 30  # Fallback only


func _ready() -> void:
	_create_deck_viewer_overlay()
	_create_dev_panel()
	_create_stats_panel()
	_create_tag_tracker_panel()
	_create_stat_upgrades_panel()  # Brotato Economy
	_refresh_shop()
	_update_ui()
	_check_merges()
	
	RunManager.scrap_changed.connect(_on_scrap_changed)
	MergeManager.merge_completed.connect(_on_merge_completed)
	
	# Hide merge popup initially
	if merge_popup:
		merge_popup.visible = false


func _refresh_shop() -> void:
	# V2: Use ShopGenerator for biased card/artifact generation
	var wave: int = RunManager.current_wave
	
	# Generate biased shop cards (4 slots in V2)
	shop_cards = ShopGenerator.generate_shop_cards(wave)
	
	# Generate biased artifacts (3 slots in V2)
	shop_artifacts = ShopGenerator.generate_shop_artifacts(wave)
	
	# Brotato Economy: Generate stat upgrades
	shop_stat_upgrades = ShopGenerator.generate_shop_stat_upgrades()
	
	# Update service costs based on wave
	heal_cost = ShopGenerator.get_heal_cost(wave)
	remove_cost = ShopGenerator.get_remove_card_cost(wave)
	reroll_cost = ShopGenerator.get_reroll_cost(wave)
	
	_populate_card_slots()
	_populate_artifact_slots()
	_populate_stat_upgrades()


# V2: Artifact generation moved to ShopGenerator for family biasing


func _populate_card_slots() -> void:
	# Clear existing
	for child: Node in card_slots.get_children():
		child.queue_free()
	
	# Create card slots
	for i: int in range(shop_cards.size()):
		var card = shop_cards[i]  # CardDefinition
		var slot: VBoxContainer = _create_shop_card_slot(card, i)
		card_slots.add_child(slot)
	
	# Show "Sold Out" if empty
	if shop_cards.size() == 0:
		var sold_out: Label = Label.new()
		sold_out.text = "Sold Out"
		sold_out.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sold_out.add_theme_font_size_override("font_size", 20)
		card_slots.add_child(sold_out)


func _create_shop_card_slot(card, index: int) -> VBoxContainer:  # card: CardDefinition
	# Use VBoxContainer to hold card + price (no wrapper panel)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Card - use same size as combat (225x338 from CardUI.tscn)
	var card_ui: Control = card_ui_scene.instantiate()
	card_ui.check_playability = false  # Don't dim cards in shop
	card_ui.setup(card, 1, index)
	card_ui.card_clicked.connect(_on_shop_card_clicked)
	# Don't override minimum size - let it use its natural size from the scene
	vbox.add_child(card_ui)
	
	# Price label below card
	var price: int = _calculate_card_price(card)
	var price_label: Label = Label.new()
	price_label.text = "%d ⚙️" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 18)
	if RunManager.scrap >= price:
		price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	else:
		price_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	vbox.add_child(price_label)
	
	vbox.set_meta("card", card)
	vbox.set_meta("price", price)
	vbox.set_meta("index", index)
	
	return vbox


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
	# V2: Use ShopGenerator for consistent pricing
	return ShopGenerator.get_card_price(card, RunManager.current_wave)


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
		_update_tag_tracker()  # Update tag counts
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
		_update_tag_tracker()  # Update tag counts (deck changed)
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
		_update_ui()
		print("[Shop] Removed card: ", card_def.card_name)
		_check_merges()
		_update_tag_tracker()  # Update tag counts
	
	deck_view_panel.visible = false


func _on_deck_view_close() -> void:
	deck_view_panel.visible = false


func _on_heal_pressed() -> void:
	if RunManager.spend_scrap(heal_cost):
		# V2: Heal 30% of missing HP
		var missing_hp: int = RunManager.player_stats.max_hp - RunManager.current_hp
		var heal_amount: int = maxi(1, int(missing_hp * 0.3))
		RunManager.heal(heal_amount)
		_update_ui()
		print("[Shop] Healed %d HP (30%% of missing)" % heal_amount)
	else:
		_show_not_enough_scrap()


func _on_reroll_pressed() -> void:
	if RunManager.spend_scrap(reroll_cost):
		_refresh_shop()
		_check_merges()
		_update_ui()
		print("[Shop] Rerolled shop (cost: %d)" % reroll_cost)
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


# === Stats Panel Functions ===

func _create_stats_panel() -> void:
	"""Create the full stats panel on the left side of the workshop."""
	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	
	# Position on left side
	stats_panel.anchor_left = 0.0
	stats_panel.anchor_right = 0.0
	stats_panel.anchor_top = 0.0
	stats_panel.anchor_bottom = 0.0
	stats_panel.offset_left = 10
	stats_panel.offset_top = 10
	stats_panel.offset_right = 260
	stats_panel.offset_bottom = 470
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.7, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	stats_panel.add_theme_stylebox_override("panel", style)
	
	# Content container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	stats_panel.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "📊 BUILD STATS"
	title.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Stats display (RichTextLabel for BBCode)
	var stats_label: RichTextLabel = RichTextLabel.new()
	stats_label.name = "StatsLabel"
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.scroll_active = false
	stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_label.add_theme_font_size_override("normal_font_size", 12)
	vbox.add_child(stats_label)
	
	add_child(stats_panel)
	
	# Connect to stats changes for live updates
	if RunManager:
		if RunManager.has_signal("stats_changed"):
			RunManager.stats_changed.connect(_update_stats_panel)
		if RunManager.has_signal("hp_changed"):
			RunManager.hp_changed.connect(_on_stats_hp_changed)
		if RunManager.has_signal("armor_changed"):
			RunManager.armor_changed.connect(_on_stats_armor_changed)
	
	# Initial update
	_update_stats_panel()


func _on_stats_hp_changed(_current: int, _max_hp: int) -> void:
	_update_stats_panel()


func _on_stats_armor_changed(_amount: int) -> void:
	_update_stats_panel()


func _update_stats_panel() -> void:
	"""Update the stats panel with current player stats."""
	if not stats_panel:
		return
	
	var stats_label: RichTextLabel = stats_panel.find_child("StatsLabel", true, false) as RichTextLabel
	if not stats_label:
		return
	
	var stats = RunManager.player_stats
	if not stats:
		stats_label.text = "[color=#ff6666]No stats available[/color]"
		return
	
	var text: String = ""
	
	# Runtime state
	text += "[color=#ffcc66]━━ RUNTIME ━━[/color]\n"
	text += "HP: [color=#ff6666]%d/%d[/color]\n" % [RunManager.current_hp, stats.max_hp]
	text += "Armor: [color=#66ccff]%d[/color]\n" % RunManager.armor
	text += "Scrap: [color=#ffcc33]%d[/color]\n" % RunManager.scrap
	text += "Wave: [color=#ffaa33]%d[/color]\n" % RunManager.current_wave
	
	# Warden info
	if RunManager.current_warden:
		var warden_name: String = "Unknown"
		if RunManager.current_warden is WardenDefinition:
			warden_name = RunManager.current_warden.warden_name
		text += "Warden: [color=#66ff66]%s[/color]\n" % warden_name
	text += "\n"
	
	# Offense stats
	text += "[color=#ff6666]━━ OFFENSE ━━[/color]\n"
	text += "Gun Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.gun_damage_percent), stats.gun_damage_percent]
	text += "Hex Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.hex_damage_percent), stats.hex_damage_percent]
	text += "Barrier Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.barrier_damage_percent), stats.barrier_damage_percent]
	text += "Generic Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.generic_damage_percent), stats.generic_damage_percent]
	text += "\n"
	
	# Defense stats
	text += "[color=#66ccff]━━ DEFENSE ━━[/color]\n"
	text += "Armor Gain: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.armor_gain_percent), stats.armor_gain_percent]
	text += "Heal Power: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.heal_power_percent), stats.heal_power_percent]
	text += "Barrier Strength: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.barrier_strength_percent), stats.barrier_strength_percent]
	text += "\n"
	
	# Economy stats
	text += "[color=#ffcc33]━━ ECONOMY ━━[/color]\n"
	text += "Energy/Turn: [color=#ffff66]%d[/color]\n" % stats.energy_per_turn
	text += "Draw/Turn: [color=#66aaff]%d[/color]\n" % stats.draw_per_turn
	text += "Hand Size: [color=#aaaaaa]%d[/color]\n" % stats.hand_size_max
	text += "Scrap Gain: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.scrap_gain_percent), stats.scrap_gain_percent]
	text += "Shop Prices: [color=#%s]%.0f%%[/color]\n" % [_get_inverse_stat_color(stats.shop_price_percent), stats.shop_price_percent]
	text += "\n"
	
	# Ring damage
	text += "[color=#aa66ff]━━ RING DMG ━━[/color]\n"
	text += "vs Melee: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_vs_melee_percent), stats.damage_vs_melee_percent]
	text += "vs Close: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_vs_close_percent), stats.damage_vs_close_percent]
	text += "vs Mid: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_vs_mid_percent), stats.damage_vs_mid_percent]
	text += "vs Far: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_vs_far_percent), stats.damage_vs_far_percent]
	
	stats_label.text = text


func _get_stat_color(value: float) -> String:
	"""Get color hex based on whether value is above, below, or at 100%."""
	if value > 100.0:
		return "66ff66"  # Green for bonus
	elif value < 100.0:
		return "ff6666"  # Red for penalty
	else:
		return "aaaaaa"  # Gray for neutral


func _get_inverse_stat_color(value: float) -> String:
	"""Get color hex for inverse stats (lower is better, like shop prices)."""
	if value < 100.0:
		return "66ff66"  # Green for bonus (cheaper)
	elif value > 100.0:
		return "ff6666"  # Red for penalty (more expensive)
	else:
		return "aaaaaa"  # Gray for neutral


# === Tag Tracker Panel Functions ===

func _create_tag_tracker_panel() -> void:
	"""Create a panel showing tag counts from player's deck."""
	tag_tracker_panel = PanelContainer.new()
	tag_tracker_panel.name = "TagTrackerPanel"
	
	# Position on right side of stats panel
	tag_tracker_panel.anchor_left = 0.0
	tag_tracker_panel.anchor_right = 0.0
	tag_tracker_panel.anchor_top = 0.0
	tag_tracker_panel.anchor_bottom = 0.0
	tag_tracker_panel.offset_left = 270  # Right of stats panel (260 + 10 gap)
	tag_tracker_panel.offset_top = 10
	tag_tracker_panel.offset_right = 470
	tag_tracker_panel.offset_bottom = 400
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.4, 0.8, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	tag_tracker_panel.add_theme_stylebox_override("panel", style)
	
	# Content container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	tag_tracker_panel.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "🏷️ TAG COUNTS"
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Tag display (RichTextLabel for BBCode)
	var tag_label: RichTextLabel = RichTextLabel.new()
	tag_label.name = "TagLabel"
	tag_label.bbcode_enabled = true
	tag_label.fit_content = true
	tag_label.scroll_active = false
	tag_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tag_label.add_theme_font_size_override("normal_font_size", 12)
	vbox.add_child(tag_label)
	
	add_child(tag_tracker_panel)
	
	# Initial update
	_update_tag_tracker()


func _update_tag_tracker() -> void:
	"""Update the tag tracker panel with current deck tag counts."""
	if not tag_tracker_panel:
		return
	
	var tag_label: RichTextLabel = tag_tracker_panel.find_child("TagLabel", true, false) as RichTextLabel
	if not tag_label:
		return
	
	# Count tags from deck
	var tag_counts: Dictionary = {}
	
	for entry: Dictionary in RunManager.deck:
		var card_def = CardDatabase.get_card(entry.card_id)
		if card_def:
			for tag: Variant in card_def.tags:
				if tag is String:
					if not tag_counts.has(tag):
						tag_counts[tag] = 0
					tag_counts[tag] += 1
	
	# Build display text
	var text: String = ""
	
	# Core type tags
	text += "[color=#ff9966]━━ CORE TYPES ━━[/color]\n"
	for core_tag: String in TagConstants.CORE_TYPES:
		var count: int = tag_counts.get(core_tag, 0)
		var display_name: String = TagConstants.get_core_type_display_name(core_tag)
		var color: String = _get_tag_count_color(count)
		var icon: String = _get_tag_icon(core_tag)
		text += "%s %s: [color=#%s]%d[/color]\n" % [icon, display_name, color, count]
	
	text += "\n"
	
	# Family tags
	text += "[color=#aa66ff]━━ FAMILIES ━━[/color]\n"
	for family_tag: String in TagConstants.FAMILY_TAGS:
		var count: int = tag_counts.get(family_tag, 0)
		var display_name: String = TagConstants.get_family_display_name(family_tag)
		var color: String = _get_tag_count_color(count)
		var icon: String = _get_family_tag_icon(family_tag)
		text += "%s %s: [color=#%s]%d[/color]\n" % [icon, display_name, color, count]
	
	tag_label.text = text


func _get_tag_count_color(count: int) -> String:
	"""Get color hex based on tag count."""
	if count == 0:
		return "666666"  # Gray for none
	elif count <= 2:
		return "aaaaaa"  # Light gray for few
	elif count <= 5:
		return "66ccff"  # Blue for moderate
	elif count <= 8:
		return "66ff66"  # Green for good
	else:
		return "ffcc33"  # Gold for many


func _get_tag_icon(tag: String) -> String:
	"""Get an icon for a core type tag."""
	match tag:
		TagConstants.TAG_GUN:
			return "🔫"
		TagConstants.TAG_HEX:
			return "🔮"
		TagConstants.TAG_BARRIER:
			return "🛡️"
		TagConstants.TAG_DEFENSE:
			return "🛡️"
		TagConstants.TAG_SKILL:
			return "⚡"
		TagConstants.TAG_ENGINE:
			return "⚙️"
		_:
			return "•"


func _get_family_tag_icon(tag: String) -> String:
	"""Get an icon for a family tag."""
	match tag:
		TagConstants.TAG_LIFEDRAIN:
			return "🩸"
		TagConstants.TAG_HEX_RITUAL:
			return "🌑"
		TagConstants.TAG_FORTRESS:
			return "🏰"
		TagConstants.TAG_BARRIER_TRAP:
			return "💥"
		TagConstants.TAG_VOLATILE:
			return "💀"
		TagConstants.TAG_ENGINE_CORE:
			return "🔋"
		_:
			return "•"


# === Stat Upgrades Panel Functions (Brotato Economy) ===

func _create_stat_upgrades_panel() -> void:
	"""Create the stat upgrades panel above the cards section."""
	stat_upgrades_panel = PanelContainer.new()
	stat_upgrades_panel.name = "StatUpgradesPanel"
	
	# Position above the main content
	stat_upgrades_panel.anchor_left = 0.5
	stat_upgrades_panel.anchor_right = 0.5
	stat_upgrades_panel.anchor_top = 0.0
	stat_upgrades_panel.anchor_bottom = 0.0
	stat_upgrades_panel.offset_left = -400
	stat_upgrades_panel.offset_top = 60
	stat_upgrades_panel.offset_right = 400
	stat_upgrades_panel.offset_bottom = 180
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	style.border_color = Color(0.6, 0.8, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	stat_upgrades_panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	stat_upgrades_panel.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "📈 STAT UPGRADES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.6, 0.9, 0.5))
	vbox.add_child(title)
	
	# Container for upgrade slots
	stat_upgrades_container = HBoxContainer.new()
	stat_upgrades_container.name = "UpgradeSlots"
	stat_upgrades_container.add_theme_constant_override("separation", 15)
	stat_upgrades_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stat_upgrades_container)
	
	add_child(stat_upgrades_panel)


func _populate_stat_upgrades() -> void:
	"""Populate the stat upgrades container."""
	if not stat_upgrades_container:
		return
	
	# Clear existing
	for child: Node in stat_upgrades_container.get_children():
		child.queue_free()
	
	if shop_stat_upgrades.size() == 0:
		stat_upgrades_panel.visible = false
		return
	
	stat_upgrades_panel.visible = true
	
	for i: int in range(shop_stat_upgrades.size()):
		var upgrade: Dictionary = shop_stat_upgrades[i]
		var slot: PanelContainer = _create_stat_upgrade_slot(upgrade, i)
		stat_upgrades_container.add_child(slot)


func _create_stat_upgrade_slot(upgrade: Dictionary, index: int) -> PanelContainer:
	"""Create a UI slot for a stat upgrade."""
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 80)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.08)
	style.border_color = Color(0.4, 0.7, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Icon
	var icon: Label = Label.new()
	icon.text = upgrade.icon
	icon.add_theme_font_size_override("font_size", 32)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)
	
	# Info column
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)
	
	# Name
	var name_label: Label = Label.new()
	name_label.text = upgrade.name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.8))
	info_vbox.add_child(name_label)
	
	# Current value
	var current_label: Label = Label.new()
	var value_str: String = ""
	if upgrade.stat in ["gun_damage_percent", "hex_damage_percent", "armor_gain_percent", "scrap_gain_percent", "shop_price_percent"]:
		value_str = "Current: %.0f%%" % upgrade.current_value
	else:
		value_str = "Current: %d" % int(upgrade.current_value)
	current_label.text = value_str
	current_label.add_theme_font_size_override("font_size", 10)
	current_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6))
	info_vbox.add_child(current_label)
	
	# Price + Buy button
	var buy_hbox: HBoxContainer = HBoxContainer.new()
	buy_hbox.add_theme_constant_override("separation", 5)
	info_vbox.add_child(buy_hbox)
	
	var price_label: Label = Label.new()
	price_label.text = "%d ⚙️" % upgrade.price
	price_label.add_theme_font_size_override("font_size", 12)
	if RunManager.scrap >= upgrade.price:
		price_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	else:
		price_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	buy_hbox.add_child(price_label)
	
	var buy_btn: Button = Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(50, 25)
	buy_btn.pressed.connect(_on_stat_upgrade_buy_pressed.bind(upgrade.upgrade_id, index))
	buy_hbox.add_child(buy_btn)
	
	panel.set_meta("upgrade", upgrade)
	panel.set_meta("index", index)
	
	return panel


func _on_stat_upgrade_buy_pressed(upgrade_id: String, index: int) -> void:
	"""Handle stat upgrade purchase."""
	if ShopGenerator.purchase_stat_upgrade(upgrade_id):
		AudioManager.play_shop_purchase()
		print("[Shop] Bought stat upgrade: %s" % upgrade_id)
		
		# Remove from shop
		shop_stat_upgrades.remove_at(index)
		_populate_stat_upgrades()
		_update_stats_panel()  # Refresh stats display
		_update_ui()
	else:
		print("[Shop] Cannot buy stat upgrade: %s" % upgrade_id)
		_show_not_enough_scrap()
