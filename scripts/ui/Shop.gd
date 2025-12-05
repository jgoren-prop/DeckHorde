extends Control
## Shop - Post-wave shop screen with cards, artifacts, merges, and services
## Uses ShopPanelBuilder and ShopStatsFormatter for UI creation (see scripts/ui/shop/)

# Note: ShopPanelBuilder and ShopStatsFormatter are globally available via class_name
# No const needed - use the class_name directly

@onready var scrap_label: Label = $MarginContainer/VBox/Header/ScrapContainer/ScrapLabel
@onready var card_slots: HBoxContainer = $MarginContainer/VBox/CardsSection/CardSlots
@onready var artifact_slots: HBoxContainer = $MarginContainer/VBox/ArtifactsSection/ArtifactSlots
@onready var merge_section: Control = $MarginContainer/VBox/MergeSection
@onready var merge_slots: HBoxContainer = $MarginContainer/VBox/MergeSection/MergeSlots
@onready var remove_cost_label: Label = $RightPanel/ServicesSection/ServiceButtons/RemoveCard/Cost
@onready var reroll_cost_label: Label = $RightPanel/ServicesSection/ServiceButtons/Reroll/Cost
@onready var deck_view_panel: PanelContainer = $DeckViewPanel
@onready var deck_grid: GridContainer = $DeckViewPanel/VBox/ScrollContainer/DeckGrid

# Card collection panel (editable in scene)
@onready var card_collection_panel: PanelContainer = $CardCollectionPanel
@onready var collection_title: Label = $CardCollectionPanel/VBox/CollectionTitle
@onready var card_scroll: ScrollContainer = $CardCollectionPanel/VBox/CardScroll
@onready var cards_container: Control = $CardCollectionPanel/VBox/CardScroll/CardsContainer

# Deck viewer overlay (view-only, created dynamically)
var deck_viewer_overlay: CanvasLayer = null
var deck_viewer_grid: GridContainer = null
var deck_viewer_title: Label = null
var deck_viewer_close_btn: Button = null

# Stats panel (always visible in workshop)
var stats_panel: PanelContainer = null

# Tag tracker panel
var tag_tracker_panel: PanelContainer = null

# Owned artifacts panel (shows all artifacts player owns)
var owned_artifacts_panel: PanelContainer = null

# Tooltip for artifacts
var artifact_tooltip: PanelContainer = null

# Dev panel reference
var dev_panel: PanelContainer = null
var dev_panel_vbox: VBoxContainer = null

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

var shop_cards: Array = []  # Array of CardDefinition (can't type due to preload issues)
var shop_artifacts: Array = []  # Array of artifact data dictionaries

# V2: Service costs calculated by ShopGenerator
var remove_cost: int = 10
var reroll_cost: int = 3

var pending_merge_card_id: String = ""
var pending_merge_tier: int = 0

# V2: Use ShopGenerator for pricing
const CARD_BASE_PRICE: int = 30  # Fallback only


func _ready() -> void:
	# V4: Reset reroll count for new shop visit
	ShopGenerator.reset_shop_reroll_count()
	
	# Apply interest and show XP summary when entering shop
	_apply_wave_rewards()
	
	# Use ShopPanelBuilder for dynamic UI creation
	_setup_deck_viewer_overlay()
	_setup_dev_panel()
	_setup_stats_panel()
	_setup_tag_tracker_panel()
	_setup_owned_artifacts_panel()
	_setup_card_collection_panel()
	_setup_artifact_tooltip()
	
	_refresh_shop()
	_update_ui()
	_check_merges()
	
	RunManager.scrap_changed.connect(_on_scrap_changed)
	MergeManager.merge_completed.connect(_on_merge_completed)


func _setup_deck_viewer_overlay() -> void:
	"""Create deck viewer overlay using ShopPanelBuilder."""
	var result: Dictionary = ShopPanelBuilder.create_deck_viewer_overlay(self)
	deck_viewer_overlay = result.overlay
	deck_viewer_grid = result.grid
	deck_viewer_title = result.title
	deck_viewer_close_btn = result.close_button
	deck_viewer_close_btn.pressed.connect(_on_deck_viewer_close)


func _setup_dev_panel() -> void:
	"""Create dev panel using ShopPanelBuilder."""
	dev_panel = ShopPanelBuilder.create_dev_panel(self)
	dev_panel_vbox = dev_panel.get_child(0) as VBoxContainer
	
	# Add dev buttons
	ShopPanelBuilder.create_dev_button(dev_panel_vbox, "🏆 Skip Wave", _dev_skip_wave)
	ShopPanelBuilder.create_dev_button(dev_panel_vbox, "⚙️ +1000 Scrap", _dev_add_scrap)
	ShopPanelBuilder.create_dev_button(dev_panel_vbox, "❤️ Full Heal", _dev_full_heal)


func _setup_stats_panel() -> void:
	"""Create stats panel using ShopPanelBuilder."""
	stats_panel = ShopPanelBuilder.create_stats_panel(self)
	
	# Connect to stats changes for live updates
	if RunManager:
		if RunManager.has_signal("stats_changed"):
			RunManager.stats_changed.connect(_update_stats_panel)
		if RunManager.has_signal("hp_changed"):
			RunManager.hp_changed.connect(_on_stats_hp_changed)
		if RunManager.has_signal("armor_changed"):
			RunManager.armor_changed.connect(_on_stats_armor_changed)
	
	_update_stats_panel()


func _setup_tag_tracker_panel() -> void:
	"""Create tag tracker panel using ShopPanelBuilder."""
	tag_tracker_panel = ShopPanelBuilder.create_tag_tracker_panel(self)
	_update_tag_tracker()


func _setup_owned_artifacts_panel() -> void:
	"""Create owned artifacts panel using ShopPanelBuilder."""
	owned_artifacts_panel = ShopPanelBuilder.create_owned_artifacts_panel(self)
	_update_owned_artifacts()


func _setup_card_collection_panel() -> void:
	"""Style the card collection panel."""
	if not card_collection_panel:
		return
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.06, 0.95)
	style.border_width_top = 2
	style.border_color = Color(0.4, 0.5, 0.7, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	card_collection_panel.add_theme_stylebox_override("panel", style)
	
	_update_card_collection()


func _setup_artifact_tooltip() -> void:
	"""Create artifact tooltip using ShopPanelBuilder."""
	artifact_tooltip = ShopPanelBuilder.create_artifact_tooltip(self)


func _apply_wave_rewards() -> void:
	"""Apply interest and show XP/level-up info when entering shop."""
	# Apply interest
	var interest_data: Dictionary = RunManager.get_interest_preview()
	var interest_amount: int = RunManager.apply_interest()
	
	if interest_amount > 0:
		_show_interest_popup(interest_data, interest_amount)
	
	# Show XP summary
	var xp_info: Dictionary = RunManager.get_xp_info()
	if xp_info.xp_this_wave > 0 or xp_info.levels_this_wave > 0:
		_show_xp_popup(xp_info)


func _show_interest_popup(data: Dictionary, earned: int) -> void:
	"""Show a brief interest popup."""
	var popup: Label = Label.new()
	popup.text = "💰 +%d Scrap (Interest: %d%% of %d)" % [earned, data.interest_rate, data.current_scrap]
	popup.add_theme_font_size_override("font_size", 20)
	popup.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup.add_theme_constant_override("outline_size", 3)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(get_viewport_rect().size.x / 2 - 180, 80)
	add_child(popup)
	
	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)


func _show_xp_popup(xp_info: Dictionary) -> void:
	"""Show XP/level-up popup."""
	var popup: Label = Label.new()
	if xp_info.levels_this_wave > 0:
		popup.text = "⭐ LEVEL UP! Level %d (+%d Max HP)" % [xp_info.level, xp_info.levels_this_wave]
		popup.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		popup.text = "✨ +%d XP (%d/%d to Level %d)" % [xp_info.xp_this_wave, xp_info.current_xp, xp_info.required_xp, xp_info.level + 1]
		popup.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	popup.add_theme_font_size_override("font_size", 18)
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup.add_theme_constant_override("outline_size", 3)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(get_viewport_rect().size.x / 2 - 180, 110)
	add_child(popup)
	
	var tween: Tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)


func _refresh_shop() -> void:
	# V4: Use ShopGenerator for biased card/artifact generation
	var wave: int = RunManager.current_wave
	
	# Generate biased shop cards (4 slots)
	shop_cards = ShopGenerator.generate_shop_cards(wave)
	
	# Generate biased artifacts (3 slots)
	shop_artifacts = ShopGenerator.generate_shop_artifacts(wave)
	
	# Update service costs based on wave and V4 reroll count
	remove_cost = ShopGenerator.get_remove_card_cost(wave)
	reroll_cost = ShopGenerator.get_reroll_cost(wave)
	
	_populate_card_slots()
	_populate_artifact_slots()
	
	# V4: Check for shop-clearing reward after refresh
	_check_shop_clearing_reward()


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
	# Minimal hover effect for shop (subtle scale, no lift)
	card_ui.hover_scale_amount = Vector2(1.03, 1.03)
	card_ui.hover_lift_amount = 5.0
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
	# Fixed size panel - large enough to fit all content without text changing size
	panel.custom_minimum_size = Vector2(180, 200)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.clip_contents = true  # Clip any overflow
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	# Add padding inside the panel
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	
	# Border color by rarity (0=common, 1=uncommon, 2=rare, 3=legendary)
	var rarity: int = artifact.get("rarity", 0)
	match rarity:
		0: style.border_color = Color(0.5, 0.5, 0.5)  # Common - Gray
		1: style.border_color = Color(0.3, 0.8, 0.3)  # Uncommon - Green
		2: style.border_color = Color(0.3, 0.6, 1.0)  # Rare - Blue
		3: style.border_color = Color(1.0, 0.8, 0.3)  # Legendary - Gold
		_: style.border_color = Color(0.5, 0.5, 0.5)  # Default to common
	
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	# Icon
	var icon: Label = Label.new()
	icon.text = artifact.get("icon", "💎")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 32)
	vbox.add_child(icon)
	
	# Name
	var name_label: Label = Label.new()
	name_label.text = artifact.get("name", "Unknown")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	vbox.add_child(name_label)
	
	# Description - fixed height container to prevent expansion
	var desc_container: Control = Control.new()
	desc_container.custom_minimum_size = Vector2(160, 55)  # Fixed height for description area
	desc_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	desc_container.clip_contents = true
	vbox.add_child(desc_container)
	
	var desc_label: Label = Label.new()
	desc_label.text = artifact.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	desc_container.add_child(desc_label)
	
	# Spacer to push price and button to bottom
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Price
	var price: int = artifact.get("cost", 0)
	var price_label: Label = Label.new()
	price_label.text = "%d ⚙️" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 14)
	if RunManager.scrap >= price:
		price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	else:
		price_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	vbox.add_child(price_label)
	
	# Buy button
	var buy_btn: Button = Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(80, 30)
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
	
	# V4: Update reroll cost with current reroll count, or show FREE if reward available
	reroll_cost = ShopGenerator.get_reroll_cost(RunManager.current_wave)
	if ShopGenerator.has_shop_clearing_reward():
		reroll_cost_label.text = "FREE!"
		reroll_cost_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		reroll_cost_label.text = "%d Scrap" % reroll_cost
		reroll_cost_label.remove_theme_color_override("font_color")
	
	# Refresh card/artifact displays to update price colors
	_populate_card_slots()
	_populate_artifact_slots()
	
	# Refresh owned artifacts and card collection displays
	_update_owned_artifacts()
	_update_card_collection()


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
		_update_card_collection()  # Update card collection display
		
		# V4: Check for shop-clearing reward
		_check_shop_clearing_reward()
	else:
		print("[Shop] Not enough scrap!")
		_show_not_enough_scrap()


func _on_artifact_buy_pressed(artifact: Dictionary, index: int) -> void:
	var price: int = artifact.get("cost", 0)
	
	if RunManager.spend_scrap(price):
		AudioManager.play_shop_purchase()
		# Add artifact
		ArtifactManager.equip_artifact(artifact.get("artifact_id", ""))
		print("[Shop] Bought artifact: ", artifact.get("name", "Unknown"))
		
		# Remove from shop
		shop_artifacts.remove_at(index)
		_populate_artifact_slots()
		_update_owned_artifacts()  # Update owned artifacts display
		
		# V4: Check for shop-clearing reward
		_check_shop_clearing_reward()
	else:
		print("[Shop] Not enough scrap for artifact!")
		_show_not_enough_scrap()


func _on_merge_pressed(card_id: String, tier: int) -> void:
	"""Handle merge button press."""
	if MergeManager.execute_merge(card_id, tier):
		AudioManager.play_merge_complete()
		_check_merges()  # Refresh merge options
		_update_tag_tracker()  # Update tag counts (deck changed)
		_update_card_collection()  # Update card collection display
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
			# Minimal hover effect (subtle scale, no lift)
			card_ui.hover_scale_amount = Vector2(1.03, 1.03)
			card_ui.hover_lift_amount = 5.0
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
		_update_card_collection()  # Update card collection display
	
	deck_view_panel.visible = false


func _on_deck_view_close() -> void:
	deck_view_panel.visible = false


func _on_reroll_pressed() -> void:
	# V4: Check for free reroll from shop-clearing reward first
	if ShopGenerator.consume_shop_clearing_reward():
		_refresh_shop()
		_check_merges()
		_update_ui()
		_show_free_reroll_popup()
		print("[Shop] V4: Free reroll used (shop-clearing reward)")
		return
	
	if RunManager.spend_scrap(reroll_cost):
		# V4: Increment reroll count AFTER successful reroll
		ShopGenerator.increment_reroll_count()
		_refresh_shop()
		_check_merges()
		_update_ui()
		print("[Shop] Rerolled shop (cost: %d, reroll count: %d)" % [reroll_cost, ShopGenerator.current_shop_reroll_count])
	else:
		_show_not_enough_scrap()


func _check_shop_clearing_reward() -> void:
	"""V4: Check if shop-clearing reward should be granted."""
	if ShopGenerator.check_shop_clearing_reward(shop_cards.size(), shop_artifacts.size()):
		_show_shop_cleared_popup()


func _show_free_reroll_popup() -> void:
	"""V4: Show popup when free reroll is used."""
	var popup: Label = Label.new()
	popup.text = "🎁 FREE REROLL!"
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup.add_theme_constant_override("outline_size", 3)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(get_viewport_rect().size.x / 2 - 100, get_viewport_rect().size.y / 2 - 50)
	add_child(popup)
	
	var tween: Tween = create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 50, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.8)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)


func _show_shop_cleared_popup() -> void:
	"""V4: Show popup when shop is cleared and free reroll is available."""
	var popup: Label = Label.new()
	popup.text = "🛒 Shop Cleared! Free Reroll Available!"
	popup.add_theme_font_size_override("font_size", 20)
	popup.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup.add_theme_constant_override("outline_size", 3)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(get_viewport_rect().size.x / 2 - 180, 80)
	add_child(popup)
	
	var tween: Tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)


func _on_continue_pressed() -> void:
	GameManager.start_next_wave()


# === Deck Viewer Overlay Functions ===

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
	RunManager.current_hp = RunManager.max_hp
	RunManager.hp_changed.emit(RunManager.current_hp, RunManager.max_hp)


# === Stats Panel Functions ===

func _on_stats_hp_changed(_current: int, _max_hp: int) -> void:
	_update_stats_panel()


func _on_stats_armor_changed(_amount: int) -> void:
	_update_stats_panel()


func _update_stats_panel() -> void:
	"""Update the stats panel with current player stats using ShopStatsFormatter."""
	if not stats_panel:
		return
	
	var stats_label: RichTextLabel = stats_panel.find_child("StatsLabel", true, false) as RichTextLabel
	if not stats_label:
		return
	
	stats_label.text = ShopStatsFormatter.format_player_stats(
		RunManager.player_stats,
		RunManager.current_hp,
		RunManager.armor,
		RunManager.scrap,
		RunManager.current_wave,
		RunManager.current_warden
	)


# === Tag Tracker Panel Functions ===

func _update_tag_tracker() -> void:
	"""Update the tag tracker panel with current deck tag counts using ShopStatsFormatter."""
	if not tag_tracker_panel:
		return
	
	var tag_label: RichTextLabel = tag_tracker_panel.find_child("TagLabel", true, false) as RichTextLabel
	if not tag_label:
		return
	
	tag_label.text = ShopStatsFormatter.format_tag_counts(RunManager.deck)


# === Owned Artifacts Panel Functions ===

func _update_owned_artifacts() -> void:
	"""Update the owned artifacts display."""
	if not owned_artifacts_panel:
		return
	
	var grid: GridContainer = owned_artifacts_panel.find_child("ArtifactGrid", true, false) as GridContainer
	if not grid:
		return
	
	# Clear existing
	for child: Node in grid.get_children():
		child.queue_free()
	
	# Get unique equipped artifacts with counts
	var unique_artifacts: Array = ArtifactManager.get_unique_equipped_artifacts()
	
	if unique_artifacts.size() == 0:
		var empty_label: Label = Label.new()
		empty_label.text = "No artifacts yet"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		grid.add_child(empty_label)
		return
	
	# Create artifact icons using ShopPanelBuilder
	for data: Dictionary in unique_artifacts:
		var artifact = data.artifact
		var count: int = data.count
		var icon_btn: Button = ShopPanelBuilder.create_artifact_icon(
			artifact, count, _on_artifact_icon_hover, _on_artifact_icon_exit
		)
		grid.add_child(icon_btn)




func _on_artifact_icon_hover(container: Control) -> void:
	"""Show tooltip when hovering over an artifact icon."""
	if not artifact_tooltip:
		return
	
	var artifact = container.get_meta("artifact")
	if not artifact:
		return
	
	var count: int = container.get_meta("count")
	
	# Update tooltip content
	var name_label: Label = artifact_tooltip.find_child("NameLabel", true, false) as Label
	var desc_label: Label = artifact_tooltip.find_child("DescLabel", true, false) as Label
	
	if name_label:
		var count_text: String = " (x%d)" % count if count > 1 else ""
		name_label.text = "%s %s%s" % [artifact.icon, artifact.artifact_name, count_text]
	
	if desc_label:
		desc_label.text = artifact.description
	
	# Position tooltip near the icon
	var global_pos: Vector2 = container.global_position
	artifact_tooltip.global_position = global_pos + Vector2(50, -20)
	artifact_tooltip.visible = true


func _on_artifact_icon_exit() -> void:
	"""Hide tooltip when leaving an artifact icon."""
	if artifact_tooltip:
		artifact_tooltip.visible = false


# === Card Collection Panel Functions ===

# Store references to card UIs for hover effects
var collection_card_uis: Array[Control] = []
var hovered_card_index: int = -1

func _update_card_collection() -> void:
	"""Update the card collection display - all cards in a horizontal row."""
	if not card_collection_panel or not cards_container:
		return
	
	var container: Control = cards_container
	var title_label: Label = collection_title
	var scroll: ScrollContainer = card_scroll
	
	if not container:
		return
	
	# Clear existing
	for child: Node in container.get_children():
		child.queue_free()
	collection_card_uis.clear()
	hovered_card_index = -1
	
	# Update title
	if title_label:
		title_label.text = "📚 YOUR DECK (%d cards)" % RunManager.deck.size()
	
	if RunManager.deck.size() == 0:
		var empty_label: Label = Label.new()
		empty_label.text = "Your deck is empty!"
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.position = Vector2(400, 70)
		container.add_child(empty_label)
		return
	
	# Sort cards by core type for visual grouping
	var sorted_cards: Array[Dictionary] = []
	var type_order: Array[String] = ["gun", "hex", "barrier", "defense", "skill", "engine", ""]
	
	for type_tag: String in type_order:
		for i: int in range(RunManager.deck.size()):
			var entry: Dictionary = RunManager.deck[i]
			var card_def = CardDatabase.get_card(entry.card_id)
			if card_def:
				var core_type: String = card_def.get_core_type()
				if core_type == type_tag or (type_tag == "" and core_type not in type_order):
					sorted_cards.append({"card": card_def, "tier": entry.tier, "index": i})
	
	# Calculate card sizing - 90% of scroll container height (not panel, which includes title)
	var scroll_height: float = scroll.size.y if scroll.size.y > 0.0 else 280.0
	var target_card_height: float = scroll_height * 0.9
	var base_card_height: float = 325.0  # CardUI base height
	var base_card_width: float = 225.0   # CardUI base width
	var card_scale: float = target_card_height / base_card_height
	
	var card_count: int = sorted_cards.size()
	var card_width: float = base_card_width * card_scale
	var card_height: float = base_card_height * card_scale
	var card_spacing: float = card_width * 0.4  # Overlap amount (40% of card width)
	
	# Calculate total width: first card full width + remaining cards overlap
	var total_width: float = card_width + (card_count - 1) * card_spacing if card_count > 0 else 0.0
	
	# Set container width to ensure proper scrolling
	container.custom_minimum_size.x = total_width + 100
	
	# Calculate starting X so the center of all cards aligns with screen center
	var viewport_width: float = get_viewport_rect().size.x
	var start_x: float = (viewport_width - total_width) / 2.0
	
	# Calculate Y to position cards with bottoms just above the scroll container bottom
	var bottom_margin: float = 8.0  # Small margin above bottom
	var base_y: float = scroll_height - card_height - bottom_margin
	
	# Create all cards
	for i: int in range(card_count):
		var card_data: Dictionary = sorted_cards[i]
		var card_def = card_data.card
		var tier: int = card_data.tier
		var deck_index: int = card_data.index
		
		# Create card UI
		var card_ui: Control = card_ui_scene.instantiate()
		card_ui.check_playability = false
		# IMPORTANT: Fully disable CardUI's internal hover - we handle it ourselves
		card_ui.enable_hover_scale = false
		
		# Scale down the cards
		card_ui.scale = Vector2(card_scale, card_scale)
		
		# Position cards in a row with overlap, vertically centered
		var x_pos: float = start_x + i * card_spacing
		var y_pos: float = base_y
		
		card_ui.position = Vector2(x_pos, y_pos)
		card_ui.z_index = i  # Stack order
		
		container.add_child(card_ui)
		card_ui.setup(card_def, tier, deck_index)
		
		# Store reference for hover effects
		collection_card_uis.append(card_ui)
		
		# Connect to click_area's mouse signals for reliable hover detection
		# (CardUI's own mouse signals can be blocked by the click_area button)
		card_ui.click_area.mouse_entered.connect(_on_collection_card_hover.bind(i))
		card_ui.click_area.mouse_exited.connect(_on_collection_card_exit.bind(i))
	
	# Call deferred to ensure panel sizes are ready, then position cards correctly
	_position_collection_cards_deferred.call_deferred()


func _position_collection_cards_deferred() -> void:
	"""Position cards after layout is ready (called deferred from _update_card_collection)."""
	# Wait one more frame to ensure all sizes are finalized
	await get_tree().process_frame
	# Position cards in their correct initial positions
	_animate_collection_cards()


func _on_collection_card_hover(card_index: int) -> void:
	"""Handle hovering over a card in the collection."""
	if hovered_card_index == card_index:
		return
	
	hovered_card_index = card_index
	_animate_collection_cards()


func _on_collection_card_exit(_card_index: int) -> void:
	"""Handle mouse leaving a card in the collection."""
	# Small delay before resetting to handle rapid mouse movement between cards
	await get_tree().create_timer(0.05).timeout
	
	# Check if we're now hovering a different card (user moved to another card)
	if hovered_card_index != _card_index:
		return
	
	# Before resetting, verify mouse is actually outside all cards
	# This prevents the stuck hover bug caused by position animations moving the card
	# Use click_area's rect since that's what actually receives mouse events
	var mouse_pos: Vector2 = get_global_mouse_position()
	for i: int in range(collection_card_uis.size()):
		if i >= collection_card_uis.size():
			break  # Safety check in case array changed
		var card: Control = collection_card_uis[i]
		if is_instance_valid(card) and card.click_area:
			# Get the click_area's global rect (accounts for parent transforms including scale)
			var click_rect: Rect2 = card.click_area.get_global_rect()
			if click_rect.has_point(mouse_pos):
				# Mouse is actually still over a card - update hover to that card
				hovered_card_index = i
				_animate_collection_cards()
				return
	
	# Mouse is truly outside all cards - reset hover state
	hovered_card_index = -1
	_animate_collection_cards()


func _animate_collection_cards() -> void:
	"""Animate cards to spread/contract based on hovered card."""
	if collection_card_uis.size() == 0:
		return
	
	var scroll: ScrollContainer = card_scroll
	if not scroll or not card_collection_panel:
		return
	
	# Calculate card sizing - 90% of scroll container height (same as _update_card_collection)
	var scroll_height: float = scroll.size.y if scroll.size.y > 0.0 else 280.0
	var target_card_height: float = scroll_height * 0.9
	var base_card_height: float = 325.0
	var base_card_width: float = 225.0
	var card_scale: float = target_card_height / base_card_height
	
	var card_count: int = collection_card_uis.size()
	var card_width: float = base_card_width * card_scale
	var card_height: float = base_card_height * card_scale
	var card_spacing: float = card_width * 0.4  # Overlap amount (40% of card width)
	var hover_spread: float = card_width * 0.5  # Extra space for hovered card
	var hover_lift: float = -card_height * 0.02  # Lift hovered card up (2% of height - subtle)
	var hover_scale: float = card_scale * 1.15  # Scale up hovered card by 15%
	
	# Calculate total width WITHOUT hover spread - keeps cards centered consistently
	var total_width: float = card_width + (card_count - 1) * card_spacing
	
	# Calculate starting X so the center of all cards aligns with screen center
	var viewport_width: float = get_viewport_rect().size.x
	var start_x: float = (viewport_width - total_width) / 2.0
	
	# Calculate Y to position cards with bottoms just above the scroll container bottom
	var bottom_margin: float = 8.0  # Small margin above bottom
	var base_y: float = scroll_height - card_height - bottom_margin
	
	for i: int in range(card_count):
		var card_ui: Control = collection_card_uis[i]
		
		# Calculate target position
		# Non-hovered cards spread away from hovered card, hovered card stays in place (only moves up)
		var x_offset: float = 0.0
		if hovered_card_index >= 0:
			if i < hovered_card_index:
				x_offset = -hover_spread * 0.5
			elif i > hovered_card_index:
				x_offset = hover_spread * 0.5
			# Hovered card (i == hovered_card_index) gets x_offset = 0
		
		var x_pos: float = start_x + i * card_spacing + x_offset
		var y_pos: float = base_y
		var current_scale: float = card_scale
		var target_z: int = i
		
		# Hovered card gets special treatment - only lift up, no horizontal shift
		if i == hovered_card_index:
			y_pos += hover_lift
			current_scale = hover_scale
			target_z = 100  # Bring to front
		
		# Animate with tween
		var tween: Tween = card_ui.create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(card_ui, "position", Vector2(x_pos, y_pos), 0.15)
		tween.tween_property(card_ui, "scale", Vector2(current_scale, current_scale), 0.15)
		card_ui.z_index = target_z
