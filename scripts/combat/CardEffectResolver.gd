extends RefCounted
class_name CardEffectResolver
## CardEffectResolver - Resolves card effects during combat

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")


static func _apply_warden_tag_bonus(base_damage: int, tags: Array, target_ring: int = -1) -> int:
	"""Apply warden tag damage bonuses (e.g., Ash Warden +15% gun damage to Close/Melee)."""
	var damage: int = base_damage
	
	for tag in tags:
		var bonus: float = RunManager.get_warden_tag_bonus(tag)
		if bonus > 0.0:
			# Ash Warden passive: bonus only applies to Close (1) and Melee (0) rings
			if target_ring < 0 or target_ring <= 1:  # -1 means random target, apply bonus
				damage = int(float(damage) * (1.0 + bonus))
				print("[CardEffectResolver] Warden tag bonus applied: +", bonus * 100.0, "% to ", tag)
	
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
	
	# Check for Ash Warden passive: gun cards deal +15% damage to Close/Melee
	damage = _apply_warden_tag_bonus(damage, card_def.tags, target_ring)
	
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
			# This would be tracked in a buff system
			# For now, we'll handle this differently via artifacts/modifiers
			print("[CardEffectResolver] Applied gun_damage buff: +", buff_value, "%")
		"damage":
			RunManager.damage_multiplier += buff_value / 100.0
		_:
			push_warning("[CardEffectResolver] Unknown buff type: " + card_def.buff_type)


static func _resolve_apply_hex(card_def, tier: int, target_ring: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Apply hex to enemies in a ring."""
	var hex_damage: int = card_def.get_scaled_value("hex_damage", tier)
	
	# Apply hex multiplier from artifacts (Void Heart)
	var hex_mult: float = ArtifactManager.get_hex_multiplier()
	hex_damage = int(float(hex_damage) * hex_mult)
	
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
	
	# Apply hex multiplier from artifacts (Void Heart)
	var hex_mult: float = ArtifactManager.get_hex_multiplier()
	hex_damage = int(float(hex_damage) * hex_mult)
	
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
	
	# Deal damage to random enemy
	var ring_mask: int = 0b1111  # All rings
	combat.deal_damage_to_random_enemy(ring_mask, damage)
	
	# Heal player
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
	
	for ring: int in rings_to_push:
		var enemies: Array = combat.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:  # enemy: EnemyInstance
			var new_ring: int = mini(BattlefieldStateScript.Ring.FAR, enemy.ring + push_amount)
			combat.battlefield.move_enemy(enemy, new_ring)


static func _resolve_damage_and_draw(card_def, tier: int, combat: Node) -> void:  # card_def: CardDefinition
	"""Deal damage to random enemy and draw cards."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var cards_count: int = card_def.cards_to_draw
	if cards_count <= 0:
		cards_count = 1
	
	# Check for Ember Charm artifact bonus (gun cards deal +2 damage)
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.bonus_damage
	
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
	
	# Apply hex multiplier from artifacts (Void Heart)
	var hex_mult: float = ArtifactManager.get_hex_multiplier()
	hex_damage = int(float(hex_damage) * hex_mult)
	
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
	
	# Emit damage signal for visual feedback
	combat.enemy_damaged.emit(target, total_damage)
	
	if target.current_hp <= 0:
		# Use CombatManager's death handler for proper artifact triggers
		combat._handle_enemy_death(target)
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
	
	# Emit damage signal for visual feedback
	combat.enemy_damaged.emit(target, total_damage)
	
	if target.current_hp <= 0:
		# Use CombatManager's death handler for proper artifact triggers
		combat._handle_enemy_death(target)
	
	combat.damage_dealt_to_enemies.emit(total_damage, target.ring)
