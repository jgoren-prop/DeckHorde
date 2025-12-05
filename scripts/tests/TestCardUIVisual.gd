extends Control
## Visual test for V5 CardUI design
## Displays several cards to verify the new layout matches DESIGN_V5.md

const CardUIScene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

var cards_container: HBoxContainer


func _ready() -> void:
	print("[TestCardUIVisual] Creating visual test for V5 CardUI...")
	
	# Create background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Create title
	var title: Label = Label.new()
	title.text = "V5 CARD UI TEST"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	title.position = Vector2(40, 20)
	add_child(title)
	
	# Create container for cards
	cards_container = HBoxContainer.new()
	cards_container.position = Vector2(40, 80)
	cards_container.add_theme_constant_override("separation", 20)
	add_child(cards_container)
	
	# Wait for frame
	await get_tree().process_frame
	
	# Create test cards at different tiers
	_create_test_cards()
	
	print("[TestCardUIVisual] Visual test ready - press ESC to exit")


func _create_test_cards() -> void:
	# Test different card types and tiers
	var test_cards: Array = [
		{"name": "pistol", "tier": 1},
		{"name": "pistol", "tier": 2},
		{"name": "shotgun", "tier": 1},
		{"name": "hex_bolt", "tier": 3},
		{"name": "frag_grenade", "tier": 4},
	]
	
	for card_data: Dictionary in test_cards:
		var card_def = CardDatabase.get_card(card_data["name"])
		if card_def:
			var card_ui: Control = CardUIScene.instantiate()
			cards_container.add_child(card_ui)
			card_ui.check_playability = false
			card_ui.enable_hover_scale = false
			card_ui.setup(card_def, card_data["tier"], 0)
			print("[TestCardUIVisual] Created card: %s (Tier %d)" % [card_data["name"], card_data["tier"]])
		else:
			print("[TestCardUIVisual] WARNING: Card not found: ", card_data["name"])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit(0)

