extends Control
## MetaMenu - Meta progression unlock menu

@onready var essence_label: Label = $MarginContainer/VBox/Header/EssenceContainer/EssenceLabel
@onready var warden_grid: GridContainer = $"MarginContainer/VBox/TabContainer/Wardens/WardenGrid"
@onready var card_grid: GridContainer = $"MarginContainer/VBox/TabContainer/Cards/CardGrid"
@onready var artifact_grid: GridContainer = $"MarginContainer/VBox/TabContainer/Artifacts/ArtifactGrid"
@onready var danger_grid: VBoxContainer = $"MarginContainer/VBox/TabContainer/Danger Levels/DangerGrid"

var total_essence: int = 0  # Loaded from save


func _ready() -> void:
	_load_progress()
	_update_ui()
	_populate_unlocks()


func _load_progress() -> void:
	# TODO: Load from save file
	total_essence = 500  # Placeholder


func _update_ui() -> void:
	essence_label.text = str(total_essence)


func _populate_unlocks() -> void:
	_populate_wardens()
	_populate_cards()
	_populate_artifacts()
	_populate_danger_levels()


func _populate_wardens() -> void:
	# Clear existing
	for child: Node in warden_grid.get_children():
		child.queue_free()
	
	# Add warden unlock entries
	var wardens: Array[Dictionary] = [
		{"name": "Ash Warden", "unlocked": true, "cost": 0},
		{"name": "Gloom Warden", "unlocked": true, "cost": 0},
		{"name": "Glass Warden", "unlocked": true, "cost": 0},
		{"name": "Void Warden", "unlocked": false, "cost": 200},
		{"name": "Storm Warden", "unlocked": false, "cost": 300}
	]
	
	for warden: Dictionary in wardens:
		var panel: PanelContainer = _create_unlock_panel(warden.name, warden.unlocked, warden.cost, "warden")
		warden_grid.add_child(panel)


func _populate_cards() -> void:
	for child: Node in card_grid.get_children():
		child.queue_free()
	
	# Add card unlock entries (placeholder)
	var info_label: Label = Label.new()
	info_label.text = "All cards unlocked by default in this version."
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	card_grid.add_child(info_label)


func _populate_artifacts() -> void:
	for child: Node in artifact_grid.get_children():
		child.queue_free()
	
	# Add artifact unlock entries (placeholder)
	var info_label: Label = Label.new()
	info_label.text = "Artifacts coming soon!"
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	artifact_grid.add_child(info_label)


func _populate_danger_levels() -> void:
	for child: Node in danger_grid.get_children():
		child.queue_free()
	
	# Add danger level entries
	var levels: Array[Dictionary] = [
		{"level": 1, "name": "Normal", "unlocked": true, "cost": 0},
		{"level": 2, "name": "Hard", "unlocked": true, "cost": 0},
		{"level": 3, "name": "Expert", "unlocked": false, "cost": 100},
		{"level": 4, "name": "Nightmare", "unlocked": false, "cost": 200},
		{"level": 5, "name": "Apocalypse", "unlocked": false, "cost": 500}
	]
	
	for level: Dictionary in levels:
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		
		var name_label: Label = Label.new()
		name_label.text = "Level %d - %s" % [level.level, level.name]
		name_label.custom_minimum_size = Vector2(200, 0)
		name_label.add_theme_font_size_override("font_size", 18)
		if level.unlocked:
			name_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hbox.add_child(name_label)
		
		if not level.unlocked:
			var unlock_btn: Button = Button.new()
			unlock_btn.text = "Unlock (%d ✨)" % level.cost
			unlock_btn.pressed.connect(_on_unlock_pressed.bind("danger", level.level, level.cost))
			hbox.add_child(unlock_btn)
		else:
			var status_label: Label = Label.new()
			status_label.text = "✓ Unlocked"
			status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			hbox.add_child(status_label)
		
		danger_grid.add_child(hbox)


func _create_unlock_panel(item_name: String, unlocked: bool, cost: int, category: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 120)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if unlocked:
		style.bg_color = Color(0.15, 0.2, 0.15)
		style.border_color = Color(0.4, 0.8, 0.4)
	else:
		style.bg_color = Color(0.15, 0.12, 0.18)
		style.border_color = Color(0.4, 0.3, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var name_label: Label = Label.new()
	name_label.text = item_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	if unlocked:
		var status: Label = Label.new()
		status.text = "✓ Unlocked"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		vbox.add_child(status)
	else:
		var unlock_btn: Button = Button.new()
		unlock_btn.text = "Unlock (%d ✨)" % cost
		unlock_btn.pressed.connect(_on_unlock_pressed.bind(category, item_name, cost))
		vbox.add_child(unlock_btn)
	
	return panel


func _on_unlock_pressed(category: String, item: Variant, cost: int) -> void:
	if total_essence >= cost:
		total_essence -= cost
		# TODO: Save unlock state
		print("[MetaMenu] Unlocked: ", category, " - ", item)
		_update_ui()
		_populate_unlocks()
	else:
		print("[MetaMenu] Not enough essence!")


func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()









