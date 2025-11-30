extends Control
## CardDebugOverlay - Visual debugging tool to track card positions and animations

var tracked_cards: Array[Control] = []
var debug_labels: Dictionary = {}  # card -> Label
var update_timer: Timer = null

func _ready() -> void:
	# Make overlay always on top
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create update timer
	update_timer = Timer.new()
	update_timer.wait_time = 0.1  # Update every 100ms
	update_timer.timeout.connect(_update_debug_info)
	update_timer.autostart = true
	add_child(update_timer)
	
	print("[CardDebugOverlay] Initialized")


func track_card(card: Control) -> void:
	"""Start tracking a card's position and state."""
	if card in tracked_cards:
		return
	
	tracked_cards.append(card)
	
	# Create debug label for this card
	var label: Label = Label.new()
	label.name = "Debug_" + str(card.get_instance_id())
	label.z_index = 1001
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	
	debug_labels[card] = label
	
  	var card_name_for_log: String = "unknown"
	if card.get("card_def") != null and card.card_def:
		card_name_for_log = card.card_def.card_name
	print("[CardDebugOverlay] Now tracking card: ", card_name_for_log)


func untrack_card(card: Control) -> void:
	"""Stop tracking a card."""
	var index: int = tracked_cards.find(card)
	if index >= 0:
		tracked_cards.remove_at(index)
	
	if card in debug_labels:
		var label: Label = debug_labels[card]
		if is_instance_valid(label):
			label.queue_free()
		debug_labels.erase(card)


func _update_debug_info() -> void:
	"""Update all debug labels with current card information."""
	# Clean up invalid cards
	for i: int in range(tracked_cards.size() - 1, -1, -1):
		var card: Control = tracked_cards[i]
		if not is_instance_valid(card):
			tracked_cards.remove_at(i)
			if card in debug_labels:
				debug_labels.erase(card)
			continue
		
		_update_card_debug(card)


func _update_card_debug(card: Control) -> void:
	"""Update debug info for a single card."""
	if not card in debug_labels:
		return
	
	var label: Label = debug_labels[card]
	if not is_instance_valid(label):
		return
	
	# Get card info
	var card_name: String = "unknown"
	if card.get("card_def") != null and card.card_def:
		card_name = card.card_def.card_name
	
	var hand_index: int = -1
	if card.get("hand_index") != null:
		hand_index = card.hand_index
	
	var is_dragging: bool = false
	if card.get("is_dragging") != null:
		is_dragging = card.is_dragging
	
	var is_being_played: bool = false
	if card.get("is_being_played") != null:
		is_being_played = card.is_being_played
	
	var has_active_tween: bool = false
	var active_tween = card.get("active_tween")
	if active_tween != null and active_tween and active_tween.is_valid():
		has_active_tween = true
	
	var parent_name: String = "null"
	if card.get_parent():
		parent_name = card.get_parent().name
	
	# Build debug text
	var debug_text: String = ""
	debug_text += "Card: " + card_name + "\n"
	debug_text += "Index: " + str(hand_index) + "\n"
	debug_text += "Local Pos: " + str(card.position) + "\n"
	debug_text += "Global Pos: " + str(card.global_position) + "\n"
	debug_text += "Parent: " + parent_name + "\n"
	debug_text += "Dragging: " + str(is_dragging) + "\n"
	debug_text += "Playing: " + str(is_being_played) + "\n"
	debug_text += "Has Tween: " + str(has_active_tween) + "\n"
	
	var orig_pos = card.get("original_position")
	if orig_pos != null:
		debug_text += "Orig Local: " + str(orig_pos) + "\n"
	var orig_global_pos = card.get("original_global_position")
	if orig_global_pos != null:
		debug_text += "Orig Global: " + str(orig_global_pos) + "\n"
	
	label.text = debug_text
	
	# Position label near card (but keep it on screen)
	var label_pos: Vector2 = card.global_position + Vector2(card.size.x + 10, 0)
	var viewport_size: Vector2 = get_viewport_rect().size
	
	# Keep label on screen
	if label_pos.x + 200 > viewport_size.x:
		label_pos.x = card.global_position.x - 220
	if label_pos.y + 150 > viewport_size.y:
		label_pos.y = viewport_size.y - 150
	
	label.global_position = label_pos


func clear_all() -> void:
	"""Clear all tracked cards."""
	for card: Control in tracked_cards.duplicate():
		untrack_card(card)
