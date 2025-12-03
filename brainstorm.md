# Board Synergy Brainstorm (2024-03-13)

### What currently works
- Persistent guns already feel good as auto-clear; shotgun/sniper variants cover Close/Far rings.
- Hex and barriers scale well when waves are wide (Plague Cloud, Ring Ward), but have few hooks into the weapon lane.
- Volatile and lifedrain cards are mostly instant; they do not currently buff or consume board state.

### Problems to solve
- Turns lack "board knobs": few cards change how deployed weapons behave or when they fire.
- Tags like `aoe`, `shotgun`, `sniper` exist, but we lack damage-type tags (explosive/beam/piercing/shock) that can be buffed wholesale.
- Instant cards rarely interact with deployed weapons or barriers beyond raw damage.

### Damage-type tag directions
- Add damage tags layered on top of behavior tags: `explosive` (splash hits adjacent rings), `piercing` (overkill flows to next target), `beam` (chains through a ring), `shock` (stun/slow chance), `corrosive` (armor shred, synergizes with hex).
- Global/turn buffs can target these tags: "Explosive shots deal +100% damage this turn and splash 2 to adjacent ring", "Piercing attacks gain +50% overflow".
- Consider **tag infusion** cards/services that permanently add a damage tag to a weapon: e.g., give Rusty Pistol `piercing` so its single shot continues through the stack and hits a second enemy, or give Storm Carbine `explosive` to add adjacent-ring splash.

### New board-deployed concepts
- Mortar Team (gun, persistent, explosive, sniper): End of turn, deal 5 damage to Far; splash 2 to Mid. Limited ammo 3; can be reloaded.
- Arc Conductor (engine, persistent, beam): Stores 1 charge when you play a hex card; at end of turn, discharge for 3 chaining damage to 3 enemies (prefers hexed).
- Bulwark Drone (engine, persistent, fortress): End of turn, grant 2 armor; if you control 3+ barriers, also place a 2-damage barrier in Close.
- Pulse Array (gun, persistent, shock, aoe): Fires before enemy phase, dealing 1 damage to all enemies in one chosen ring; applies slow if they already moved this turn.
- Ammo Foundry (engine, persistent, volatile): Every 2 kills, give +1 damage to all deployed guns for the next turn; then deal 1 self-damage.
- Scrap Forge (engine, persistent): On kill, 20% chance to create a 1-cost "Shard Shot" (instant gun, 4 damage) into hand next turn.

### Instant/tempo plays that touch the board
- Overclock (skill, instant, engine_core): All deployed guns fire immediately for 75% damage; draw 1.
- Target Sync (skill, instant): Choose a ring; deployed weapons prioritize that ring this turn and gain +2 damage against it.
- Explosive Primer (skill, instant, explosive tag): This turn, explosive attacks double splash damage and can damage barriers to refresh them (restore 1 use/HP per hit).
- Hex Transfer (skill, instant, hex_ritual): Move all hex from one enemy to another and make your next persistent gun apply 2 hex on hit.
- Barrier Channel (skill, instant, fortress): Triggers all barriers once without consuming uses; each trigger grants 1 armor.
- Emergency Deploy (skill, instant, swarm_clear): Play the top persistent gun from your draw pile to the lane for -1 cost and fire it once.

### Cross-tag synergies to chase (Brotato-style)
- Explosive + Barrier: Barriers detonated by explosive splash deal bonus hex and refresh 1 use.
- Beam + Hex: Beam damage spreads hex instead of consuming it; encourages lane + hex builds.
- Shock + Shotgun: Multi-hit guns apply stacking slow, amplifying push/lockdown rings.
- Piercing + Lifedrain: Overflow damage heals for 50% of overflow; rewards overkill builds.

### What to avoid
- Too many single-ring-only buffs; prefer effects that either retarget the board or scale all weapons of a tag to keep generic synergy feel.
- Permanent multiplicative stacking on the lane without caps; keep turn-based bursts or short-duration ammo to avoid runaway boards.

### Starter deck rethink (board-first, tag-flex)
- Premise: lane online by turn 1-2, then scale via tempo and tag infusion so future shops have clear synergy hooks.
- Proposed 10-card starter (concept only):
	- Rusty Pistol ×2 (persistent gun) – baseline lane fill, good pierce target.
	- Storm Carbine ×1 (persistent gun, close/mid) – spreads coverage without high cost.
	- Ammo Cache ×1 (engine_core skill) – fuels early plays and cheaper guns.
	- Minor Hex ×1 (instant hex) – sets up beam/hex synergies and Arc Conductor-style effects.
	- Minor Barrier ×1 (instant barrier) – early ring control and fortress hooks.
	- Guard Stance ×1 (defense) – stabilizer, scales with armor stats.
	- Precision Strike ×1 (instant single_target) – stack breaker and tag-scaling testbed.
	- Shove ×1 (ring_control) – barrier trigger and movement control.
	- Overclock ×1 (new) – "All deployed guns fire immediately for 75% damage; draw 1." (tempo lever).
	- Tag Infusion: Piercing ×1 (new) – "Add `piercing` tag to a chosen gun; piercing shots continue through a stack to hit a second enemy (overflow applies)." (turns Rusty Pistol into two-hit vs stacks).
- Early shop guidance: grab 1 more persistent gun (Twin Pistols/Choirbreaker/Infernal Pistol), 1 barrier enabler (Ring Ward/Barrier Sigil), and 1 extra tempo tool (Ammo Cache/Ritual Cartridge) to keep lane filling and firing twice per turn with Overclock.

## Card concepts (50, board/tag focus)

Includes the 10-card starter above (marked [Starter]). Costs and effects are balance targets.

| # | Card | Cost | Tags | Effect |
|---|------|------|------|--------|
| 1 | Rusty Pistol [Starter] | 1 | gun, persistent, single_target | End of turn: deal 3 damage to a random enemy. |
| 2 | Storm Carbine [Starter] | 2 | gun, persistent, close_focus | End of turn: deal 3 damage to 2 enemies in Close/Mid. |
| 3 | Ammo Cache [Starter] | 1 | skill, instant, engine_core, gun | Draw 2. Next gun costs 1 less this turn. |
| 4 | Minor Hex [Starter] | 1 | hex, instant, hex_ritual | Apply 3 hex to a random enemy. |
| 5 | Minor Barrier [Starter] | 1 | barrier, instant, ring_control, barrier_trap | Place barrier: 3 damage when crossed, 1 use. |
| 6 | Guard Stance [Starter] | 1 | defense, instant, fortress | Gain 4 armor. |
| 7 | Precision Strike [Starter] | 1 | gun, instant, aoe | Deal 2 damage to all enemies in a group. |
| 8 | Shove [Starter] | 1 | skill, instant, ring_control, volatile | Push 1 enemy back 1 ring; barrier hit deals 2. |
| 9 | Overclock [Starter] | 1 | skill, instant, engine_core | All deployed guns fire immediately for 75% damage; draw 1. |
| 10 | Tag Infusion: Piercing [Starter] | 1 | skill, instant | Add `piercing` to a chosen gun: its shots continue through a stack to hit a second enemy; overflow applies. |
| 11 | Mortar Team | 2 | gun, persistent, sniper, explosive | End of turn: 5 damage to Far, splash 2 to Mid; 3 ammo. Reload 2 scrap: restore 2 ammo. |
| 12 | Arc Conductor | 2 | engine, persistent, beam | Gain 1 charge when you play a hex card. End of turn: expend all charges to deal 3 chaining damage to that many enemies (prefers hexed). |
| 13 | Bulwark Drone | 2 | engine, persistent, fortress | End of turn: grant 2 armor. If you control 3+ barriers, also place a 2-damage, 1-use barrier in Close. |
| 14 | Pulse Array | 2 | gun, persistent, aoe, shock | Before enemy phase: deal 1 to all enemies in a chosen ring; if they moved this turn, apply Slow. |
| 15 | Ammo Foundry | 1 | engine, persistent, volatile | Every 2 kills: +1 damage to all deployed guns next turn; then lose 1 HP. |
| 16 | Scrap Forge | 1 | engine, persistent | On kill: 20% chance to create a 1-cost "Shard Shot" (gun, instant, 4 damage) in next hand. |
| 17 | Target Sync | 1 | skill, instant | Choose a ring; deployed guns prioritize it this turn and gain +2 damage against it. |
| 18 | Explosive Primer | 1 | skill, instant, explosive | This turn: explosive attacks double splash; explosive hits restore 1 use/HP to any friendly barrier they damage. |
| 19 | Hex Transfer | 1 | skill, instant, hex_ritual | Move all hex from one enemy to another; your next persistent gun applies 2 hex on hit this turn. |
| 20 | Barrier Channel | 1 | skill, instant, fortress | Trigger all barriers once without consuming uses; gain 1 armor per trigger. |
| 21 | Emergency Deploy | 1 | skill, instant, swarm_clear | Play top persistent gun from draw pile to lane at -1 cost; it fires once at 75% damage. |
| 22 | Piercing Ammo | 1 | skill, instant, piercing | This turn, guns gain piercing: overkill flows to next enemy in stack/ring (50% overflow). |
| 23 | Beam Splitter | 2 | gun, instant, beam, aoe | Deal 4 damage chaining to up to 3 enemies in the same ring; each hit spreads 1 hex if present. |
| 24 | Shock Lattice | 1 | engine, persistent, shock | When you play a ring_control card, deal 1 shock damage to all enemies in that ring; 20% chance to Slow. |
| 25 | Corrosive Rounds | 1 | skill, instant, corrosive | This turn, guns apply -2 armor shred on hit; if target has hex, shred doubles. |
| 26 | Scatter Mines | 2 | barrier, engine, persistent, barrier_trap, explosive | Place 3 mines across random rings: 3 damage, 2 uses, splash 1 to adjacent ring on trigger. |
| 27 | Kinetic Pulse | 1 | skill, instant, ring_control, shock | Push all Melee enemies to Close; deal 2 and apply Slow to pushed enemies. |
| 28 | Twin Lances | 2 | gun, persistent, beam, single_target | End of turn: deal 2 damage to 2 enemies; if both hits land in same stack, spread 1 hex to the stack. |
| 29 | Volley Rig | 2 | gun, persistent, shotgun, swarm_clear | End of turn: 1 damage 5 times in Melee/Close; each kill refunds 1 ammo charge (max 3 charges, +1 damage per charge). |
| 30 | Rail Piercer | 2 | gun, instant, piercing, sniper | Deal 9 damage; overflow 50% continues to the next enemy in line or stack. |
| 31 | Flame Coil | 1 | gun, instant, explosive, aoe | Deal 3 damage to a ring; splash 1 to adjacent rings; explosive hits add 1 hex. |
| 32 | Hex Lance Turret | 2 | engine, persistent, hex, beam | End of turn: deal 2 damage to a hexed enemy; if it survives, increase its hex by 1. |
| 33 | Barrier Siphon | 1 | skill, instant, lifedrain, fortress | Drain 2 HP from each barrier you control; heal equal to total drained; barriers keep uses. |
| 34 | Shock Net | 1 | barrier, instant, shock, ring_control | Place barrier: 0 damage, 2 uses; enemies crossing are Slowed and take +1 damage from shock this turn. |
| 35 | Pulse Repeater | 1 | engine, persistent, engine_core | At turn start, choose one: draw 1, or your next Overclock this turn costs 0. |
| 36 | Focused Salvo | 1 | gun, instant, single_target, engine_core | Deal 5 damage; if a deployed gun shares a tag with this (gun, explosive, beam, shock, piercing), it fires at the same target for +2 damage. |
| 37 | Fracture Rounds | 1 | skill, instant, piercing, swarm_clear | Next shotgun/piercing attack this turn repeats on a second random target for 50% damage. |
| 38 | Hex Capacitor | 1 | engine, persistent, hex_ritual | Whenever hex is consumed, gain 1 charge (max 3); spend a charge: next gun applies 2 hex. |
| 39 | Sentinel Barrier | 2 | barrier, engine, persistent, fortress | Place barrier with 3 HP, 2 damage; when it triggers, your weakest gun gains +1 damage this turn. |
| 40 | Overwatch Drone | 1 | engine, persistent, sniper | When you play a skill, deal 2 damage to a Far/Mid enemy. If none, hit a random enemy. |
| 41 | Ricochet Disk | 1 | gun, instant, piercing, shotgun | Deal 2 damage bouncing up to 4 times among enemies in Close/Mid; cannot hit same enemy twice. |
| 42 | Hex Bloom | 2 | hex, instant, aoe | Apply 1 hex to all enemies; if an enemy already has hex, apply +2 more to it. |
| 43 | Runic Overload | 1 | skill, instant, fortress, volatile | Gain 4 armor; if you have 3+ barriers, Overclock costs 0 this turn. |
| 44 | Barrier Bloom | 1 | skill, instant, barrier_trap | Choose a ring; duplicate each barrier there with 1 use and 1 damage. |
| 45 | Scrap Vents | 0 | skill, instant, volatile | Lose 2 HP; your next explosive or piercing card this turn gains +3 damage. |
| 46 | Shockwave Gauntlet | 1 | gun, instant, shock, ring_control | Deal 3 damage and push target 1 ring; if it hits a barrier, stun it for 1 turn. |
| 47 | Inferno Stack | 2 | gun, persistent, explosive, sniper | End of turn: deal 4 to Far/Mid; splash 2 to adjacent ring; each kill adds +1 splash (resets after firing if no kill). |
| 48 | Chain Reactor | 2 | engine, persistent, beam, explosive | First time you play a gun each turn, deal 2 beam damage to two enemies. If either dies, deal 2 explosive splash to its ring. |
| 49 | Glass Shards | 1 | gun, instant, piercing, volatile | Deal 6 damage; lose 2 armor. If target dies, gain 1 energy next turn. |
| 50 | Null Field | 1 | defense, instant, fortress | Gain 5 armor. This turn, enemies in Melee deal -2 damage; if you control a barrier, also slow Melee enemies. |

---

## New Artifacts (synergy with new card mechanics)

The existing 26 artifacts (listed in DESIGN.md) focus on the original build families and stat scaling. These new artifacts hook into the **damage-type tags**, **deployed gun/engine synergies**, **kill chains**, and **cross-tag combos** introduced above. Together with the originals, this creates ~48 artifacts for rich Brotato-style buildcraft.

### Damage-Type Tag Artifacts (8)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Blast Shielding | Common | ✓ | Explosive damage +15% |
| Piercing Scope | Common | ✓ | Piercing attacks deal +2 overflow damage |
| Arc Coil | Common | ✓ | Beam attacks chain to +1 additional target |
| Static Buildup | Uncommon | ✗ | Shock attacks have +20% chance to apply Slow |
| Corrosive Residue | Uncommon | ✗ | Corrosive attacks shred 1 additional armor |
| Unstable Payload | Uncommon | ✓ | Explosive splash damage +50%. Max HP -3 |
| Rifling Upgrade | Uncommon | ✓ | Piercing attacks ignore 1 armor per hit |
| Chain Lightning Module | Rare | ✗ | Beam attacks deal +1 damage per enemy already hit in the chain |

### Deployed Gun/Engine Artifacts (7)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Turret Oil | Common | ✓ | Deployed guns and engines deal +10% damage |
| Firing Solution | Uncommon | ✗ | Deployed guns deal +1 damage per other gun on the board (max +3) |
| Ammo Belts | Common | ✓ | Guns with limited ammo have +1 max ammo |
| Quick Draw | Uncommon | ✗ | First gun you play each turn costs 1 less |
| Autoloader | Rare | ✗ | When a gun runs out of ammo, 30% chance to fully reload it |
| Engine Sync | Uncommon | ✗ | When you play an engine, all deployed guns fire once at 50% damage |
| Lane Commander | Rare | ✗ | Start of turn: if 4+ cards deployed in lane, gain 1 energy |

### Kill Chain / On-Kill Artifacts (6)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Hunter's Quota | Common | ✓ | On kill: gain 1 scrap |
| Rampage Core | Uncommon | ✗ | On kill: next gun this turn deals +2 damage (stacks up to 3 kills) |
| Salvage Frame | Uncommon | ✓ | On kill: 15% chance to draw a card |
| Execution Protocol | Rare | ✗ | Kill 4+ enemies in a single turn: gain 1 energy next turn |
| Overkill Catalyst | Uncommon | ✗ | On kill with overkill: deal overkill amount to a random enemy in the same ring |
| Blood Harvest | Uncommon | ✗ | On kill: heal 1 HP. Max HP -5 |

### Cross-Tag Synergy Artifacts (6)

These reward mixing damage types and build families, Brotato-style.

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Detonation Matrix | Rare | ✗ | Explosive damage to barriers restores 1 barrier use instead of consuming it |
| Hex Conductor | Rare | ✗ | Beam attacks spread hex to chained targets instead of consuming hex |
| Tesla Casing | Uncommon | ✗ | Shotgun attacks with shock apply Slow to all targets hit |
| Overflow Transfusion | Rare | ✗ | Piercing overflow damage heals you for 50% of overflow dealt |
| Corrosive Resonance | Uncommon | ✗ | Corrosive armor shred on hexed enemies is doubled |
| Volatile Reactor | Rare | ✗ | When you take self-damage, deal that damage to a random enemy in Melee/Close |

### Tempo / Overclock Artifacts (5)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Overclock Capacitor | Uncommon | ✗ | First Overclock you play each turn costs 0 |
| Burst Amplifier | Common | ✓ | "Fire immediately" effects deal +2 damage |
| Coolant System | Uncommon | ✗ | After playing 3 skill cards in a turn, draw 1 card |
| Rapid Deployment | Common | ✓ | Persistent guns deploy with +1 damage for their first firing |
| Infusion Anchor | Uncommon | ✗ | Tag Infusion cards also grant +1 permanent damage to the infused gun |

---

### Artifact Design Notes

**Existing artifacts to keep unchanged:**
All 26 original artifacts (Sharpened Rounds, Hex Lens, Leech Core, Occult Focus, Trap Engineer, etc.) work fine with the new cards. They provide baseline stat scaling and build-family hooks.

**New stats needed in PlayerStats:**
- `explosive_damage_percent` (default 100)
- `piercing_damage_percent` (default 100)
- `beam_damage_percent` (default 100)
- `shock_damage_percent` (default 100)
- `corrosive_damage_percent` (default 100)
- `deployed_gun_damage_percent` (default 100)
- `engine_damage_percent` (default 100)

**New trigger types needed in ArtifactDefinition:**
- `on_explosive_hit`
- `on_piercing_overflow`
- `on_beam_chain`
- `on_shock_hit`
- `on_corrosive_hit`
- `on_gun_deploy`
- `on_gun_fire`
- `on_gun_out_of_ammo`
- `on_engine_trigger`
- `on_self_damage`
- `on_overkill`

**Priority order for implementation:**
1. Damage-type tag artifacts (enable the new tags)
2. Deployed gun artifacts (enable board-centric play)
3. Kill chain artifacts (reward clearing efficiently)
4. Cross-tag artifacts (reward hybrid builds)
5. Tempo artifacts (reward Overclock/skill chains)
