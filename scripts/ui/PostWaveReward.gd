extends Control
## PostWaveReward - Post-wave reward selection screen

@onready var title: Label = $VBoxContainer/Title
@onready var wave_info: Label = $VBoxContainer/WaveInfo
@onready var scrap_description: Label = $VBoxContainer/RewardOptions/ScrapReward/VBox/Description
@onready var heal_description: Label = $VBoxContainer/RewardOptions/HealReward/VBox/Description
@onready var card_selection: PanelContainer = $CardSelection
@onready var card_options: HBoxContainer = $CardSelection/VBox/CardOptions

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")
var offered_cards: Array[CardDefinition] = []

const BASE_SCRAP_REWARD: int = 30
const BASE_HEAL_AMOUNT: int = 15


func _ready() -> void:
	_setup_display()


func _setup_display() -> void:
	wave_info.text = "Wave %d cleared" % RunManager.current_wave
	
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
