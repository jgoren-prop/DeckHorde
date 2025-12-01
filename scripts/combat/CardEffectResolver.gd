extends RefCounted
class_name CardEffectResolver
## CardEffectResolver - Resolves card effects during combat

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")


static func _apply_damage_multipliers(base_damage: int, card_def, target_ring: int = -1) -> int:
	"""Apply V2 damage multipliers based on card tags and target ring.
	Uses ADDITIVE stacking from PlayerStats.
	"""
	# Get the combined multiplier from RunManager (additive tag + ring bonuses)
	var mult: float = RunManager.get_damage_multiplier_for_card(card_def, target_ring)
	var damage: int = int(float(base_damage) * mult)
	
	if mult != 1.0:
		print("[CardEffectResolver] V2 damage multiplier applied: ", mult, "x (", base_damage, " -> ", damage, ")")
	
	return damage

static func resolve(card_def, tier: int, target_ring: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Resolve a card's effect."""
	match card_def.effect_type:
		"instant_damage":
			_resolve_instant_damage(card_def, tier, target_ring, combat)
		"weapon_persistent":
			_resolve_weapon_persistent(card_def, tier, combat)
		"heal":
			_resolve_heal(card_def, tier)
		"buff":
			_resolve_buff(card_def, tier)
		"apply_hex":
			_resolve_apply_hex(card_def, tier, target_ring, combat)
		"apply_hex_multi":
			_resolve_apply_hex_multi(card_def, tier, combat)
		"gain_armor":
			_resolve_gain_armor(card_def, tier)
		"ring_barrier":
			_resolve_ring_barrier(card_def, tier, target_ring, combat)
		"damage_and_heal":
			_resolve_damage_and_heal(card_def, tier, combat)
		"damage_and_armor":
			_resolve_damage_and_armor(card_def, tier, target_ring, combat)
		"armor_and_lifesteal":
			_resolve_armor_and_lifesteal(card_def, tier, combat)
		"armor_and_heal":
			_resolve_armor_and_heal(card_def, tier)
		"draw_cards":
			_resolve_draw_cards(card_def, tier, combat)
		"push_enemies":
			_resolve_push_enemies(card_def, tier, target_ring, combat)
		"damage_and_draw":
			_resolve_damage_and_draw(card_def, tier, combat)
		"scatter_damage":
			_resolve_scatter_damage(card_def, tier, combat)
		"energy_and_draw":
			_resolve_energy_and_draw(card_def, tier, combat)
		"gambit":
			_resolve_gambit(card_def, tier, combat)
		"damage_and_hex":
			_resolve_damage_and_hex(card_def, tier, combat)
		"shield_bash":
			_resolve_shield_bash(card_def, tier, combat)
		_:
			push_warning("[CardEffectResolver] Unknown effect type: " + card_def.effect_type)


static func resolve_weapon_effect(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Resolve a persistent weapon's triggered effect."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	
	# Check for Ember Charm artifact bonus (gun cards deal +2 damage)
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply damage multipliers (use -1 for random target ring)
	damage = _apply_damage_multipliers(damage, card_def, -1)
	
	# Build ring mask from target_rings
	var ring_mask: int = 0
	for ring: int in card_def.target_rings:
		ring_mask |= (1 << ring)
	
	if ring_mask > 0:
		combat.deal_damage_to_random_enemy(ring_mask, damage)


static func _resolve_instant_damage(card_def, tier: int, target_ring: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal instant damage to targets."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	
	# Check for Ember Charm artifact bonus (gun cards deal +2 damage)
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply damage multipliers based on card tags and target ring
	damage = _apply_damage_multipliers(damage, card_def, target_ring)
	
	match card_def.target_type:
		"ring":
			var rings_to_hit: Array[int] = []
			if card_def.requires_target:
				rings_to_hit = [target_ring]
			else:
				rings_to_hit.assign(card_def.target_rings)
			
			for ring: int in rings_to_hit:
				combat.deal_damage_to_ring(ring, damage)
		
		"all_rings":
			for ring: int in range(4):
				combat.deal_damage_to_ring(ring, damage)
		
		"random_enemy":
			var ring_mask: int = 0
			for ring: int in card_def.target_rings:
				ring_mask |= (1 << ring)
			if ring_mask == 0:
				ring_mask = 0b1111  # All rings
			combat.deal_damage_to_random_enemy(ring_mask, damage)
		
		"all_enemies":
			for ring: int in range(4):
				combat.deal_damage_to_ring(ring, damage)


static func _resolve_weapon_persistent(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Register a persistent weapon effect (triggers at end of turn only)."""
	# Register the weapon for this and future turns
	# Weapon will trigger at end of turn, NOT when played
	combat.register_weapon(card_def, tier, -1)  # -1 = rest of wave
	print("[CardEffectResolver] Persistent weapon registered (fires at end of turn): ", card_def.card_name)


static func _resolve_heal(card_def, tier: int) -> void:  # card_def: CardDefinition
	"""Heal the player."""
	var heal_amount: int = card_def.get_scaled_value("heal_amount", tier)
	RunManager.heal(heal_amount)


static func _resolve_buff(card_def, tier: int) -> void:  # card_def: CardDefinition
	"""Apply a buff to the player."""
	var buff_value: int = card_def.get_scaled_value("buff_value", tier)
	
	match card_def.buff_type:
		"gun_damage":
			# V2: Apply gun damage buff via PlayerStats
			RunManager.player_stats.gun_damage_percent += float(buff_value)
			RunManager.stats_changed.emit()
			print("[CardEffectResolver] Applied gun_damage buff: +", buff_value, "%")
		"damage":
			# V2: Apply generic damage buff via PlayerStats
			RunManager.player_stats.generic_damage_percent += float(buff_value)
			RunManager.stats_changed.emit()
			print("[CardEffectResolver] Applied generic damage buff: +", buff_value, "%")
		_:
			push_warning("[CardEffectResolver] Unknown buff type: " + card_def.buff_type)


static func _resolve_apply_hex(card_def, tier: int, target_ring: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Apply hex to enemies in a ring."""
	var hex_damage: int = card_def.get_scaled_value("hex_damage", tier)
	
	# V2: Apply hex multiplier from PlayerStats
	var stats_mult: float = RunManager.get_hex_damage_multiplier()
	hex_damage = int(float(hex_damage) * stats_mult)
	
	# Also apply artifact hex multiplier (Void Heart) - stacks multiplicatively
	var artifact_mult: float = ArtifactManager.get_hex_multiplier()
	hex_damage = int(float(hex_damage) * artifact_mult)
	
	var rings_to_hex: Array[int] = []
	if card_def.requires_target:
		rings_to_hex = [target_ring]
	else:
		rings_to_hex.assign(card_def.target_rings)
	
	for ring: int in rings_to_hex:
		var enemies: Array = combat.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:  # enemy: EnemyInstance
			# Emit hex signal for visual feedback BEFORE applying
			combat.enemy_hexed.emit(enemy, hex_damage)
			enemy.apply_status("hex", hex_damage, -1)  # -1 = permanent


static func _resolve_apply_hex_multi(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Apply hex to multiple random enemies."""
	var hex_damage: int = card_def.get_scaled_value("hex_damage", tier)
	var target_count: int = card_def.get_scaled_value("target_count", tier)
	
	# V2: Apply hex multiplier from PlayerStats
	var stats_mult: float = RunManager.get_hex_damage_multiplier()
	hex_damage = int(float(hex_damage) * stats_mult)
	
	# Also apply artifact hex multiplier (Void Heart) - stacks multiplicatively
	var artifact_mult: float = ArtifactManager.get_hex_multiplier()
	hex_damage = int(float(hex_damage) * artifact_mult)
	
	var all_enemies: Array = combat.battlefield.get_all_enemies()
	all_enemies.shuffle()
	
	var count: int = min(target_count, all_enemies.size())
	for i: int in range(count):
		# Emit hex signal for visual feedback
		combat.enemy_hexed.emit(all_enemies[i], hex_damage)
		all_enemies[i].apply_status("hex", hex_damage, -1)


static func _resolve_gain_armor(card_def, tier: int) -> void:  # card_def: CardDefinition
	"""Grant armor to the player."""
	var armor_amount: int = card_def.get_scaled_value("armor_amount", tier)
	
	# Check for Refracting Core artifact bonus
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	armor_amount += artifact_effects.bonus_armor
	
	RunManager.add_armor(armor_amount)


static func _resolve_ring_barrier(card_def, tier: int, target_ring: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Create a barrier on a ring that damages crossing enemies."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var duration: int = card_def.get_scaled_value("duration", tier)
	
	# V2: Apply barrier damage multiplier
	var damage_mult: float = RunManager.get_barrier_damage_multiplier()
	damage = int(float(damage) * damage_mult)
	
	# V2: Apply barrier strength multiplier to duration (HP/crossings)
	var strength_mult: float = RunManager.get_barrier_strength_multiplier()
	duration = int(float(duration) * strength_mult)
	
	combat.battlefield.add_ring_barrier(target_ring, damage, duration)
	
	# Emit signal for visual feedback
	combat.barrier_placed.emit(target_ring, damage, duration)


static func _resolve_damage_and_heal(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal damage and heal based on it."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var heal_amount: int = card_def.get_scaled_value("heal_amount", tier)
	
	# Check for Ember Charm artifact bonus (gun cards deal +2 damage)
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply damage multipliers
	damage = _apply_damage_multipliers(damage, card_def, -1)
	
	# Deal damage to random enemy
	var ring_mask: int = 0b1111  # All rings
	combat.deal_damage_to_random_enemy(ring_mask, damage)
	
	# Heal player (heal multiplier applied in RunManager.heal)
	RunManager.heal(heal_amount)


static func _resolve_damage_and_armor(card_def, tier: int, target_ring: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal damage and gain armor."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var armor_amount: int = card_def.get_scaled_value("armor_amount", tier)
	
	# Deal damage
	var rings_to_hit: Array[int] = []
	if card_def.requires_target:
		rings_to_hit = [target_ring]
	else:
		rings_to_hit.assign(card_def.target_rings)
	
	for ring: int in rings_to_hit:
		combat.deal_damage_to_ring(ring, damage)
	
	# Gain armor
	RunManager.add_armor(armor_amount)


static func _resolve_armor_and_lifesteal(card_def, tier: int, _combat: Node) -> void:  # card_def: CardDefinition
	"""Gain armor and set up lifesteal on kill."""
	var armor_amount: int = card_def.get_scaled_value("armor_amount", tier)
	var lifesteal: int = card_def.lifesteal_on_kill
	
	RunManager.add_armor(armor_amount)
	
	# Lifesteal on kill would be handled by a buff system
	# For now, we'll skip this advanced feature
	print("[CardEffectResolver] Lifesteal on kill: ", lifesteal, " (not fully implemented)")


static func _resolve_armor_and_heal(card_def, tier: int) -> void:  # card_def: CardDefinition
	"""Gain armor and heal the player."""
	var armor_amount: int = card_def.get_scaled_value("armor_amount", tier)
	var heal_amount: int = card_def.get_scaled_value("heal_amount", tier)
	
	RunManager.add_armor(armor_amount)
	RunManager.heal(heal_amount)
	print("[CardEffectResolver] Armor and heal: +", armor_amount, " armor, +", heal_amount, " HP")


static func _resolve_draw_cards(card_def, _tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Draw additional cards."""
	var count: int = card_def.cards_to_draw
	if count <= 0:
		count = 1
	
	for i: int in range(count):
		combat.deck_manager.draw_card()


static func _resolve_push_enemies(card_def, _tier: int, target_ring: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Push enemies outward."""
	var push_amount: int = card_def.push_amount
	
	var rings_to_push: Array[int] = []
	if card_def.requires_target:
		rings_to_push = [target_ring]
	else:
		rings_to_push.assign(card_def.target_rings)
	
	# IMPORTANT: Collect all enemies to push FIRST, then push them.
	# This prevents enemies from being pushed multiple times when iterating through rings
	# (e.g., enemy in MELEE gets pushed to CLOSE, then pushed again to MID)
	var enemies_to_push: Array = []
	for ring: int in rings_to_push:
		var enemies: Array = combat.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:
			enemies_to_push.append(enemy)
	
	# Now push all collected enemies
	for enemy in enemies_to_push:  # enemy: EnemyInstance
		var old_ring: int = enemy.ring
		var new_ring: int = mini(BattlefieldStateScript.Ring.FAR, old_ring + push_amount)
		if new_ring != old_ring:
			combat.battlefield.move_enemy(enemy, new_ring)
			# Emit CombatManager signal so BattlefieldArena updates visuals
			CombatManager.enemy_moved.emit(enemy, old_ring, new_ring)


static func _resolve_damage_and_draw(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal damage to random enemy and draw cards."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var cards_count: int = card_def.cards_to_draw
	if cards_count <= 0:
		cards_count = 1
	
	# Check for Ember Charm artifact bonus (gun cards deal +2 damage)
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply damage multipliers
	damage = _apply_damage_multipliers(damage, card_def, -1)
	
	# Build ring mask from target_rings
	var ring_mask: int = 0
	for ring: int in card_def.target_rings:
		ring_mask |= (1 << ring)
	if ring_mask == 0:
		ring_mask = 0b1111
	
	# Deal damage to random enemy
	combat.deal_damage_to_random_enemy(ring_mask, damage)
	
	# Draw cards
	for i: int in range(cards_count):
		combat.deck_manager.draw_card()


static func _resolve_scatter_damage(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal damage to multiple random enemies."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var target_count: int = card_def.get_scaled_value("target_count", tier)
	
	# Check for Ember Charm artifact bonus (gun cards deal +2 damage)
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply damage multipliers
	damage = _apply_damage_multipliers(damage, card_def, -1)
	
	# Build ring mask from target_rings
	var ring_mask: int = 0
	for ring: int in card_def.target_rings:
		ring_mask |= (1 << ring)
	if ring_mask == 0:
		ring_mask = 0b1111
	
	# Hit multiple random enemies (can hit same enemy multiple times)
	for i: int in range(target_count):
		combat.deal_damage_to_random_enemy(ring_mask, damage)


static func _resolve_energy_and_draw(card_def, _tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Gain energy and draw cards."""
	var energy_gain: int = card_def.buff_value
	if energy_gain <= 0:
		energy_gain = 1
	
	var cards_count: int = card_def.cards_to_draw
	if cards_count <= 0:
		cards_count = 1
	
	# Gain energy
	combat.current_energy += energy_gain
	combat.energy_changed.emit(combat.current_energy, combat.max_energy)
	
	# Draw cards
	for i: int in range(cards_count):
		combat.deck_manager.draw_card()


static func _resolve_gambit(card_def, _tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Discard hand and draw new cards."""
	var cards_count: int = card_def.cards_to_draw
	if cards_count <= 0:
		cards_count = 5
	
	# Discard current hand
	combat.deck_manager.discard_hand()
	
	# Draw new hand
	for i: int in range(cards_count):
		combat.deck_manager.draw_card()


static func _resolve_damage_and_hex(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal damage and apply hex to a single target."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var hex_damage: int = card_def.get_scaled_value("hex_damage", tier)
	
	# V2: Apply damage multipliers
	damage = _apply_damage_multipliers(damage, card_def, -1)
	
	# V2: Apply hex multiplier from PlayerStats
	var stats_mult: float = RunManager.get_hex_damage_multiplier()
	hex_damage = int(float(hex_damage) * stats_mult)
	
	# Also apply artifact hex multiplier (Void Heart)
	var artifact_mult: float = ArtifactManager.get_hex_multiplier()
	hex_damage = int(float(hex_damage) * artifact_mult)
	
	# Find a valid target in target_rings
	var candidates: Array = []
	for ring: int in card_def.target_rings:
		candidates.append_array(combat.battlefield.get_enemies_in_ring(ring))
	
	if candidates.size() == 0:
		return
	
	# Pick random target
	var target = candidates[randi() % candidates.size()]
	
	# Emit targeting signal for visual (expand stack if needed)
	combat.enemy_targeted.emit(target)
	await combat.get_tree().create_timer(0.3).timeout
	
	# Deal damage using take_damage (triggers any existing hex)
	var result: Dictionary = target.take_damage(damage)
	var total_damage: int = result.total_damage
	
	# Emit damage signal for visual feedback (with hex_triggered info)
	combat.enemy_damaged.emit(target, total_damage, result.hex_triggered)
	
	if target.current_hp <= 0:
		# Use CombatManager's death handler for proper artifact triggers
		combat._handle_enemy_death(target, result.hex_triggered)
	else:
		# Apply NEW hex only if enemy survived - emit hex signal for visual
		combat.enemy_hexed.emit(target, hex_damage)
		target.apply_status("hex", hex_damage, -1)
	
	combat.damage_dealt_to_enemies.emit(total_damage, target.ring)


static func _resolve_shield_bash(card_def, _tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal damage equal to player's armor to enemy in melee."""
	var damage: int = RunManager.armor
	
	if damage <= 0:
		print("[CardEffectResolver] Shield Bash: No armor, no damage dealt")
		return
	
	# Find targets in valid rings
	var candidates: Array = []
	for ring: int in card_def.target_rings:
		candidates.append_array(combat.battlefield.get_enemies_in_ring(ring))
	
	if candidates.size() == 0:
		return
	
	# Pick random target
	var target = candidates[randi() % candidates.size()]
	
	# Deal damage using take_damage (triggers hex)
	var result: Dictionary = target.take_damage(damage)
	var total_damage: int = result.total_damage
	
	# Emit damage signal for visual feedback (with hex_triggered info)
	combat.enemy_damaged.emit(target, total_damage, result.hex_triggered)
	
	if target.current_hp <= 0:
		# Use CombatManager's death handler for proper artifact triggers
		combat._handle_enemy_death(target, result.hex_triggered)
	
	combat.damage_dealt_to_enemies.emit(total_damage, target.ring)
