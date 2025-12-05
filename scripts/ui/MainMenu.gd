extends Control
## MainMenu - Main menu screen controller

@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var meta_button: Button = $VBoxContainer/MetaButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var codex_button: Button = $VBoxContainer/CodexButton
@onready var card_collection_button: Button = $VBoxContainer/CardCollectionButton
@onready var dev_tools_button: Button = $VBoxContainer/DevToolsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

# Card Collection viewer overlay (created dynamically)
var card_collection_overlay: CanvasLayer = null
var card_collection_grid: GridContainer = null
var card_collection_title: Label = null
var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

# Codex overlay
var codex_scene: PackedScene = preload("res://scenes/Codex.tscn")
var codex_instance: Control = null


func _ready() -> void:
	# Create the card collection overlay
	_create_card_collection_overlay()
	
	# Ensure buttons are properly connected
	if not new_run_button.pressed.is_connected(_on_new_run_pressed):
		new_run_button.pressed.connect(_on_new_run_pressed)
	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Play entrance animation (future)
	_animate_entrance()


func _animate_entrance() -> void:
	# Simple fade-in
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)


func _on_new_run_pressed() -> void:
	print("[MainMenu] New Run pressed")
	GameManager.change_state(GameManager.GameState.WARDEN_SELECT)
	GameManager.go_to_scene("warden_select")


func _on_meta_pressed() -> void:
	print("[MainMenu] Meta/Unlocks pressed")
	GameManager.change_state(GameManager.GameState.META_MENU)
	GameManager.go_to_scene("meta_menu")


func _on_settings_pressed() -> void:
	print("[MainMenu] Settings pressed")
	GameManager.go_to_scene("settings")


func _on_codex_pressed() -> void:
	print("[MainMenu] Codex pressed")
	AudioManager.play_button_click()
	_show_codex()


func _on_card_collection_pressed() -> void:
	print("[MainMenu] Card Collection pressed")
	AudioManager.play_button_click()
	_show_card_collection()


func _on_dev_tools_pressed() -> void:
	print("[MainMenu] Dev Tools pressed")
	AudioManager.play_button_click()
	GameManager.change_scene("res://scenes/devtools/EncounterDesigner.tscn")


func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	get_tree().quit()


# === Card Collection Viewer Functions ===

func _create_card_collection_overlay() -> void:
	"""Create the card collection viewer overlay showing all cards in the game."""
	card_collection_overlay = CanvasLayer.new()
	card_collection_overlay.name = "CardCollectionOverlay"
	card_collection_overlay.layer = 50
	card_collection_overlay.visible = false
	add_child(card_collection_overlay)
	
	# Dimmer background
	var dimmer: ColorRect = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.9)
	card_collection_overlay.add_child(dimmer)
	
	# Main panel - larger to show all cards
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "CollectionPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -550
	panel.offset_top = -420
	panel.offset_right = 550
	panel.offset_bottom = 420
	
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.04, 0.08, 0.98)
	panel_style.border_color = Color(0.8, 0.6, 0.3, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(16)
	panel_style.content_margin_left = 25.0
	panel_style.content_margin_right = 25.0
	panel_style.content_margin_top = 15.0
	panel_style.content_margin_bottom = 15.0
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	card_collection_overlay.add_child(panel)
	
	# VBox for content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	# Header with title and close button
	var header: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header)
	
	card_collection_title = Label.new()
	card_collection_title.text = "📜 CARD COLLECTION"
	card_collection_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_collection_title.add_theme_font_size_override("font_size", 32)
	card_collection_title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	header.add_child(card_collection_title)
	
	var close_btn: Button = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(50, 50)
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.flat = true
	close_btn.pressed.connect(_on_card_collection_close)
	header.add_child(close_btn)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Info label
	var info_label: Label = Label.new()
	info_label.text = "All cards available in the game. Unlock more through gameplay!"
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)
	
	# Filter buttons
	var filter_hbox: HBoxContainer = HBoxContainer.new()
	filter_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(filter_hbox)
	
	var filter_label: Label = Label.new()
	filter_label.text = "Filter: "
	filter_label.add_theme_font_size_override("font_size", 14)
	filter_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	filter_hbox.add_child(filter_label)
	
	var all_btn: Button = Button.new()
	all_btn.text = "All"
	all_btn.pressed.connect(_filter_cards.bind("all"))
	filter_hbox.add_child(all_btn)
	
	var weapon_btn: Button = Button.new()
	weapon_btn.text = "⚔️ Weapons"
	weapon_btn.pressed.connect(_filter_cards.bind("weapon"))
	filter_hbox.add_child(weapon_btn)
	
	var skill_btn: Button = Button.new()
	skill_btn.text = "✨ Skills"
	skill_btn.pressed.connect(_filter_cards.bind("skill"))
	filter_hbox.add_child(skill_btn)
	
	var hex_btn: Button = Button.new()
	hex_btn.text = "☠️ Hex"
	hex_btn.pressed.connect(_filter_cards.bind("hex"))
	filter_hbox.add_child(hex_btn)
	
	var defense_btn: Button = Button.new()
	defense_btn.text = "🛡️ Defense"
	defense_btn.pressed.connect(_filter_cards.bind("defense"))
	filter_hbox.add_child(defense_btn)
	
	# Scroll container for cards
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(1050, 650)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Grid for cards
	card_collection_grid = GridContainer.new()
	card_collection_grid.columns = 6
	card_collection_grid.add_theme_constant_override("h_separation", 15)
	card_collection_grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(card_collection_grid)


func _show_card_collection(filter: String = "all") -> void:
	"""Show the card collection overlay with all cards filtered by type."""
	if not card_collection_overlay or not card_collection_grid:
		return
	
	# Clear existing cards
	for child: Node in card_collection_grid.get_children():
		child.queue_free()
	
	# Get all cards from the database
	var all_cards: Array = CardDatabase.cards.values()
	
	# Filter cards if needed
	var filtered_cards: Array = []
	for card in all_cards:
		if filter == "all" or card.card_type == filter:
			filtered_cards.append(card)
	
	# Sort cards by type, then by name
	filtered_cards.sort_custom(func(a, b):
		if a.card_type != b.card_type:
			var type_order: Dictionary = {"weapon": 0, "skill": 1, "hex": 2, "defense": 3, "curse": 4}
			return type_order.get(a.card_type, 99) < type_order.get(b.card_type, 99)
		return a.card_name < b.card_name
	)
	
	# Update title with count
	if filter == "all":
		card_collection_title.text = "📜 CARD COLLECTION (%d cards)" % filtered_cards.size()
	else:
		card_collection_title.text = "📜 CARD COLLECTION - %s (%d cards)" % [filter.capitalize(), filtered_cards.size()]
	
	# Populate with cards
	for i: int in range(filtered_cards.size()):
		var card_def = filtered_cards[i]
		var card_ui: Control = card_ui_scene.instantiate()
		card_ui.check_playability = false  # Don't dim cards in collection viewer
		card_collection_grid.add_child(card_ui)
		card_ui.setup(card_def, 1, i)  # Show at tier 1
		# Make the card non-interactive (view only)
		card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Scale down slightly to fit more cards
		card_ui.scale = Vector2(0.8, 0.8)
	
	card_collection_overlay.visible = true


func _filter_cards(card_type: String) -> void:
	"""Filter the card collection by type."""
	AudioManager.play_button_click()
	_show_card_collection(card_type)


func _on_card_collection_close() -> void:
	"""Close the card collection overlay."""
	AudioManager.play_button_click()
	card_collection_overlay.visible = false


# === Codex Functions ===

func _show_codex() -> void:
	"""Show the codex overlay with all game knowledge."""
	if codex_instance and is_instance_valid(codex_instance):
		codex_instance.queue_free()
	
	codex_instance = codex_scene.instantiate()
	codex_instance.closed.connect(_on_codex_closed)
	add_child(codex_instance)


func _on_codex_closed() -> void:
	"""Handle codex being closed."""
	codex_instance = null
