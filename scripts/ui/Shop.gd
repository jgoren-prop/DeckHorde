extends Control
## Shop - Post-wave shop screen

@onready var scrap_label: Label = $MarginContainer/VBox/Header/ScrapContainer/ScrapLabel
@onready var card_slots: HBoxContainer = $MarginContainer/VBox/CardsSection/CardSlots
@onready var artifact_slots: HBoxContainer = $MarginContainer/VBox/ArtifactsSection/ArtifactSlots
@onready var remove_cost_label: Label = $MarginContainer/VBox/ServicesSection/ServiceButtons/RemoveCard/Cost
@onready var heal_cost_label: Label = $MarginContainer/VBox/ServicesSection/ServiceButtons/Heal/Cost
@onready var reroll_cost_label: Label = $MarginContainer/VBox/ServicesSection/ServiceButtons/Reroll/Cost
@onready var deck_view_panel: PanelContainer = $DeckViewPanel
@onready var deck_grid: GridContainer = $DeckViewPanel/VBox/ScrollContainer/DeckGrid

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

var shop_cards: Array[CardDefinition] = []
var shop_artifacts: Array[ArtifactDefinition] = []

var remove_cost: int = 50
var heal_cost: int = 30
var reroll_cost: int = 10
var reroll_count: int = 0

const CARD_BASE_PRICE: int = 40
const ARTIFACT_BASE_PRICE: int = 80


func _ready() -> void:
	_refresh_shop()
	_update_ui()
	
	RunManager.scrap_changed.connect(_on_scrap_changed)


func _refresh_shop() -> void:
	# Generate shop cards
	shop_cards = CardDatabase.get_shop_cards(3, RunManager.current_wave)
	
	# Generate artifacts (placeholder)
	shop_artifacts.clear()
	# TODO: Load actual artifacts
	
	_populate_card_slots()
	_populate_artifact_slots()


func _populate_card_slots() -> void:
	# Clear existing
	for child: Node in card_slots.get_children():
		child.queue_free()
	
	# Create card slots
	for i: int in range(shop_cards.size()):
		var card = shop_cards[i]  # CardDefinition
		var slot: PanelContainer = _create_shop_card_slot(card, i)
		card_slots.add_child(slot)


func _create_shop_card_slot(card, index: int) -> PanelContainer:  # card: CardDefinition
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 180)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Card preview (simplified)
	var card_ui: Control = card_ui_scene.instantiate()
	card_ui.setup(card, 1, index)
	card_ui.card_clicked.connect(_on_shop_card_clicked)
	vbox.add_child(card_ui)
	
	# Price
	var price: int = _calculate_card_price(card)
	var price_label: Label = Label.new()
	price_label.text = "%d ⚙️" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vbox.add_child(price_label)
	
	panel.set_meta("card", card)
	panel.set_meta("price", price)
	panel.set_meta("index", index)
	
	return panel


func _populate_artifact_slots() -> void:
	# Clear existing
	for child: Node in artifact_slots.get_children():
		child.queue_free()
	
	# Placeholder artifacts
	for i: int in range(2):
		var slot: PanelContainer = _create_artifact_placeholder(i)
		artifact_slots.add_child(slot)


func _create_artifact_placeholder(index: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 100)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.15)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var icon: Label = Label.new()
	icon.text = "💎"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 32)
	vbox.add_child(icon)
	
	var name_label: Label = Label.new()
	name_label.text = "Coming Soon"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(name_label)
	
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


func _on_scrap_changed(amount: int) -> void:
	scrap_label.text = str(amount)


func _on_shop_card_clicked(card_def, tier: int, index: int) -> void:  # card_def: CardDefinition
	var price: int = _calculate_card_price(card_def)
	
	if RunManager.spend_scrap(price):
		# Add card to deck
		RunManager.add_card_to_deck(card_def.card_id, 1)
		print("[Shop] Bought card: ", card_def.card_name)
		
		# Remove from shop
		shop_cards.remove_at(index)
		_populate_card_slots()
		_update_ui()
	else:
		print("[Shop] Not enough scrap!")


func _on_remove_card_pressed() -> void:
	if RunManager.scrap < remove_cost:
		print("[Shop] Not enough scrap to remove card")
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
			card_ui.setup(card_def, entry.tier, i)
			card_ui.card_clicked.connect(_on_remove_card_selected)
			deck_grid.add_child(card_ui)
	
	deck_view_panel.visible = true


func _on_remove_card_selected(card_def, tier: int, index: int) -> void:  # card_def: CardDefinition
	if RunManager.spend_scrap(remove_cost):
		RunManager.remove_card_from_deck(index)
		remove_cost += 25  # Increase cost each time
		print("[Shop] Removed card: ", card_def.card_name)
		_update_ui()
	
	deck_view_panel.visible = false


func _on_deck_view_close() -> void:
	deck_view_panel.visible = false


func _on_heal_pressed() -> void:
	if RunManager.spend_scrap(heal_cost):
		RunManager.heal(10)
		heal_cost += 15  # Increase cost
		print("[Shop] Healed 10 HP")
		_update_ui()


func _on_reroll_pressed() -> void:
	if RunManager.spend_scrap(reroll_cost):
		reroll_count += 1
		reroll_cost = 10 + reroll_count * 10
		_refresh_shop()
		_update_ui()
		print("[Shop] Rerolled shop")


func _on_continue_pressed() -> void:
	GameManager.start_next_wave()

