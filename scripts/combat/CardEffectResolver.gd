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
		"targeted_group_damage":
			_resolve_targeted_group_damage(card_def, tier, combat)
		# V2 Effect Types
		"fire_all_guns":
			_resolve_fire_all_guns(card_def, tier, combat)
		"target_sync":
			_resolve_target_sync(card_def, tier, combat)
		"barrier_trigger":
			_resolve_barrier_trigger(card_def, tier, combat)
		"tag_infusion":
			_resolve_tag_infusion(card_def, tier, combat)
		"explosive_damage":
			_resolve_explosive_damage(card_def, tier, target_ring, combat)
		"beam_damage":
			_resolve_beam_damage(card_def, tier, target_ring, combat)
		"piercing_damage":
			_resolve_piercing_damage(card_def, tier, target_ring, combat)
		"shock_damage":
			_resolve_shock_damage(card_def, tier, target_ring, combat)
		"corrosive_damage":
			_resolve_corrosive_damage(card_def, tier, target_ring, combat)
		"energy_refund":
			_resolve_energy_refund(card_def, tier, combat)
		"hex_transfer":
			_resolve_hex_transfer(card_def, tier, combat)
		_:
			push_warning("[CardEffectResolver] Unknown effect type: " + card_def.effect_type)


static func resolve_weapon_effect_single_shot(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Resolve a single shot of a persistent weapon's triggered effect.
	For multi-target weapons, CombatManager calls this multiple times with awaits.
	"""
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


static func get_weapon_target_count(card_def, tier: int) -> int:
	"""Get how many targets a weapon should hit."""
	var target_count: int = card_def.get_scaled_value("target_count", tier)
	if target_count <= 0:
		target_count = 1  # Default to single target if not specified
	return target_count


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


static func _resolve_targeted_group_damage(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal damage to a targeted enemy and all enemies in its group/stack.
	If the enemy is not in a group, only hits that single enemy."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	
	# Check for Ember Charm artifact bonus (gun cards deal +2 damage)
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply damage multipliers
	damage = _apply_damage_multipliers(damage, card_def, -1)
	
	# Find candidates in target_rings
	var candidates: Array = []
	for ring: int in card_def.target_rings:
		candidates.append_array(combat.battlefield.get_enemies_in_ring(ring))
	
	if candidates.size() == 0:
		print("[CardEffectResolver] No valid targets for Precision Strike")
		return
	
	# Debug: Print all candidates and their group_ids
	print("[CardEffectResolver] Precision Strike - Found ", candidates.size(), " candidates:")
	for c in candidates:
		print("  - ", c.enemy_id, " (instance_id=", c.instance_id, ", group_id='", c.group_id, "', ring=", c.ring, ")")
	
	# Pick random target
	var target = candidates[randi() % candidates.size()]
	print("[CardEffectResolver] Selected target: ", target.enemy_id, " (group_id='", target.group_id, "')")
	
	# Emit targeting signal for visual (expand stack if needed)
	combat.enemy_targeted.emit(target)
	await combat.get_tree().create_timer(0.3).timeout
	
	# Find all enemies in the same group (if target has a group)
	var targets_to_hit: Array = []
	if not target.group_id.is_empty():
		# Hit all enemies in the same group
		var all_enemies: Array = combat.battlefield.get_all_enemies()
		for enemy in all_enemies:
			if enemy.group_id == target.group_id:
				targets_to_hit.append(enemy)
		print("[CardEffectResolver] Precision Strike hitting group '", target.group_id, "' with ", targets_to_hit.size(), " enemies")
	else:
		# Single enemy, not in a group
		targets_to_hit.append(target)
		print("[CardEffectResolver] Precision Strike hitting single enemy (no group_id)")
	
	# Deal damage to all targets in the group
	var total_damage_dealt: int = 0
	var enemies_to_kill: Array = []
	
	for enemy in targets_to_hit:
		# Use take_damage to handle hex triggering
		var result: Dictionary = enemy.take_damage(damage)
		var total_dmg: int = result.total_damage
		total_damage_dealt += total_dmg
		
		# Emit damage signal for visual feedback (with hex_triggered info)
		combat.enemy_damaged.emit(enemy, total_dmg, result.hex_triggered)
		
		if result.hex_triggered:
			print("[CardEffectResolver] Hex triggered on ", enemy.enemy_id, "! ", damage, " + ", result.hex_bonus, " = ", total_dmg)
		
		if enemy.current_hp <= 0:
			enemies_to_kill.append({"enemy": enemy, "hex_triggered": result.hex_triggered})
	
	# Handle deaths after all damage is dealt
	for kill_data: Dictionary in enemies_to_kill:
		combat._handle_enemy_death(kill_data.enemy, kill_data.hex_triggered)
	
	combat.damage_dealt_to_enemies.emit(total_damage_dealt, target.ring)


# =============================================================================
# V2 EFFECT HANDLERS
# =============================================================================

static func _resolve_fire_all_guns(card_def, _tier: int, combat: Node) -> void:
	"""Overclock-style: All deployed guns fire immediately at reduced damage."""
	var damage_percent: float = card_def.effect_params.get("damage_percent", 75.0)
	var draw_cards: int = card_def.cards_to_draw
	
	print("[CardEffectResolver] Fire All Guns at ", damage_percent, "% damage")
	
	# Fire all registered weapons
	var weapons: Array = combat.get_registered_weapons()
	for weapon_data: Dictionary in weapons:
		var weapon_def = weapon_data.card_def
		var weapon_tier: int = weapon_data.tier
		
		# Calculate reduced damage
		var base_damage: int = weapon_def.get_scaled_value("damage", weapon_tier)
		var reduced_damage: int = int(float(base_damage) * damage_percent / 100.0)
		
		# Apply V2 multipliers
		reduced_damage = _apply_damage_multipliers(reduced_damage, weapon_def, -1)
		
		# Build ring mask from target_rings
		var ring_mask: int = 0
		for ring: int in weapon_def.target_rings:
			ring_mask |= (1 << ring)
		if ring_mask == 0:
			ring_mask = 0b1111
		
		# Fire!
		combat.deal_damage_to_random_enemy(ring_mask, reduced_damage)
		
		# Emit weapon fire signal for visual
		if combat.has_signal("weapon_fired"):
			combat.weapon_fired.emit(weapon_def)
	
	# Draw cards if specified
	for i: int in range(draw_cards):
		combat.deck_manager.draw_card()


static func _resolve_target_sync(card_def, tier: int, combat: Node) -> void:
	"""Choose a ring; deployed weapons prioritize that ring and gain bonus damage."""
	var bonus_damage: int = card_def.get_scaled_value("damage", tier)
	var target_ring: int = card_def.effect_params.get("ring", -1)
	
	# If no ring specified in params, use a random valid ring from target_rings
	if target_ring < 0 and card_def.target_rings.size() > 0:
		target_ring = card_def.target_rings[0]
	
	if target_ring >= 0:
		combat.set_priority_ring(target_ring, bonus_damage)
		print("[CardEffectResolver] Target Sync: Ring ", target_ring, " prioritized with +", bonus_damage, " damage")


static func _resolve_barrier_trigger(card_def, _tier: int, combat: Node) -> void:
	"""Trigger all barriers once without consuming uses."""
	var armor_per_trigger: int = card_def.effect_params.get("armor_per_trigger", 0)
	
	var barriers: Array = combat.battlefield.get_all_barriers()
	var trigger_count: int = 0
	
	for barrier: Dictionary in barriers:
		# Trigger the barrier's effect without consuming uses
		var enemies: Array = combat.battlefield.get_enemies_in_ring(barrier.ring)
		if enemies.size() > 0:
			# Deal damage to first enemy (barrier trigger)
			var target = enemies[0]
			var damage: int = barrier.damage
			var result: Dictionary = target.take_damage(damage)
			combat.enemy_damaged.emit(target, result.total_damage, result.hex_triggered)
			
			if target.current_hp <= 0:
				combat._handle_enemy_death(target, result.hex_triggered)
			
			trigger_count += 1
			
			# Emit barrier trigger signal
			combat.barrier_triggered.emit(barrier.ring, damage)
	
	# Gain armor per trigger
	if armor_per_trigger > 0 and trigger_count > 0:
		RunManager.add_armor(armor_per_trigger * trigger_count)
		print("[CardEffectResolver] Barrier Channel: Triggered ", trigger_count, " barriers, gained ", armor_per_trigger * trigger_count, " armor")


static func _resolve_tag_infusion(card_def, _tier: int, combat: Node) -> void:
	"""Add a tag permanently to a deployed gun."""
	var tag_to_add: String = card_def.effect_params.get("tag", "piercing")
	var bonus_damage: int = card_def.effect_params.get("bonus_damage", 0)
	
	# Get all deployed weapons
	var weapons: Array = combat.get_registered_weapons()
	if weapons.size() == 0:
		print("[CardEffectResolver] Tag Infusion: No deployed guns to infuse")
		return
	
	# For now, infuse the first weapon (could be made targetable later)
	var weapon_data: Dictionary = weapons[0]
	var weapon_def = weapon_data.card_def
	
	# Add tag to the weapon's tags (if not already present)
	if not weapon_def.tags.has(tag_to_add):
		weapon_def.tags.append(tag_to_add)
		print("[CardEffectResolver] Tag Infusion: Added '", tag_to_add, "' to ", weapon_def.card_name)
	
	# Apply bonus damage if any (stored in weapon_data for future reference)
	if bonus_damage > 0:
		weapon_data["bonus_damage"] = weapon_data.get("bonus_damage", 0) + bonus_damage
		print("[CardEffectResolver] Tag Infusion: +", bonus_damage, " permanent damage to ", weapon_def.card_name)


static func _resolve_explosive_damage(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Deal damage with splash to adjacent rings."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var splash_damage: int = card_def.get_scaled_value("splash_damage", tier)
	if splash_damage <= 0:
		splash_damage = int(float(damage) * 0.5)  # Default: 50% splash
	
	# Apply artifact bonuses
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply explosive damage multiplier
	var explosive_mult: float = RunManager.player_stats.get_explosive_damage_multiplier()
	damage = int(float(damage) * explosive_mult)
	splash_damage = int(float(splash_damage) * explosive_mult)
	
	# Apply base damage multipliers
	damage = _apply_damage_multipliers(damage, card_def, target_ring)
	
	# Deal main damage to target ring
	combat.deal_damage_to_ring(target_ring, damage)
	
	# Deal splash to adjacent rings
	if target_ring > 0:  # Has inner ring
		combat.deal_damage_to_ring(target_ring - 1, splash_damage)
	if target_ring < 3:  # Has outer ring
		combat.deal_damage_to_ring(target_ring + 1, splash_damage)
	
	# Trigger explosive hit artifact
	ArtifactManager.trigger_artifacts("on_explosive_hit", {"damage": damage, "splash_damage": splash_damage, "ring": target_ring})
	
	print("[CardEffectResolver] Explosive: ", damage, " to ring ", target_ring, ", ", splash_damage, " splash to adjacent")


static func _resolve_beam_damage(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Chain damage through targets (prefers hexed enemies)."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var chain_count: int = card_def.get_scaled_value("chain_count", tier)
	if chain_count <= 0:
		chain_count = 3  # Default: chain to 3 targets
	
	# Apply artifact bonuses
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply beam damage multiplier
	var beam_mult: float = RunManager.player_stats.get_beam_damage_multiplier()
	damage = int(float(damage) * beam_mult)
	
	# Get all enemies in target ring (or all rings if ring not specified)
	var candidates: Array = []
	if target_ring >= 0:
		candidates = combat.battlefield.get_enemies_in_ring(target_ring)
	else:
		candidates = combat.battlefield.get_all_enemies()
	
	if candidates.size() == 0:
		return
	
	# Sort by hex status (prefer hexed enemies first)
	candidates.sort_custom(func(a, b): 
		var a_hex: int = a.get_status_value("hex")
		var b_hex: int = b.get_status_value("hex")
		return a_hex > b_hex
	)
	
	# Chain through targets
	var hit_count: int = min(chain_count, candidates.size())
	var total_damage: int = 0
	
	for i: int in range(hit_count):
		var target = candidates[i]
		
		# Emit targeting signal
		combat.enemy_targeted.emit(target)
		
		# Deal damage
		var result: Dictionary = target.take_damage(damage)
		total_damage += result.total_damage
		
		combat.enemy_damaged.emit(target, result.total_damage, result.hex_triggered)
		
		if target.current_hp <= 0:
			combat._handle_enemy_death(target, result.hex_triggered)
		
		# Trigger beam chain artifact for each hit after the first
		if i > 0:
			ArtifactManager.trigger_artifacts("on_beam_chain", {"damage": damage, "chain_index": i})
	
	combat.damage_dealt_to_enemies.emit(total_damage, target_ring if target_ring >= 0 else 0)
	print("[CardEffectResolver] Beam: Chained through ", hit_count, " targets for total ", total_damage, " damage")


static func _resolve_piercing_damage(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Deal damage with overkill flowing to next target (50% overflow)."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var overflow_percent: float = card_def.effect_params.get("overflow_percent", 50.0)
	
	# Apply artifact bonuses
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply piercing damage multiplier
	var piercing_mult: float = RunManager.player_stats.get_piercing_damage_multiplier()
	damage = int(float(damage) * piercing_mult)
	
	# Get targets in ring
	var candidates: Array = []
	if target_ring >= 0:
		candidates = combat.battlefield.get_enemies_in_ring(target_ring)
	else:
		candidates = combat.battlefield.get_all_enemies()
	
	if candidates.size() == 0:
		return
	
	var total_damage_dealt: int = 0
	var current_damage: int = damage
	var target_index: int = 0
	
	while current_damage > 0 and target_index < candidates.size():
		var target = candidates[target_index]
		
		# Emit targeting signal
		combat.enemy_targeted.emit(target)
		
		# Calculate overkill
		var target_hp: int = target.current_hp
		var result: Dictionary = target.take_damage(current_damage)
		total_damage_dealt += result.total_damage
		
		combat.enemy_damaged.emit(target, result.total_damage, result.hex_triggered)
		
		if target.current_hp <= 0:
			# Calculate overflow
			var overkill: int = current_damage - target_hp
			if overkill > 0:
				var overflow: int = int(float(overkill) * overflow_percent / 100.0)
				current_damage = overflow
				
				# Trigger piercing overflow artifact
				ArtifactManager.trigger_artifacts("on_piercing_overflow", {"overflow": overflow, "overkill": overkill})
				print("[CardEffectResolver] Piercing: ", overkill, " overkill -> ", overflow, " overflow")
			else:
				current_damage = 0
			
			combat._handle_enemy_death(target, result.hex_triggered)
		else:
			current_damage = 0  # No overkill, stop chain
		
		target_index += 1
	
	combat.damage_dealt_to_enemies.emit(total_damage_dealt, target_ring if target_ring >= 0 else 0)


static func _resolve_shock_damage(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Deal damage with chance to apply slow/stun."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var slow_chance: float = card_def.effect_params.get("slow_chance", 20.0)
	
	# Apply artifact bonuses
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply shock damage multiplier
	var shock_mult: float = RunManager.player_stats.get_shock_damage_multiplier()
	damage = int(float(damage) * shock_mult)
	
	# Get targets
	var candidates: Array = []
	if target_ring >= 0:
		candidates = combat.battlefield.get_enemies_in_ring(target_ring)
	else:
		candidates = combat.battlefield.get_all_enemies()
	
	for target in candidates:
		# Emit targeting signal
		combat.enemy_targeted.emit(target)
		
		# Deal damage
		var result: Dictionary = target.take_damage(damage)
		combat.enemy_damaged.emit(target, result.total_damage, result.hex_triggered)
		
		if target.current_hp <= 0:
			combat._handle_enemy_death(target, result.hex_triggered)
		else:
			# Roll for slow
			if randf() * 100.0 < slow_chance:
				target.apply_status("slow", 1, 1)  # Slow for 1 turn
				print("[CardEffectResolver] Shock: Applied slow to ", target.enemy_id)
		
		# Trigger shock hit artifact
		ArtifactManager.trigger_artifacts("on_shock_hit", {"damage": damage, "target": target})
	
	combat.damage_dealt_to_enemies.emit(damage * candidates.size(), target_ring if target_ring >= 0 else 0)


static func _resolve_corrosive_damage(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Deal damage with armor shred, doubled on hexed enemies."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var armor_shred: int = card_def.get_scaled_value("armor_shred", tier)
	if armor_shred <= 0:
		armor_shred = 2  # Default: -2 armor
	
	# Apply artifact bonuses
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
	# V2: Apply corrosive damage multiplier
	var corrosive_mult: float = RunManager.player_stats.get_corrosive_damage_multiplier()
	damage = int(float(damage) * corrosive_mult)
	
	# Get targets
	var candidates: Array = []
	if target_ring >= 0:
		candidates = combat.battlefield.get_enemies_in_ring(target_ring)
	else:
		candidates = combat.battlefield.get_all_enemies()
	
	for target in candidates:
		# Check if target is hexed (double armor shred)
		var hex_status: int = target.get_status_value("hex")
		var actual_shred: int = armor_shred
		if hex_status > 0:
			actual_shred *= 2
		
		# Apply armor shred
		target.apply_status("armor_shred", actual_shred, -1)
		
		# Deal damage
		var result: Dictionary = target.take_damage(damage)
		combat.enemy_damaged.emit(target, result.total_damage, result.hex_triggered)
		
		if target.current_hp <= 0:
			combat._handle_enemy_death(target, result.hex_triggered)
		
		# Trigger corrosive hit artifact
		ArtifactManager.trigger_artifacts("on_corrosive_hit", {"damage": damage, "armor_shred": actual_shred, "target": target})
		
		print("[CardEffectResolver] Corrosive: ", damage, " damage, -", actual_shred, " armor to ", target.enemy_id)


static func _resolve_energy_refund(card_def, _tier: int, combat: Node) -> void:
	"""Refund energy (for cost reduction effects)."""
	var energy_refund: int = card_def.effect_params.get("energy_refund", 1)
	
	combat.current_energy += energy_refund
	combat.energy_changed.emit(combat.current_energy, combat.max_energy)
	print("[CardEffectResolver] Energy refund: +", energy_refund)


static func _resolve_hex_transfer(card_def, _tier: int, combat: Node) -> void:
	"""Move all hex from one enemy to another."""
	var candidates: Array = combat.battlefield.get_all_enemies()
	if candidates.size() < 2:
		print("[CardEffectResolver] Hex Transfer: Need at least 2 enemies")
		return
	
	# Find enemy with most hex
	var source = null
	var max_hex: int = 0
	for enemy in candidates:
		var hex_val: int = enemy.get_status_value("hex")
		if hex_val > max_hex:
			max_hex = hex_val
			source = enemy
	
	if source == null or max_hex == 0:
		print("[CardEffectResolver] Hex Transfer: No hexed enemies found")
		return
	
	# Find different target (prefer unhexed)
	var target = null
	for enemy in candidates:
		if enemy != source:
			target = enemy
			break
	
	if target == null:
		return
	
	# Transfer hex
	source.clear_status("hex")
	target.apply_status("hex", max_hex, -1)
	
	# Emit signals for visual feedback
	combat.enemy_hexed.emit(target, max_hex)
	
	print("[CardEffectResolver] Hex Transfer: Moved ", max_hex, " hex from ", source.enemy_id, " to ", target.enemy_id)
