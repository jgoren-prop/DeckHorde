extends RefCounted
class_name CardEffectResolver
## CardEffectResolver - Resolves card effects during combat
## V5: New damage formula with 3 damage types, stat scaling, and crits

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")


# =============================================================================
# V5 DAMAGE CALCULATION
# =============================================================================

static func calculate_v5_damage(card_def, include_crit: bool = true) -> Dictionary:
	"""Calculate damage using the V5 formula.
	Formula: Final = (Base + Stat Scaling) × Type Multiplier × Global Multiplier × Crit
	
	Returns: {damage: int, is_crit: bool, breakdown: Dictionary}
	"""
	var stats = RunManager.player_stats
	
	# Use the card's built-in calculation
	var calc: Dictionary = card_def.calculate_damage(stats)
	
	# Add lane bonus damage if present
	var lane_bonus: int = _get_lane_bonus_damage(card_def)
	if lane_bonus > 0:
		calc.final += lane_bonus
		calc.breakdown["lane_bonus"] = lane_bonus
	
	# Add artifact bonus damage
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {
		"card_tags": card_def.tags,
		"categories": card_def.categories,
		"damage_type": card_def.damage_type
	})
	var artifact_bonus: int = artifact_effects.get("bonus_damage", 0)
	if artifact_bonus > 0:
		calc.final += artifact_bonus
		calc.breakdown["artifact_bonus"] = artifact_bonus
	
	# Roll for crit if requested
	var is_crit: bool = false
	var final_damage: int = calc.final
	
	if include_crit and calc.crit_chance > 0:
		is_crit = randf() < calc.crit_chance
		if is_crit:
			final_damage = int(float(calc.final) * calc.crit_mult)
	
	return {
		"damage": maxi(0, final_damage),
		"is_crit": is_crit,
		"crit_mult": calc.crit_mult if is_crit else 1.0,
		"base_damage": calc.final,
		"breakdown": calc.breakdown,
		"type_mult": calc.type_mult,
		"global_mult": calc.global_mult,
	}


static func calculate_v5_damage_preview(card_def) -> int:
	"""Calculate expected damage for UI preview (no crit roll)."""
	var result: Dictionary = calculate_v5_damage(card_def, false)
	return result.damage


static func _apply_damage_multipliers(base_damage: int, card_def, target_ring: int = -1) -> int:
	"""Apply damage multipliers based on card tags and target ring.
	Uses ADDITIVE stacking from PlayerStats.
	"""
	var mult: float = RunManager.get_damage_multiplier_for_card(card_def, target_ring)
	var damage: int = int(float(base_damage) * mult)
	
	if mult != 1.0:
		print("[CardEffectResolver] Damage multiplier applied: ", mult, "x (", base_damage, " -> ", damage, ")")
	
	return damage


static func _get_lane_bonus_damage(card_def) -> int:
	"""Get bonus damage from lane buffs stored in effect_params."""
	var bonus: int = card_def.effect_params.get("lane_bonus_damage", 0)
	return bonus


static func _get_execution_context(card_def) -> Dictionary:
	"""Get the execution context from effect_params."""
	return card_def.effect_params.get("execution_context", {})


static func resolve(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Resolve a card's effect."""
	match card_def.effect_type:
		# V5 Effect Types
		"v5_damage":
			_resolve_v5_damage(card_def, tier, target_ring, combat)
		"v5_multi_hit":
			_resolve_v5_multi_hit(card_def, tier, combat)
		"v5_aoe":
			_resolve_v5_aoe(card_def, tier, target_ring, combat)
		"v5_ring_damage":
			_resolve_v5_ring_damage(card_def, tier, target_ring, combat)
		
		# Status Effect Types
		"apply_hex":
			_resolve_apply_hex(card_def, tier, target_ring, combat)
		"apply_hex_multi":
			_resolve_apply_hex_multi(card_def, tier, combat)
		"apply_burn":
			_resolve_apply_burn(card_def, tier, target_ring, combat)
		"apply_burn_multi":
			_resolve_apply_burn_multi(card_def, tier, combat)
		
		# Utility Effect Types
		"heal":
			_resolve_heal(card_def, tier)
		"buff":
			_resolve_buff(card_def, tier)
		"gain_armor":
			_resolve_gain_armor(card_def, tier)
		"ring_barrier":
			_resolve_ring_barrier(card_def, tier, target_ring, combat)
		"draw_cards":
			_resolve_draw_cards(card_def, tier, combat)
		"push_enemies":
			_resolve_push_enemies(card_def, tier, target_ring, combat)
		
		# Lane Staging Effect Types
		"lane_buff":
			_resolve_lane_buff(card_def, tier)
		"splash_damage":
			_resolve_splash_damage(card_def, tier, combat)
		"scaling_damage":
			_resolve_scaling_damage(card_def, tier, target_ring, combat)
		"last_damaged":
			_resolve_last_damaged(card_def, tier, combat)
		
		_:
			push_warning("[CardEffectResolver] Unknown effect type: " + card_def.effect_type)


static func get_target_count(card_def, tier: int) -> int:
	"""Get how many targets a card should hit."""
	var target_count: int = card_def.get_scaled_value("target_count", tier)
	if target_count <= 0:
		target_count = 1
	return target_count


# =============================================================================
# UTILITY EFFECT HANDLERS
# =============================================================================

static func _resolve_heal(card_def, tier: int) -> void:
	"""Heal the player."""
	var heal_amount: int = card_def.get_scaled_value("heal_amount", tier)
	RunManager.heal(heal_amount)


static func _resolve_buff(card_def, tier: int) -> void:
	"""Apply a buff to the player."""
	var buff_value: int = card_def.get_scaled_value("buff_value", tier)
	
	match card_def.buff_type:
		"energy":
			# Add energy this turn
			CombatManager.current_energy += buff_value
			CombatManager.energy_changed.emit(CombatManager.current_energy, CombatManager.max_energy)
			print("[CardEffectResolver] Applied energy buff: +", buff_value)
		"guaranteed_crit":
			# Next weapon guaranteed crit (stored in effect_params for CombatManager to check)
			CombatManager.set_next_weapon_crit(true)
			print("[CardEffectResolver] Applied guaranteed crit buff")
		"crit_damage_bonus":
			# Next weapon +crit damage (stored for CombatManager)
			CombatManager.set_next_weapon_crit_bonus(50)
			print("[CardEffectResolver] Applied crit damage bonus: +50%")
		"prevent_advance":
			# Enemies can't advance this turn
			CombatManager.set_prevent_advance(true)
			print("[CardEffectResolver] Applied prevent advance buff")
		"weapon_apply_burn":
			# Next weapon applies burn
			CombatManager.set_next_weapon_burn(2)
			print("[CardEffectResolver] Applied weapon burn buff: 2 stacks")
		"weapon_apply_hex":
			# Next weapon applies hex
			CombatManager.set_next_weapon_hex(2)
			print("[CardEffectResolver] Applied weapon hex buff: 2 stacks")
		"missing_hp_damage":
			# Next weapon +damage per missing HP
			var missing_hp: int = RunManager.max_hp - RunManager.current_hp
			var bonus: int = int(float(missing_hp) / 5.0)
			CombatManager.set_next_weapon_bonus_damage(bonus)
			print("[CardEffectResolver] Applied missing HP damage: +", bonus)
		_:
			push_warning("[CardEffectResolver] Unknown buff type: " + card_def.buff_type)


static func _resolve_apply_hex(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Apply hex to enemies in a ring."""
	var hex_damage: int = card_def.get_scaled_value("hex_damage", tier)
	
	# V5: Apply hex potency from PlayerStats
	var potency_mult: float = RunManager.player_stats.get_hex_potency_multiplier()
	hex_damage = int(float(hex_damage) * potency_mult)
	
	var rings_to_hex: Array[int] = []
	if card_def.requires_target:
		rings_to_hex = [target_ring]
	else:
		rings_to_hex.assign(card_def.target_rings)
	
	for ring: int in rings_to_hex:
		var enemies: Array = combat.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:
			combat.enemy_hexed.emit(enemy, hex_damage)
			enemy.apply_status("hex", hex_damage, -1)


static func _resolve_apply_hex_multi(card_def, tier: int, combat: Node) -> void:
	"""Apply hex to multiple random enemies."""
	var hex_damage: int = card_def.get_scaled_value("hex_damage", tier)
	var target_count: int = card_def.get_scaled_value("target_count", tier)
	
	# V5: Apply hex potency from PlayerStats
	var potency_mult: float = RunManager.player_stats.get_hex_potency_multiplier()
	hex_damage = int(float(hex_damage) * potency_mult)
	
	var all_enemies: Array = combat.battlefield.get_all_enemies()
	all_enemies.shuffle()
	
	var count: int = min(target_count, all_enemies.size())
	for i: int in range(count):
		combat.enemy_hexed.emit(all_enemies[i], hex_damage)
		all_enemies[i].apply_status("hex", hex_damage, -1)


static func _resolve_gain_armor(card_def, tier: int) -> void:
	"""Grant armor to the player."""
	var armor_amount: int = card_def.get_scaled_value("armor_amount", tier)
	
	# Check for special armor calculation
	if card_def.effect_params.get("armor_equals_stat", "") == "armor_start":
		armor_amount = RunManager.player_stats.armor_start
	
	# Check for artifact bonus
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	armor_amount += artifact_effects.get("bonus_armor", 0)
	
	RunManager.add_armor(armor_amount)


static func _resolve_ring_barrier(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Create a barrier on a ring that damages crossing enemies.
	V5: Uses barrier_damage_bonus and barrier_uses_bonus from PlayerStats.
	"""
	var base_damage: int = card_def.get_scaled_value("damage", tier)
	var base_duration: int = card_def.effect_params.get("duration", 2)
	
	# V5: Apply barrier_damage_bonus (flat bonus)
	var damage: int = base_damage + RunManager.player_stats.barrier_damage_bonus
	
	# V5: Apply barrier_uses_bonus (extra uses)
	var duration: int = base_duration + RunManager.player_stats.barrier_uses_bonus
	duration = maxi(1, duration)
	
	combat.battlefield.add_ring_barrier(target_ring, damage, duration)
	
	# V5: Track active barriers for weapons that scale with barrier count
	RunManager.player_stats.barriers += 1
	
	# Emit signal for visual feedback
	combat.barrier_placed.emit(target_ring, damage, duration)
	print("[CardEffectResolver V5] Barrier placed: ring=", target_ring, " damage=", damage, " uses=", duration)


static func _resolve_draw_cards(card_def, _tier: int, combat: Node) -> void:
	"""Draw additional cards."""
	var count: int = card_def.cards_to_draw
	if count <= 0:
		count = 1
	
	for i: int in range(count):
		combat.deck_manager.draw_card()


static func _resolve_push_enemies(card_def, _tier: int, target_ring: int, combat: Node) -> void:
	"""Push enemies outward."""
	var push_amount: int = card_def.push_amount
	
	var rings_to_push: Array[int] = []
	if card_def.requires_target:
		rings_to_push = [target_ring]
	else:
		rings_to_push.assign(card_def.target_rings)
	
	# Collect all enemies to push FIRST, then push them
	var enemies_to_push: Array = []
	for ring: int in rings_to_push:
		var enemies: Array = combat.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:
			enemies_to_push.append(enemy)
	
	for enemy in enemies_to_push:
		var old_ring: int = enemy.ring
		var new_ring: int = mini(BattlefieldStateScript.Ring.FAR, old_ring + push_amount)
		if new_ring != old_ring:
			combat.battlefield.move_enemy(enemy, new_ring)
			CombatManager.enemy_moved.emit(enemy, old_ring, new_ring)


# =============================================================================
# V5 EFFECT HANDLERS
# =============================================================================

static func _resolve_v5_damage(card_def, _tier: int, target_ring: int, combat: Node) -> void:
	"""V5 damage: Single target using V5 damage formula with crit."""
	var damage_result: Dictionary = calculate_v5_damage(card_def, true)
	var damage: int = damage_result.damage
	var is_crit: bool = damage_result.is_crit
	
	# Handle self-damage for volatile cards
	if card_def.self_damage > 0:
		var self_dmg: int = card_def.self_damage
		self_dmg = maxi(0, self_dmg - RunManager.player_stats.self_damage_reduction)
		if self_dmg > 0:
			RunManager.take_damage(self_dmg)
			print("[CardEffectResolver V5] Self-damage: ", self_dmg)
	
	# Deal damage based on target type
	match card_def.target_type:
		"ring":
			var rings_to_hit: Array[int] = []
			if card_def.requires_target:
				rings_to_hit = [target_ring]
			else:
				rings_to_hit.assign(card_def.target_rings)
			for ring: int in rings_to_hit:
				_deal_v5_damage_to_ring(ring, damage, is_crit, combat)
		
		"random_enemy":
			var ring_mask: int = _build_ring_mask(card_def.target_rings)
			_deal_v5_damage_to_random(ring_mask, damage, is_crit, card_def.target_count, combat)
		
		"all_enemies":
			_deal_v5_damage_to_all(damage, is_crit, combat)
	
	if is_crit:
		print("[CardEffectResolver V5] CRIT! ", damage_result.base_damage, " x ", damage_result.crit_mult, " = ", damage)
	
	RunManager.player_stats.cards_played += 1


static func _resolve_v5_multi_hit(card_def, _tier: int, combat: Node) -> void:
	"""V5 multi-hit: Hit multiple times, each can crit separately."""
	var hit_count: int = card_def.hit_count
	if hit_count <= 0:
		hit_count = 1
	
	var ring_mask: int = _build_ring_mask(card_def.target_rings)
	var total_damage: int = 0
	var crit_count: int = 0
	
	# Handle self-damage first
	if card_def.self_damage > 0:
		var self_dmg: int = card_def.self_damage
		self_dmg = maxi(0, self_dmg - RunManager.player_stats.self_damage_reduction)
		if self_dmg > 0:
			RunManager.take_damage(self_dmg)
	
	for i: int in range(hit_count):
		var damage_result: Dictionary = calculate_v5_damage(card_def, true)
		var damage: int = damage_result.damage
		var is_crit: bool = damage_result.is_crit
		
		if is_crit:
			crit_count += 1
		
		_deal_v5_damage_to_random(ring_mask, damage, is_crit, 1, combat)
		total_damage += damage
	
	print("[CardEffectResolver V5] Multi-hit: ", hit_count, " hits, ", total_damage, " total damage, ", crit_count, " crits")
	RunManager.player_stats.cards_played += 1


static func _resolve_v5_aoe(card_def, _tier: int, target_ring: int, combat: Node) -> void:
	"""V5 AOE: Hit all enemies in target ring(s)."""
	var damage_result: Dictionary = calculate_v5_damage(card_def, true)
	var damage: int = damage_result.damage
	var is_crit: bool = damage_result.is_crit
	
	# Handle self-damage
	if card_def.self_damage > 0:
		var self_dmg: int = card_def.self_damage
		self_dmg = maxi(0, self_dmg - RunManager.player_stats.self_damage_reduction)
		if self_dmg > 0:
			RunManager.take_damage(self_dmg)
	
	var rings_to_hit: Array[int] = []
	if card_def.requires_target:
		rings_to_hit = [target_ring]
	elif card_def.target_type == "all_rings" or card_def.target_type == "all_enemies":
		rings_to_hit = [0, 1, 2, 3]
	else:
		rings_to_hit.assign(card_def.target_rings)
	
	var total_enemies_hit: int = 0
	for ring: int in rings_to_hit:
		var enemies: Array = combat.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage, is_crit, combat)
			total_enemies_hit += 1
	
	if is_crit:
		print("[CardEffectResolver V5] AOE CRIT! ", total_enemies_hit, " enemies hit for ", damage, " each")
	else:
		print("[CardEffectResolver V5] AOE: ", total_enemies_hit, " enemies hit for ", damage, " each")
	
	RunManager.player_stats.cards_played += 1


static func _resolve_v5_ring_damage(card_def, _tier: int, target_ring: int, combat: Node) -> void:
	"""V5 ring damage: Hit entire ring, used for thermal AOE."""
	var damage_result: Dictionary = calculate_v5_damage(card_def, true)
	var damage: int = damage_result.damage
	var is_crit: bool = damage_result.is_crit
	
	# Handle self-damage
	if card_def.self_damage > 0:
		var self_dmg: int = card_def.self_damage
		self_dmg = maxi(0, self_dmg - RunManager.player_stats.self_damage_reduction)
		if self_dmg > 0:
			RunManager.take_damage(self_dmg)
	
	_deal_v5_damage_to_ring(target_ring, damage, is_crit, combat)
	
	# Apply splash damage to adjacent groups if present
	if card_def.splash_damage > 0:
		var splash: int = int(float(card_def.splash_damage) * damage_result.type_mult * damage_result.global_mult)
		var enemies: Array = combat.battlefield.get_enemies_in_ring(target_ring)
		for enemy in enemies:
			if enemy.current_hp > 0:
				_deal_damage_to_enemy(enemy, splash, false, combat)
	
	RunManager.player_stats.cards_played += 1


static func _resolve_apply_burn(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Apply burn stacks to enemies in a ring."""
	var burn_amount: int = card_def.get_scaled_value("burn_damage", tier)
	if burn_amount <= 0:
		burn_amount = card_def.burn_damage
	
	# V5: Apply burn potency from stats
	var potency_mult: float = RunManager.player_stats.get_burn_potency_multiplier()
	burn_amount = int(float(burn_amount) * potency_mult)
	
	var rings_to_burn: Array[int] = []
	if card_def.requires_target:
		rings_to_burn = [target_ring]
	else:
		rings_to_burn.assign(card_def.target_rings)
	
	for ring: int in rings_to_burn:
		var enemies: Array = combat.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:
			enemy.apply_status("burn", burn_amount, -1)
			if combat.has_signal("enemy_burned"):
				combat.enemy_burned.emit(enemy, burn_amount)
			print("[CardEffectResolver V5] Applied ", burn_amount, " Burn to ", enemy.enemy_id)
	
	RunManager.player_stats.cards_played += 1


static func _resolve_apply_burn_multi(card_def, tier: int, combat: Node) -> void:
	"""Apply burn stacks to multiple random enemies."""
	var burn_amount: int = card_def.get_scaled_value("burn_damage", tier)
	if burn_amount <= 0:
		burn_amount = card_def.burn_damage
	var target_count: int = card_def.target_count
	
	# V5: Apply burn potency
	var potency_mult: float = RunManager.player_stats.get_burn_potency_multiplier()
	burn_amount = int(float(burn_amount) * potency_mult)
	
	var all_enemies: Array = combat.battlefield.get_all_enemies()
	all_enemies.shuffle()
	
	var count: int = mini(target_count, all_enemies.size())
	for i: int in range(count):
		all_enemies[i].apply_status("burn", burn_amount, -1)
		print("[CardEffectResolver V5] Applied ", burn_amount, " Burn to ", all_enemies[i].enemy_id)
	
	RunManager.player_stats.cards_played += 1


# =============================================================================
# V5 HELPER FUNCTIONS
# =============================================================================

static func _build_ring_mask(target_rings: Array) -> int:
	"""Build a ring bitmask from target_rings array."""
	var mask: int = 0
	for ring: Variant in target_rings:
		if ring is int:
			mask |= (1 << ring)
	if mask == 0:
		mask = 0b1111
	return mask


static func _deal_v5_damage_to_ring(ring: int, damage: int, is_crit: bool, combat: Node) -> void:
	"""Deal V5 damage to all enemies in a ring."""
	var enemies: Array = combat.battlefield.get_enemies_in_ring(ring)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage, is_crit, combat)


static func _deal_v5_damage_to_random(ring_mask: int, damage: int, is_crit: bool, count: int, combat: Node) -> void:
	"""Deal V5 damage to random enemies."""
	for i: int in range(count):
		var enemy = combat.battlefield.get_random_enemy_in_rings(ring_mask)
		if enemy:
			_deal_damage_to_enemy(enemy, damage, is_crit, combat)


static func _deal_v5_damage_to_all(damage: int, is_crit: bool, combat: Node) -> void:
	"""Deal V5 damage to all enemies."""
	var all_enemies: Array = combat.battlefield.get_all_enemies()
	for enemy in all_enemies:
		_deal_damage_to_enemy(enemy, damage, is_crit, combat)


static func _deal_damage_to_enemy(enemy, damage: int, _is_crit: bool, combat: Node) -> void:
	"""Deal damage to a single enemy with V5 handling."""
	combat.enemy_targeted.emit(enemy)
	
	var result: Dictionary = enemy.take_damage(damage)
	var total_damage: int = result.total_damage
	
	combat.enemy_damaged.emit(enemy, total_damage, result.hex_triggered)
	
	if enemy.current_hp <= 0:
		combat._handle_enemy_death(enemy, result.hex_triggered)
		RunManager.player_stats.kills_this_turn += 1
	
	combat.damage_dealt_to_enemies.emit(total_damage, enemy.ring)


# =============================================================================
# LANE STAGING EFFECT HANDLERS
# =============================================================================

static func _resolve_lane_buff(card_def, _tier: int) -> void:
	"""Lane buff cards apply their buff instantly when staged."""
	print("[CardEffectResolver] Lane buff executed: ", card_def.card_name)


static func _resolve_scaling_damage(card_def, tier: int, target_ring: int, combat: Node) -> void:
	"""Deal damage that scales based on lane execution state."""
	var base_damage: int = card_def.get_scaled_value("damage", tier)
	var scaling_value: int = card_def.get_scaled_value("scaling_value", tier)
	
	var context: Dictionary = _get_execution_context(card_def)
	var bonus_damage: int = 0
	
	match card_def.scaling_type:
		"guns_fired":
			var guns_fired: int = context.get("guns_fired", 0)
			bonus_damage = guns_fired * scaling_value
		"cards_played":
			var cards_played: int = context.get("cards_played", 0)
			bonus_damage = cards_played * scaling_value
		"damage_dealt":
			var damage_dealt: int = context.get("damage_dealt", 0)
			bonus_damage = int(float(damage_dealt) / 10.0) * scaling_value
	
	bonus_damage += _get_lane_bonus_damage(card_def)
	var total_damage: int = base_damage + bonus_damage
	
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	total_damage += artifact_effects.get("bonus_damage", 0)
	
	total_damage = _apply_damage_multipliers(total_damage, card_def, target_ring)
	
	match card_def.target_type:
		"random_enemy":
			var ring_mask: int = _build_ring_mask(card_def.target_rings)
			combat.deal_damage_to_random_enemy(ring_mask, total_damage)
		"last_damaged":
			combat.deal_damage_to_last_damaged(total_damage)
		_:
			combat.deal_damage_to_random_enemy(0b1111, total_damage)
	
	print("[CardEffectResolver] Scaling damage: base ", base_damage, " + bonus ", bonus_damage, " = ", total_damage)


static func _resolve_splash_damage(card_def, tier: int, combat: Node) -> void:
	"""Deal damage to a target and splash damage to its group."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var splash: int = card_def.get_scaled_value("splash_damage", tier)
	
	damage += _get_lane_bonus_damage(card_def)
	
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.get("bonus_damage", 0)
	
	damage = _apply_damage_multipliers(damage, card_def, -1)
	splash = int(float(splash) * RunManager.get_damage_multiplier_for_card(card_def, -1))
	
	var ring_mask: int = _build_ring_mask(card_def.target_rings)
	
	var candidates: Array = []
	for ring: int in range(4):
		if ring_mask & (1 << ring):
			candidates.append_array(combat.battlefield.get_enemies_in_ring(ring))
	
	if candidates.is_empty():
		return
	
	var target = candidates[randi() % candidates.size()]
	
	combat.enemy_targeted.emit(target)
	await combat.get_tree().create_timer(0.3).timeout
	
	var result: Dictionary = target.take_damage(damage)
	combat.enemy_damaged.emit(target, result.total_damage, result.hex_triggered)
	
	if target.current_hp <= 0:
		combat._handle_enemy_death(target, result.hex_triggered)
	
	if splash > 0 and not target.group_id.is_empty():
		var all_enemies: Array = combat.battlefield.get_all_enemies()
		for enemy in all_enemies:
			if enemy.group_id == target.group_id and enemy.instance_id != target.instance_id:
				var splash_result: Dictionary = enemy.take_damage(splash)
				combat.enemy_damaged.emit(enemy, splash_result.total_damage, splash_result.hex_triggered)
				if enemy.current_hp <= 0:
					combat._handle_enemy_death(enemy, splash_result.hex_triggered)


static func _resolve_last_damaged(card_def, tier: int, combat: Node) -> void:
	"""Deal damage to the last enemy that was damaged this execution."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	
	damage += _get_lane_bonus_damage(card_def)
	
	var artifact_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": card_def.tags})
	damage += artifact_effects.get("bonus_damage", 0)
	
	damage = _apply_damage_multipliers(damage, card_def, -1)
	
	combat.deal_damage_to_last_damaged(damage)
	
	var armor_amount: int = card_def.get_scaled_value("armor_amount", tier)
	if armor_amount > 0:
		var context: Dictionary = _get_execution_context(card_def)
		var scaling_armor: int = armor_amount
		if card_def.scales_with_lane and card_def.scaling_type == "guns_fired":
			var guns_fired: int = context.get("guns_fired", 0)
			scaling_armor += guns_fired * card_def.scaling_value
		RunManager.add_armor(scaling_armor)
