extends Control
## DamageTooltip - V5 damage breakdown tooltip
## Shows detailed calculation of card damage including:
## - Base damage (with tier scaling)
## - Stat scaling breakdown
## - Type multipliers
## - Crit chance/damage
## - Effect glossary

signal closed()

@onready var background: Panel = $Background
@onready var content: VBoxContainer = $Background/Content
@onready var title_label: Label = $Background/Content/TitleLabel
@onready var breakdown_label: RichTextLabel = $Background/Content/BreakdownLabel
@onready var effects_label: RichTextLabel = $Background/Content/EffectsLabel
@onready var close_button: Button = $Background/Content/CloseButton

var card_def = null
var card_tier: int = 1


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_setup_style()
	visible = false


func _setup_style() -> void:
	"""Setup the tooltip visual style."""
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	bg_style.border_color = Color(0.4, 0.35, 0.5, 1.0)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(8)
	bg_style.shadow_color = Color(0, 0, 0, 0.3)
	bg_style.shadow_size = 4
	background.add_theme_stylebox_override("panel", bg_style)


func show_tooltip(card, tier: int, pos: Vector2) -> void:
	"""Show the tooltip for a card at a given position."""
	card_def = card
	card_tier = tier
	
	# Update content
	_update_title()
	_update_breakdown()
	_update_effects()
	
	# Position tooltip
	position = pos
	
	# Clamp to screen bounds
	var screen_size: Vector2 = get_viewport_rect().size
	if position.x + size.x > screen_size.x:
		position.x = screen_size.x - size.x - 10
	if position.y + size.y > screen_size.y:
		position.y = screen_size.y - size.y - 10
	
	visible = true


func hide_tooltip() -> void:
	"""Hide the tooltip."""
	visible = false
	card_def = null


func _update_title() -> void:
	"""Update the title with card name and tier."""
	var tier_suffix: String = ""
	if card_tier > 1:
		tier_suffix = " +" + str(card_tier - 1)
	title_label.text = card_def.card_name + tier_suffix


func _update_breakdown() -> void:
	"""Update the damage breakdown section."""
	var text: String = ""
	
	# V5 Damage Calculation breakdown
	var base_damage: int = card_def.base_damage
	
	if base_damage > 0:
		# Tier scaling
		var tier_mult: float = 1.0 + (card_tier - 1) * 0.5
		var scaled_base: int = int(base_damage * tier_mult)
		
		text += "[color=#aaaaaa]── DAMAGE CALCULATION ──[/color]\n\n"
		
		# Base damage
		text += "[color=#88ddff]Base Damage:[/color] %d\n" % base_damage
		if card_tier > 1:
			text += "[color=#88ddff]Tier %d Bonus:[/color] ×%.1f → %d\n" % [card_tier, tier_mult, scaled_base]
		
		# Stat scaling
		var has_scaling: bool = false
		var scaling_text: String = ""
		var stat_bonus: int = 0
		
		if card_def.kinetic_scaling > 0:
			has_scaling = true
			var stat_val: int = RunManager.player_stats.kinetic if RunManager and RunManager.player_stats else 0
			var tier_scale_mult: float = 1.0 + (card_tier - 1) * 0.25
			var bonus: int = int(stat_val * card_def.kinetic_scaling * tier_scale_mult / 100.0)
			stat_bonus += bonus
			scaling_text += "  [color=#bbbbbb]Kinetic (%d%% of %d):[/color] +%d\n" % [int(card_def.kinetic_scaling * tier_scale_mult), stat_val, bonus]
		
		if card_def.thermal_scaling > 0:
			has_scaling = true
			var stat_val: int = RunManager.player_stats.thermal if RunManager and RunManager.player_stats else 0
			var tier_scale_mult: float = 1.0 + (card_tier - 1) * 0.25
			var bonus: int = int(stat_val * card_def.thermal_scaling * tier_scale_mult / 100.0)
			stat_bonus += bonus
			scaling_text += "  [color=#bbbbbb]Thermal (%d%% of %d):[/color] +%d\n" % [int(card_def.thermal_scaling * tier_scale_mult), stat_val, bonus]
		
		if card_def.arcane_scaling > 0:
			has_scaling = true
			var stat_val: int = RunManager.player_stats.arcane if RunManager and RunManager.player_stats else 0
			var tier_scale_mult: float = 1.0 + (card_tier - 1) * 0.25
			var bonus: int = int(stat_val * card_def.arcane_scaling * tier_scale_mult / 100.0)
			stat_bonus += bonus
			scaling_text += "  [color=#bbbbbb]Arcane (%d%% of %d):[/color] +%d\n" % [int(card_def.arcane_scaling * tier_scale_mult), stat_val, bonus]
		
		if card_def.armor_start_scaling > 0:
			has_scaling = true
			var stat_val: int = RunManager.player_stats.armor_start if RunManager and RunManager.player_stats else 0
			var tier_scale_mult: float = 1.0 + (card_tier - 1) * 0.25
			var bonus: int = int(stat_val * card_def.armor_start_scaling * tier_scale_mult / 100.0)
			stat_bonus += bonus
			scaling_text += "  [color=#bbbbbb]Armor/Wave (%d%% of %d):[/color] +%d\n" % [int(card_def.armor_start_scaling * tier_scale_mult), stat_val, bonus]
		
		if has_scaling:
			text += "\n[color=#88ddff]Stat Scaling:[/color]\n"
			text += scaling_text
		
		# Subtotal
		var subtotal: int = scaled_base + stat_bonus
		text += "\n[color=#ffcc55]Subtotal:[/color] %d\n" % subtotal
		
		# Multipliers
		var damage_type: String = card_def.damage_type
		var type_mult: float = 1.0
		var type_bonus: float = 0.0  # Bonus over baseline (0 = no bonus)
		
		if RunManager and RunManager.player_stats:
			match damage_type:
				"kinetic":
					type_mult = RunManager.player_stats.get_kinetic_multiplier()
					type_bonus = RunManager.player_stats.kinetic_percent - 100.0  # Bonus over 100%
				"thermal":
					type_mult = RunManager.player_stats.get_thermal_multiplier()
					type_bonus = RunManager.player_stats.thermal_percent - 100.0
				"arcane":
					type_mult = RunManager.player_stats.get_arcane_multiplier()
					type_bonus = RunManager.player_stats.arcane_percent - 100.0
			
			var global_mult: float = RunManager.player_stats.get_damage_multiplier()
			var global_bonus: float = RunManager.player_stats.damage_percent - 100.0  # Bonus over 100%
			
			# Only show multipliers section if there are actual bonuses
			var has_bonuses: bool = type_bonus > 0 or global_bonus > 0
			if has_bonuses:
				text += "\n[color=#88ddff]Multipliers:[/color]\n"
				if type_bonus > 0:
					text += "  [color=#bbbbbb]%s damage:[/color] +%d%%\n" % [damage_type.capitalize(), int(type_bonus)]
				if global_bonus > 0:
					text += "  [color=#bbbbbb]All damage:[/color] +%d%%\n" % int(global_bonus)
				
				var total_mult: float = type_mult * global_mult
				text += "  [color=#ffaa55]Total multiplier:[/color] ×%.2f\n" % total_mult
			
			# Final damage
			var final: int = int(subtotal * type_mult * global_mult)
			text += "\n[color=#44ff44]Final Damage:[/color] %d\n" % final
		else:
			text += "  (No stats available)\n"
			text += "\n[color=#44ff44]Final Damage:[/color] %d\n" % subtotal
		
		# Crit info
		var crit_chance: float = 5.0 + card_def.crit_chance_bonus
		var crit_damage: float = 150.0 + card_def.crit_damage_bonus
		if RunManager and RunManager.player_stats:
			crit_chance += RunManager.player_stats.crit_chance
			crit_damage += RunManager.player_stats.crit_damage
		
		text += "\n[color=#ff8855]Crit:[/color] %.0f%% chance for %.0f%% damage\n" % [crit_chance, crit_damage]
	else:
		text += "[color=#aaaaaa]This card does not deal damage.[/color]\n"
	
	breakdown_label.text = text


func _update_effects() -> void:
	"""Update the effects/glossary section."""
	var text: String = ""
	
	# Check for status effects using actual CardDefinition properties
	var has_effects: bool = false
	
	var hex_stacks: int = card_def.hex_damage
	var burn_stacks: int = card_def.burn_damage
	
 	# Barrier is determined by effect_type
	var is_barrier_card: bool = card_def.effect_type == "ring_barrier"
	
	if hex_stacks > 0 or burn_stacks > 0 or is_barrier_card:
		text += "\n[color=#aaaaaa]── EFFECTS ──[/color]\n\n"
		has_effects = true
	
	if hex_stacks > 0:
		var potency: float = 1.0
		if RunManager and RunManager.player_stats:
			potency = RunManager.player_stats.get_hex_potency_multiplier()
		var final_hex: int = int(hex_stacks * potency)
		text += "[color=#bb77ff]☠ Hex:[/color] Apply %d stacks\n" % final_hex
		text += "  [color=#888888]When hexed enemy takes damage:\n  Add Hex stacks to damage, then consume Hex[/color]\n\n"
	
	if burn_stacks > 0:
		var potency: float = 1.0
		if RunManager and RunManager.player_stats:
			potency = RunManager.player_stats.get_burn_potency_multiplier()
		var final_burn: int = int(burn_stacks * potency)
		text += "[color=#ff7744]🔥 Burn:[/color] Apply %d stacks\n" % final_burn
		text += "  [color=#888888]At end of turn:\n  Deal Burn damage, reduce stacks by 1[/color]\n\n"
	
	if is_barrier_card:
		# Barrier info from effect_params if available
		var barrier_dmg: int = card_def.effect_params.get("barrier_damage", card_def.base_damage) as int
		var barrier_uses: int = card_def.effect_params.get("barrier_uses", 3) as int
		var dmg_bonus: float = 1.0
		var uses_bonus: int = 0
		if RunManager and RunManager.player_stats:
			dmg_bonus = RunManager.player_stats.get_barrier_damage_bonus_multiplier()
			uses_bonus = int(RunManager.player_stats.barrier_uses_bonus)
		var final_dmg: int = int(barrier_dmg * dmg_bonus)
		var final_uses: int = barrier_uses + uses_bonus
		text += "[color=#77ddff]🚧 Barrier:[/color] %d damage, %d uses\n" % [final_dmg, final_uses]
		text += "  [color=#888888]When enemy crosses barrier:\n  Deal damage, lose 1 use[/color]\n\n"
	
	# Other effects - use actual CardDefinition property names
	var armor: int = card_def.armor_amount
	if armor > 0:
		text += "[color=#77ccff]🛡 Armor:[/color] Gain %d\n" % armor
		text += "  [color=#888888]Absorbs damage before HP[/color]\n\n"
	
	var cards_drawn: int = card_def.cards_to_draw
	if cards_drawn > 0:
		text += "[color=#77ff77]📜 Draw:[/color] %d cards\n\n" % cards_drawn
	
	var self_dmg: int = card_def.self_damage
	if self_dmg > 0:
		var reduction: int = 0
		if RunManager and RunManager.player_stats:
			reduction = RunManager.player_stats.self_damage_reduction
		var final_self_dmg: int = maxi(0, self_dmg - reduction)
		text += "[color=#ff4444]💔 Self-damage:[/color] %d" % final_self_dmg
		if reduction > 0:
			text += " (reduced from %d)" % self_dmg
		text += "\n\n"
	
	if not has_effects and text == "":
		text = "\n[color=#666666]No special effects[/color]"
	
	effects_label.text = text


func _on_close_pressed() -> void:
	"""Handle close button press."""
	hide_tooltip()
	closed.emit()


func _input(event: InputEvent) -> void:
	"""Handle input for closing tooltip."""
	if visible and event is InputEventMouseButton and event.pressed:
		# Check if click is outside tooltip
		var mouse_pos: Vector2 = get_global_mouse_position()
		var tooltip_rect: Rect2 = Rect2(global_position, size)
		if not tooltip_rect.has_point(mouse_pos):
			hide_tooltip()
			closed.emit()
