extends Control
## CombatScreen - Main combat UI controller

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")

# UI References - Top bar
@onready var wave_label: Label = $TopBar/HBox/WaveInfo/WaveLabel
@onready var turn_label: Label = $TopBar/HBox/WaveInfo/TurnLabel
@onready var hp_label: Label = $TopBar/HBox/WardenStats/HPContainer/HPLabel
@onready var armor_label: Label = $TopBar/HBox/WardenStats/ArmorContainer/ArmorLabel
@onready var scrap_label: Label = $TopBar/HBox/WardenStats/ScrapContainer/ScrapLabel

# UI References - Threat preview
@onready var incoming_damage: Label = $ThreatPreview/ThreatContent/IncomingDamage
@onready var threat_breakdown: RichTextLabel = $ThreatPreview/ThreatContent/ThreatBreakdown
@onready var moving_to_melee: Label = $ThreatPreview/ThreatContent/MovingToMelee

# UI References - Battlefield
@onready var battlefield_arena = $BattlefieldArena

# UI References - Bottom section
@onready var card_hand: HBoxContainer = $BottomSection/CardHand
@onready var deck_count: Label = $BottomSection/BottomBar/HBox/DeckInfo/DeckCount
@onready var energy_label: Label = $BottomSection/BottomBar/HBox/EnergyContainer/EnergyLabel
@onready var end_turn_button: Button = $BottomSection/BottomBar/HBox/EndTurnButton
@onready var discard_count: Label = $BottomSection/BottomBar/HBox/DiscardInfo/DiscardCount

# UI References - Ring selector
@onready var ring_selector: PanelContainer = $RingSelector

var card_ui_scene: PackedScene = preload("res://scenes/ui/CardUI.tscn")
var pending_card_index: int = -1
var pending_card_def = null  # CardDefinition


func _ready() -> void:
	_connect_signals()
	_start_combat()


func _connect_signals() -> void:
	# CombatManager signals
	CombatManager.phase_changed.connect(_on_phase_changed)
	CombatManager.turn_started.connect(_on_turn_started)
	CombatManager.energy_changed.connect(_on_energy_changed)
	CombatManager.wave_ended.connect(_on_wave_ended)
	
	# RunManager signals
	RunManager.health_changed.connect(_on_health_changed)
	RunManager.scrap_changed.connect(_on_scrap_changed)


func _start_combat() -> void:
	# Start the wave
	RunManager.start_wave()
	
	# Create wave definition
	var wave_def: WaveDefinition = WaveDefinition.create_basic_wave(RunManager.current_wave)
	
	# Initialize combat
	CombatManager.initialize_combat(wave_def)
	
	_update_ui()


func _update_ui() -> void:
	_update_wave_info()
	_update_stats()
	_update_threat_preview()
	_update_hand()
	_update_deck_info()


func _update_wave_info() -> void:
	wave_label.text = "Wave %d/%d" % [RunManager.current_wave, RunManager.MAX_WAVES]
	turn_label.text = "Turn %d/%d" % [CombatManager.current_turn, CombatManager.turn_limit]
	
	if RunManager.is_elite_wave():
		wave_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
	elif RunManager.is_boss_wave():
		wave_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		wave_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))


func _update_stats() -> void:
	hp_label.text = "%d/%d" % [RunManager.current_hp, RunManager.max_hp]
	armor_label.text = str(RunManager.armor)
	scrap_label.text = str(RunManager.scrap)
	
	# HP color based on health
	var hp_percent: float = float(RunManager.current_hp) / float(RunManager.max_hp)
	if hp_percent <= 0.25:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif hp_percent <= 0.5:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	else:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))


func _update_threat_preview() -> void:
	if not CombatManager.battlefield:
		return
	
	var threat: Dictionary = CombatManager.calculate_incoming_damage()
	
	incoming_damage.text = str(threat.total)
	
	# Color based on severity
	if threat.total >= RunManager.current_hp:
		incoming_damage.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif threat.total >= RunManager.current_hp * 0.5:
		incoming_damage.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	else:
		incoming_damage.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
	
	# Build breakdown text
	var breakdown_text: String = ""
	for entry: Dictionary in threat.breakdown:
		breakdown_text += "%dx %s (%s): %d\n" % [
			entry.count,
			entry.name,
			BattlefieldStateScript.new().get_ring_name(entry.ring),
			entry.damage
		]
	threat_breakdown.text = breakdown_text
	
	# Enemies moving to melee
	var moving_count: int = CombatManager.get_enemies_moving_to_melee()
	moving_to_melee.text = "→ Melee next: %d" % moving_count


func _update_hand() -> void:
	# Clear existing cards
	for child: Node in card_hand.get_children():
		child.queue_free()
	
	if not CombatManager.deck_manager:
		return
	
	# Create card UI for each card in hand
	for i: int in range(CombatManager.deck_manager.hand.size()):
		var card_entry: Dictionary = CombatManager.deck_manager.hand[i]
		var card_def = CardDatabase.get_card(card_entry.card_id)  # CardDefinition
		
		if card_def:
			var card_ui: Control = card_ui_scene.instantiate()
			card_hand.add_child(card_ui)  # Add to tree first so @onready vars are initialized
			card_ui.setup(card_def, card_entry.tier, i)
			card_ui.card_clicked.connect(_on_card_clicked)
			card_ui.card_hovered.connect(_on_card_hovered)


func _update_deck_info() -> void:
	if CombatManager.deck_manager:
		deck_count.text = str(CombatManager.deck_manager.get_deck_size())
		discard_count.text = str(CombatManager.deck_manager.get_discard_size())


func _on_phase_changed(phase: int) -> void:
	match phase:
		CombatManager.CombatPhase.PLAYER_PHASE:
			end_turn_button.disabled = false
		CombatManager.CombatPhase.ENEMY_PHASE:
			end_turn_button.disabled = true
			_show_turn_banner("Enemy Turn")
		_:
			end_turn_button.disabled = true
	
	_update_ui()


func _on_turn_started(_turn: int) -> void:
	_show_turn_banner("Your Turn")
	_update_wave_info()
	_update_hand()
	_update_deck_info()


func _show_turn_banner(text: String) -> void:
	"""Show a banner that slides in and out."""
	var banner: Label = Label.new()
	banner.text = text
	banner.add_theme_font_size_override("font_size", 48)
	banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	banner.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	banner.add_theme_constant_override("outline_size", 4)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.anchors_preset = Control.PRESET_CENTER
	banner.position = Vector2(get_viewport_rect().size.x / 2 - 100, -50)
	add_child(banner)
	
	# Slide in, pause, slide out
	var tween: Tween = create_tween()
	tween.tween_property(banner, "position:y", get_viewport_rect().size.y / 3, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(banner, "modulate:a", 0.0, 0.3)
	tween.tween_callback(banner.queue_free)


func _on_energy_changed(current: int, max_energy: int) -> void:
	energy_label.text = "%d/%d" % [current, max_energy]


func _on_health_changed(current: int, max_hp: int) -> void:
	_update_stats()


func _on_scrap_changed(amount: int) -> void:
	scrap_label.text = str(amount)


func _on_wave_ended(success: bool) -> void:
	print("[CombatScreen] Wave ended. Success: ", success)
	
	if success and RunManager.current_wave < RunManager.MAX_WAVES:
		# Go to post-wave reward
		await get_tree().create_timer(1.0).timeout
		GameManager.go_to_post_wave_reward()
	elif success:
		# Run victory!
		await get_tree().create_timer(1.0).timeout
		GameManager.end_run(true)
	else:
		# Player died
		await get_tree().create_timer(1.0).timeout
		GameManager.end_run(false)


func _on_end_turn_pressed() -> void:
	CombatManager.end_player_turn()


func _on_card_clicked(card_def, tier: int, hand_index: int) -> void:  # card_def: CardDefinition
	if CombatManager.current_phase != CombatManager.CombatPhase.PLAYER_PHASE:
		return
	
	if not CombatManager.can_play_card(card_def, tier):
		print("[CombatScreen] Cannot play card - not enough energy")
		return
	
	if card_def.requires_target:
		# Show ring selector
		pending_card_index = hand_index
		pending_card_def = card_def
		ring_selector.visible = true
	else:
		# Play card immediately
		CombatManager.play_card(hand_index, -1)
		_update_hand()
		_update_threat_preview()


func _on_card_hovered(card_def, tier: int, is_hovering: bool) -> void:  # card_def: CardDefinition
	if is_hovering:
		# Preview what would happen if card is played
		# This could update the threat preview panel
		pass


func _on_ring_selected(ring: int) -> void:
	ring_selector.visible = false
	
	if pending_card_index >= 0:
		CombatManager.play_card(pending_card_index, ring)
		_update_hand()
		_update_threat_preview()
	
	pending_card_index = -1
	pending_card_def = null


func _on_ring_cancel() -> void:
	ring_selector.visible = false
	pending_card_index = -1
	pending_card_def = null

