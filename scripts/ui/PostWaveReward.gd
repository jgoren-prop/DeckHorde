extends Control
## PostWaveReward - Post-wave reward selection screen
## Brotato Economy: Includes interest system

@onready var title: Label = $VBoxContainer/Title
@onready var wave_info: Label = $VBoxContainer/WaveInfo
@onready var scrap_description: Label = $VBoxContainer/RewardOptions/ScrapReward/VBox/Description
@onready var heal_description: Label = $VBoxContainer/RewardOptions/HealReward/VBox/Description
@onready var card_selection: PanelContainer = $CardSelection
@onready var card_options: HBoxContainer = $CardSelection/VBox/CardOptions

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")
var offered_cards: Array[CardDefinition] = []

# Interest display panel (created dynamically)
var interest_panel: PanelContainer = null
var xp_panel: PanelContainer = null

const BASE_SCRAP_REWARD: int = 30
const BASE_HEAL_AMOUNT: int = 15


func _ready() -> void:
	# Brotato Economy: Apply interest before showing rewards
	_apply_and_display_interest()
	# Show XP and level-up info
	_display_xp_summary()
	_setup_display()


func _apply_and_display_interest() -> void:
	"""Brotato Economy: Apply interest and show animated display."""
	var interest_data: Dictionary = RunManager.get_interest_preview()
	var interest_amount: int = RunManager.apply_interest()
	
	if interest_amount > 0:
		_create_interest_display(interest_data, interest_amount)


func _create_interest_display(data: Dictionary, earned: int) -> void:
	"""Create the interest display panel at the top of the screen."""
	interest_panel = PanelContainer.new()
	interest_panel.name = "InterestPanel"
	
	# Position at top center
	interest_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	interest_panel.offset_top = 20
	interest_panel.offset_bottom = 100
	interest_panel.offset_left = -200
	interest_panel.offset_right = 200
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.1, 0.95)
	style.border_color = Color(0.4, 0.8, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	interest_panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	interest_panel.add_child(vbox)
	
	# Title
	var title_lbl: Label = Label.new()
	title_lbl.text = "💰 INTEREST EARNED"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	vbox.add_child(title_lbl)
	
	# Interest amount
	var amount_lbl: Label = Label.new()
	amount_lbl.text = "+%d Scrap" % earned
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_lbl.add_theme_font_size_override("font_size", 28)
	amount_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(amount_lbl)
	
	# Rate info
	var rate_lbl: Label = Label.new()
	rate_lbl.text = "%d%% of %d scrap (max 25)" % [data.interest_rate, data.current_scrap]
	rate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rate_lbl.add_theme_font_size_override("font_size", 12)
	rate_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6))
	vbox.add_child(rate_lbl)
	
	add_child(interest_panel)
	
	# Animate the panel
	interest_panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(interest_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(interest_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(interest_panel.queue_free)


func _display_xp_summary() -> void:
	"""Display XP gained this wave and any level-ups."""
	var xp_info: Dictionary = RunManager.get_xp_info()
	
	# Only show if XP was gained or levels were gained
	if xp_info.xp_this_wave <= 0 and xp_info.levels_this_wave <= 0:
		return
	
	xp_panel = PanelContainer.new()
	xp_panel.name = "XPPanel"
	
	# Position below interest panel
	xp_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	xp_panel.offset_top = 110  # Below interest panel
	xp_panel.offset_bottom = 220
	xp_panel.offset_left = -200
	xp_panel.offset_right = 200
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	# Gold/yellow for level ups, blue for just XP
	if xp_info.levels_this_wave > 0:
		style.bg_color = Color(0.15, 0.12, 0.05, 0.95)
		style.border_color = Color(1.0, 0.85, 0.3)
	else:
		style.bg_color = Color(0.05, 0.1, 0.15, 0.95)
		style.border_color = Color(0.3, 0.6, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	xp_panel.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	xp_panel.add_child(vbox)
	
	# Title - changes if leveled up
	var title_lbl: Label = Label.new()
	if xp_info.levels_this_wave > 0:
		title_lbl.text = "⭐ LEVEL UP!"
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		title_lbl.text = "✨ XP GAINED"
		title_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_lbl)
	
	# Level info (if leveled up)
	if xp_info.levels_this_wave > 0:
		var level_lbl: Label = Label.new()
		if xp_info.levels_this_wave == 1:
			level_lbl.text = "Level %d" % xp_info.level
		else:
			level_lbl.text = "Level %d (+%d levels!)" % [xp_info.level, xp_info.levels_this_wave]
		level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_lbl.add_theme_font_size_override("font_size", 28)
		level_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		vbox.add_child(level_lbl)
		
		# HP gained info
		var hp_lbl: Label = Label.new()
		hp_lbl.text = "+%d Max HP" % xp_info.levels_this_wave
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.add_theme_font_size_override("font_size", 14)
		hp_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		vbox.add_child(hp_lbl)
	else:
		# Just show XP gained
		var xp_lbl: Label = Label.new()
		xp_lbl.text = "+%d XP" % xp_info.xp_this_wave
		xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_lbl.add_theme_font_size_override("font_size", 24)
		xp_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		vbox.add_child(xp_lbl)
	
	# Progress to next level
	var progress_lbl: Label = Label.new()
	progress_lbl.text = "%d / %d XP to Level %d" % [xp_info.current_xp, xp_info.required_xp, xp_info.level + 1]
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.add_theme_font_size_override("font_size", 12)
	progress_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	vbox.add_child(progress_lbl)
	
	add_child(xp_panel)
	
	# Animate
	xp_panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(xp_panel, "modulate:a", 1.0, 0.3).set_delay(0.5)
	if xp_info.levels_this_wave > 0:
		# Level up gets longer display
		tween.tween_interval(3.0)
	else:
		tween.tween_interval(2.0)
	tween.tween_property(xp_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(xp_panel.queue_free)


func _setup_display() -> void:
	var xp_info: Dictionary = RunManager.get_xp_info()
	wave_info.text = "Wave %d cleared | Level %d | Scrap: %d" % [RunManager.current_wave, xp_info.level, RunManager.scrap]
	
	# Calculate rewards based on wave
	var scrap_reward: int = BASE_SCRAP_REWARD + RunManager.current_wave * 5
	var heal_amount: int = BASE_HEAL_AMOUNT + RunManager.current_wave * 2
	
	scrap_description.text = "+%d" % scrap_reward
	heal_description.text = "+%d HP" % heal_amount
	
	# Special text for elite/boss waves
	if RunManager.is_boss_wave():
		title.text = "Boss Defeated!"
		title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	elif RunManager.is_elite_wave():
		title.text = "Elite Wave Complete!"
		title.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))


func _on_card_reward_pressed() -> void:
	_show_card_selection()


func _on_scrap_reward_pressed() -> void:
	var reward: int = BASE_SCRAP_REWARD + RunManager.current_wave * 5
	RunManager.add_scrap(reward)
	_proceed_to_shop()


func _on_heal_reward_pressed() -> void:
	var heal: int = BASE_HEAL_AMOUNT + RunManager.current_wave * 2
	RunManager.heal(heal)
	_proceed_to_shop()


func _show_card_selection() -> void:
	# Clear existing cards
	for child: Node in card_options.get_children():
		child.queue_free()
	
	# Get 3 random cards
	offered_cards = CardDatabase.get_shop_cards(3, RunManager.current_wave)
	
	# Create card UIs
	for i: int in range(offered_cards.size()):
		var card = offered_cards[i]  # CardDefinition
		var card_ui: Control = card_ui_scene.instantiate()
		card_ui.check_playability = false  # Don't dim cards in reward selection
		card_ui.setup(card, 1, i)
		card_ui.card_clicked.connect(_on_card_selected)
		card_options.add_child(card_ui)
	
	card_selection.visible = true


func _on_card_selected(card_def, _tier: int, _index: int) -> void:  # card_def: CardDefinition
	# Add card to deck
	RunManager.add_card_to_deck(card_def.card_id, 1)
	print("[PostWaveReward] Added card: ", card_def.card_name)
	
	# Check for merge
	_check_merge_prompt(card_def.card_id, 1)
	
	card_selection.visible = false
	_proceed_to_shop()


func _on_skip_card_pressed() -> void:
	card_selection.visible = false
	_proceed_to_shop()


func _check_merge_prompt(card_id: String, tier: int) -> void:
	# Check if we now have 3 copies for merge
	if MergeManager.can_merge(card_id, tier):
		# For now, auto-prompt - could show a dialog
		print("[PostWaveReward] Merge available for: ", card_id)
		# MergeManager.perform_merge(card_id, tier)


func _proceed_to_shop() -> void:
	GameManager.go_to_shop()
