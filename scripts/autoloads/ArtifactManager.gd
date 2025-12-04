extends Node
## ArtifactManager - V2 Brotato-style Artifact System
## Artifacts use stat_modifiers for PlayerStats integration
## Supports stackable artifacts for build diversity

signal artifact_triggered(artifact, context: Dictionary)
signal artifact_acquired(artifact)
signal stats_changed()  # V2: Emitted when artifact modifiers change

var artifacts: Dictionary = {}  # artifact_id -> ArtifactDefinition
var equipped_artifacts: Array = []  # Array of artifact_ids (can have duplicates for stackable)

const ArtifactDef = preload("res://scripts/resources/ArtifactDefinition.gd")


func _ready() -> void:
	_create_v2_artifacts()
	print("[ArtifactManager] Initialized with ", artifacts.size(), " V2 artifacts")


func _create_v2_artifacts() -> void:
	"""Create the V2 artifact pool - Brotato-style stackable stat items."""
	_create_core_stat_artifacts()
	_create_lifedrain_artifacts()
	_create_hex_ritual_artifacts()
	_create_barrier_fortress_artifacts()
	_create_volatile_artifacts()
	# V2 Brainstorm artifacts
	_create_damage_type_artifacts()
	_create_deployed_gun_artifacts()
	_create_kill_chain_artifacts()
	_create_cross_tag_artifacts()
	_create_tempo_artifacts()


# =============================================================================
# CORE STAT ARTIFACTS (Tag-Agnostic)
# =============================================================================

func _create_core_stat_artifacts() -> void:
	"""Pure stat boosts with mild or no downsides."""
	
	# Sharpened Rounds - gun damage boost
	var sharpened := ArtifactDef.new()
	sharpened.artifact_id = "sharpened_rounds"
	sharpened.artifact_name = "Sharpened Rounds"
	sharpened.description = "Gun damage +10%."
	sharpened.rarity = 1
	sharpened.base_cost = 40
	sharpened.stackable = true
	sharpened.stat_modifiers = {"gun_damage_percent": 10.0}
	sharpened.trigger_type = "passive"
	sharpened.icon = "🔫"
	sharpened.icon_color = Color(0.9, 0.5, 0.2)
	_register_artifact(sharpened)
	
	# Hex Lens - hex damage boost
	var hex_lens := ArtifactDef.new()
	hex_lens.artifact_id = "hex_lens"
	hex_lens.artifact_name = "Hex Lens"
	hex_lens.description = "Hex damage +10%."
	hex_lens.rarity = 1
	hex_lens.base_cost = 40
	hex_lens.stackable = true
	hex_lens.stat_modifiers = {"hex_damage_percent": 10.0}
	hex_lens.trigger_type = "passive"
	hex_lens.icon = "🔮"
	hex_lens.icon_color = Color(0.6, 0.2, 0.8)
	_register_artifact(hex_lens)
	
	# Reinforced Plating - armor gain boost
	var reinforced := ArtifactDef.new()
	reinforced.artifact_id = "reinforced_plating"
	reinforced.artifact_name = "Reinforced Plating"
	reinforced.description = "Armor gained +15%."
	reinforced.rarity = 1
	reinforced.base_cost = 45
	reinforced.stackable = true
	reinforced.stat_modifiers = {"armor_gain_percent": 15.0}
	reinforced.trigger_type = "passive"
	reinforced.icon = "🛡️"
	reinforced.icon_color = Color(0.5, 0.5, 0.6)
	_register_artifact(reinforced)
	
	# Barrier Alloy - barrier strength boost
	var barrier_alloy := ArtifactDef.new()
	barrier_alloy.artifact_id = "barrier_alloy"
	barrier_alloy.artifact_name = "Barrier Alloy"
	barrier_alloy.description = "Barriers have +20% HP/duration."
	barrier_alloy.rarity = 1
	barrier_alloy.base_cost = 45
	barrier_alloy.stackable = true
	barrier_alloy.stat_modifiers = {"barrier_strength_percent": 20.0}
	barrier_alloy.trigger_type = "passive"
	barrier_alloy.icon = "🧱"
	barrier_alloy.icon_color = Color(0.4, 0.6, 0.8)
	_register_artifact(barrier_alloy)
	
	# Tactical Pack - draw boost (non-stackable)
	var tactical := ArtifactDef.new()
	tactical.artifact_id = "tactical_pack"
	tactical.artifact_name = "Tactical Pack"
	tactical.description = "Draw +1 card per turn."
	tactical.rarity = 2
	tactical.base_cost = 75
	tactical.stackable = false
	tactical.stat_modifiers = {"draw_per_turn": 1}
	tactical.trigger_type = "passive"
	tactical.icon = "🎒"
	tactical.icon_color = Color(0.3, 0.5, 0.2)
	_register_artifact(tactical)
	
	# Surge Capacitor - energy boost (non-stackable)
	var surge := ArtifactDef.new()
	surge.artifact_id = "surge_capacitor"
	surge.artifact_name = "Surge Capacitor"
	surge.description = "Energy per turn +1."
	surge.rarity = 2
	surge.base_cost = 80
	surge.stackable = false
	surge.stat_modifiers = {"energy_per_turn": 1}
	surge.trigger_type = "passive"
	surge.icon = "⚡"
	surge.icon_color = Color(1.0, 0.9, 0.2)
	_register_artifact(surge)
	
	# Glass Core - gun boost with HP penalty
	var glass_core := ArtifactDef.new()
	glass_core.artifact_id = "glass_core"
	glass_core.artifact_name = "Glass Core"
	glass_core.description = "Gun damage +20%. Max HP -5."
	glass_core.rarity = 2
	glass_core.base_cost = 60
	glass_core.stackable = true
	glass_core.stat_modifiers = {"gun_damage_percent": 20.0, "max_hp": -5}
	glass_core.trigger_type = "passive"
	glass_core.icon = "💠"
	glass_core.icon_color = Color(0.7, 0.9, 1.0)
	_register_artifact(glass_core)
	
	# Runic Plating - armor boost with heal penalty
	var runic := ArtifactDef.new()
	runic.artifact_id = "runic_plating"
	runic.artifact_name = "Runic Plating"
	runic.description = "Armor gained +25%. Heal power -10%."
	runic.rarity = 2
	runic.base_cost = 55
	runic.stackable = true
	runic.stat_modifiers = {"armor_gain_percent": 25.0, "heal_power_percent": -10.0}
	runic.trigger_type = "passive"
	runic.icon = "🔷"
	runic.icon_color = Color(0.3, 0.4, 0.9)
	_register_artifact(runic)
	
	# Forward Bastion - close range focus
	var forward := ArtifactDef.new()
	forward.artifact_id = "forward_bastion"
	forward.artifact_name = "Forward Bastion"
	forward.description = "Damage vs Melee/Close +15%. Damage vs Mid/Far -10%."
	forward.rarity = 2
	forward.base_cost = 50
	forward.stackable = true
	forward.stat_modifiers = {
		"damage_vs_melee_percent": 15.0,
		"damage_vs_close_percent": 15.0,
		"damage_vs_mid_percent": -10.0,
		"damage_vs_far_percent": -10.0
	}
	forward.trigger_type = "passive"
	forward.icon = "🏰"
	forward.icon_color = Color(0.6, 0.4, 0.2)
	_register_artifact(forward)
	
	# Scrap Magnet - economy boost
	var scrap_magnet := ArtifactDef.new()
	scrap_magnet.artifact_id = "scrap_magnet"
	scrap_magnet.artifact_name = "Scrap Magnet"
	scrap_magnet.description = "Scrap gained +15%."
	scrap_magnet.rarity = 1
	scrap_magnet.base_cost = 50
	scrap_magnet.stackable = true
	scrap_magnet.stat_modifiers = {"scrap_gain_percent": 15.0}
	scrap_magnet.trigger_type = "passive"
	scrap_magnet.icon = "🧲"
	scrap_magnet.icon_color = Color(0.8, 0.6, 0.3)
	_register_artifact(scrap_magnet)


# =============================================================================
# LIFEDRAIN FAMILY ARTIFACTS
# =============================================================================

func _create_lifedrain_artifacts() -> void:
	"""Artifacts for lifedrain/sustain builds."""
	
	# Leech Core - lifedrain heals more
	var leech := ArtifactDef.new()
	leech.artifact_id = "leech_core"
	leech.artifact_name = "Leech Core"
	leech.description = "Lifedrain cards heal +1 HP."
	leech.rarity = 1
	leech.base_cost = 45
	leech.stackable = true
	leech.required_tags = ["lifedrain"]
	leech.trigger_type = "on_card_play"
	leech.trigger_tag = "lifedrain"
	leech.effect_type = "bonus_heal"
	leech.effect_value = 1
	leech.icon = "🩸"
	leech.icon_color = Color(0.8, 0.1, 0.2)
	_register_artifact(leech)
	
	# Sanguine Reservoir - HP boost with heal penalty
	var sanguine := ArtifactDef.new()
	sanguine.artifact_id = "sanguine_reservoir"
	sanguine.artifact_name = "Sanguine Reservoir"
	sanguine.description = "Max HP +10. Heal power -10%."
	sanguine.rarity = 2
	sanguine.base_cost = 55
	sanguine.stackable = false
	sanguine.stat_modifiers = {"max_hp": 10, "heal_power_percent": -10.0}
	sanguine.trigger_type = "passive"
	sanguine.icon = "🫀"
	sanguine.icon_color = Color(0.7, 0.2, 0.3)
	_register_artifact(sanguine)
	
	# Hemorrhage Engine - heal converts to damage (rare)
	var hemorrhage := ArtifactDef.new()
	hemorrhage.artifact_id = "hemorrhage_engine"
	hemorrhage.artifact_name = "Hemorrhage Engine"
	hemorrhage.description = "Whenever you heal, deal that much damage split among enemies in Melee/Close."
	hemorrhage.rarity = 3
	hemorrhage.base_cost = 100
	hemorrhage.stackable = false
	hemorrhage.trigger_type = "on_heal"
	hemorrhage.effect_type = "heal_to_damage"
	hemorrhage.icon = "💉"
	hemorrhage.icon_color = Color(0.9, 0.2, 0.3)
	_register_artifact(hemorrhage)
	
	# Red Aegis - overheal to armor
	var red_aegis := ArtifactDef.new()
	red_aegis.artifact_id = "red_aegis"
	red_aegis.artifact_name = "Red Aegis"
	red_aegis.description = "When you heal at full HP, gain 2 armor instead."
	red_aegis.rarity = 2
	red_aegis.base_cost = 60
	red_aegis.stackable = false
	red_aegis.trigger_type = "on_heal"
	red_aegis.effect_type = "overheal_to_armor"
	red_aegis.effect_value = 2
	red_aegis.icon = "❤️‍🔥"
	red_aegis.icon_color = Color(0.9, 0.3, 0.4)
	_register_artifact(red_aegis)


# =============================================================================
# HEX RITUAL FAMILY ARTIFACTS
# =============================================================================

func _create_hex_ritual_artifacts() -> void:
	"""Artifacts for hex/ritual builds."""
	
	# Occult Focus - hex_ritual applies more hex
	var occult := ArtifactDef.new()
	occult.artifact_id = "occult_focus"
	occult.artifact_name = "Occult Focus"
	occult.description = "Hex_ritual cards apply +1 additional hex."
	occult.rarity = 1
	occult.base_cost = 45
	occult.stackable = true
	occult.required_tags = ["hex_ritual"]
	occult.trigger_type = "on_card_play"
	occult.trigger_tag = "hex_ritual"
	occult.effect_type = "bonus_hex"
	occult.effect_value = 1
	occult.icon = "🌀"
	occult.icon_color = Color(0.5, 0.2, 0.7)
	_register_artifact(occult)
	
	# Blood Pact - scaling hex damage
	var blood_pact := ArtifactDef.new()
	blood_pact.artifact_id = "blood_pact"
	blood_pact.artifact_name = "Blood Pact"
	blood_pact.description = "Start each wave: lose 3 HP, gain +2% hex damage permanently."
	blood_pact.rarity = 2
	blood_pact.base_cost = 65
	blood_pact.stackable = false
	blood_pact.trigger_type = "on_wave_start"
	blood_pact.effect_type = "blood_pact"
	blood_pact.effect_value = 3  # HP lost
	blood_pact.icon = "📜"
	blood_pact.icon_color = Color(0.6, 0.1, 0.3)
	_register_artifact(blood_pact)
	
	# Creeping Doom - hex spreads on consume (rare)
	var creeping := ArtifactDef.new()
	creeping.artifact_id = "creeping_doom"
	creeping.artifact_name = "Creeping Doom"
	creeping.description = "When hex is consumed, apply 1 hex to all other enemies in that ring."
	creeping.rarity = 3
	creeping.base_cost = 95
	creeping.stackable = false
	creeping.trigger_type = "on_hex_consumed"
	creeping.effect_type = "hex_spread"
	creeping.effect_value = 1
	creeping.icon = "☠️"
	creeping.icon_color = Color(0.3, 0.5, 0.2)
	_register_artifact(creeping)
	
	# Ritual Anchor - armor on hex_ritual play
	var anchor := ArtifactDef.new()
	anchor.artifact_id = "ritual_anchor"
	anchor.artifact_name = "Ritual Anchor"
	anchor.description = "When you play a hex_ritual card, gain 1 armor."
	anchor.rarity = 2
	anchor.base_cost = 50
	anchor.stackable = true
	anchor.required_tags = ["hex_ritual"]
	anchor.trigger_type = "on_card_play"
	anchor.trigger_tag = "hex_ritual"
	anchor.effect_type = "gain_armor"
	anchor.effect_value = 1
	anchor.icon = "⚓"
	anchor.icon_color = Color(0.4, 0.3, 0.6)
	_register_artifact(anchor)


# =============================================================================
# BARRIER/FORTRESS FAMILY ARTIFACTS
# =============================================================================

func _create_barrier_fortress_artifacts() -> void:
	"""Artifacts for barrier/fortress builds."""
	
	# Trap Engineer - barrier_trap damage boost
	var trap_eng := ArtifactDef.new()
	trap_eng.artifact_id = "trap_engineer"
	trap_eng.artifact_name = "Trap Engineer"
	trap_eng.description = "Barriers with barrier_trap deal +2 damage."
	trap_eng.rarity = 1
	trap_eng.base_cost = 45
	trap_eng.stackable = true
	trap_eng.required_tags = ["barrier_trap"]
	trap_eng.trigger_type = "on_barrier_trigger"
	trap_eng.trigger_tag = "barrier_trap"
	trap_eng.effect_type = "bonus_damage"
	trap_eng.effect_value = 2
	trap_eng.icon = "⚙️"
	trap_eng.icon_color = Color(0.5, 0.5, 0.5)
	_register_artifact(trap_eng)
	
	# Runic Bastion - fortress barriers grant armor
	var runic_bast := ArtifactDef.new()
	runic_bast.artifact_id = "runic_bastion"
	runic_bast.artifact_name = "Runic Bastion"
	runic_bast.description = "Fortress barriers grant 1 armor when triggered."
	runic_bast.rarity = 2
	runic_bast.base_cost = 55
	runic_bast.stackable = true
	runic_bast.required_tags = ["fortress"]
	runic_bast.trigger_type = "on_barrier_trigger"
	runic_bast.trigger_tag = "fortress"
	runic_bast.effect_type = "gain_armor"
	runic_bast.effect_value = 1
	runic_bast.icon = "🏯"
	runic_bast.icon_color = Color(0.3, 0.4, 0.7)
	_register_artifact(runic_bast)
	
	# Punishing Walls - barrier damage applies hex (rare)
	var punishing := ArtifactDef.new()
	punishing.artifact_id = "punishing_walls"
	punishing.artifact_name = "Punishing Walls"
	punishing.description = "Whenever a barrier deals damage, apply 1 hex to that enemy."
	punishing.rarity = 3
	punishing.base_cost = 90
	punishing.stackable = false
	punishing.trigger_type = "on_barrier_trigger"
	punishing.effect_type = "barrier_hex"
	punishing.effect_value = 1
	punishing.icon = "🧱"
	punishing.icon_color = Color(0.6, 0.3, 0.5)
	_register_artifact(punishing)
	
	# Nested Circles - start with barrier
	var nested := ArtifactDef.new()
	nested.artifact_id = "nested_circles"
	nested.artifact_name = "Nested Circles"
	nested.description = "Start each wave with a Minor Barrier in Close."
	nested.rarity = 2
	nested.base_cost = 60
	nested.stackable = false
	nested.trigger_type = "on_wave_start"
	nested.effect_type = "spawn_barrier"
	nested.effect_value = 1  # Close ring
	nested.icon = "⭕"
	nested.icon_color = Color(0.4, 0.6, 0.7)
	_register_artifact(nested)


# =============================================================================
# VOLATILE/PUSH FAMILY ARTIFACTS
# =============================================================================

func _create_volatile_artifacts() -> void:
	"""Artifacts for volatile/push builds."""
	
	# Kinetic Harness - push deals damage
	var kinetic := ArtifactDef.new()
	kinetic.artifact_id = "kinetic_harness"
	kinetic.artifact_name = "Kinetic Harness"
	kinetic.description = "When you push an enemy, deal 1 damage to it."
	kinetic.rarity = 1
	kinetic.base_cost = 40
	kinetic.stackable = true
	kinetic.trigger_type = "on_card_play"
	kinetic.trigger_tag = "ring_control"
	kinetic.effect_type = "push_damage"
	kinetic.effect_value = 1
	kinetic.icon = "💨"
	kinetic.icon_color = Color(0.5, 0.7, 0.9)
	_register_artifact(kinetic)
	
	# Shock Collars - movement damage
	var shock := ArtifactDef.new()
	shock.artifact_id = "shock_collars"
	shock.artifact_name = "Shock Collars"
	shock.description = "Enemies that move from Mid to Close take 1 damage."
	shock.rarity = 2
	shock.base_cost = 55
	shock.stackable = true
	shock.trigger_type = "passive"  # Handled by combat system
	shock.effect_type = "movement_damage"
	shock.effect_value = 1
	shock.icon = "⚡"
	shock.icon_color = Color(1.0, 0.8, 0.2)
	_register_artifact(shock)
	
	# Last Stand Protocol - defensive boost (rare)
	var last_stand := ArtifactDef.new()
	last_stand.artifact_id = "last_stand_protocol"
	last_stand.artifact_name = "Last Stand Protocol"
	last_stand.description = "At turn start, if 3+ enemies in Melee: gain +1 energy and 3 armor."
	last_stand.rarity = 3
	last_stand.base_cost = 85
	last_stand.stackable = false
	last_stand.trigger_type = "on_turn_start"
	last_stand.effect_type = "last_stand"
	last_stand.effect_value = 3  # Armor gained
	last_stand.icon = "🛑"
	last_stand.icon_color = Color(0.9, 0.3, 0.2)
	_register_artifact(last_stand)
	
	# Overloader - volatile boost with HP cost
	var overloader := ArtifactDef.new()
	overloader.artifact_id = "overloader"
	overloader.artifact_name = "Overloader"
	overloader.description = "Volatile cards deal +2 damage. At end of each wave, lose 3 HP."
	overloader.rarity = 2
	overloader.base_cost = 50
	overloader.stackable = false
	overloader.required_tags = ["volatile"]
	overloader.trigger_type = "on_card_play"
	overloader.trigger_tag = "volatile"
	overloader.effect_type = "bonus_damage"
	overloader.effect_value = 2
	overloader.icon = "💥"
	overloader.icon_color = Color(1.0, 0.5, 0.2)
	_register_artifact(overloader)


# =============================================================================
# V2 DAMAGE-TYPE TAG ARTIFACTS (8)
# =============================================================================

func _create_damage_type_artifacts() -> void:
	"""Artifacts that boost damage-type tags (explosive, piercing, beam, shock, corrosive)."""
	
	# Blast Shielding - explosive damage boost
	var blast := ArtifactDef.new()
	blast.artifact_id = "blast_shielding"
	blast.artifact_name = "Blast Shielding"
	blast.description = "Explosive damage +15%."
	blast.rarity = 1
	blast.base_cost = 40
	blast.stackable = true
	blast.stat_modifiers = {"explosive_damage_percent": 15.0}
	blast.trigger_type = "passive"
	blast.icon = "💥"
	blast.icon_color = Color(1.0, 0.5, 0.1)
	_register_artifact(blast)
	
	# Piercing Scope - piercing overflow boost
	var piercing_scope := ArtifactDef.new()
	piercing_scope.artifact_id = "piercing_scope"
	piercing_scope.artifact_name = "Piercing Scope"
	piercing_scope.description = "Piercing attacks deal +2 overflow damage."
	piercing_scope.rarity = 1
	piercing_scope.base_cost = 40
	piercing_scope.stackable = true
	piercing_scope.trigger_type = "on_piercing_overflow"
	piercing_scope.effect_type = "bonus_overflow"
	piercing_scope.effect_value = 2
	piercing_scope.icon = "🎯"
	piercing_scope.icon_color = Color(0.3, 0.6, 0.9)
	_register_artifact(piercing_scope)
	
	# Arc Coil - beam chain boost
	var arc_coil := ArtifactDef.new()
	arc_coil.artifact_id = "arc_coil"
	arc_coil.artifact_name = "Arc Coil"
	arc_coil.description = "Beam attacks chain to +1 additional target."
	arc_coil.rarity = 1
	arc_coil.base_cost = 45
	arc_coil.stackable = true
	arc_coil.trigger_type = "on_beam_chain"
	arc_coil.effect_type = "bonus_chain"
	arc_coil.effect_value = 1
	arc_coil.icon = "⚡"
	arc_coil.icon_color = Color(0.2, 0.8, 1.0)
	_register_artifact(arc_coil)
	
	# Static Buildup - shock slow chance
	var static_buildup := ArtifactDef.new()
	static_buildup.artifact_id = "static_buildup"
	static_buildup.artifact_name = "Static Buildup"
	static_buildup.description = "Shock attacks have +20% chance to apply Slow."
	static_buildup.rarity = 2
	static_buildup.base_cost = 55
	static_buildup.stackable = false
	static_buildup.trigger_type = "on_shock_hit"
	static_buildup.effect_type = "bonus_slow_chance"
	static_buildup.effect_value = 20
	static_buildup.icon = "⚡"
	static_buildup.icon_color = Color(1.0, 0.9, 0.3)
	_register_artifact(static_buildup)
	
	# Corrosive Residue - extra armor shred
	var corrosive_res := ArtifactDef.new()
	corrosive_res.artifact_id = "corrosive_residue"
	corrosive_res.artifact_name = "Corrosive Residue"
	corrosive_res.description = "Corrosive attacks shred 1 additional armor."
	corrosive_res.rarity = 2
	corrosive_res.base_cost = 50
	corrosive_res.stackable = false
	corrosive_res.trigger_type = "on_corrosive_hit"
	corrosive_res.effect_type = "bonus_shred"
	corrosive_res.effect_value = 1
	corrosive_res.icon = "🧪"
	corrosive_res.icon_color = Color(0.5, 0.9, 0.2)
	_register_artifact(corrosive_res)
	
	# Unstable Payload - explosive splash boost with HP cost
	var unstable := ArtifactDef.new()
	unstable.artifact_id = "unstable_payload"
	unstable.artifact_name = "Unstable Payload"
	unstable.description = "Explosive splash damage +50%. Max HP -3."
	unstable.rarity = 2
	unstable.base_cost = 55
	unstable.stackable = true
	unstable.stat_modifiers = {"explosive_damage_percent": 50.0, "max_hp": -3}
	unstable.trigger_type = "passive"
	unstable.icon = "💣"
	unstable.icon_color = Color(1.0, 0.3, 0.1)
	_register_artifact(unstable)
	
	# Rifling Upgrade - piercing ignores armor
	var rifling := ArtifactDef.new()
	rifling.artifact_id = "rifling_upgrade"
	rifling.artifact_name = "Rifling Upgrade"
	rifling.description = "Piercing attacks ignore 1 armor per hit."
	rifling.rarity = 2
	rifling.base_cost = 60
	rifling.stackable = true
	rifling.stat_modifiers = {"piercing_damage_percent": 10.0}
	rifling.trigger_type = "on_piercing_overflow"
	rifling.effect_type = "ignore_armor"
	rifling.effect_value = 1
	rifling.icon = "🔩"
	rifling.icon_color = Color(0.6, 0.6, 0.6)
	_register_artifact(rifling)
	
	# Chain Lightning Module - beam damage scales with chain
	var chain_lightning := ArtifactDef.new()
	chain_lightning.artifact_id = "chain_lightning_module"
	chain_lightning.artifact_name = "Chain Lightning Module"
	chain_lightning.description = "Beam attacks deal +1 damage per enemy already hit in the chain."
	chain_lightning.rarity = 3
	chain_lightning.base_cost = 95
	chain_lightning.stackable = false
	chain_lightning.trigger_type = "on_beam_chain"
	chain_lightning.effect_type = "scaling_chain_damage"
	chain_lightning.effect_value = 1
	chain_lightning.icon = "⚡"
	chain_lightning.icon_color = Color(0.8, 0.2, 1.0)
	_register_artifact(chain_lightning)


# =============================================================================
# V2 DEPLOYED GUN/ENGINE ARTIFACTS (7)
# =============================================================================

func _create_deployed_gun_artifacts() -> void:
	"""Artifacts for deployed gun/engine builds."""
	
	# Turret Oil - deployed damage boost
	var turret_oil := ArtifactDef.new()
	turret_oil.artifact_id = "turret_oil"
	turret_oil.artifact_name = "Turret Oil"
	turret_oil.description = "Deployed guns and engines deal +10% damage."
	turret_oil.rarity = 1
	turret_oil.base_cost = 40
	turret_oil.stackable = true
	turret_oil.stat_modifiers = {"deployed_gun_damage_percent": 10.0, "engine_damage_percent": 10.0}
	turret_oil.trigger_type = "passive"
	turret_oil.icon = "🛢️"
	turret_oil.icon_color = Color(0.3, 0.3, 0.3)
	_register_artifact(turret_oil)
	
	# Firing Solution - gun count bonus
	var firing_sol := ArtifactDef.new()
	firing_sol.artifact_id = "firing_solution"
	firing_sol.artifact_name = "Firing Solution"
	firing_sol.description = "Deployed guns deal +1 damage per other gun on the board (max +3)."
	firing_sol.rarity = 2
	firing_sol.base_cost = 65
	firing_sol.stackable = false
	firing_sol.trigger_type = "on_gun_fire"
	firing_sol.effect_type = "gun_synergy_damage"
	firing_sol.effect_value = 1
	firing_sol.effect_params = {"max_bonus": 3}
	firing_sol.icon = "📐"
	firing_sol.icon_color = Color(0.2, 0.5, 0.8)
	_register_artifact(firing_sol)
	
	# Ammo Belts - extra ammo
	var ammo_belts := ArtifactDef.new()
	ammo_belts.artifact_id = "ammo_belts"
	ammo_belts.artifact_name = "Ammo Belts"
	ammo_belts.description = "Guns with limited ammo have +1 max ammo."
	ammo_belts.rarity = 1
	ammo_belts.base_cost = 45
	ammo_belts.stackable = true
	ammo_belts.trigger_type = "on_gun_deploy"
	ammo_belts.effect_type = "bonus_ammo"
	ammo_belts.effect_value = 1
	ammo_belts.icon = "🎖️"
	ammo_belts.icon_color = Color(0.6, 0.5, 0.3)
	_register_artifact(ammo_belts)
	
	# Quick Draw - first gun cost reduction
	var quick_draw := ArtifactDef.new()
	quick_draw.artifact_id = "quick_draw"
	quick_draw.artifact_name = "Quick Draw"
	quick_draw.description = "First gun you play each turn costs 1 less."
	quick_draw.rarity = 2
	quick_draw.base_cost = 60
	quick_draw.stackable = false
	quick_draw.trigger_type = "on_turn_start"
	quick_draw.effect_type = "gun_cost_reduction"
	quick_draw.effect_value = 1
	quick_draw.icon = "🤠"
	quick_draw.icon_color = Color(0.8, 0.6, 0.3)
	_register_artifact(quick_draw)
	
	# Autoloader - ammo reload chance
	var autoloader := ArtifactDef.new()
	autoloader.artifact_id = "autoloader"
	autoloader.artifact_name = "Autoloader"
	autoloader.description = "When a gun runs out of ammo, 30% chance to fully reload it."
	autoloader.rarity = 3
	autoloader.base_cost = 90
	autoloader.stackable = false
	autoloader.trigger_type = "on_gun_out_of_ammo"
	autoloader.effect_type = "reload_chance"
	autoloader.effect_value = 30
	autoloader.icon = "🔄"
	autoloader.icon_color = Color(0.4, 0.7, 0.4)
	_register_artifact(autoloader)
	
	# Engine Sync - engine triggers guns
	var engine_sync := ArtifactDef.new()
	engine_sync.artifact_id = "engine_sync"
	engine_sync.artifact_name = "Engine Sync"
	engine_sync.description = "When you play an engine, all deployed guns fire once at 50% damage."
	engine_sync.rarity = 2
	engine_sync.base_cost = 70
	engine_sync.stackable = false
	engine_sync.trigger_type = "on_engine_trigger"
	engine_sync.effect_type = "trigger_all_guns"
	engine_sync.effect_value = 50
	engine_sync.icon = "⚙️"
	engine_sync.icon_color = Color(0.5, 0.5, 0.6)
	_register_artifact(engine_sync)
	
	# Lane Commander - deployed card energy
	var lane_cmd := ArtifactDef.new()
	lane_cmd.artifact_id = "lane_commander"
	lane_cmd.artifact_name = "Lane Commander"
	lane_cmd.description = "Start of turn: if 4+ cards deployed in lane, gain 1 energy."
	lane_cmd.rarity = 3
	lane_cmd.base_cost = 85
	lane_cmd.stackable = false
	lane_cmd.trigger_type = "on_turn_start"
	lane_cmd.effect_type = "lane_energy"
	lane_cmd.effect_value = 1
	lane_cmd.effect_params = {"deployed_threshold": 4}
	lane_cmd.icon = "👨‍✈️"
	lane_cmd.icon_color = Color(0.9, 0.8, 0.2)
	_register_artifact(lane_cmd)


# =============================================================================
# V2 KILL CHAIN ARTIFACTS (6)
# =============================================================================

func _create_kill_chain_artifacts() -> void:
	"""Artifacts that reward killing enemies."""
	
	# Hunter's Quota - scrap on kill
	var hunters := ArtifactDef.new()
	hunters.artifact_id = "hunters_quota"
	hunters.artifact_name = "Hunter's Quota"
	hunters.description = "On kill: gain 1 scrap."
	hunters.rarity = 1
	hunters.base_cost = 45
	hunters.stackable = true
	hunters.trigger_type = "on_kill"
	hunters.effect_type = "bonus_scrap"
	hunters.effect_value = 1
	hunters.icon = "🏹"
	hunters.icon_color = Color(0.6, 0.4, 0.2)
	_register_artifact(hunters)
	
	# Rampage Core - stacking kill damage
	var rampage := ArtifactDef.new()
	rampage.artifact_id = "rampage_core"
	rampage.artifact_name = "Rampage Core"
	rampage.description = "On kill: next gun this turn deals +2 damage (stacks up to 3 kills)."
	rampage.rarity = 2
	rampage.base_cost = 65
	rampage.stackable = false
	rampage.trigger_type = "on_kill"
	rampage.effect_type = "rampage_damage"
	rampage.effect_value = 2
	rampage.effect_params = {"max_stacks": 3}
	rampage.icon = "😤"
	rampage.icon_color = Color(0.9, 0.2, 0.2)
	_register_artifact(rampage)
	
	# Salvage Frame - draw on kill
	var salvage := ArtifactDef.new()
	salvage.artifact_id = "salvage_frame"
	salvage.artifact_name = "Salvage Frame"
	salvage.description = "On kill: 15% chance to draw a card."
	salvage.rarity = 2
	salvage.base_cost = 55
	salvage.stackable = true
	salvage.trigger_type = "on_kill"
	salvage.effect_type = "draw_chance"
	salvage.effect_value = 15
	salvage.icon = "🔧"
	salvage.icon_color = Color(0.5, 0.6, 0.7)
	_register_artifact(salvage)
	
	# Execution Protocol - multi-kill energy
	var execution := ArtifactDef.new()
	execution.artifact_id = "execution_protocol"
	execution.artifact_name = "Execution Protocol"
	execution.description = "Kill 4+ enemies in a single turn: gain 1 energy next turn."
	execution.rarity = 3
	execution.base_cost = 80
	execution.stackable = false
	execution.trigger_type = "on_turn_end"
	execution.effect_type = "multi_kill_energy"
	execution.effect_value = 1
	execution.effect_params = {"kill_threshold": 4}
	execution.icon = "☠️"
	execution.icon_color = Color(0.3, 0.3, 0.3)
	_register_artifact(execution)
	
	# Overkill Catalyst - overkill spreads
	var overkill := ArtifactDef.new()
	overkill.artifact_id = "overkill_catalyst"
	overkill.artifact_name = "Overkill Catalyst"
	overkill.description = "On kill with overkill: deal overkill amount to a random enemy in the same ring."
	overkill.rarity = 2
	overkill.base_cost = 65
	overkill.stackable = false
	overkill.trigger_type = "on_overkill"
	overkill.effect_type = "overkill_spread"
	overkill.effect_value = 100
	overkill.icon = "💀"
	overkill.icon_color = Color(0.8, 0.1, 0.1)
	_register_artifact(overkill)
	
	# Blood Harvest - heal on kill with HP penalty
	var blood_harvest := ArtifactDef.new()
	blood_harvest.artifact_id = "blood_harvest"
	blood_harvest.artifact_name = "Blood Harvest"
	blood_harvest.description = "On kill: heal 1 HP. Max HP -5."
	blood_harvest.rarity = 2
	blood_harvest.base_cost = 50
	blood_harvest.stackable = false
	blood_harvest.stat_modifiers = {"max_hp": -5}
	blood_harvest.trigger_type = "on_kill"
	blood_harvest.effect_type = "heal"
	blood_harvest.effect_value = 1
	blood_harvest.icon = "🌾"
	blood_harvest.icon_color = Color(0.8, 0.2, 0.3)
	_register_artifact(blood_harvest)


# =============================================================================
# V2 CROSS-TAG SYNERGY ARTIFACTS (6)
# =============================================================================

func _create_cross_tag_artifacts() -> void:
	"""Artifacts that reward mixing damage types and build families."""
	
	# Detonation Matrix - explosive restores barriers
	var detonation := ArtifactDef.new()
	detonation.artifact_id = "detonation_matrix"
	detonation.artifact_name = "Detonation Matrix"
	detonation.description = "Explosive damage to barriers restores 1 barrier use instead of consuming it."
	detonation.rarity = 3
	detonation.base_cost = 90
	detonation.stackable = false
	detonation.trigger_type = "on_explosive_hit"
	detonation.effect_type = "barrier_restore"
	detonation.effect_value = 1
	detonation.icon = "🔲"
	detonation.icon_color = Color(1.0, 0.6, 0.1)
	_register_artifact(detonation)
	
	# Hex Conductor - beam spreads hex
	var hex_conductor := ArtifactDef.new()
	hex_conductor.artifact_id = "hex_conductor"
	hex_conductor.artifact_name = "Hex Conductor"
	hex_conductor.description = "Beam attacks spread hex to chained targets instead of consuming hex."
	hex_conductor.rarity = 3
	hex_conductor.base_cost = 95
	hex_conductor.stackable = false
	hex_conductor.trigger_type = "on_beam_chain"
	hex_conductor.effect_type = "hex_spread"
	hex_conductor.effect_value = 1
	hex_conductor.icon = "🔮"
	hex_conductor.icon_color = Color(0.6, 0.2, 0.9)
	_register_artifact(hex_conductor)
	
	# Tesla Casing - shotgun + shock slow
	var tesla := ArtifactDef.new()
	tesla.artifact_id = "tesla_casing"
	tesla.artifact_name = "Tesla Casing"
	tesla.description = "Shotgun attacks with shock apply Slow to all targets hit."
	tesla.rarity = 2
	tesla.base_cost = 60
	tesla.stackable = false
	tesla.required_tags = ["shotgun", "shock"]
	tesla.trigger_type = "on_shock_hit"
	tesla.trigger_tag = "shotgun"
	tesla.effect_type = "aoe_slow"
	tesla.effect_value = 1
	tesla.icon = "🔋"
	tesla.icon_color = Color(0.2, 0.8, 0.9)
	_register_artifact(tesla)
	
	# Overflow Transfusion - piercing heals
	var overflow_trans := ArtifactDef.new()
	overflow_trans.artifact_id = "overflow_transfusion"
	overflow_trans.artifact_name = "Overflow Transfusion"
	overflow_trans.description = "Piercing overflow damage heals you for 50% of overflow dealt."
	overflow_trans.rarity = 3
	overflow_trans.base_cost = 90
	overflow_trans.stackable = false
	overflow_trans.trigger_type = "on_piercing_overflow"
	overflow_trans.effect_type = "overflow_heal"
	overflow_trans.effect_value = 50
	overflow_trans.icon = "💉"
	overflow_trans.icon_color = Color(0.9, 0.3, 0.4)
	_register_artifact(overflow_trans)
	
	# Corrosive Resonance - double shred on hex
	var corrosive_res := ArtifactDef.new()
	corrosive_res.artifact_id = "corrosive_resonance"
	corrosive_res.artifact_name = "Corrosive Resonance"
	corrosive_res.description = "Corrosive armor shred on hexed enemies is doubled."
	corrosive_res.rarity = 2
	corrosive_res.base_cost = 60
	corrosive_res.stackable = false
	corrosive_res.trigger_type = "on_corrosive_hit"
	corrosive_res.effect_type = "double_shred_hex"
	corrosive_res.effect_value = 2
	corrosive_res.icon = "☣️"
	corrosive_res.icon_color = Color(0.4, 0.8, 0.2)
	_register_artifact(corrosive_res)
	
	# Volatile Reactor - self-damage deals enemy damage
	var volatile_reactor := ArtifactDef.new()
	volatile_reactor.artifact_id = "volatile_reactor"
	volatile_reactor.artifact_name = "Volatile Reactor"
	volatile_reactor.description = "When you take self-damage, deal that damage to a random enemy in Melee/Close."
	volatile_reactor.rarity = 3
	volatile_reactor.base_cost = 85
	volatile_reactor.stackable = false
	volatile_reactor.trigger_type = "on_self_damage"
	volatile_reactor.effect_type = "reflect_self_damage"
	volatile_reactor.effect_value = 100
	volatile_reactor.icon = "☢️"
	volatile_reactor.icon_color = Color(1.0, 0.8, 0.1)
	_register_artifact(volatile_reactor)


# =============================================================================
# V3 STAGING/LANE ARTIFACTS (5)
# =============================================================================

func _create_tempo_artifacts() -> void:
	"""Artifacts that reward lane staging and card sequencing."""
	
	# Staging Capacitor - first card staged each turn is free
	var staging_cap := ArtifactDef.new()
	staging_cap.artifact_id = "staging_capacitor"
	staging_cap.artifact_name = "Staging Capacitor"
	staging_cap.description = "First card staged each turn costs 0 energy."
	staging_cap.rarity = 2
	staging_cap.base_cost = 65
	staging_cap.stackable = false
	staging_cap.trigger_type = "on_turn_start"
	staging_cap.effect_type = "free_first_card"
	staging_cap.effect_value = 1
	staging_cap.icon = "⏱️"
	staging_cap.icon_color = Color(0.2, 0.6, 0.9)
	_register_artifact(staging_cap)
	
	# Burst Amplifier - fire immediately bonus
	var burst_amp := ArtifactDef.new()
	burst_amp.artifact_id = "burst_amplifier"
	burst_amp.artifact_name = "Burst Amplifier"
	burst_amp.description = "'Fire immediately' effects deal +2 damage."
	burst_amp.rarity = 1
	burst_amp.base_cost = 45
	burst_amp.stackable = true
	burst_amp.trigger_type = "on_gun_fire"
	burst_amp.trigger_condition = "immediate_fire"
	burst_amp.effect_type = "bonus_damage"
	burst_amp.effect_value = 2
	burst_amp.icon = "💨"
	burst_amp.icon_color = Color(0.9, 0.5, 0.2)
	_register_artifact(burst_amp)
	
	# Coolant System - skill chain draw
	var coolant := ArtifactDef.new()
	coolant.artifact_id = "coolant_system"
	coolant.artifact_name = "Coolant System"
	coolant.description = "After playing 3 skill cards in a turn, draw 1 card."
	coolant.rarity = 2
	coolant.base_cost = 60
	coolant.stackable = false
	coolant.trigger_type = "on_card_play"
	coolant.trigger_tag = "skill"
	coolant.effect_type = "skill_chain_draw"
	coolant.effect_value = 1
	coolant.effect_params = {"skills_needed": 3}
	coolant.icon = "❄️"
	coolant.icon_color = Color(0.3, 0.8, 0.9)
	_register_artifact(coolant)
	
	# Rapid Deployment - persistent gun first fire bonus
	var rapid_deploy := ArtifactDef.new()
	rapid_deploy.artifact_id = "rapid_deployment"
	rapid_deploy.artifact_name = "Rapid Deployment"
	rapid_deploy.description = "Persistent guns deploy with +1 damage for their first firing."
	rapid_deploy.rarity = 1
	rapid_deploy.base_cost = 40
	rapid_deploy.stackable = true
	rapid_deploy.trigger_type = "on_gun_deploy"
	rapid_deploy.effect_type = "first_fire_bonus"
	rapid_deploy.effect_value = 1
	rapid_deploy.icon = "🚀"
	rapid_deploy.icon_color = Color(0.8, 0.3, 0.1)
	_register_artifact(rapid_deploy)
	
	# Infusion Anchor - tag infusion bonus
	var infusion_anchor := ArtifactDef.new()
	infusion_anchor.artifact_id = "infusion_anchor"
	infusion_anchor.artifact_name = "Infusion Anchor"
	infusion_anchor.description = "Tag Infusion cards also grant +1 permanent damage to the infused gun."
	infusion_anchor.rarity = 2
	infusion_anchor.base_cost = 55
	infusion_anchor.stackable = false
	infusion_anchor.trigger_type = "on_card_play"
	infusion_anchor.trigger_condition = "tag_infusion"
	infusion_anchor.effect_type = "infusion_bonus_damage"
	infusion_anchor.effect_value = 1
	infusion_anchor.icon = "⚓"
	infusion_anchor.icon_color = Color(0.5, 0.4, 0.6)
	_register_artifact(infusion_anchor)


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func _register_artifact(artifact) -> void:
	artifacts[artifact.artifact_id] = artifact


func get_artifact(artifact_id: String):
	return artifacts.get(artifact_id, null)


func equip_artifact(artifact_id: String) -> bool:
	"""Equip an artifact. Returns false if non-stackable and already owned."""
	var artifact = get_artifact(artifact_id)
	if not artifact:
		return false
	
	# Check stackability
	if not artifact.stackable and artifact_id in equipped_artifacts:
		print("[ArtifactManager] Cannot stack non-stackable artifact: ", artifact.artifact_name)
		return false
	
	equipped_artifacts.append(artifact_id)
	artifact_acquired.emit(artifact)
	
	# Apply stat modifiers to PlayerStats
	if artifact.stat_modifiers.size() > 0 and RunManager:
		RunManager.player_stats.apply_modifiers(artifact.stat_modifiers)
		RunManager.stats_changed.emit()
	
	print("[ArtifactManager] Equipped artifact: ", artifact.artifact_name, " (x", get_artifact_count(artifact_id), ")")
	stats_changed.emit()
	return true


func get_artifact_count(artifact_id: String) -> int:
	"""Get how many copies of an artifact are equipped."""
	var count: int = 0
	for id: String in equipped_artifacts:
		if id == artifact_id:
			count += 1
	return count


func has_artifact(artifact_id: String) -> bool:
	return artifact_id in equipped_artifacts


func clear_artifacts() -> void:
	equipped_artifacts.clear()
	stats_changed.emit()


func get_equipped_artifacts() -> Array:
	"""Get list of all equipped artifact definitions."""
	var result: Array = []
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if artifact:
			result.append(artifact)
	return result


func get_unique_equipped_artifacts() -> Array:
	"""Get list of unique equipped artifacts with counts."""
	var unique_ids: Array = []
	var result: Array = []
	
	for artifact_id: String in equipped_artifacts:
		if artifact_id not in unique_ids:
			unique_ids.append(artifact_id)
			var artifact = get_artifact(artifact_id)
			if artifact:
				result.append({
					"artifact": artifact,
					"count": get_artifact_count(artifact_id)
				})
	return result


func trigger_artifacts(trigger_type: String, context: Dictionary = {}) -> Dictionary:
	"""Trigger all artifacts of a specific trigger type and return combined effects."""
	var effects: Dictionary = {
		"bonus_damage": 0,
		"bonus_armor": 0,
		"bonus_heal": 0,
		"bonus_hex": 0,
		"heal": 0,
		"draw_cards": 0,
		"bonus_scrap": 0,
		"cost_reduction": 0,
		"gain_armor": 0
	}
	
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if not artifact:
			continue
		
		if artifact.trigger_type != trigger_type:
			continue
		
		# Check tag filter
		if artifact.trigger_tag != "" and context.has("card_tags"):
			if artifact.trigger_tag not in context.card_tags:
				continue
		
		# Check condition
		if artifact.trigger_condition != "" and context.has("condition"):
			if artifact.trigger_condition != context.condition:
				continue
		
		# Apply effect based on type
		match artifact.effect_type:
			"bonus_damage":
				effects.bonus_damage += artifact.effect_value
			"bonus_armor", "gain_armor":
				effects.gain_armor += artifact.effect_value
			"bonus_heal":
				effects.bonus_heal += artifact.effect_value
			"bonus_hex":
				effects.bonus_hex += artifact.effect_value
			"heal":
				if RunManager:
					RunManager.heal(artifact.effect_value)
			"draw_cards":
				effects.draw_cards += artifact.effect_value
			"bonus_scrap":
				effects.bonus_scrap += artifact.effect_value
			"cost_reduction":
				effects.cost_reduction += artifact.effect_value
			"push_damage":
				effects.bonus_damage += artifact.effect_value
			"blood_pact":
				# Lose HP, gain permanent hex damage
				if RunManager:
					RunManager.take_damage(artifact.effect_value)
					RunManager.player_stats.apply_modifier("hex_damage_percent", 2.0)
			"last_stand":
				# Check if 3+ enemies in Melee
				if context.has("melee_enemy_count") and context.melee_enemy_count >= 3:
					effects.gain_armor += artifact.effect_value
					if RunManager:
						RunManager.add_energy(1)
		
		artifact_triggered.emit(artifact, context)
	
	# Apply armor gain
	if effects.gain_armor > 0 and RunManager:
		RunManager.add_armor(effects.gain_armor)
	
	return effects


func get_total_stat_modifiers() -> Dictionary:
	"""Get combined stat modifiers from all equipped artifacts."""
	var total: Dictionary = {}
	
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if artifact and artifact.stat_modifiers.size() > 0:
			for stat_name: String in artifact.stat_modifiers:
				if not total.has(stat_name):
					total[stat_name] = 0
				total[stat_name] += artifact.stat_modifiers[stat_name]
	
	return total


func get_hex_multiplier() -> float:
	"""Get hex damage multiplier from equipped artifacts (V2 compatibility)."""
	var mods: Dictionary = get_total_stat_modifiers()
	var bonus: float = mods.get("hex_damage_percent", 0.0)
	return 1.0 + (bonus / 100.0)


func get_gun_multiplier() -> float:
	"""Get gun damage multiplier from equipped artifacts."""
	var mods: Dictionary = get_total_stat_modifiers()
	var bonus: float = mods.get("gun_damage_percent", 0.0)
	return 1.0 + (bonus / 100.0)


func get_barrier_multiplier() -> float:
	"""Get barrier damage multiplier from equipped artifacts."""
	var mods: Dictionary = get_total_stat_modifiers()
	var bonus: float = mods.get("barrier_damage_percent", 0.0)
	return 1.0 + (bonus / 100.0)


func get_random_artifact(exclude_ids: Array = []):
	"""Get a random artifact. Excludes non-stackable artifacts already owned."""
	var available: Array = []
	for artifact_id: String in artifacts.keys():
		if artifact_id in exclude_ids:
			continue
		var artifact = artifacts[artifact_id]
		# Skip non-stackable artifacts already owned
		if not artifact.stackable and artifact_id in equipped_artifacts:
			continue
		available.append(artifact_id)
	
	if available.size() > 0:
		return artifacts[available[randi() % available.size()]]
	return null


func get_available_artifacts() -> Array:
	"""Get all artifacts available for shop (respects stackability)."""
	var result: Array = []
	for artifact_id: String in artifacts.keys():
		var artifact = artifacts[artifact_id]
		# Skip non-stackable artifacts already owned
		if not artifact.stackable and artifact_id in equipped_artifacts:
			continue
		
		result.append({
			"artifact_id": artifact.artifact_id,
			"artifact_name": artifact.artifact_name,
			"description": artifact.get_description_with_values(),
			"rarity": artifact.rarity,
			"cost": artifact.base_cost,
			"icon": artifact.icon,
			"icon_color": artifact.icon_color,
			"stackable": artifact.stackable,
			"owned_count": get_artifact_count(artifact_id)
		})
	return result


func acquire_artifact(artifact_id: String) -> bool:
	"""Acquire an artifact (purchase from shop)."""
	return equip_artifact(artifact_id)
